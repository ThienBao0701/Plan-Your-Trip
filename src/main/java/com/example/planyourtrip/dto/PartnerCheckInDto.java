package com.example.planyourtrip.dto;

import java.time.Instant;

/**
 * Phase 7.40 — Partner Guest Check-in (the FIRST staff-performed booking MUTATION).
 *
 * <p>Request/response shapes for {@code POST /api/partner/bookings/check-in}. An approved partner
 * admits a guest either by scanning the Phase 7.38 signed voucher QR payload ({@code voucherPayload})
 * or by typing the booking code directly ({@code bookingCode}) — exactly one must be supplied. This is
 * the MUTATION counterpart to the Phase 7.39 read-only verify endpoint; it reuses the SAME
 * signature-verification + booking-resolution + ownership logic, then performs the
 * {@code CONFIRMED/CHECK_IN_READY → CHECKED_IN} transition via {@code BookingStatusEngineService}.
 *
 * <p><b>Deliberately minimal, staff-facing projection.</b> The response carries ONLY what a front desk
 * needs to confirm an admission: success flag, booking code/status, the check-in instant, hotel/room/
 * guest names and a human-readable message. It NEVER exposes payment/transaction ids, gift-card /
 * coupon / travel-credit / loyalty data, JWTs, the guest email, or partner internal notes.
 */
public class PartnerCheckInDto {

    /**
     * Exactly one of {@code voucherPayload} / {@code bookingCode} must be non-blank (400 otherwise).
     * {@code voucherPayload} is the exact QR string {@code PYT-V1.<bookingCode>.<sig>}; {@code bookingCode}
     * is the raw immutable booking code (a partner may admit their own booking without a scanned QR).
     * Ownership + eligibility + time-window checks apply identically regardless of which is used.
     */
    public record CheckInRequest(String voucherPayload, String bookingCode) {}

    public record CheckInResponse(
        boolean success,
        String bookingCode,
        String bookingStatus,
        Instant checkedInAt,
        String hotelName,
        String roomName,
        String guestName,
        String message
    ) {}
}
