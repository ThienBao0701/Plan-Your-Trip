package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.AITripContextDto.ActivitySummary;
import com.example.planyourtrip.dto.AITripContextDto.AITripContextResponse;
import com.example.planyourtrip.dto.AITripContextDto.WishlistSummary;
import com.example.planyourtrip.dto.BookingDto.BookingSummaryResponse;
import com.example.planyourtrip.dto.CollectionDto.CollectionSummaryResponse;
import com.example.planyourtrip.dto.CustomerProfileDto.CustomerProfileResponse;
import com.example.planyourtrip.dto.PersonalizationDto.CustomerPreferenceProfileResponse;
import com.example.planyourtrip.dto.RecommendationEngineDto.RecommendationResponse;
import com.example.planyourtrip.dto.ReviewDto.ReviewSummaryResponse;
import com.example.planyourtrip.dto.TripPlanBudgetDto.TripPlanBudgetSummaryResponse;
import com.example.planyourtrip.dto.TripPlanDto.TripSummaryResponse;
import com.example.planyourtrip.dto.UserInterestDto.InterestProfileResponse;
import com.example.planyourtrip.dto.WishlistDto.WishlistResponse;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;

/**
 * Phase 7.50 — assembles the {@link AITripContextResponse}, the single source of truth every future
 * AI module will consume.
 *
 * <p><b>Pure aggregation.</b> This service owns NO business logic: it calls the existing customer
 * read services and stitches their outputs together. It never mines raw entities, never recomputes an
 * interest profile / recommendation score / budget / statistic, never persists, caches, mutates, or
 * emits notifications. Every reused service is itself {@code @Transactional(readOnly = true)} and
 * batch-optimised; running under a single read-only transaction here keeps the whole snapshot
 * consistent without adding queries of its own.
 *
 * <p>Trip classification (current vs upcoming) is the only derived step, and it is a pure filter over
 * the already-fetched {@code getMine} list — no new query, no duplicated trip logic.
 */
@Service
@Transactional(readOnly = true)
public class AITripContextService {

    /** Cap on the most-recent reviews surfaced in the context. */
    static final int RECENT_REVIEWS_LIMIT = 5;

    private final CustomerProfileService customerProfileService;
    private final UserInterestProfileService userInterestProfileService;
    private final RecommendationEngineService recommendationEngineService;
    private final TripPlannerService tripPlannerService;
    private final BookingService bookingService;
    private final SavedCollectionService savedCollectionService;
    private final WishlistService wishlistService;
    private final ReviewService reviewService;
    private final TripPlanBudgetService tripPlanBudgetService;
    private final CustomerPersonalizationService personalizationService;

    public AITripContextService(CustomerProfileService customerProfileService,
                                UserInterestProfileService userInterestProfileService,
                                RecommendationEngineService recommendationEngineService,
                                TripPlannerService tripPlannerService,
                                BookingService bookingService,
                                SavedCollectionService savedCollectionService,
                                WishlistService wishlistService,
                                ReviewService reviewService,
                                TripPlanBudgetService tripPlanBudgetService,
                                CustomerPersonalizationService personalizationService) {
        this.customerProfileService = customerProfileService;
        this.userInterestProfileService = userInterestProfileService;
        this.recommendationEngineService = recommendationEngineService;
        this.tripPlannerService = tripPlannerService;
        this.bookingService = bookingService;
        this.savedCollectionService = savedCollectionService;
        this.wishlistService = wishlistService;
        this.reviewService = reviewService;
        this.tripPlanBudgetService = tripPlanBudgetService;
        this.personalizationService = personalizationService;
    }

    /**
     * Build the full context for the acting user. Own-scoped end to end: every reused call receives
     * only {@code userId}, so no other user's data can enter the snapshot.
     */
    public AITripContextResponse buildContext(Long userId) {
        // ── Reused service outputs (no re-mining) ──────────────────────────────────────────────
        CustomerProfileResponse userProfile = customerProfileService.getMyProfile(userId);
        InterestProfileResponse interestProfile = userInterestProfileService.get(userId);
        List<RecommendationResponse> recommendations = recommendationEngineService.recommend(userId);
        List<TripSummaryResponse> myTrips = tripPlannerService.getMine(userId);
        List<BookingSummaryResponse> bookings = bookingService.getMyBookings(userId);
        List<CollectionSummaryResponse> savedCollections = savedCollectionService.listMine(userId);
        WishlistResponse wishlist = wishlistService.getMine(userId);
        List<ReviewSummaryResponse> allReviews = reviewService.getMyReviews(userId);
        CustomerPreferenceProfileResponse preferences = personalizationService.getPreferenceProfile(userId);

        // ── Derived (pure filters over the already-fetched trip list) ──────────────────────────
        LocalDate today = LocalDate.now();
        TripSummaryResponse currentTrip = pickCurrentTrip(myTrips, today);
        List<TripSummaryResponse> upcomingTrips = pickUpcomingTrips(myTrips, today);

        // Budget summary reuses the existing aggregation, only for the in-progress trip.
        TripPlanBudgetSummaryResponse budgetSummary = currentTrip != null
            ? tripPlanBudgetService.getBudgetSummary(userId, currentTrip.id())
            : null;

        List<ReviewSummaryResponse> recentReviews = allReviews.stream()
            .limit(RECENT_REVIEWS_LIMIT).toList();

        List<com.example.planyourtrip.dto.WishlistDto.WishlistItemResponse> wishlistItems =
            wishlist != null && wishlist.items() != null ? wishlist.items() : List.of();
        WishlistSummary wishlistSummary = new WishlistSummary(wishlistItems.size(), wishlistItems);

        ActivitySummary activitySummary = new ActivitySummary(
            myTrips.size(),
            (int) myTrips.stream().filter(t -> "ACTIVE".equals(t.status())).count(),
            upcomingTrips.size(),
            (int) myTrips.stream().filter(t -> "COMPLETED".equals(t.status())).count(),
            myTrips.stream().mapToLong(TripSummaryResponse::dayCount).sum(),
            bookings.size(),
            savedCollections.size(),
            wishlistItems.size(),
            allReviews.size(),
            recommendations.size());

        return new AITripContextResponse(
            userProfile, interestProfile, recommendations, currentTrip, upcomingTrips,
            bookings, savedCollections, wishlistSummary, recentReviews, budgetSummary,
            activitySummary, preferences, Instant.now());
    }

    // ── Trip classification (deterministic filters, no duplicated trip logic) ───────────────────

    /**
     * The in-progress trip: a non-cancelled, non-completed trip whose {@code [startDate, endDate]}
     * range contains today. Deterministic tie-break: earliest start date, then lowest id. Null if none.
     */
    private TripSummaryResponse pickCurrentTrip(List<TripSummaryResponse> trips, LocalDate today) {
        return trips.stream()
            .filter(t -> isOpenStatus(t.status()))
            .filter(t -> t.startDate() != null && t.endDate() != null)
            .filter(t -> !today.isBefore(t.startDate()) && !today.isAfter(t.endDate()))
            .min(Comparator.comparing(TripSummaryResponse::startDate)
                .thenComparing(TripSummaryResponse::id))
            .orElse(null);
    }

    /** Trips that have not started yet (start date strictly after today), earliest first. */
    private List<TripSummaryResponse> pickUpcomingTrips(List<TripSummaryResponse> trips, LocalDate today) {
        return trips.stream()
            .filter(t -> isOpenStatus(t.status()))
            .filter(t -> t.startDate() != null && t.startDate().isAfter(today))
            .sorted(Comparator.comparing(TripSummaryResponse::startDate)
                .thenComparing(TripSummaryResponse::id))
            .toList();
    }

    private static boolean isOpenStatus(String status) {
        return !"CANCELLED".equals(status) && !"COMPLETED".equals(status);
    }
}
