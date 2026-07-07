package com.example.planyourtrip.dto;

import com.example.planyourtrip.dto.PartnerAnalyticsDto.MetricBreakdown;
import com.example.planyourtrip.dto.PartnerAnalyticsDto.TimeSeriesPoint;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public class PartnerFinanceDto {

    /** Generic (label, amount) pair — used for month-bucketed or category-bucketed monetary breakdowns. */
    public record FinanceMetric(String label, BigDecimal amount) {}

    /** One synthesized settlement/payout period (a calendar month) with its gross/commission/net split. */
    public record SettlementHistoryItem(
        String period,
        BigDecimal grossAmount,
        BigDecimal commissionAmount,
        BigDecimal netAmount,
        String status
    ) {}

    public record PartnerFinanceOverviewResponse(
        BigDecimal grossRevenue,
        BigDecimal netRevenue,
        BigDecimal commissionAmount,
        BigDecimal estimatedTax,
        long completedBookings,
        long paidBookings,
        BigDecimal refundedAmount,
        BigDecimal pendingSettlement,
        LocalDate nextEstimatedPayoutDate
    ) {}

    public record PartnerRevenueResponse(
        List<TimeSeriesPoint> revenueByDay,
        List<FinanceMetric> revenueByMonth,
        List<MetricBreakdown> revenueByHotel,
        List<MetricBreakdown> revenueByRoom,
        BigDecimal averageBookingValue,
        BigDecimal highestBooking
    ) {}

    public record PartnerCommissionResponse(
        BigDecimal gross,
        BigDecimal commission,
        BigDecimal net,
        double commissionRate
    ) {}

    public record PartnerSettlementResponse(
        BigDecimal currentSettlement,
        BigDecimal lastSettlement,
        BigDecimal pending,
        BigDecimal paid,
        List<SettlementHistoryItem> settlementHistory,
        BigDecimal estimatedNextSettlement
    ) {}

    public record PartnerPayoutResponse(
        List<SettlementHistoryItem> upcomingPayouts,
        List<SettlementHistoryItem> completedPayouts,
        LocalDate estimatedPayoutDate
    ) {}

    public record PartnerInvoiceFinanceResponse(
        long issued,
        long paid,
        long cancelled,
        long refunded,
        BigDecimal totalInvoiceAmount
    ) {}

    public record PartnerRefundResponse(
        long refundCount,
        BigDecimal refundAmount,
        double refundPercentage
    ) {}
}
