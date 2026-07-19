package com.example.planyourtrip.dto;

import com.example.planyourtrip.dto.PartnerAnalyticsDto.MetricBreakdown;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * Read-only platform-wide analytics for the platform ADMIN.
 *
 * <p>Deliberately mirrors the {@link PartnerAnalyticsDto} conventions (optional
 * {@code from}/{@code to} date window, {@link MetricBreakdown} response record) so admin
 * and partner numbers reconcile, but the metrics here are UN-scoped aggregates across
 * every row in the platform rather than the owner-scoped metrics a partner sees.
 */
public class AdminAnalyticsDto {

    /**
     * Platform headline metrics.
     *
     * @param from                 resolved start of the date window (echoed for clarity)
     * @param to                   resolved end of the date window (echoed for clarity)
     * @param totalBookings        all-time count of every booking on the platform
     * @param bookingsByStatus     all-time count grouped by {@code BookingStatus} (every status present, 0-filled)
     * @param grossRevenue         all-time gross revenue: sum of {@code Booking.finalPrice} for revenue-recognised statuses
     * @param activeHotels         count of hotels whose backing place is PUBLISHED (live)
     * @param activeRooms          count of hotel rooms flagged {@code active = true}
     * @param totalUsers           count of all registered user accounts
     * @param totalPartners        count of all partner profiles (any verification status)
     * @param bookingsInRange      count of bookings whose check-in date falls in [from, to]
     * @param revenueInRange       gross revenue (same definition as {@code grossRevenue}) restricted to check-in in [from, to]
     */
    public record AdminAnalyticsOverviewResponse(
        LocalDate from,
        LocalDate to,
        long totalBookings,
        List<MetricBreakdown> bookingsByStatus,
        BigDecimal grossRevenue,
        long activeHotels,
        long activeRooms,
        long totalUsers,
        long totalPartners,
        long bookingsInRange,
        BigDecimal revenueInRange
    ) {}

    /**
     * Phase 7.46 — platform-wide ADMIN review-analytics overview (read-only, un-scoped).
     * Computed from additive aggregate queries on {@code ReviewRepository} (no row loading). Populations:
     *
     * <ul>
     *   <li>totalReviews: all reviews on the platform.</li>
     *   <li>statusBreakdown: one {@link MetricBreakdown} per {@code ReviewStatus} (all 5, 0-filled).</li>
     *   <li>ratingDistribution: map 1..5 → count of APPROVED reviews with that overall rating (0-filled).</li>
     *   <li>averageOverallRating + category averages: over APPROVED reviews; 0.0 when there are none.</li>
     *   <li>partnerReplyRate: percentage 0–100 = reviews-with-a-reply / totalReviews * 100; 0.0 when none.</li>
     *   <li>reviewedPlaces: distinct places with ≥1 review (any status).</li>
     *   <li>latestReviewAt: newest createdAt across the platform; null when there are none.</li>
     *   <li>reviewsInRange: count of ALL reviews created within [from, to].</li>
     *   <li>averageRatingInRange: mean overall of APPROVED reviews created within [from, to]; 0.0 when none.</li>
     * </ul>
     */
    public record AdminReviewAnalyticsOverviewResponse(
        LocalDate from,
        LocalDate to,
        long totalReviews,
        List<MetricBreakdown> statusBreakdown,
        Map<Integer, Long> ratingDistribution,
        double averageOverallRating,
        double averageCleanliness,
        double averageService,
        double averageLocation,
        double averageValue,
        double averageFacilities,
        double partnerReplyRate,
        long reviewedPlaces,
        Instant latestReviewAt,
        long reviewsInRange,
        double averageRatingInRange
    ) {}
}
