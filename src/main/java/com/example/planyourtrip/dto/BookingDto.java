package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.BookingStatus;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public class BookingDto {

    /**
     * Phase 7.15 additions — both optional and ignored when absent, so the
     * pre-7.15 payload behaves exactly as before:
     * {@code couponCode} — a coupon code the customer has CLAIMED (matched
     * case-insensitively; code chosen over couponId as the friendlier contract);
     * {@code creditAmount} — an explicit positive amount of promotional travel
     * credits to redeem (explicit amount chosen over a use-all boolean for
     * customer control). Coupon applies first, credits against the remainder.
     */
    public record BookingRequest(
        @NotNull Long roomId,
        @NotNull LocalDate checkIn,
        @NotNull LocalDate checkOut,
        @NotNull @Min(1) Integer adults,
        Integer children,
        Integer numberOfRooms,
        String specialRequest,
        String couponCode,
        @DecimalMin(value = "0.0", inclusive = false) BigDecimal creditAmount
    ) {}

    public record BookingResponse(
        Long id,
        String bookingCode,
        Long userId, String userFullName, String userEmail,
        Long hotelId, String hotelName,
        Long roomId, String roomName, String roomCode,
        LocalDate checkIn, LocalDate checkOut,
        int nights, int adults, int children, int numberOfRooms,
        String status,
        String currency,
        BigDecimal basePrice,
        BigDecimal ratePlanPrice,
        BigDecimal discountAmount,
        BigDecimal finalPrice,
        String specialRequest,
        String partnerNote,
        Instant createdAt,
        Instant updatedAt,
        Instant confirmedAt,
        Instant cancelledAt,
        Instant actualCheckInAt,
        Instant actualCheckOutAt,
        Instant completedAt,
        Instant archivedAt,
        Instant lastStatusChangedAt,
        String cancelReason,
        // Phase 7.15 — additive only; all three are null when no coupon/credits were used.
        String couponCode,
        BigDecimal couponDiscountAmount,
        BigDecimal creditAmountUsed,
        // Phase 7.20 — additive only; both null when no loyalty redemption was applied.
        BigDecimal loyaltyDiscountAmount,
        Long loyaltyPointsRedeemed
    ) {}

    public record BookingSummaryResponse(
        Long id,
        String bookingCode,
        Long hotelId, String hotelName,
        Long roomId, String roomName,
        LocalDate checkIn, LocalDate checkOut,
        int nights,
        String status,
        BigDecimal finalPrice,
        String currency,
        Instant createdAt
    ) {}

    public record BookingStatusRequest(
        @NotNull BookingStatus status
    ) {}

    public record CancelRequest(String cancelReason) {}

    public record TimelineEvent(String event, Instant occurredAt, String description) {}

    public record BookingTimelineResponse(
        Long bookingId,
        String bookingCode,
        List<TimelineEvent> events
    ) {}

    public record UpcomingBookingResponse(
        Long id,
        String bookingCode,
        String hotelName,
        String roomName,
        LocalDate checkIn,
        LocalDate checkOut,
        int nights,
        String status,
        BigDecimal finalPrice,
        String currency
    ) {}

    public record BookingHistoryResponse(
        Long id,
        String bookingCode,
        String hotelName,
        String roomName,
        LocalDate checkIn,
        LocalDate checkOut,
        int nights,
        String status,
        BigDecimal finalPrice,
        String currency,
        Instant createdAt,
        Instant confirmedAt
    ) {}
}
