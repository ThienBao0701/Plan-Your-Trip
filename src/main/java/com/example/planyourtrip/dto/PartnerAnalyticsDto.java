package com.example.planyourtrip.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

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
}
