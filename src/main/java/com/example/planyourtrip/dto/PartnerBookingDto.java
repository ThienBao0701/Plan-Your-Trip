package com.example.planyourtrip.dto;

import com.example.planyourtrip.dto.BookingDto.BookingTimelineResponse;
import com.example.planyourtrip.dto.InvoiceDto.InvoiceSummaryResponse;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public class PartnerBookingDto {

    /**
     * RBAC R3b — {@code guestName} is masked without {@code booking.guest_identity.view} (P54) and
     * {@code guestEmail} omitted (null) without {@code booking.guest_contact.view} (P35); {@code redacted} lists
     * what was withheld (§21.2 SD-1).
     */
    public record PartnerBookingSummaryResponse(
        Long id,
        String bookingCode,
        Long roomId, String roomName, String roomCode,
        String guestName, String guestEmail,
        LocalDate checkIn, LocalDate checkOut, int nights,
        String status,
        BigDecimal finalPrice, String currency,
        Instant createdAt,
        List<RedactedField> redacted
    ) {}

    /**
     * RBAC R3b — a booking as a partner may see it (§21). Never present, for any partner role (§21.3 NR-2): the
     * traveller's {@code userId} and {@code loyaltyPointsRedeemed}. Field-level (null and listed in
     * {@code redacted} when not held at the booking's property): {@code userFullName} masked without P54,
     * {@code userEmail} without P35, the guest free text ({@code specialRequest}, {@code partnerNote},
     * {@code cancelReason}) without P40, the price breakdown without P36.
     */
    public record PartnerBookingView(
        Long id,
        String bookingCode,
        String userFullName, String userEmail,
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
        String couponCode,
        BigDecimal couponDiscountAmount,
        BigDecimal creditAmountUsed,
        BigDecimal loyaltyDiscountAmount,
        BigDecimal giftCardAmountUsed,
        String giftCardReference,
        Long selectedRatePlanId,
        String selectedRatePlanCode,
        String selectedRatePlanName,
        String mealPlanType,
        String cancellationPolicyType,
        Instant cancellationDeadlineAt,
        Boolean refundable,
        BigDecimal nightlyRateSnapshot,
        BigDecimal ratePlanAdjustmentSnapshot,
        List<RedactedField> redacted
    ) {}

    /**
     * RBAC R3b — a payment record for a partner holding {@code booking.payment.view} (P36). The payment link
     * ({@code checkoutUrl}) and the raw provider error ({@code failureReason}) are never in any partner response
     * (§21.3 NR-1).
     */
    public record PartnerPaymentView(
        Long id,
        String paymentCode,
        Long bookingId,
        String bookingCode,
        BigDecimal amount,
        String currency,
        String paymentMethod,
        String status,
        String provider,
        String providerTransactionId,
        Instant paidAt,
        Instant failedAt,
        Instant refundedAt,
        Instant createdAt,
        Instant updatedAt
    ) {}

    /** {@code payments} and {@code invoice} are null without P36; {@code redacted} lists every withheld path. */
    public record PartnerBookingDetailResponse(
        PartnerBookingView booking,
        List<PartnerPaymentView> payments,
        InvoiceSummaryResponse invoice,
        BookingTimelineResponse timeline,
        List<RedactedField> redacted
    ) {}

    /**
     * Operational counts over the bookings the caller may view; {@code revenueToday} and {@code revenueMonth}
     * are null (and listed in {@code redacted}) unless {@code finance.revenue.view} (P49) covers every property
     * counted.
     */
    public record PartnerDashboardResponse(
        long todaysArrivals,
        long todaysDepartures,
        long currentGuests,
        long upcoming,
        long cancelled,
        long completed,
        double occupancyRate,
        BigDecimal revenueToday,
        BigDecimal revenueMonth,
        double averageStayNights,
        List<RedactedField> redacted
    ) {}
}
