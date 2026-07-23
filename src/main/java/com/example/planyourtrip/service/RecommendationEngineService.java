package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PlaceDto.PlaceSummaryResponse;
import com.example.planyourtrip.dto.RecommendationEngineDto.RecommendationResponse;
import com.example.planyourtrip.dto.UserInterestDto.InterestProfileResponse;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Phase 7.49 — the deterministic, rule-based Recommendation Engine foundation.
 *
 * <p><b>Not AI.</b> No GPT, ML, embeddings or vector search. It scores every published place against
 * the acting user's persisted {@link UserInterestProfile} (Phase 7.48) with a fixed weighted model,
 * normalises to 0–100, attaches a confidence and the matched interest dimensions, and returns a
 * deterministically ordered list.
 *
 * <p><b>Reuse, not duplication.</b> The user-interest vector is the Phase 7.48 profile (which already
 * aggregates completed bookings, wishlist, saved collections and approved reviews) — this engine does
 * NOT re-mine raw signals. Place summaries reuse {@link PlaceService#toSummary}. It shares nothing
 * with, and does not touch, the Phase 7.23 persisted/rule-based recommendation snapshot system.
 *
 * <p><b>Determinism.</b> Scoring is pure integer arithmetic over profile/place data; ordering is
 * (score desc, confidence desc, placeId asc). No randomness, no timestamps, no UUIDs, no hash-order
 * iteration influences the result — two identical databases always produce identical ordering.
 */
@Service
@Transactional(readOnly = true)
public class RecommendationEngineService {

    // ── Fixed dimension weights (spec 7.49) ───────────────────────────────────────────────────
    static final int W_TRAVEL_STYLE  = 30;
    static final int W_BUDGET        = 20;
    static final int W_PROVINCE      = 15;
    static final int W_CATEGORY      = 15;
    static final int W_TAGS          = 10;
    static final int W_ACCESSIBILITY = 5;
    static final int W_CROWD         = 5;
    static final int W_WEATHER       = 5;

    /** Sum of all weights — the raw score of a place that matches every populated dimension. */
    static final int MAX_RAW = W_TRAVEL_STYLE + W_BUDGET + W_PROVINCE + W_CATEGORY
        + W_TAGS + W_ACCESSIBILITY + W_CROWD + W_WEATHER; // 105

    /** Upper bound on returned recommendations (deterministic top-N after sorting). */
    static final int MAX_RESULTS = 50;

    private final UserInterestProfileService interestProfileService;
    private final PlaceRepository placeRepo;
    private final PlaceMetadataRepository metadataRepo;
    private final PlaceTagRepository tagRepo;
    private final CategoryRepository categoryRepo;
    private final AdministrativeUnitRepository unitRepo;
    private final PlaceService placeService;

    public RecommendationEngineService(UserInterestProfileService interestProfileService,
                                       PlaceRepository placeRepo,
                                       PlaceMetadataRepository metadataRepo,
                                       PlaceTagRepository tagRepo,
                                       CategoryRepository categoryRepo,
                                       AdministrativeUnitRepository unitRepo,
                                       PlaceService placeService) {
        this.interestProfileService = interestProfileService;
        this.placeRepo = placeRepo;
        this.metadataRepo = metadataRepo;
        this.tagRepo = tagRepo;
        this.categoryRepo = categoryRepo;
        this.unitRepo = unitRepo;
        this.placeService = placeService;
    }

    /**
     * Live, own-scoped recommendations for the acting user. Derives ONLY from that user's persisted
     * interest profile — never another user's data. An empty / never-recalculated profile yields an
     * empty list (nothing to match against).
     */
    public List<RecommendationResponse> recommend(Long userId) {
        InterestProfileResponse profile = interestProfileService.get(userId);

        // Weight of the dimensions the profile actually carries data for (confidence denominator).
        int populatedWeight = 0;
        boolean hasStyles = !profile.preferredTravelStyles().isEmpty();
        boolean hasBudget = profile.preferredBudgetLevel() != null;
        boolean hasProvinces = !profile.favoriteProvinces().isEmpty();
        boolean hasCategories = !profile.favoriteCategories().isEmpty();
        boolean hasTags = !profile.favoriteTags().isEmpty();
        boolean hasAccessibility = profile.preferredAccessibilityLevel() != null;
        boolean hasCrowd = profile.preferredCrowdLevel() != null;
        boolean hasWeather = !profile.preferredWeatherTypes().isEmpty();
        if (hasStyles) populatedWeight += W_TRAVEL_STYLE;
        if (hasBudget) populatedWeight += W_BUDGET;
        if (hasProvinces) populatedWeight += W_PROVINCE;
        if (hasCategories) populatedWeight += W_CATEGORY;
        if (hasTags) populatedWeight += W_TAGS;
        if (hasAccessibility) populatedWeight += W_ACCESSIBILITY;
        if (hasCrowd) populatedWeight += W_CROWD;
        if (hasWeather) populatedWeight += W_WEATHER;

        // No usable interest signal → nothing can match → empty (spec: empty profile ⇒ empty list).
        if (populatedWeight == 0) return List.of();

        // Fast-contains sets for the profile vector (case-insensitive names, deterministic content).
        Set<TravelStyle> styleSet = new HashSet<>(profile.preferredTravelStyles());
        Set<WeatherType> weatherSet = new HashSet<>(profile.preferredWeatherTypes());
        Set<String> provinceSet = lower(profile.favoriteProvinces());
        Set<String> categorySet = lower(profile.favoriteCategories());
        Set<String> tagSet = lower(profile.favoriteTags());

        // ── Filtering: only PUBLISHED + active places (excludes DRAFT / PENDING_REVIEW / APPROVED /
        //    HIDDEN / ARCHIVED / REJECTED, and soft-deleted rows). ──────────────────────────────
        List<Place> candidates = placeRepo.findByStatus(PlaceStatus.PUBLISHED).stream()
            .filter(Place::isActive)
            .toList();
        if (candidates.isEmpty()) return List.of();

        List<Long> placeIds = candidates.stream().map(Place::getId).toList();

        // ── Batch loads (no N+1) ──────────────────────────────────────────────────────────────
        Map<Long, PlaceMetadata> metaByPlace = metadataRepo.findByPlaceIdIn(placeIds).stream()
            .filter(m -> m.getPlace() != null && m.getPlace().getId() != null)
            .collect(Collectors.toMap(m -> m.getPlace().getId(), m -> m, (a, b) -> a));

        Map<Long, List<String>> tagsByPlace = new HashMap<>();
        for (PlaceTag t : tagRepo.findByPlaceIdIn(placeIds)) {
            if (t.getPlace() == null || t.getPlace().getId() == null) continue;
            String tag = normalize(t.getTag());
            if (tag != null) tagsByPlace.computeIfAbsent(t.getPlace().getId(), k -> new ArrayList<>()).add(tag);
        }

        // Category / province names resolved by id (proxy id needs no load), then batch-fetched.
        Set<Long> catIds = new HashSet<>();
        Set<Long> unitIds = new HashSet<>();
        for (Place p : candidates) {
            if (p.getCategory() != null) catIds.add(p.getCategory().getId());
            if (p.getAdministrativeUnit() != null) unitIds.add(p.getAdministrativeUnit().getId());
        }
        Map<Long, String> catNameById = categoryRepo.findAllById(catIds).stream()
            .collect(Collectors.toMap(Category::getId, Category::getName, (a, b) -> a));
        Map<Long, String> unitNameById = unitRepo.findAllById(unitIds).stream()
            .collect(Collectors.toMap(AdministrativeUnit::getId, AdministrativeUnit::getName, (a, b) -> a));

        // ── Score every candidate ─────────────────────────────────────────────────────────────
        List<Scored> scored = new ArrayList<>();
        for (Place place : candidates) {
            Scored s = score(place, metaByPlace.get(place.getId()),
                tagsByPlace.getOrDefault(place.getId(), List.of()),
                place.getCategory() != null ? catNameById.get(place.getCategory().getId()) : null,
                place.getAdministrativeUnit() != null ? unitNameById.get(place.getAdministrativeUnit().getId()) : null,
                styleSet, weatherSet, provinceSet, categorySet, tagSet,
                profile, populatedWeight);
            if (s != null) scored.add(s); // null ⇒ raw 0 ⇒ not recommended
        }

        // ── Deterministic ordering: score desc, confidence desc, placeId asc ──────────────────
        scored.sort(Comparator.comparingInt((Scored s) -> s.score).reversed()
            .thenComparing(Comparator.comparingInt((Scored s) -> s.confidence).reversed())
            .thenComparing(s -> s.place.getId()));

        return scored.stream()
            .limit(MAX_RESULTS)
            .map(s -> s.response)
            .toList();
    }

    // ── Scoring (pure, deterministic) ───────────────────────────────────────────────────────────

    private Scored score(Place place, PlaceMetadata meta, List<String> placeTags,
                         String categoryName, String provinceName,
                         Set<TravelStyle> styleSet, Set<WeatherType> weatherSet,
                         Set<String> provinceSet, Set<String> categorySet, Set<String> tagSet,
                         InterestProfileResponse profile, int populatedWeight) {
        int raw = 0;

        // Travel style (30) — any overlap with the profile's preferred styles.
        List<TravelStyle> matchedStyles = new ArrayList<>();
        if (meta != null && meta.getTravelStyles() != null) {
            for (TravelStyle style : profile.preferredTravelStyles()) {   // profile order = deterministic
                if (meta.getTravelStyles().contains(style)) matchedStyles.add(style);
            }
        }
        if (!matchedStyles.isEmpty()) raw += W_TRAVEL_STYLE;

        // Budget (20) — exact modal budget match.
        BudgetLevel matchedBudget = null;
        if (meta != null && meta.getEstimatedBudgetLevel() != null
            && meta.getEstimatedBudgetLevel() == profile.preferredBudgetLevel()) {
            matchedBudget = meta.getEstimatedBudgetLevel();
            raw += W_BUDGET;
        }

        // Province (15).
        String matchedProvince = null;
        if (provinceName != null && provinceSet.contains(provinceName.toLowerCase(Locale.ROOT))) {
            matchedProvince = provinceName;
            raw += W_PROVINCE;
        }

        // Category (15) — a place has one category (0 or 1 match).
        List<String> matchedCategories = new ArrayList<>();
        if (categoryName != null && categorySet.contains(categoryName.toLowerCase(Locale.ROOT))) {
            matchedCategories.add(categoryName);
            raw += W_CATEGORY;
        }

        // Tags (10) — any overlap. Deterministic order: follow the profile's favouriteTags order.
        List<String> matchedTags = new ArrayList<>();
        if (!placeTags.isEmpty()) {
            Set<String> placeTagLower = lower(placeTags);
            for (String favTag : profile.favoriteTags()) {
                if (placeTagLower.contains(favTag.toLowerCase(Locale.ROOT))) matchedTags.add(favTag);
            }
        }
        if (!matchedTags.isEmpty()) raw += W_TAGS;

        // Accessibility (5).
        AccessibilityLevel matchedAccessibility = null;
        if (meta != null && meta.getAccessibilityLevel() != null
            && meta.getAccessibilityLevel() == profile.preferredAccessibilityLevel()) {
            matchedAccessibility = meta.getAccessibilityLevel();
            raw += W_ACCESSIBILITY;
        }

        // Crowd (5).
        CrowdLevel matchedCrowd = null;
        if (meta != null && meta.getCrowdLevel() != null
            && meta.getCrowdLevel() == profile.preferredCrowdLevel()) {
            matchedCrowd = meta.getCrowdLevel();
            raw += W_CROWD;
        }

        // Weather (5) — any overlap.
        List<WeatherType> matchedWeather = new ArrayList<>();
        if (meta != null && meta.getWeatherTypes() != null) {
            for (WeatherType w : profile.preferredWeatherTypes()) {
                if (meta.getWeatherTypes().contains(w)) matchedWeather.add(w);
            }
        }
        if (!matchedWeather.isEmpty()) raw += W_WEATHER;

        if (raw == 0) return null; // nothing matched → not a recommendation

        int score = (int) Math.round(raw * 100.0 / MAX_RAW);
        int confidence = (int) Math.round(raw * 100.0 / populatedWeight);

        List<String> reasons = buildReasons(matchedStyles, matchedBudget, matchedProvince,
            matchedCategories, matchedTags, matchedWeather, matchedCrowd, matchedAccessibility);

        PlaceSummaryResponse summary = placeService.toSummary(place);
        RecommendationResponse response = new RecommendationResponse(
            summary, score, confidence, reasons,
            matchedStyles, matchedBudget, matchedProvince, matchedCategories, matchedTags,
            matchedWeather, matchedCrowd, matchedAccessibility);

        Scored s = new Scored();
        s.place = place;
        s.score = score;
        s.confidence = confidence;
        s.response = response;
        return s;
    }

    /** Human-readable reasons in a fixed dimension order (deterministic). */
    private List<String> buildReasons(List<TravelStyle> styles, BudgetLevel budget, String province,
                                      List<String> categories, List<String> tags,
                                      List<WeatherType> weather, CrowdLevel crowd,
                                      AccessibilityLevel accessibility) {
        List<String> reasons = new ArrayList<>();
        if (!styles.isEmpty()) reasons.add("Matches your travel style: " + join(styles));
        if (budget != null) reasons.add("Matches your preferred budget: " + budget.name());
        if (province != null) reasons.add("In a province you love: " + province);
        if (!categories.isEmpty()) reasons.add("A category you favour: " + String.join(", ", categories));
        if (!tags.isEmpty()) reasons.add("Shares tags you like: " + String.join(", ", tags));
        if (!weather.isEmpty()) reasons.add("Matches your preferred weather: " + join(weather));
        if (crowd != null) reasons.add("Matches your preferred crowd level: " + crowd.name());
        if (accessibility != null) reasons.add("Matches your accessibility preference: " + accessibility.name());
        return reasons;
    }

    private static <E extends Enum<E>> String join(List<E> values) {
        return values.stream().map(Enum::name).collect(Collectors.joining(", "));
    }

    private static Set<String> lower(List<String> values) {
        Set<String> out = new HashSet<>();
        for (String v : values) {
            String n = normalize(v);
            if (n != null) out.add(n.toLowerCase(Locale.ROOT));
        }
        return out;
    }

    private static String normalize(String s) {
        if (s == null) return null;
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }

    private static final class Scored {
        Place place;
        int score;
        int confidence;
        RecommendationResponse response;
    }
}
