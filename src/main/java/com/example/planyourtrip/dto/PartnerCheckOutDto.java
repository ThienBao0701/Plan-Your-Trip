package com.example.planyourtrip.dto;

import java.time.Instant;

/**
 * Phase 7.41 — Partner Guest Check-out (near-mirror of Phase 7.40's check-in MUTATION).
 *
 * <p>Request/response shapes for {@code POST /api/partner/bookings/check-out}. An approved partner checks
 * a guest out either by scanning the Phase 7.38 signed voucher QR payload ({@code voucherPayload}) or by
 * typing the booking code directly ({@code bookingCode}) — exactly one must be supplied. It reuses the
 * SAME signature-verification + booking-resolution + ownership logic as check-in, then performs the
 * {@code CHECKED_IN → CHECKED_OUT} transition via {@code BookingStatusEngineService}.
 *
 * <p><b>Deliberately minimal, staff-facing projection.</b> The response carries ONLY what a front desk
 * needs to confirm a departure: success flag, booking code/status, the check-out instant, hotel/room/
 * guest names and a human-readable message. It NEVER exposes payment/transaction ids, gift-card /
 * coupon / travel-credit / loyalty data, JWTs, the guest email, or partner internal notes.
 */
public class PartnerCheckOutDto {

    /**
     * Exactly one of {@code voucherPayload} / {@code bookingCode} must be non-blank (400 otherwise).
     * {@code voucherPayload} is the exact QR string {@code PYT-V1.<bookingCode>.<sig>} (⇒ QR_SCAN method);
     * {@code bookingCode} is the raw immutable booking code (⇒ MANUAL method). Ownership + eligibility +
     * time-window checks apply identically regardless of which is used.
     */
    public record CheckOutRequest(String voucherPayload, String bookingCode) {}

    public record CheckOutResponse(
        boolean success,
        String bookingCode,
        String bookingStatus,
        Instant checkedOutAt,
        String hotelName,
        String roomName,
        String guestName,
        String message
    ) {}
}
