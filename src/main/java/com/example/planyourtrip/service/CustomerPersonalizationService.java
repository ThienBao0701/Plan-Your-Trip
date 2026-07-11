package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.dto.PersonalizationDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Phase 7.23 — Personalized Offers &amp; Rule-Based Recommendations.
 *
 * <p><b>Rule-based, deterministic, additive.</b> This service does NOT integrate
 * any AI/ML model, create embeddings, or introduce a second promotion/coupon
 * engine. It mines EXISTING customer activity (wishlist, recently-viewed,
 * bookings, profile, membership/loyalty, trips) into a preference profile, runs
 * admin-configured {@link PersonalizationRule}s to pick candidate resources from
 * the live catalogue, scores them with a single centralized deterministic model
 * (0–100), and writes read-only {@link CustomerRecommendation} snapshots. It
 * never claims coupons, reserves rooms, or changes prices.
 *
 * <p><b>Reuse.</b> Target summaries are produced by the existing response
 * mappers ({@code PlaceService#toSummary}, {@code HotelRoomService#toResponse},
 * {@code PromotionService#toResponse}, {@code CouponDefinitionService#toResponse}),
 * and coupon tier-eligibility reuses
 * {@code CustomerMembershipService#effectiveTierForUser} (the same accessor the
 * coupon eligibility evaluator uses) — no tier-comparison logic is duplicated.
 *
 * <p><b>TRIP_IDEA</b> is produced (only) by an {@code ABANDONED_INTEREST} rule,
 * as a PLACE-backed snapshot in an incomplete trip's destination tagged with
 * {@link RecommendationReasonCode#CONTINUE_PLANNING}. Future booking-attribution
 * work (auto-marking {@code convertedAt} when a recommended hotel/room is later
 * booked) is intentionally deferred — see class-level notes in the phase report.
 */
@Service
@Transactional(readOnly = true)
public class CustomerPersonalizationService {

    // ── Centralized scoring model (single source of truth) ────────────────────
    static final int MAX_SCORE = 100;
    static final int DESTINATION_MATCH = 40;
    static final int PLACE_TYPE_MATCH = 20;
    static final int TRAVEL_STYLE_MATCH = 20;
    static final int WISHLIST_SIGNAL = 25;
    static final int RECENTLY_VIEWED_SIGNAL = 15;
    static final int BOOKING_DESTINATION = 15;
    static final int ACTIVE_PROMOTION = 10;
    static final int MEMBERSHIP_EXCLUSIVE = 10;
    static final int OFFER_BASE = 20;
    static final int TRENDING_BASE = 15;
    static final int MANUAL_BASE = 35;

    static final int MAX_RECOMMENDATIONS = 50;
    static final int SIGNAL_LIMIT = 50;
    static final int TRENDING_LIMIT = 10;
    static final long DEFAULT_EXPIRY_DAYS = 30;

    private final CustomerRecommendationRepository recRepo;
    private final PersonalizationRuleRepository ruleRepo;
    private final UserRepository userRepo;
    private final WishlistRepository wishlistRepo;
    private final WishlistItemRepository wishlistItemRepo;
    private final RecentlyViewedPlaceRepository recentlyViewedRepo;
    private final BookingRepository bookingRepo;
    private final CustomerProfileRepository customerProfileRepo;
    private final TripPlanRepository tripPlanRepo;
    private final PlaceRepository placeRepo;
    private final PlaceMetadataRepository metadataRepo;
    private final HotelDetailRepository hotelDetailRepo;
    private final HotelRoomRepository hotelRoomRepo;
    private final PromotionRepository promotionRepo;
    private final CouponDefinitionRepository couponRepo;
    private final LoyaltyAccountRepository loyaltyAccountRepo;
    private final CustomerMembershipService membershipService;
    private final PlaceService placeService;
    private final HotelRoomService hotelRoomService;
    private final PromotionService promotionService;
    private final CouponDefinitionService couponDefinitionService;

    public CustomerPersonalizationService(CustomerRecommendationRepository recRepo,
                                          PersonalizationRuleRepository ruleRepo,
                                          UserRepository userRepo,
                                          WishlistRepository wishlistRepo,
                                          WishlistItemRepository wishlistItemRepo,
                                          RecentlyViewedPlaceRepository recentlyViewedRepo,
                                          BookingRepository bookingRepo,
                                          CustomerProfileRepository customerProfileRepo,
                                          TripPlanRepository tripPlanRepo,
                                          PlaceRepository placeRepo,
                                          PlaceMetadataRepository metadataRepo,
                                          HotelDetailRepository hotelDetailRepo,
                                          HotelRoomRepository hotelRoomRepo,
                                          PromotionRepository promotionRepo,
                                          CouponDefinitionRepository couponRepo,
                                          LoyaltyAccountRepository loyaltyAccountRepo,
                                          CustomerMembershipService membershipService,
                                          PlaceService placeService,
                                          HotelRoomService hotelRoomService,
                                          PromotionService promotionService,
                                          CouponDefinitionService couponDefinitionService) {
        this.recRepo = recRepo;
        this.ruleRepo = ruleRepo;
        this.userRepo = userRepo;
        this.wishlistRepo = wishlistRepo;
        this.wishlistItemRepo = wishlistItemRepo;
        this.recentlyViewedRepo = recentlyViewedRepo;
        this.bookingRepo = bookingRepo;
        this.customerProfileRepo = customerProfileRepo;
        this.tripPlanRepo = tripPlanRepo;
        this.placeRepo = placeRepo;
        this.metadataRepo = metadataRepo;
        this.hotelDetailRepo = hotelDetailRepo;
        this.hotelRoomRepo = hotelRoomRepo;
        this.promotionRepo = promotionRepo;
        this.couponRepo = couponRepo;
        this.loyaltyAccountRepo = loyaltyAccountRepo;
        this.membershipService = membershipService;
        this.placeService = placeService;
        this.hotelRoomService = hotelRoomService;
        this.promotionService = promotionService;
        this.couponDefinitionService = couponDefinitionService;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // GENERATION
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Regenerates the user's active recommendation set. Deletes only unengaged
     * active snapshots, preserves clicked/converted/dismissed history, prevents
     * duplicate active recommendations for the same user+type+target, and caps
     * the generated set at {@link #MAX_RECOMMENDATIONS}. Reused verbatim by both
     * the customer and admin generation endpoints.
     */
    @Transactional
    public RecommendationGenerationResponse generate(Long userId) {
        userOrThrow(userId);
        Instant now = Instant.now();
        LocalDate today = LocalDate.now();

        PreferenceProfile profile = buildProfile(userId);

        // Preserve engaged history; remember which target keys already exist so we
        // never regenerate a duplicate active snapshot for them.
        List<CustomerRecommendation> existing = recRepo.findByUserId(userId);
        Set<String> preservedKeys = new HashSet<>();
        int preservedActive = 0;
        for (CustomerRecommendation e : existing) {
            boolean engaged = e.getDismissedAt() != null || e.getClickedAt() != null || e.getConvertedAt() != null;
            if (engaged) {
                preservedKeys.add(e.getTargetKey());
                if (e.getDismissedAt() == null && !isExpired(e, now)) preservedActive++;
            }
        }

        // Applicable rules: active + in validity window + tier gate satisfied.
        List<PersonalizationRule> rules = ruleRepo.findApplicable(now).stream()
            .filter(r -> tierGateSatisfied(r.getMinimumMembershipTier(), profile.tier))
            .toList();

        // Bounded catalogue load (avoids N+1).
        List<Place> published = placeRepo.findByStatus(PlaceStatus.PUBLISHED);
        List<Long> placeIds = published.stream().map(Place::getId).toList();
        Map<Long, PlaceMetadata> metaById = placeIds.isEmpty() ? Map.of()
            : metadataRepo.findByPlaceIdIn(placeIds).stream()
                .collect(Collectors.toMap(m -> m.getPlace().getId(), m -> m, (a, b) -> a));
        Set<Long> hotelPlaceIds = placeIds.isEmpty() ? Set.of()
            : hotelDetailRepo.findByPlaceIdIn(placeIds).stream()
                .map(hd -> hd.getPlace().getId()).collect(Collectors.toSet());

        List<Candidate> candidates = new ArrayList<>();
        for (PersonalizationRule rule : rules) {
            generateForRule(rule, profile, published, metaById, hotelPlaceIds, today, candidates);
        }

        // Deduplicate by target key (highest score wins), drop already-owned engaged keys.
        Map<String, Candidate> byKey = new LinkedHashMap<>();
        for (Candidate c : candidates) {
            if (preservedKeys.contains(c.targetKey)) continue;
            Candidate current = byKey.get(c.targetKey);
            if (current == null || c.score > current.score) byKey.put(c.targetKey, c);
        }
        List<Candidate> finalists = new ArrayList<>(byKey.values());
        finalists.sort(Comparator.comparingInt((Candidate c) -> c.score).reversed()
            .thenComparing(c -> c.targetKey));
        if (finalists.size() > MAX_RECOMMENDATIONS) finalists = finalists.subList(0, MAX_RECOMMENDATIONS);

        // Replace only unengaged active snapshots.
        recRepo.deleteUnengagedForUser(userId);

        Instant expiresAt = now.plus(DEFAULT_EXPIRY_DAYS, ChronoUnit.DAYS);
        List<CustomerRecommendation> saved = new ArrayList<>();
        for (Candidate c : finalists) {
            CustomerRecommendation rec = new CustomerRecommendation();
            rec.setUser(userRepo.getReferenceById(userId));
            rec.setRecommendationType(c.type);
            rec.setSourceRule(c.rule);
            rec.setPlace(c.place);
            rec.setHotel(c.hotel);
            rec.setRoom(c.room);
            rec.setPromotion(c.promotion);
            rec.setCouponDefinition(c.coupon);
            rec.setTargetKey(c.targetKey);
            rec.setScore(c.score);
            rec.setReasonCode(c.reasonCode);
            rec.setReasonText(c.reasonText);
            rec.setGeneratedAt(now);
            rec.setExpiresAt(expiresAt);
            rec.setMetadataJson(c.metadataJson);
            saved.add(recRepo.save(rec));
        }

        int totalActive = preservedActive + saved.size();
        List<CustomerRecommendationResponse> mapped = saved.stream().map(r -> toResponse(r, now)).toList();
        return new RecommendationGenerationResponse(saved.size(), totalActive, now, mapped);
    }

    private void generateForRule(PersonalizationRule rule, PreferenceProfile p, List<Place> published,
                                 Map<Long, PlaceMetadata> metaById, Set<Long> hotelPlaceIds,
                                 LocalDate today, List<Candidate> out) {
        switch (rule.getRuleType()) {
            case WISHLIST_AFFINITY -> genWishlistAffinity(rule, p, published, metaById, out);
            case RECENTLY_VIEWED -> genRecentlyViewed(rule, p, published, metaById, out);
            case BOOKING_HISTORY -> genBookingHistory(rule, p, published, metaById, hotelPlaceIds, out);
            case DESTINATION_AFFINITY -> genDestinationAffinity(rule, p, published, metaById, out);
            case TRAVEL_STYLE -> genTravelStyle(rule, p, published, metaById, out);
            case MEMBERSHIP_TIER -> genMembershipCoupons(rule, p, today, out);
            case LOYALTY_ACTIVITY -> genLoyaltyCoupons(rule, p, today, out);
            case REENGAGEMENT -> genReengagement(rule, p, today, out);
            case TRENDING -> genTrending(rule, p, published, metaById, out);
            case ABANDONED_INTEREST -> genAbandonedInterest(rule, p, published, metaById, hotelPlaceIds, out);
            case MANUAL -> genManual(rule, p, today, out);
        }
    }

    // ── Signal-driven place/hotel generators ──────────────────────────────────

    private void genWishlistAffinity(PersonalizationRule rule, PreferenceProfile p, List<Place> published,
                                     Map<Long, PlaceMetadata> metaById, List<Candidate> out) {
        if (p.wishlistPlaceIds.isEmpty()) return;
        for (Place place : published) {
            if (p.wishlistPlaceIds.contains(place.getId())) continue; // recommend SIMILAR, not the saved ones
            boolean related = p.wishlistDestinationIds.contains(place.getAdministrativeUnit().getId())
                || p.wishlistCategoryIds.contains(place.getCategory().getId())
                || styleMatch(place, p, metaById);
            if (!related) continue;
            int score = scorePlace(place, p, metaById, true, false);
            out.add(placeCandidate(place, rule, RecommendationReasonCode.SAVED_SIMILAR_PLACE,
                "Because you saved similar places", score));
        }
    }

    private void genRecentlyViewed(PersonalizationRule rule, PreferenceProfile p, List<Place> published,
                                   Map<Long, PlaceMetadata> metaById, List<Candidate> out) {
        if (p.recentPlaceIds.isEmpty()) return;
        for (Place place : published) {
            if (p.recentPlaceIds.contains(place.getId())) continue;
            boolean related = p.recentDestinationIds.contains(place.getAdministrativeUnit().getId())
                || p.recentCategoryIds.contains(place.getCategory().getId());
            if (!related) continue;
            int score = scorePlace(place, p, metaById, false, true);
            out.add(placeCandidate(place, rule, RecommendationReasonCode.VIEWED_SIMILAR_PLACE,
                "Because you recently viewed similar places", score));
        }
    }

    private void genBookingHistory(PersonalizationRule rule, PreferenceProfile p, List<Place> published,
                                   Map<Long, PlaceMetadata> metaById, Set<Long> hotelPlaceIds, List<Candidate> out) {
        if (p.bookedDestinationIds.isEmpty()) return;
        for (Place place : published) {
            if (!hotelPlaceIds.contains(place.getId())) continue;        // hotels only
            if (p.bookedHotelPlaceIds.contains(place.getId())) continue; // not one you already booked
            if (!p.bookedDestinationIds.contains(place.getAdministrativeUnit().getId())) continue;
            int score = scorePlace(place, p, metaById, false, false);
            out.add(hotelCandidate(place, rule, RecommendationReasonCode.BOOKED_SIMILAR_DESTINATION,
                "Because you booked in this destination before", score));
            cheapestActiveRoom(place).ifPresent(room -> out.add(roomCandidate(room, rule,
                RecommendationReasonCode.BOOKED_SIMILAR_DESTINATION,
                "A room in a destination you booked before", score)));
        }
    }

    private void genDestinationAffinity(PersonalizationRule rule, PreferenceProfile p, List<Place> published,
                                        Map<Long, PlaceMetadata> metaById, List<Candidate> out) {
        if (p.affinityDestinationIds.isEmpty()) return;
        for (Place place : published) {
            if (p.wishlistPlaceIds.contains(place.getId())) continue;
            if (!p.affinityDestinationIds.contains(place.getAdministrativeUnit().getId())) continue;
            int score = scorePlace(place, p, metaById, false, false);
            out.add(placeCandidate(place, rule, RecommendationReasonCode.POPULAR_NEARBY,
                "In a destination you're interested in", score));
        }
    }

    private void genTravelStyle(PersonalizationRule rule, PreferenceProfile p, List<Place> published,
                                Map<Long, PlaceMetadata> metaById, List<Candidate> out) {
        if (p.affinityStyles.isEmpty()) return;
        for (Place place : published) {
            if (p.wishlistPlaceIds.contains(place.getId())) continue;
            if (!styleMatch(place, p, metaById)) continue;
            int score = scorePlace(place, p, metaById, false, false);
            out.add(placeCandidate(place, rule, RecommendationReasonCode.MATCHED_TRAVEL_STYLE,
                "Matches your travel style", score));
        }
    }

    private void genTrending(PersonalizationRule rule, PreferenceProfile p, List<Place> published,
                             Map<Long, PlaceMetadata> metaById, List<Candidate> out) {
        published.stream()
            .filter(place -> !p.wishlistPlaceIds.contains(place.getId()))
            .sorted(Comparator.comparingDouble(Place::getRatingAvg).reversed()
                .thenComparing(Comparator.comparingInt(Place::getReviewCount).reversed()))
            .limit(TRENDING_LIMIT)
            .forEach(place -> {
                int score = clamp(TRENDING_BASE + (int) Math.round(place.getRatingAvg() * 4)
                    + affinityBonus(place, p, metaById));
                out.add(placeCandidate(place, rule, RecommendationReasonCode.POPULAR_NEARBY,
                    "Popular with other travellers", score));
            });
    }

    private void genAbandonedInterest(PersonalizationRule rule, PreferenceProfile p, List<Place> published,
                                      Map<Long, PlaceMetadata> metaById, Set<Long> hotelPlaceIds, List<Candidate> out) {
        // 1) Saved-but-not-booked places → a nudge to finish planning.
        Map<Long, Place> publishedById = published.stream().collect(Collectors.toMap(Place::getId, x -> x, (a, b) -> a));
        for (Long placeId : p.wishlistPlaceIds) {
            if (p.bookedHotelPlaceIds.contains(placeId)) continue;
            Place place = publishedById.get(placeId);
            if (place == null) continue; // not published
            int score = scorePlace(place, p, metaById, true, false);
            out.add(placeCandidate(place, rule, RecommendationReasonCode.CONTINUE_PLANNING,
                "You saved this — ready to plan it?", score));
        }
        // 2) Incomplete trips → TRIP_IDEA places in the trip's destination.
        for (String dest : p.planningDestinations) {
            for (Place place : published) {
                if (!destinationMatchesString(place, dest)) continue;
                int score = clamp(DESTINATION_MATCH + affinityBonus(place, p, metaById));
                Candidate c = placeCandidate(place, rule, RecommendationReasonCode.CONTINUE_PLANNING,
                    "An idea for your trip to " + dest, score);
                c.type = RecommendationType.TRIP_IDEA;
                c.targetKey = RecommendationType.TRIP_IDEA + ":" + place.getId();
                c.metadataJson = "{\"tripDestination\":\"" + jsonEscape(dest) + "\"}";
                out.add(c);
            }
        }
    }

    // ── Offer generators (promotions / coupons) ───────────────────────────────

    private void genMembershipCoupons(PersonalizationRule rule, PreferenceProfile p, LocalDate today, List<Candidate> out) {
        for (CouponDefinition c : couponRepo.findAll()) {
            if (c.getMinimumTier() == null) continue;              // tier-exclusive only
            if (!couponRecommendable(c, p, today)) continue;
            out.add(couponCandidate(c, rule, RecommendationReasonCode.MEMBERSHIP_EXCLUSIVE,
                "A members-only coupon for your tier", clamp(OFFER_BASE + MEMBERSHIP_EXCLUSIVE)));
        }
    }

    private void genLoyaltyCoupons(PersonalizationRule rule, PreferenceProfile p, LocalDate today, List<Candidate> out) {
        if (!p.loyaltyActive) return;
        for (CouponDefinition c : couponRepo.findAll()) {
            if (c.getMinimumTier() != null) continue;              // tier ones handled by MEMBERSHIP_TIER
            if (!couponRecommendable(c, p, today)) continue;
            out.add(couponCandidate(c, rule, RecommendationReasonCode.LOYALTY_EXCLUSIVE,
                "A coupon for loyalty members", clamp(OFFER_BASE + MEMBERSHIP_EXCLUSIVE)));
        }
    }

    private void genReengagement(PersonalizationRule rule, PreferenceProfile p, LocalDate today, List<Candidate> out) {
        if (p.bookingCount == 0) return; // returning customers only
        for (Promotion promo : promotionRepo.findActiveForDateRange(today, today)) {
            out.add(promotionCandidate(promo, rule, RecommendationReasonCode.RETURNING_CUSTOMER,
                "Welcome back — a deal for you", clamp(OFFER_BASE + ACTIVE_PROMOTION)));
        }
        for (CouponDefinition c : couponRepo.findAll()) {
            if (c.getMinimumTier() != null) continue;
            if (!couponRecommendable(c, p, today)) continue;
            out.add(couponCandidate(c, rule, RecommendationReasonCode.RETURNING_CUSTOMER,
                "Welcome back — a coupon for you", clamp(OFFER_BASE + ACTIVE_PROMOTION)));
        }
    }

    private void genManual(PersonalizationRule rule, PreferenceProfile p, LocalDate today, List<Candidate> out) {
        if (rule.getTargetPlaceId() != null) {
            placeRepo.findById(rule.getTargetPlaceId())
                .filter(pl -> pl.getStatus() == PlaceStatus.PUBLISHED)
                .ifPresent(pl -> out.add(placeCandidate(pl, rule, RecommendationReasonCode.MANUAL_RULE,
                    manualReason(rule), MANUAL_BASE)));
        }
        if (rule.getTargetHotelId() != null) {
            placeRepo.findById(rule.getTargetHotelId())
                .filter(pl -> pl.getStatus() == PlaceStatus.PUBLISHED)
                .ifPresent(pl -> out.add(hotelCandidate(pl, rule, RecommendationReasonCode.MANUAL_RULE,
                    manualReason(rule), MANUAL_BASE)));
        }
        if (rule.getTargetPromotionId() != null) {
            promotionRepo.findById(rule.getTargetPromotionId())
                .filter(pr -> promotionRecommendable(pr, today))
                .ifPresent(pr -> out.add(promotionCandidate(pr, rule, RecommendationReasonCode.MANUAL_RULE,
                    manualReason(rule), MANUAL_BASE)));
        }
        if (rule.getTargetCouponDefinitionId() != null) {
            couponRepo.findById(rule.getTargetCouponDefinitionId())
                .filter(c -> couponRecommendable(c, p, today))
                .ifPresent(c -> out.add(couponCandidate(c, rule, RecommendationReasonCode.MANUAL_RULE,
                    manualReason(rule), MANUAL_BASE)));
        }
    }

    private String manualReason(PersonalizationRule rule) {
        return rule.getDescription() != null && !rule.getDescription().isBlank()
            ? rule.getDescription() : "Handpicked for you";
    }

    // ── Central scoring ───────────────────────────────────────────────────────

    /** The one place per-place/hotel scores are computed — no scoring is duplicated elsewhere. */
    private int scorePlace(Place place, PreferenceProfile p, Map<Long, PlaceMetadata> metaById,
                           boolean wishlistSignal, boolean recentSignal) {
        int s = 0;
        Long destId = place.getAdministrativeUnit().getId();
        Long catId = place.getCategory().getId();
        if (p.affinityDestinationIds.contains(destId)) s += DESTINATION_MATCH;
        if (p.affinityCategoryIds.contains(catId)) s += PLACE_TYPE_MATCH;
        if (styleMatch(place, p, metaById)) s += TRAVEL_STYLE_MATCH;
        if (wishlistSignal) s += WISHLIST_SIGNAL;
        if (recentSignal) s += RECENTLY_VIEWED_SIGNAL;
        if (p.bookedDestinationIds.contains(destId)) s += BOOKING_DESTINATION;
        return clamp(s);
    }

    /** Non-signal-flag portion of the score, reused where a base is added separately (trending / trip ideas). */
    private int affinityBonus(Place place, PreferenceProfile p, Map<Long, PlaceMetadata> metaById) {
        int s = 0;
        if (p.affinityDestinationIds.contains(place.getAdministrativeUnit().getId())) s += DESTINATION_MATCH;
        if (p.affinityCategoryIds.contains(place.getCategory().getId())) s += PLACE_TYPE_MATCH;
        if (styleMatch(place, p, metaById)) s += TRAVEL_STYLE_MATCH;
        return s;
    }

    private boolean styleMatch(Place place, PreferenceProfile p, Map<Long, PlaceMetadata> metaById) {
        if (p.affinityStyles.isEmpty()) return false;
        PlaceMetadata meta = metaById.get(place.getId());
        if (meta == null || meta.getTravelStyles() == null) return false;
        return meta.getTravelStyles().stream().anyMatch(p.affinityStyles::contains);
    }

    private int clamp(int s) { return Math.max(0, Math.min(MAX_SCORE, s)); }

    // ── Eligibility ────────────────────────────────────────────────────────────

    private boolean promotionRecommendable(Promotion promo, LocalDate today) {
        return promo.isActive()
            && !today.isBefore(promo.getStartDate())
            && !today.isAfter(promo.getEndDate());
    }

    private boolean couponRecommendable(CouponDefinition c, PreferenceProfile p, LocalDate today) {
        if (!c.isActive()) return false;
        if (today.isBefore(c.getValidFrom()) || today.isAfter(c.getValidUntil())) return false;
        if (c.getTotalUsageLimit() != null && c.getCurrentUsageCount() >= c.getTotalUsageLimit()) return false;
        return tierGateSatisfied(c.getMinimumTier(), p.tier);
    }

    private boolean tierGateSatisfied(MembershipTier required, MembershipTier actual) {
        if (required == null) return true;
        return actual != null && actual.ordinal() >= required.ordinal();
    }

    private Optional<HotelRoom> cheapestActiveRoom(Place hotelPlace) {
        return hotelDetailRepo.findByPlaceId(hotelPlace.getId())
            .map(hd -> hotelRoomRepo.findAllByHotelDetailIdAndActiveTrue(hd.getId()).stream()
                .filter(r -> r.getPriceFrom() != null)
                .min(Comparator.comparing(HotelRoom::getPriceFrom))
                .orElse(null));
    }

    // ── Candidate factories ────────────────────────────────────────────────────

    private Candidate placeCandidate(Place place, PersonalizationRule rule, RecommendationReasonCode code,
                                     String text, int score) {
        Candidate c = new Candidate();
        c.type = RecommendationType.PLACE;
        c.place = place;
        c.rule = rule;
        c.reasonCode = code;
        c.reasonText = text;
        c.score = score;
        c.targetKey = RecommendationType.PLACE + ":" + place.getId();
        return c;
    }

    private Candidate hotelCandidate(Place hotel, PersonalizationRule rule, RecommendationReasonCode code,
                                     String text, int score) {
        Candidate c = new Candidate();
        c.type = RecommendationType.HOTEL;
        c.hotel = hotel;
        c.rule = rule;
        c.reasonCode = code;
        c.reasonText = text;
        c.score = score;
        c.targetKey = RecommendationType.HOTEL + ":" + hotel.getId();
        return c;
    }

    private Candidate roomCandidate(HotelRoom room, PersonalizationRule rule, RecommendationReasonCode code,
                                    String text, int score) {
        Candidate c = new Candidate();
        c.type = RecommendationType.ROOM;
        c.room = room;
        c.rule = rule;
        c.reasonCode = code;
        c.reasonText = text;
        c.score = score;
        c.targetKey = RecommendationType.ROOM + ":" + room.getId();
        return c;
    }

    private Candidate promotionCandidate(Promotion promo, PersonalizationRule rule, RecommendationReasonCode code,
                                         String text, int score) {
        Candidate c = new Candidate();
        c.type = RecommendationType.PROMOTION;
        c.promotion = promo;
        c.rule = rule;
        c.reasonCode = code;
        c.reasonText = text;
        c.score = score;
        c.targetKey = RecommendationType.PROMOTION + ":" + promo.getId();
        return c;
    }

    private Candidate couponCandidate(CouponDefinition coupon, PersonalizationRule rule, RecommendationReasonCode code,
                                      String text, int score) {
        Candidate c = new Candidate();
        c.type = RecommendationType.COUPON;
        c.coupon = coupon;
        c.rule = rule;
        c.reasonCode = code;
        c.reasonText = text;
        c.score = score;
        c.targetKey = RecommendationType.COUPON + ":" + coupon.getId();
        return c;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // QUERY + ENGAGEMENT
    // ═══════════════════════════════════════════════════════════════════════

    public PageResponse<CustomerRecommendationResponse> list(Long userId, RecommendationType type,
                                                             String destination, Integer minScore,
                                                             boolean includeDismissed, int page, int size) {
        Instant now = Instant.now();
        List<CustomerRecommendation> all = recRepo.findByUserId(userId);
        List<CustomerRecommendation> filtered = all.stream()
            .filter(r -> includeDismissed || r.getDismissedAt() == null)
            .filter(r -> includeDismissed || !isExpired(r, now))
            .filter(r -> type == null || r.getRecommendationType() == type)
            .filter(r -> minScore == null || r.getScore() >= minScore)
            .filter(r -> destination == null || destination.isBlank() || matchesDestination(r, destination))
            .sorted(activeOrder())
            .toList();

        int from = Math.min(page * size, filtered.size());
        int to = Math.min(from + size, filtered.size());
        List<CustomerRecommendationResponse> content = filtered.subList(from, to).stream()
            .map(r -> toResponse(r, now)).toList();
        return PageResponse.of(new PageImpl<>(content, PageRequest.of(page, size), filtered.size()));
    }

    public CustomerRecommendationResponse get(Long userId, Long id) {
        return toResponse(ownedOrThrow(userId, id), Instant.now());
    }

    public List<CustomerRecommendationResponse> listByTypes(Long userId, Set<RecommendationType> types) {
        Instant now = Instant.now();
        return recRepo.findByUserId(userId).stream()
            .filter(r -> r.getDismissedAt() == null && !isExpired(r, now))
            .filter(r -> types.contains(r.getRecommendationType()))
            .sorted(activeOrder())
            .map(r -> toResponse(r, now))
            .toList();
    }

    @Transactional
    public CustomerRecommendationResponse dismiss(Long userId, Long id) {
        CustomerRecommendation rec = ownedOrThrow(userId, id);
        if (rec.getDismissedAt() == null) rec.setDismissedAt(Instant.now());
        return toResponse(recRepo.save(rec), Instant.now());
    }

    @Transactional
    public CustomerRecommendationResponse click(Long userId, Long id) {
        CustomerRecommendation rec = ownedOrThrow(userId, id);
        if (rec.getClickedAt() == null) rec.setClickedAt(Instant.now()); // idempotent
        return toResponse(recRepo.save(rec), Instant.now());
    }

    @Transactional
    public CustomerRecommendationResponse convert(Long userId, Long id) {
        CustomerRecommendation rec = ownedOrThrow(userId, id);
        if (rec.getConvertedAt() == null) rec.setConvertedAt(Instant.now()); // idempotent
        return toResponse(recRepo.save(rec), Instant.now());
    }

    public RecommendationReasonResponse explain(Long userId, Long id) {
        CustomerRecommendation rec = ownedOrThrow(userId, id);
        return new RecommendationReasonResponse(rec.getId(), rec.getRecommendationType(),
            rec.getReasonCode(), rec.getReasonText(), rec.getScore(),
            rec.getSourceRule() != null ? rec.getSourceRule().getId() : null,
            rec.getSourceRule() != null ? rec.getSourceRule().getRuleCode() : null);
    }

    public RecommendationSummaryResponse summary(Long userId) {
        Instant now = Instant.now();
        List<CustomerRecommendation> all = recRepo.findByUserId(userId);
        List<CustomerRecommendation> active = all.stream()
            .filter(r -> r.getDismissedAt() == null && !isExpired(r, now)).toList();

        Map<RecommendationType, Long> byType = active.stream()
            .collect(Collectors.groupingBy(CustomerRecommendation::getRecommendationType, Collectors.counting()));

        long dismissed = all.stream().filter(r -> r.getDismissedAt() != null).count();
        long clicked = all.stream().filter(r -> r.getClickedAt() != null).count();
        long converted = all.stream().filter(r -> r.getConvertedAt() != null).count();

        String topDestination = topDestination(active);
        RecommendationType strongest = active.stream()
            .max(Comparator.comparingInt(CustomerRecommendation::getScore))
            .map(CustomerRecommendation::getRecommendationType).orElse(null);
        Instant lastGenerated = all.stream().map(CustomerRecommendation::getGeneratedAt)
            .max(Comparator.naturalOrder()).orElse(null);

        return new RecommendationSummaryResponse(
            active.size(),
            byType.getOrDefault(RecommendationType.PLACE, 0L),
            byType.getOrDefault(RecommendationType.HOTEL, 0L),
            byType.getOrDefault(RecommendationType.ROOM, 0L),
            byType.getOrDefault(RecommendationType.PROMOTION, 0L),
            byType.getOrDefault(RecommendationType.COUPON, 0L),
            byType.getOrDefault(RecommendationType.TRIP_IDEA, 0L),
            dismissed, clicked, converted, topDestination, strongest, lastGenerated);
    }

    public CustomerPreferenceProfileResponse getPreferenceProfile(Long userId) {
        userOrThrow(userId);
        PreferenceProfile p = buildProfile(userId);
        return new CustomerPreferenceProfileResponse(
            userId,
            new ArrayList<>(p.wishlistDestinationNames),
            new ArrayList<>(p.wishlistCategoryNames),
            new ArrayList<>(p.wishlistStyles),
            new ArrayList<>(p.recentDestinationNames),
            new ArrayList<>(p.bookedDestinationNames),
            p.avgBookingValue, p.preferredStar, p.typicalStayNights, p.lastBookingDate,
            p.profileTravelStyleRaw, p.preferredLanguage, p.preferredCurrency,
            p.accessibilityNeeds, p.dietaryPreference, p.tier, p.loyaltyActive, p.loyaltyBalance,
            new ArrayList<>(p.planningDestinations), p.wishlistItemCount, p.recentlyViewedCount, p.bookingCount);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PROFILE
    // ═══════════════════════════════════════════════════════════════════════

    private PreferenceProfile buildProfile(Long userId) {
        PreferenceProfile p = new PreferenceProfile();

        // Wishlist
        wishlistRepo.findByUserId(userId).ifPresent(wl -> {
            List<WishlistItem> items = wishlistItemRepo.findByWishlistIdOrderByCreatedAtDesc(wl.getId());
            p.wishlistItemCount = items.size();
            items.stream().limit(SIGNAL_LIMIT).forEach(item -> {
                Place place = item.getPlace();
                p.wishlistPlaceIds.add(place.getId());
                p.wishlistCategoryIds.add(place.getCategory().getId());
                p.wishlistDestinationIds.add(place.getAdministrativeUnit().getId());
                p.wishlistDestinationNames.add(place.getAdministrativeUnit().getName());
                p.wishlistCategoryNames.add(place.getCategory().getName());
            });
        });
        if (!p.wishlistPlaceIds.isEmpty()) {
            metadataRepo.findByPlaceIdIn(p.wishlistPlaceIds).forEach(m -> {
                if (m.getTravelStyles() != null) p.wishlistStyles.addAll(m.getTravelStyles());
            });
        }

        // Recently viewed
        List<RecentlyViewedPlace> recent = recentlyViewedRepo.findByUserIdOrderByViewedAtDesc(userId);
        p.recentlyViewedCount = recent.size();
        recent.stream().limit(SIGNAL_LIMIT).forEach(rv -> {
            Place place = rv.getPlace();
            p.recentPlaceIds.add(place.getId());
            p.recentCategoryIds.add(place.getCategory().getId());
            p.recentDestinationIds.add(place.getAdministrativeUnit().getId());
            p.recentDestinationNames.add(place.getAdministrativeUnit().getName());
        });

        // Bookings
        List<Booking> bookings = bookingRepo.findByUserIdOrderByCreatedAtDesc(userId);
        p.bookingCount = bookings.size();
        List<Booking> window = bookings.stream().limit(SIGNAL_LIMIT).toList();
        BigDecimal totalValue = BigDecimal.ZERO;
        long totalNights = 0;
        for (Booking b : window) {
            Place hotel = b.getHotel();
            p.bookedHotelPlaceIds.add(hotel.getId());
            p.bookedCategoryIds.add(hotel.getCategory().getId());
            p.bookedDestinationIds.add(hotel.getAdministrativeUnit().getId());
            p.bookedDestinationNames.add(hotel.getAdministrativeUnit().getName());
            if (b.getFinalPrice() != null) totalValue = totalValue.add(b.getFinalPrice());
            if (b.getCheckInDate() != null && b.getCheckOutDate() != null)
                totalNights += ChronoUnit.DAYS.between(b.getCheckInDate(), b.getCheckOutDate());
            if (p.lastBookingDate == null && b.getCreatedAt() != null) p.lastBookingDate = b.getCreatedAt();
        }
        if (!window.isEmpty()) {
            p.avgBookingValue = totalValue.divide(BigDecimal.valueOf(window.size()), 2, RoundingMode.HALF_UP);
            p.typicalStayNights = (int) Math.max(1, Math.round((double) totalNights / window.size()));
            if (!p.bookedHotelPlaceIds.isEmpty()) {
                List<HotelDetail> details = hotelDetailRepo.findByPlaceIdIn(p.bookedHotelPlaceIds);
                if (!details.isEmpty()) {
                    double avgStar = details.stream().mapToInt(HotelDetail::getStarRating).average().orElse(0);
                    p.preferredStar = (int) Math.round(avgStar);
                }
            }
        }

        // Profile
        customerProfileRepo.findByUserId(userId).ifPresent(cp -> {
            p.preferredLanguage = cp.getPreferredLanguage();
            p.preferredCurrency = cp.getPreferredCurrency();
            p.accessibilityNeeds = cp.getAccessibilityNeeds();
            p.dietaryPreference = cp.getDietaryPreference();
            p.profileTravelStyleRaw = cp.getTravelStyle();
            p.profileStyle = parseTravelStyle(cp.getTravelStyle());
        });

        // Membership + loyalty
        p.tier = membershipService.effectiveTierForUser(userId).orElse(null);
        loyaltyAccountRepo.findByUserId(userId).ifPresent(la -> {
            p.loyaltyActive = la.getStatus() == LoyaltyAccountStatus.ACTIVE;
            p.loyaltyBalance = la.getCurrentBalance();
        });

        // Trips (incomplete → planning destinations)
        tripPlanRepo.findByUserIdOrderByUpdatedAtDesc(userId).stream()
            .filter(t -> t.getStatus() == TripPlanStatus.PLANNING || t.getStatus() == TripPlanStatus.ACTIVE)
            .map(TripPlan::getDestination)
            .filter(d -> d != null && !d.isBlank())
            .map(String::trim)
            .forEach(p.planningDestinations::add);

        // Derived affinity unions
        p.affinityDestinationIds.addAll(p.wishlistDestinationIds);
        p.affinityDestinationIds.addAll(p.recentDestinationIds);
        p.affinityDestinationIds.addAll(p.bookedDestinationIds);
        p.affinityCategoryIds.addAll(p.wishlistCategoryIds);
        p.affinityCategoryIds.addAll(p.recentCategoryIds);
        p.affinityCategoryIds.addAll(p.bookedCategoryIds);
        p.affinityStyles.addAll(p.wishlistStyles);
        if (p.profileStyle != null) p.affinityStyles.add(p.profileStyle);

        return p;
    }

    private TravelStyle parseTravelStyle(String raw) {
        if (raw == null || raw.isBlank()) return null;
        try {
            return TravelStyle.valueOf(raw.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // MAPPING + HELPERS
    // ═══════════════════════════════════════════════════════════════════════

    private CustomerRecommendationResponse toResponse(CustomerRecommendation r, Instant now) {
        var place = r.getPlace() != null ? placeService.toSummary(r.getPlace()) : null;
        var hotel = r.getHotel() != null ? placeService.toSummary(r.getHotel()) : null;
        var room = r.getRoom() != null ? hotelRoomService.toResponse(r.getRoom()) : null;
        var promotion = r.getPromotion() != null ? promotionService.toResponse(r.getPromotion()) : null;
        var coupon = r.getCouponDefinition() != null ? couponDefinitionService.toResponse(r.getCouponDefinition()) : null;

        String targetSummary = place != null ? place.name()
            : hotel != null ? hotel.name()
            : room != null ? room.roomName()
            : promotion != null ? promotion.name()
            : coupon != null ? coupon.name()
            : null;

        return new CustomerRecommendationResponse(
            r.getId(), r.getRecommendationType(), r.getScore(), r.getReasonCode(), r.getReasonText(),
            r.getGeneratedAt(), r.getExpiresAt(), engagementState(r, now),
            r.getDismissedAt(), r.getClickedAt(), r.getConvertedAt(),
            r.getSourceRule() != null ? r.getSourceRule().getId() : null,
            r.getSourceRule() != null ? r.getSourceRule().getRuleCode() : null,
            targetSummary, place, hotel, room, promotion, coupon, r.getMetadataJson());
    }

    private String engagementState(CustomerRecommendation r, Instant now) {
        if (r.getDismissedAt() != null) return "DISMISSED";
        if (r.getConvertedAt() != null) return "CONVERTED";
        if (r.getClickedAt() != null) return "CLICKED";
        if (isExpired(r, now)) return "EXPIRED";
        return "ACTIVE";
    }

    private boolean isExpired(CustomerRecommendation r, Instant now) {
        return r.getExpiresAt() != null && !r.getExpiresAt().isAfter(now);
    }

    private Comparator<CustomerRecommendation> activeOrder() {
        return Comparator.comparingInt(CustomerRecommendation::getScore).reversed()
            .thenComparing(Comparator.comparing(CustomerRecommendation::getGeneratedAt).reversed())
            .thenComparing(Comparator.comparing(CustomerRecommendation::getId).reversed());
    }

    private boolean matchesDestination(CustomerRecommendation r, String destination) {
        Place place = r.getPlace() != null ? r.getPlace() : r.getHotel();
        if (place == null && r.getRoom() != null)
            place = r.getRoom().getHotelDetail().getPlace();
        if (place == null) return false;
        String needle = destination.toLowerCase(Locale.ROOT);
        AdministrativeUnit u = place.getAdministrativeUnit();
        return (u.getName() != null && u.getName().toLowerCase(Locale.ROOT).contains(needle))
            || (u.getFullPath() != null && u.getFullPath().toLowerCase(Locale.ROOT).contains(needle));
    }

    private boolean destinationMatchesString(Place place, String dest) {
        String needle = dest.toLowerCase(Locale.ROOT);
        AdministrativeUnit u = place.getAdministrativeUnit();
        return (u.getName() != null && u.getName().toLowerCase(Locale.ROOT).contains(needle))
            || (u.getFullPath() != null && u.getFullPath().toLowerCase(Locale.ROOT).contains(needle));
    }

    private String topDestination(List<CustomerRecommendation> active) {
        Map<String, Long> counts = new HashMap<>();
        for (CustomerRecommendation r : active) {
            Place place = r.getPlace() != null ? r.getPlace() : r.getHotel();
            if (place == null) continue;
            String name = place.getAdministrativeUnit().getName();
            if (name != null) counts.merge(name, 1L, Long::sum);
        }
        return counts.entrySet().stream().max(Map.Entry.comparingByValue())
            .map(Map.Entry::getKey).orElse(null);
    }

    private String jsonEscape(String s) {
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    private CustomerRecommendation ownedOrThrow(Long userId, Long id) {
        return recRepo.findByIdAndUserId(id, userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Recommendation not found: " + id));
    }

    private User userOrThrow(Long userId) {
        return userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found: " + userId));
    }

    // ── Internal holders ────────────────────────────────────────────────────

    private static final class PreferenceProfile {
        Set<Long> wishlistPlaceIds = new HashSet<>();
        Set<Long> wishlistCategoryIds = new HashSet<>();
        Set<Long> wishlistDestinationIds = new HashSet<>();
        Set<TravelStyle> wishlistStyles = new HashSet<>();
        Set<String> wishlistDestinationNames = new LinkedHashSet<>();
        Set<String> wishlistCategoryNames = new LinkedHashSet<>();

        Set<Long> recentPlaceIds = new HashSet<>();
        Set<Long> recentCategoryIds = new HashSet<>();
        Set<Long> recentDestinationIds = new HashSet<>();
        Set<String> recentDestinationNames = new LinkedHashSet<>();

        Set<Long> bookedHotelPlaceIds = new HashSet<>();
        Set<Long> bookedCategoryIds = new HashSet<>();
        Set<Long> bookedDestinationIds = new HashSet<>();
        Set<String> bookedDestinationNames = new LinkedHashSet<>();
        BigDecimal avgBookingValue;
        Integer preferredStar;
        Integer typicalStayNights;
        Instant lastBookingDate;

        String profileTravelStyleRaw;
        TravelStyle profileStyle;
        String preferredLanguage;
        String preferredCurrency;
        String accessibilityNeeds;
        String dietaryPreference;

        MembershipTier tier;
        boolean loyaltyActive;
        Long loyaltyBalance;

        List<String> planningDestinations = new ArrayList<>();
        int wishlistItemCount;
        int recentlyViewedCount;
        int bookingCount;

        Set<Long> affinityDestinationIds = new HashSet<>();
        Set<Long> affinityCategoryIds = new HashSet<>();
        Set<TravelStyle> affinityStyles = new HashSet<>();
    }

    private static final class Candidate {
        RecommendationType type;
        Place place;
        Place hotel;
        HotelRoom room;
        Promotion promotion;
        CouponDefinition coupon;
        PersonalizationRule rule;
        RecommendationReasonCode reasonCode;
        String reasonText;
        int score;
        String targetKey;
        String metadataJson;
    }
}
