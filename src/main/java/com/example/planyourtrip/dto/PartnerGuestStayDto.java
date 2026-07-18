package com.example.planyourtrip.dto;

import com.example.planyourtrip.dto.BookingDto.BookingTimelineResponse;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

/**
 * Phase 7.42 — Consolidated READ-ONLY Partner Guest Stay Detail.
 *
 * <p>A single, ownership-scoped projection that lets the partner frontend build the whole guest-stay
 * screen from ONE call to {@code GET /api/partner/stays/{bookingId}} instead of stitching together the
 * booking detail, timeline, modification history and check-in/out audits. It is a SUPERSET of
 * {@code PartnerBookingDetailResponse} for the stay use-case and performs NO mutation of any kind — it
 * only reads already-persisted rows (booking, timeline, modification audits, check-in/out audits).
 *
 * <p>Deliberately excluded (never present in this response): payment/transaction ids, webhook payloads,
 * gift-card codes, coupon secrets, loyalty/travel-credit ledger detail, JWTs, the voucher signing
 * secret and any QR payload, guest email/phone (no safe guest phone exists — {@code User} has none and
 * {@code CustomerProfile.emergencyContactPhone} is a third party's number).
 */
public class PartnerGuestStayDto {

    /** Persisted occupancy snapshot. Guest phone/email intentionally omitted (no safe source). */
    public record OccupancyInfo(int adults, int children) {}

    /**
     * Stay schedule + derived stay progress. {@code currentStayState} is a RESPONSE-LEVEL classification
     * (never a DB enum), derived from the persisted booking status + dates + today. Night numbers are
     * deterministic and never negative (see {@code PartnerBookingService}).
     */
    public record StaySchedule(
        LocalDate checkInDate,
        LocalDate checkOutDate,
        long totalNights,
        Instant actualCheckInAt,
        Instant actualCheckOutAt,
        String currentStayState,
        long currentNightNumber,
        long remainingNights
    ) {}

    /**
     * Voucher classification only — reuses the SAME derivation as {@code BookingService.getVoucher}
     * ({@code voucherStatusOf} + latest payment status). No QR payload, no signature, no secret.
     * {@code voucherAvailable} is true only when the status classifies as VALID.
     */
    public record VoucherSummary(boolean voucherAvailable, String voucherStatus) {}

    /** One immutable {@code BookingModification} row (Phase 7.36), mapped verbatim. */
    public record StayModification(
        LocalDate previousCheckIn, LocalDate newCheckIn,
        LocalDate previousCheckOut, LocalDate newCheckOut,
        int previousAdults, int newAdults,
        int previousChildren, int newChildren,
        Long previousRatePlanId, Long newRatePlanId,
        String previousRatePlan, String newRatePlan,
        BigDecimal previousPrice, BigDecimal newPrice,
        Instant modifiedAt
    ) {}

    /**
     * A single check-in ({@code method} null) or check-out ({@code method} = QR_SCAN/MANUAL) audit row.
     * Each booking has AT MOST ONE of each (Phase 7.40/7.41 idempotency guarantee).
     */
    public record StayCheckAudit(
        Long partnerProfileId,
        Long partnerUserId,
        String operation,
        String method,
        Instant timestamp
    ) {}

    public record PartnerGuestStayResponse(
        // 1. Booking
        Long bookingId,
        String bookingCode,
        String bookingStatus,
        Instant createdAt,
        Instant updatedAt,
        // 2. Guest (phone/email omitted — no safe source)
        String guestName,
        OccupancyInfo occupancy,
        // 3. Hotel / room
        Long hotelId, String hotelName,
        Long roomId, String roomName, String roomCode,
        // 4. Stay schedule + derived progress
        StaySchedule schedule,
        // 5. Voucher classification (no secret/internals)
        VoucherSummary voucher,
        // 6. Reused lifecycle timeline (BookingService.adminGetTimeline)
        BookingTimelineResponse timeline,
        // 7. Modification history (ascending)
        List<StayModification> modifications,
        // 8. Check-in audit (nullable single)
        StayCheckAudit checkInAudit,
        // 9. Check-out audit (nullable single)
        StayCheckAudit checkOutAudit,
        // 10. Derived operational warnings
        List<String> operationalWarnings
    ) {}
}
