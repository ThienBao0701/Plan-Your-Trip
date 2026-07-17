package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PartnerVoucherDto.Occupancy;
import com.example.planyourtrip.dto.PartnerVoucherDto.VoucherVerificationResponse;
import com.example.planyourtrip.dto.PartnerVoucherDto.VoucherVerifyRequest;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.Booking;
import com.example.planyourtrip.model.BookingStatus;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.PartnerVerificationStatus;
import com.example.planyourtrip.repository.BookingRepository;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.security.VoucherSignatureService;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.temporal.ChronoUnit;
import java.util.EnumSet;
import java.util.Set;

/**
 * Phase 7.39 — Partner Voucher Verification (read-only; NO check-in).
 *
 * <p>The FIRST consumer of the Phase 7.38 HMAC-signed voucher QR payload. An approved partner scans a
 * customer's voucher; this service verifies the signature, resolves the booking, confirms it belongs
 * to one of the partner's OWN hotels, and reports check-in eligibility — returning a minimal
 * staff-facing summary. It is STRICTLY READ-ONLY: it never mutates a booking, holds/releases
 * inventory, writes a payment/ledger/notification/audit row, acquires a lock, or performs any status
 * transition. Actual check-in remains the partner's existing
 * {@code PATCH /api/partner/bookings/{id}/check-in} flow / is expanded in Phase 7.40.
 *
 * <p><b>Reuse, not reinvention.</b> Signature verification + bookingCode extraction is delegated
 * verbatim to {@link VoucherSignatureService#verifyAndExtractBookingCode(String)} (no crypto is
 * duplicated). Ownership follows the exact pattern in {@code PartnerBookingService.ownedBookingOrThrow}:
 * resolve the caller's approved {@link PartnerProfile}, then confirm {@code booking.getHotel()} (a
 * {@code Place}) is owned by that profile.
 *
 * <p><b>Uniform 404, no enumeration.</b> An invalid/tampered/wrong-version/malformed signature, an
 * unknown booking, and a booking owned by a DIFFERENT partner ALL collapse to the same
 * 404 "Booking not found" — a partner can never distinguish "bad signature" from "not my hotel" from
 * "no such booking", so the endpoint leaks nothing about other hotels' bookings. (Spring Security
 * independently returns 401/403 for anonymous / non-partner callers before this code runs.)
 *
 * <p><b>Eligible-but-invalid is NOT an error.</b> A found + owned + signature-valid booking always
 * returns 200 with {@code verified=true}; {@code eligible} is true only for {@link #ELIGIBLE_STATUSES}
 * (CONFIRMED / CHECK_IN_READY), otherwise {@code eligible=false} with a human-readable {@code reason}.
 * Only invalid-signature / not-found / not-owned throw 404.
 */
@Service
@Transactional(readOnly = true)
public class PartnerVoucherVerificationService {

    /** Statuses a front desk may admit a guest against. Everything else → eligible=false + reason. */
    private static final Set<BookingStatus> ELIGIBLE_STATUSES =
        EnumSet.of(BookingStatus.CONFIRMED, BookingStatus.CHECK_IN_READY);

    private final VoucherSignatureService voucherSignatureService;
    private final BookingRepository bookingRepo;
    private final PartnerProfileRepository partnerProfiles;

    public PartnerVoucherVerificationService(VoucherSignatureService voucherSignatureService,
                                             BookingRepository bookingRepo,
                                             PartnerProfileRepository partnerProfiles) {
        this.voucherSignatureService = voucherSignatureService;
        this.bookingRepo = bookingRepo;
        this.partnerProfiles = partnerProfiles;
    }

    public VoucherVerificationResponse verify(Long userId, VoucherVerifyRequest req) {
        // Resolve the calling partner FIRST so an unapproved/absent partner profile is rejected
        // identically regardless of the payload (no signal about the payload's validity).
        PartnerProfile profile = myApprovedProfileOrThrow(userId);

        // 1) Verify signature + extract bookingCode. Empty (tampered/invalid/wrong-version/malformed)
        //    → uniform 404, indistinguishable from "unknown booking".
        String payload = req != null ? req.voucherPayload() : null;
        String bookingCode = voucherSignatureService.verifyAndExtractBookingCode(payload)
            .orElseThrow(this::notFound);

        // 2) Resolve the booking by its immutable, unique code.
        Booking booking = bookingRepo.findByBookingCode(bookingCode)
            .orElseThrow(this::notFound);

        // 3) Ownership: the booking's hotel (a Place) must be owned by THIS partner. Otherwise 404
        //    (never 403) — a partner must not learn that another hotel's booking exists.
        PartnerProfile owner = booking.getHotel().getOwner();
        if (owner == null || !owner.getId().equals(profile.getId()))
            throw notFound();

        // 4) Eligibility — verification only, NEVER a mutation or status transition.
        BookingStatus status = booking.getStatus();
        boolean eligible = ELIGIBLE_STATUSES.contains(status);
        String reason = eligible ? null
            : "Booking status " + status.name() + " is not eligible for check-in";

        int nights = (int) ChronoUnit.DAYS.between(booking.getCheckInDate(), booking.getCheckOutDate());

        return new VoucherVerificationResponse(
            true,
            eligible,
            reason,
            booking.getBookingCode(),
            status.name(),
            booking.getHotel().getId(),
            booking.getHotel().getName(),
            booking.getRoom().getId(),
            booking.getRoom().getRoomName(),
            booking.getUser().getFullName(),
            booking.getCheckInDate(),
            booking.getCheckOutDate(),
            new Occupancy(booking.getAdults(), booking.getChildren()),
            nights
        );
    }

    /** Same approved-profile gate as PartnerBookingService / PartnerAnalyticsService. */
    private PartnerProfile myApprovedProfileOrThrow(Long userId) {
        PartnerProfile profile = partnerProfiles.findByUserId(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Partner profile not found"));
        if (profile.getVerificationStatus() != PartnerVerificationStatus.APPROVED)
            throw new ApiException(HttpStatus.FORBIDDEN, "Partner profile is not approved");
        return profile;
    }

    /** Uniform, non-enumerating 404 for every invalid/unknown/not-owned case. */
    private ApiException notFound() {
        return new ApiException(HttpStatus.NOT_FOUND, "Booking not found");
    }
}
