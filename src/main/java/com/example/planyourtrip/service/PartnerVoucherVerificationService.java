package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PartnerVoucherDto.Occupancy;
import com.example.planyourtrip.dto.PartnerVoucherDto.VoucherVerificationResponse;
import com.example.planyourtrip.dto.PartnerVoucherDto.VoucherVerifyRequest;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.Booking;
import com.example.planyourtrip.model.BookingStatus;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.repository.BookingRepository;
import com.example.planyourtrip.security.VoucherSignatureService;
import com.example.planyourtrip.dto.RedactedField;
import com.example.planyourtrip.security.rbac.PartnerAccessContext;
import com.example.planyourtrip.security.rbac.PartnerPermission;
import com.example.planyourtrip.security.rbac.ResourceType;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.temporal.ChronoUnit;
import java.util.EnumSet;
import java.util.Set;

import static com.example.planyourtrip.security.rbac.PartnerPermission.BOOKING_ARRIVAL_OPERATE;

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
    private final PartnerAccessService partnerAccess;
    private final PartnerBookingRedactor redactor;

    /** RBAC R3b — a booking the caller may act on, with the workspace the decision was made in. */
    public record AuthorizedBooking(Booking booking, PartnerAccessContext access) {}

    public PartnerVoucherVerificationService(VoucherSignatureService voucherSignatureService,
                                             BookingRepository bookingRepo,
                                             PartnerAccessService partnerAccess,
                                             PartnerBookingRedactor redactor) {
        this.voucherSignatureService = voucherSignatureService;
        this.bookingRepo = bookingRepo;
        this.partnerAccess = partnerAccess;
        this.redactor = redactor;
    }

    public VoucherVerificationResponse verify(Long userId, VoucherVerifyRequest req) {
        // Reuse the shared verify+resolve+ownership step, then report eligibility WITHOUT mutating.
        String payload = req != null ? req.voucherPayload() : null;
        AuthorizedBooking authorized = resolveOwnedBookingByPayload(userId, payload, BOOKING_ARRIVAL_OPERATE);
        Booking booking = authorized.booking();
        java.util.List<RedactedField> redacted = new java.util.ArrayList<>();

        // Eligibility — verification only, NEVER a mutation or status transition.
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
            redactor.guestName(authorized.access(), booking, booking.getUser().getFullName(), redacted, "guestName"),
            booking.getCheckInDate(),
            booking.getCheckOutDate(),
            new Occupancy(booking.getAdults(), booking.getChildren()),
            nights,
            java.util.List.copyOf(redacted)
        );
    }

    /**
     * Phase 7.40 reuse — the shared "verify signed payload → resolved, owned {@link Booking}" step.
     *
     * <p>Resolves the caller's approved partner profile, verifies + extracts the bookingCode from the
     * signed payload (reusing {@link VoucherSignatureService#verifyAndExtractBookingCode}), resolves the
     * booking, and confirms it belongs to one of the caller's OWN hotels. Every invalid /
     * tampered / unknown / not-owned case collapses to the SAME uniform 404 — identical semantics to
     * {@link #verify}. Callers (e.g. the Phase 7.40 check-in mutation) get back the managed Booking and
     * apply their own status/window logic; this method itself mutates NOTHING.
     */
    public AuthorizedBooking resolveOwnedBookingByPayload(Long userId, String voucherPayload,
                                                          PartnerPermission permission) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        String bookingCode = voucherSignatureService.verifyAndExtractBookingCode(voucherPayload)
            .orElseThrow(this::notFound);
        return authorizedByCode(access, bookingCode, permission);
    }

    /**
     * Phase 7.40 reuse — resolve a booking from a directly-supplied {@code bookingCode} (no scanned QR),
     * still enforcing ownership. Same uniform-404 semantics as {@link #resolveOwnedBookingByPayload}: an
     * unknown code and another partner's booking are indistinguishable. No crypto is involved (the code
     * was typed, not signed), but the ownership guarantee is identical.
     */
    public AuthorizedBooking resolveOwnedBookingByCode(Long userId, String bookingCode, PartnerPermission permission) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        return authorizedByCode(access, bookingCode, permission);
    }

    /**
     * RBAC R3b — §4.5 RESOURCE (booking by code): the booking lives at {@code booking.hotel}'s property; the caller
     * needs {@code permission} there. Another company's booking, a booking the caller has no booking view over and
     * an unknown code are the same 404; a caller who can view the booking but not do this gets 403.
     */
    private AuthorizedBooking authorizedByCode(PartnerAccessContext access, String bookingCode,
                                               PartnerPermission permission) {
        partnerAccess.decide(access, permission, ResourceType.BOOKING, partnerAccess.bookingCodeTarget(bookingCode),
            "Booking not found");
        Booking booking = bookingRepo.findByBookingCode(bookingCode).orElseThrow(this::notFound);
        return new AuthorizedBooking(booking, access);
    }

    /** Uniform, non-enumerating 404 for every invalid/unknown/not-owned case. */
    private ApiException notFound() {
        return new ApiException(HttpStatus.NOT_FOUND, "Booking not found");
    }
}
