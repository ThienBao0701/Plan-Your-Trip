package com.example.planyourtrip.dto;

import com.example.planyourtrip.dto.PartnerAnalyticsDto.MetricBreakdown;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

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
}
