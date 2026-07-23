package com.example.planyourtrip.dto;

import com.example.planyourtrip.dto.BookingDto.BookingSummaryResponse;
import com.example.planyourtrip.dto.CollectionDto.CollectionSummaryResponse;
import com.example.planyourtrip.dto.CustomerProfileDto.CustomerProfileResponse;
import com.example.planyourtrip.dto.PersonalizationDto.CustomerPreferenceProfileResponse;
import com.example.planyourtrip.dto.RecommendationEngineDto.RecommendationResponse;
import com.example.planyourtrip.dto.ReviewDto.ReviewSummaryResponse;
import com.example.planyourtrip.dto.TripPlanBudgetDto.TripPlanBudgetSummaryResponse;
import com.example.planyourtrip.dto.TripPlanDto.TripSummaryResponse;
import com.example.planyourtrip.dto.UserInterestDto.InterestProfileResponse;
import com.example.planyourtrip.dto.WishlistDto.WishlistItemResponse;

import java.time.Instant;
import java.util.List;

/**
 * Phase 7.50 — the AI Trip Context: a read-only, single-source-of-truth aggregate that every future
 * AI capability will consume. It carries ONLY outputs already produced by existing services — it
 * introduces no new place/trip/booking DTOs, and every embedded field is an existing response record
 * reused verbatim.
 *
 * <p>Nothing here is persisted or cached. {@link #contextGeneratedAt} records when the snapshot was
 * assembled; it is the only non-deterministic field (all others are pure functions of stored data).
 */
public final class AITripContextDto {

    private AITripContextDto() {}

    public record AITripContextResponse(
        CustomerProfileResponse userProfile,
        InterestProfileResponse interestProfile,
        List<RecommendationResponse> recommendations,
        TripSummaryResponse currentTrip,                 // nullable — no in-progress trip
        List<TripSummaryResponse> upcomingTrips,
        List<BookingSummaryResponse> bookings,
        List<CollectionSummaryResponse> savedCollections,
        WishlistSummary wishlistSummary,
        List<ReviewSummaryResponse> recentReviews,
        TripPlanBudgetSummaryResponse budgetSummary,     // nullable — only when a current trip exists
        ActivitySummary activitySummary,
        CustomerPreferenceProfileResponse preferences,
        Instant contextGeneratedAt
    ) {}

    /** Compact wishlist view — count plus the reused wishlist item responses (no re-mapping). */
    public record WishlistSummary(
        int itemCount,
        List<WishlistItemResponse> items
    ) {}

    /** Cross-section counts derived purely from the already-aggregated collections (no extra queries). */
    public record ActivitySummary(
        int totalTrips,
        int activeTrips,
        int upcomingTrips,
        int completedTrips,
        long totalPlannedDays,
        int totalBookings,
        int savedCollections,
        int wishlistItems,
        int reviews,
        int recommendations
    ) {}
}
