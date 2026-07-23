package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.UserInterestDto.InterestProfileResponse;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;

/**
 * Phase 7.48 — derives and persists the read-only {@link UserInterestProfile}.
 *
 * <p><b>What it aggregates.</b> Four implicit signal sources, each resolving to a {@link Place}:
 * <ol>
 *   <li>completed bookings ({@code CHECKED_OUT} / {@code COMPLETED});</li>
 *   <li>wishlist items;</li>
 *   <li>saved-collection places;</li>
 *   <li>approved reviews the user left with {@code ratingOverall >= }{@value #POSITIVE_REVIEW_THRESHOLD}
 *       (a low rating is not a positive-interest signal).</li>
 * </ol>
 * A place that appears in several sources contributes several times (a stronger signal). From each
 * place it pulls the reused {@link PlaceMetadata} taxonomy enums (travel style / weather / budget /
 * crowd / accessibility) plus the place's province ({@link AdministrativeUnit}), {@link Category} and
 * {@link PlaceTag}s.
 *
 * <p><b>Determinism.</b> Every list is a frequency ranking sorted by (count desc, then key asc) and
 * capped at {@value #MAX_LIST}; every scalar enum is the mode (ties broken by enum name). Identical
 * signal data therefore always yields byte-identical field values — only {@code lastRecalculatedAt}
 * moves. No AI / ML / randomness / recommendation ranking is involved; this is pure behavioural
 * aggregation.
 *
 * <p><b>Read purity.</b> {@link #get} never persists (no lazy row creation) — it returns the stored
 * profile or an empty snapshot. {@link #recalculate} is the only mutation and upserts the single row.
 */
@Service
public class UserInterestProfileService {

    /** Minimum overall rating for an approved review to count as a positive interest signal. */
    static final int POSITIVE_REVIEW_THRESHOLD = 4;

    /** Cap for each ranked list (travel styles / weather / provinces / categories / tags). */
    private static final int MAX_LIST = 10;

    private static final Set<BookingStatus> COMPLETED_BOOKING_STATUSES =
        EnumSet.of(BookingStatus.CHECKED_OUT, BookingStatus.COMPLETED);

    private final UserInterestProfileRepository profileRepo;
    private final BookingRepository bookingRepo;
    private final WishlistRepository wishlistRepo;
    private final WishlistItemRepository wishlistItemRepo;
    private final SavedCollectionRepository savedCollectionRepo;
    private final SavedCollectionPlaceRepository savedCollectionPlaceRepo;
    private final ReviewRepository reviewRepo;
    private final PlaceMetadataRepository placeMetadataRepo;
    private final PlaceTagRepository placeTagRepo;

    public UserInterestProfileService(UserInterestProfileRepository profileRepo,
                                      BookingRepository bookingRepo,
                                      WishlistRepository wishlistRepo,
                                      WishlistItemRepository wishlistItemRepo,
                                      SavedCollectionRepository savedCollectionRepo,
                                      SavedCollectionPlaceRepository savedCollectionPlaceRepo,
                                      ReviewRepository reviewRepo,
                                      PlaceMetadataRepository placeMetadataRepo,
                                      PlaceTagRepository placeTagRepo) {
        this.profileRepo = profileRepo;
        this.bookingRepo = bookingRepo;
        this.wishlistRepo = wishlistRepo;
        this.wishlistItemRepo = wishlistItemRepo;
        this.savedCollectionRepo = savedCollectionRepo;
        this.savedCollectionPlaceRepo = savedCollectionPlaceRepo;
        this.reviewRepo = reviewRepo;
        this.placeMetadataRepo = placeMetadataRepo;
        this.placeTagRepo = placeTagRepo;
    }

    /** Read the persisted profile, or an empty (never-recalculated) snapshot. Never mutates. */
    @Transactional(readOnly = true)
    public InterestProfileResponse get(Long userId) {
        return profileRepo.findByUserId(userId)
            .map(this::toResponse)
            .orElseGet(() -> emptyResponse(userId));
    }

    /** Re-derive every field from current signals and upsert the single per-user row. */
    @Transactional
    public InterestProfileResponse recalculate(Long userId) {
        List<Place> signals = collectSignalPlaces(userId);

        // Frequency accumulators.
        Map<TravelStyle, Integer> styleCounts = new HashMap<>();
        Map<WeatherType, Integer> weatherCounts = new HashMap<>();
        Map<BudgetLevel, Integer> budgetCounts = new HashMap<>();
        Map<CrowdLevel, Integer> crowdCounts = new HashMap<>();
        Map<AccessibilityLevel, Integer> accessCounts = new HashMap<>();
        Map<String, Integer> provinceCounts = new HashMap<>();
        Map<String, Integer> categoryCounts = new HashMap<>();
        Map<String, Integer> tagCounts = new HashMap<>();

        // Batch-load metadata for all distinct signal places (avoids N+1 on the OneToOne).
        Set<Long> distinctPlaceIds = new HashSet<>();
        for (Place p : signals) {
            if (p != null && p.getId() != null) distinctPlaceIds.add(p.getId());
        }
        Map<Long, PlaceMetadata> metadataByPlaceId = new HashMap<>();
        if (!distinctPlaceIds.isEmpty()) {
            for (PlaceMetadata md : placeMetadataRepo.findByPlaceIdIn(distinctPlaceIds)) {
                if (md.getPlace() != null && md.getPlace().getId() != null) {
                    metadataByPlaceId.put(md.getPlace().getId(), md);
                }
            }
        }
        // Tags have no bulk lookup — resolve once per distinct place, reuse across occurrences.
        Map<Long, List<String>> tagsByPlaceId = new HashMap<>();
        for (Long pid : distinctPlaceIds) {
            List<String> tags = new ArrayList<>();
            for (PlaceTag t : placeTagRepo.findAllByPlaceId(pid)) {
                String tag = normalize(t.getTag());
                if (tag != null) tags.add(tag);
            }
            tagsByPlaceId.put(pid, tags);
        }

        for (Place place : signals) {
            if (place == null || place.getId() == null) continue;

            // Province & category come straight off the Place (both non-null columns; defensive anyway).
            addName(provinceCounts, place.getAdministrativeUnit() != null
                ? place.getAdministrativeUnit().getName() : null);
            addName(categoryCounts, place.getCategory() != null
                ? place.getCategory().getName() : null);

            for (String tag : tagsByPlaceId.getOrDefault(place.getId(), List.of())) {
                increment(tagCounts, tag);
            }

            PlaceMetadata md = metadataByPlaceId.get(place.getId());
            if (md == null) continue; // null-safe: a place may have no metadata row

            // Distinct styles/weathers within one place count once per signal occurrence.
            if (md.getTravelStyles() != null) {
                for (TravelStyle s : new LinkedHashSet<>(md.getTravelStyles())) {
                    if (s != null) increment(styleCounts, s);
                }
            }
            if (md.getWeatherTypes() != null) {
                for (WeatherType w : new LinkedHashSet<>(md.getWeatherTypes())) {
                    if (w != null) increment(weatherCounts, w);
                }
            }
            if (md.getEstimatedBudgetLevel() != null) increment(budgetCounts, md.getEstimatedBudgetLevel());
            if (md.getCrowdLevel() != null) increment(crowdCounts, md.getCrowdLevel());
            if (md.getAccessibilityLevel() != null) increment(accessCounts, md.getAccessibilityLevel());
        }

        UserInterestProfile profile = profileRepo.findByUserId(userId)
            .orElseGet(() -> {
                UserInterestProfile fresh = new UserInterestProfile();
                fresh.setUserId(userId);
                return fresh;
            });

        // Replace (never merge) — a recalculation is a full re-derivation. On an existing row these
        // reassign the JPA element collections, so the assigned lists must be mutable.
        profile.setPreferredTravelStyles(new ArrayList<>(topEnums(styleCounts)));
        profile.setPreferredWeatherTypes(new ArrayList<>(topEnums(weatherCounts)));
        profile.setPreferredBudgetLevel(mode(budgetCounts));
        profile.setPreferredCrowdLevel(mode(crowdCounts));
        profile.setPreferredAccessibilityLevel(mode(accessCounts));
        profile.setFavoriteProvinces(new ArrayList<>(topStrings(provinceCounts)));
        profile.setFavoriteCategories(new ArrayList<>(topStrings(categoryCounts)));
        profile.setFavoriteTags(new ArrayList<>(topStrings(tagCounts)));
        profile.setSignalCount(signals.size());
        profile.setLastRecalculatedAt(Instant.now());

        return toResponse(profileRepo.save(profile));
    }

    // ── Signal collection ───────────────────────────────────────────────────────────────────

    private List<Place> collectSignalPlaces(Long userId) {
        List<Place> places = new ArrayList<>();

        // 1) Completed bookings → the booked place ("hotel").
        for (Booking b : bookingRepo.findByUserIdOrderByCreatedAtDesc(userId)) {
            if (b.getStatus() != null && COMPLETED_BOOKING_STATUSES.contains(b.getStatus())) {
                if (b.getHotel() != null) places.add(b.getHotel());
            }
        }

        // 2) Wishlist items.
        wishlistRepo.findByUserId(userId).ifPresent(wl ->
            wishlistItemRepo.findByWishlistIdOrderByCreatedAtDesc(wl.getId())
                .forEach(item -> { if (item.getPlace() != null) places.add(item.getPlace()); }));

        // 3) Saved-collection places (across all of the user's collections).
        for (SavedCollection col : savedCollectionRepo.findByOwnerIdOrderBySortOrderAscCreatedAtAsc(userId)) {
            for (SavedCollectionPlace scp : savedCollectionPlaceRepo.findByCollectionIdOrderByPositionAsc(col.getId())) {
                if (scp.getPlace() != null) places.add(scp.getPlace());
            }
        }

        // 4) Approved reviews the user rated positively.
        for (Review r : reviewRepo.findByUserIdOrderByCreatedAtDesc(userId)) {
            if (r.getStatus() == ReviewStatus.APPROVED
                && r.getRatingOverall() >= POSITIVE_REVIEW_THRESHOLD
                && r.getPlace() != null) {
                places.add(r.getPlace());
            }
        }

        return places;
    }

    // ── Deterministic ranking helpers ───────────────────────────────────────────────────────

    private static <K extends Enum<K>> void increment(Map<K, Integer> m, K key) {
        m.merge(key, 1, Integer::sum);
    }

    private static void increment(Map<String, Integer> m, String key) {
        m.merge(key, 1, Integer::sum);
    }

    private static void addName(Map<String, Integer> m, String rawName) {
        String name = normalize(rawName);
        if (name != null) increment(m, name);
    }

    private static String normalize(String s) {
        if (s == null) return null;
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }

    /** Enum ranking: (count desc, enum name asc), capped at {@link #MAX_LIST}. */
    private static <K extends Enum<K>> List<K> topEnums(Map<K, Integer> counts) {
        return counts.entrySet().stream()
            .sorted(Comparator.<Map.Entry<K, Integer>>comparingInt(Map.Entry::getValue).reversed()
                .thenComparing(e -> e.getKey().name()))
            .limit(MAX_LIST)
            .map(Map.Entry::getKey)
            .toList();
    }

    /** String ranking: (count desc, value asc), capped at {@link #MAX_LIST}. Keys already de-duplicated. */
    private static List<String> topStrings(Map<String, Integer> counts) {
        return counts.entrySet().stream()
            .sorted(Comparator.<Map.Entry<String, Integer>>comparingInt(Map.Entry::getValue).reversed()
                .thenComparing(Map.Entry::getKey))
            .limit(MAX_LIST)
            .map(Map.Entry::getKey)
            .toList();
    }

    /** Modal enum value: (count desc, enum name asc). Null when no data. */
    private static <K extends Enum<K>> K mode(Map<K, Integer> counts) {
        return counts.entrySet().stream()
            .max(Comparator.<Map.Entry<K, Integer>>comparingInt(Map.Entry::getValue)
                .thenComparing(e -> e.getKey().name(), Comparator.reverseOrder()))
            .map(Map.Entry::getKey)
            .orElse(null);
    }

    // ── Mapping ─────────────────────────────────────────────────────────────────────────────

    private InterestProfileResponse toResponse(UserInterestProfile p) {
        return new InterestProfileResponse(
            p.getUserId(),
            List.copyOf(p.getPreferredTravelStyles()),
            List.copyOf(p.getPreferredWeatherTypes()),
            p.getPreferredBudgetLevel(),
            p.getPreferredCrowdLevel(),
            p.getPreferredAccessibilityLevel(),
            List.copyOf(p.getFavoriteProvinces()),
            List.copyOf(p.getFavoriteCategories()),
            List.copyOf(p.getFavoriteTags()),
            p.getSignalCount(),
            p.getLastRecalculatedAt()
        );
    }

    private InterestProfileResponse emptyResponse(Long userId) {
        return new InterestProfileResponse(
            userId, List.of(), List.of(), null, null, null,
            List.of(), List.of(), List.of(), 0, null
        );
    }
}
