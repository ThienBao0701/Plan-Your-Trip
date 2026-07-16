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
        @DecimalMin(value = "0.0", inclusive = false) BigDecimal creditAmount,
        // Phase 7.25 — optional gift-card code redeemed at checkout AFTER travel
        // credits (auto-clamped to min(balance, remaining payable); ignored when absent).
        String giftCardCode,
        // Phase 7.29 — optional explicit rate plan selection + extra beds. When
        // ratePlanId is provided it is validated for eligibility (else 422) and its
        // terms are snapshotted onto the booking; when omitted the best eligible plan
        // is snapshotted. Both ignored (null/0) for the pre-7.29 payload.
        Long ratePlanId,
        Integer extraBeds
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
        Long loyaltyPointsRedeemed,
        // Phase 7.25 — additive only; both null when no gift card was redeemed
        // (or after a redemption is released/refunded).
        BigDecimal giftCardAmountUsed,
        String giftCardReference,
        // Phase 7.29 — additive only; all null when no rate plan was resolved for the booking.
        Long selectedRatePlanId,
        String selectedRatePlanCode,
        String selectedRatePlanName,
        String mealPlanType,
        String cancellationPolicyType,
        Instant cancellationDeadlineAt,
        Boolean refundable,
        BigDecimal nightlyRateSnapshot,
        BigDecimal ratePlanAdjustmentSnapshot
    ) {}

    /**
     * Phase 7.34 — customer modification of a PENDING (not-yet-paid) booking. Every field is
     * OPTIONAL: an omitted (null) field keeps the booking's current value, so a caller can change
     * just the dates, just the occupancy, or just the rate plan. Scoped deliberately to PENDING
     * bookings to avoid the payment-settlement price-difference problem (see BookingService.modify).
     *
     * <p>Notes on the two fields that are NOT persisted on the booking entity:
     * <ul>
     *   <li>{@code extraBeds} is a pricing-only input (never stored on Booking), so an omitted
     *       extraBeds is treated as 0 — mirroring {@code create()} where an omitted extraBeds is 0.
     *       Resend it if the stay still needs extra beds.</li>
     *   <li>{@code ratePlanId} omitted keeps the booking's currently-snapshotted rate plan and
     *       re-prices it for the new params; that retained plan must remain eligible for the new
     *       dates/occupancy or the modification is rejected (422), exactly like create().</li>
     * </ul>
     */
    public record BookingModificationRequest(
        LocalDate checkIn,
        LocalDate checkOut,
        @Min(1) Integer adults,
        @Min(0) Integer children,
        @Min(0) Integer extraBeds,
        Long ratePlanId
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
