package com.example.planyourtrip.dto;

import java.time.LocalDate;

/**
 * Phase 7.39 — Partner Voucher Verification (read-only; NO check-in).
 *
 * <p>Request/response shapes for the single authenticated partner endpoint
 * {@code POST /api/partner/bookings/voucher/verify}. A partner scans the customer's Phase 7.38
 * signed voucher QR payload ({@code PYT-V1.<bookingCode>.<sig>}); the backend verifies the HMAC
 * signature (reusing {@code security.VoucherSignatureService}), resolves the booking, confirms it
 * belongs to one of the calling partner's OWN hotels and reports check-in eligibility — WITHOUT
 * mutating anything. Actual check-in is deferred to Phase 7.40.
 *
 * <p><b>Deliberately minimal, staff-facing projection.</b> The response carries ONLY the fields a
 * front-desk clerk needs to admit a guest: booking code/status, hotel, room, guest name, stay dates,
 * occupancy and nights. It NEVER exposes payment/transaction ids, gift-card / coupon / travel-credit /
 * loyalty data, JWTs, the guest email, or partner internal notes.
 *
 * <p><b>{@code guestPhone} is intentionally absent.</b> The spec listed a {@code guestPhone}, but the
 * data model has no guest phone number: {@code User} has no phone field, and {@code CustomerProfile}
 * only stores an {@code emergencyContactPhone} (a third party's number, semantically wrong to surface
 * as the guest's own contact). Rather than invent or mislabel data, the field is omitted.
 */
public class PartnerVoucherDto {

    /** The exact QR string produced by the Phase 7.38 customer voucher ({@code qrPayload}). */
    public record VoucherVerifyRequest(String voucherPayload) {}

    /** Minimal occupancy projection — adults/children only (no pricing, no per-guest detail). */
    public record Occupancy(int adults, int children) {}

    /**
     * Result of a partner voucher verification.
     *
     * <p>{@code verified} is true ONLY when the signature is valid AND the booking exists AND it is
     * owned by the calling partner — otherwise the endpoint returns 404 (no field is populated). A
     * verified-but-ineligible booking (e.g. PENDING/CANCELLED) still returns 200 with
     * {@code verified=true}, {@code eligible=false} and a human-readable {@code reason}; only an
     * invalid signature / unknown booking / not-owned booking collapses to a uniform 404.
     */
    public record VoucherVerificationResponse(
        boolean verified,
        boolean eligible,
        String reason,
        String bookingCode,
        String bookingStatus,
        Long hotelId,
        String hotelName,
        Long roomId,
        String roomName,
        String guestName,
        LocalDate checkInDate,
        LocalDate checkOutDate,
        Occupancy occupancy,
        int nights
    ) {}
}
