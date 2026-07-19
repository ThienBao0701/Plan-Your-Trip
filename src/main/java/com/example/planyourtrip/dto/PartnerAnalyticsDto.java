package com.example.planyourtrip.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

public class PartnerAnalyticsDto {

    public record TimeSeriesPoint(LocalDate date, BigDecimal value) {}

    public record MetricBreakdown(String label, BigDecimal value, long count) {}

    public record PartnerAnalyticsOverviewResponse(
        BigDecimal totalRevenue,
        long totalBookings,
        long confirmedBookings,
        long cancelledBookings,
        long completedBookings,
        double occupancyRate,
        double averageDailyRate,
        double averageStayNights,
        double reviewAverage,
        long reviewCount,
        long unreadMessages,
        Double responseRate
    ) {}

    public record RevenueAnalyticsResponse(
        List<TimeSeriesPoint> revenueByDay,
        List<MetricBreakdown> revenueByRoom,
        List<MetricBreakdown> revenueByHotel,
        BigDecimal revenueMonthToDate,
        BigDecimal revenueLast30Days
    ) {}

    public record OccupancyAnalyticsResponse(
        List<TimeSeriesPoint> occupancyByDay,
        int totalRoomInventory,
        int soldRooms,
        int availableRooms,
        long stopSellDaysCount
    ) {}

    public record BookingAnalyticsResponse(
        List<MetricBreakdown> bookingsByStatus,
        long arrivals,
        long departures,
        long cancellations,
        long noShows,
        double averageStayLength
    ) {}

    public record RoomAnalyticsResponse(
        List<MetricBreakdown> topRoomsByRevenue,
        List<MetricBreakdown> topRoomsByBookings,
        List<MetricBreakdown> roomAvailabilitySummary,
        double roomOccupancyEstimate
    ) {}

    public record PromotionAnalyticsResponse(
        long activePromotions,
        List<MetricBreakdown> promotionsByType,
        Long estimatedDiscountedBookings,
        List<MetricBreakdown> promotionCountByStatus
    ) {}

    public record ReviewPreview(
        Long id,
        String guestName,
        int ratingOverall,
        String title,
        String status,
        Instant createdAt
    ) {}

    public record ReviewAnalyticsResponse(
        double averageRating,
        long reviewCount,
        long pendingReviews,
        long approvedReviews,
        long rejectedReviews,
        List<ReviewPreview> latestReviews
    ) {}

    public record MessageAnalyticsResponse(
        long openConversations,
        long closedConversations,
        long archivedConversations,
        long unreadPartnerMessages,
        Double averageResponseTimeMinutes
    ) {}

    /**
     * Phase 7.46 — single-place PARTNER review analytics (read-only). Population of each metric:
     *
     * <ul>
     *   <li>total/approved/pending/rejected/hidden/reported: counts over ALL reviews of the place, by status.</li>
     *   <li>averageOverallRating and the category averages: mean over APPROVED reviews only (the public,
     *       reputation-bearing set — consistent with {@code getReviewAnalytics}); 0.0 when there are none.
     *       Each category average ignores reviews that left that category null.</li>
     *   <li>starDistribution: map 1..5 → count of APPROVED reviews whose overall rating equals the star
     *       (0-filled for every star), so it lines up with averageOverallRating's population.</li>
     *   <li>partnerReplyCount: reviews (any status) that carry a partner reply.</li>
     *   <li>partnerReplyRate: percentage 0–100 = partnerReplyCount / totalReviews * 100; 0.0 when no reviews.</li>
     *   <li>latestReviewAt: newest createdAt over ALL reviews; null when there are none.</li>
     *   <li>reviewsInRange: count of ALL reviews created within [from, to].</li>
     *   <li>averageRatingInRange: mean overall of APPROVED reviews created within [from, to]; 0.0 when none.</li>
     * </ul>
     */
    public record PlaceReviewAnalyticsResponse(
        Long placeId,
        String placeName,
        long totalReviews,
        long approvedReviews,
        long pendingReviews,
        long rejectedReviews,
        long hiddenReviews,
        long reportedReviews,
        double averageOverallRating,
        double averageCleanliness,
        double averageService,
        double averageLocation,
        double averageValue,
        double averageFacilities,
        Map<Integer, Long> starDistribution,
        long partnerReplyCount,
        double partnerReplyRate,
        Instant latestReviewAt,
        long reviewsInRange,
        double averageRatingInRange
    ) {}
}
