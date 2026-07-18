package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PartnerCheckOutDto.CheckOutRequest;
import com.example.planyourtrip.dto.PartnerCheckOutDto.CheckOutResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.Booking;
import com.example.planyourtrip.model.BookingCheckOutAudit;
import com.example.planyourtrip.model.BookingStatus;
import com.example.planyourtrip.model.CheckMethod;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.repository.BookingCheckOutAuditRepository;
import com.example.planyourtrip.repository.BookingRepository;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;

/**
 * Phase 7.41 — Partner Guest Check-out (a near-mirror of Phase 7.40's check-in MUTATION).
 *
 * <p>The departure counterpart to the Phase 7.40 check-in endpoint. A partner supplies either a signed
 * voucher payload or a raw booking code (exactly one); this service:
 * <ol>
 *   <li>REUSES {@link PartnerVoucherVerificationService#resolveOwnedBookingByPayload} /
 *       {@link PartnerVoucherVerificationService#resolveOwnedBookingByCode} for the identical
 *       signature-verify + booking-resolution + ownership check (uniform 404, no crypto duplicated);</li>
 *   <li>short-circuits IDEMPOTENTLY if the booking is already {@code CHECKED_OUT};</li>
 *   <li>enforces eligibility ({@code CHECKED_IN} ONLY) and a clock-skew + configurable late-check-out
 *       time window;</li>
 *   <li>performs the actual {@code CHECKED_IN → CHECKED_OUT} transition via
 *       {@link BookingStatusEngineService#transition} (which sets {@code actualCheckOutAt}), never
 *       hand-rolling the state machine;</li>
 *   <li>writes exactly one immutable {@link BookingCheckOutAudit} row (carrying the derived
 *       {@link CheckMethod}: {@code QR_SCAN} for a scanned payload, {@code MANUAL} for a typed code).</li>
 * </ol>
 *
 * <p>The derived CHECKED_OUT timeline event (see {@code BookingService.buildTimeline}) appears
 * automatically once the engine sets {@code actualCheckOutAt} — no parallel timeline is built.
 *
 * <p><b>Note on notifications (Phase 7.40 dedup, upheld here):</b> {@link BookingStatusEngineService} is
 * the SINGLE SOURCE OF TRUTH for customer notifications caused by booking lifecycle transitions — it
 * emits the one "Booking checked out" notification on the CHECKED_OUT transition. This service
 * deliberately emits NO notification of its own, so a check-out produces exactly ONE customer
 * notification. It fires only on the real first transition — the idempotent repeat emits none.
 */
@Service
public class PartnerCheckOutService {

    private final PartnerVoucherVerificationService verificationService;
    private final BookingStatusEngineService statusEngine;
    private final BookingRepository bookingRepo;
    private final BookingCheckOutAuditRepository auditRepo;
    private final PartnerProfileRepository partnerProfiles;

    /**
     * How many days AFTER the check-out date a guest may still be checked out (late-check-out grace
     * window). Default 1 — a guest departing the day after the scheduled check-out can still be checked
     * out. Configurable via {@code booking.checkout.late-window-days}
     * (env {@code BOOKING_CHECKOUT_LATE_WINDOW_DAYS}).
     */
    private final long lateWindowDays;

    public PartnerCheckOutService(PartnerVoucherVerificationService verificationService,
                                  BookingStatusEngineService statusEngine,
                                  BookingRepository bookingRepo,
                                  BookingCheckOutAuditRepository auditRepo,
                                  PartnerProfileRepository partnerProfiles,
                                  @Value("${booking.checkout.late-window-days:1}") long lateWindowDays) {
        this.verificationService = verificationService;
        this.statusEngine = statusEngine;
        this.bookingRepo = bookingRepo;
        this.auditRepo = auditRepo;
        this.partnerProfiles = partnerProfiles;
        this.lateWindowDays = lateWindowDays;
    }

    @Transactional
    public CheckOutResponse checkOut(Long userId, CheckOutRequest req) {
        String payload = req != null ? trimToNull(req.voucherPayload()) : null;
        String code = req != null ? trimToNull(req.bookingCode()) : null;

        // Exactly one of voucherPayload / bookingCode must be provided.
        if ((payload == null) == (code == null)) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "Provide exactly one of voucherPayload or bookingCode");
        }

        // Input shape → audit method: scanned signed payload ⇒ QR_SCAN; typed raw code ⇒ MANUAL.
        CheckMethod method = payload != null ? CheckMethod.QR_SCAN : CheckMethod.MANUAL;

        // Reuse Phase 7.39/7.40 verify+resolve+ownership (uniform 404 for invalid/unknown/not-owned).
        Booking booking = payload != null
            ? verificationService.resolveOwnedBookingByPayload(userId, payload)
            : verificationService.resolveOwnedBookingByCode(userId, code);

        // IDEMPOTENCY: already checked out and owned by the caller → deterministic 200, NO re-transition,
        // NO re-notify, NO second audit row, checkedOutAt unchanged. Checked FIRST, before eligibility/
        // window/engine (the engine would otherwise throw on CHECKED_OUT → CHECKED_OUT).
        if (booking.getStatus() == BookingStatus.CHECKED_OUT) {
            return toResponse(booking, "Guest is already checked out");
        }

        // Eligibility — ONLY a CHECKED_IN booking may be checked out; everything else → 422.
        BookingStatus status = booking.getStatus();
        if (status != BookingStatus.CHECKED_IN) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Cannot check out booking with status: " + status.name());
        }

        // Time window — reject an impossible check-out-before-check-in and an expired late window.
        validateCheckOutWindow(booking);

        // Actual mutation — REUSE the status engine, which is the SINGLE SOURCE OF TRUTH for the customer
        // lifecycle notification: it sets status=CHECKED_OUT + actualCheckOutAt AND emits the one
        // "Booking checked out" customer notification. This service deliberately does NOT emit a second
        // notification of its own (Phase 7.40 dedup decision, upheld). No state machine hand-rolled.
        statusEngine.transition(booking, BookingStatus.CHECKED_OUT);
        Booking saved = bookingRepo.save(booking);

        // Exactly one immutable audit row on the real transition, recording the derived method.
        writeAudit(userId, saved, method);

        return toResponse(saved, "Check-out completed");
    }

    /**
     * Allow check-out from the moment the guest actually checked in up to {@code checkOutDate +
     * lateWindowDays}:
     * <ul>
     *   <li>(a) reject a physically impossible check-out BEFORE the recorded check-in instant
     *       ({@code now < actualCheckInAt} → 422, a clock-skew guard; since status is CHECKED_IN the
     *       timestamp is always set);</li>
     *   <li>(b) reject once today is beyond {@code checkOutDate + lateWindowDays} → 422 (the late
     *       check-out grace window has passed).</li>
     * </ul>
     */
    private void validateCheckOutWindow(Booking booking) {
        Instant checkedInAt = booking.getActualCheckInAt();
        if (checkedInAt != null && Instant.now().isBefore(checkedInAt)) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Cannot check out before check-in");
        }
        LocalDate today = LocalDate.now();
        LocalDate windowCloses = booking.getCheckOutDate().plusDays(lateWindowDays);
        if (today.isAfter(windowCloses)) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Check-out window has passed on " + windowCloses);
        }
    }

    private void writeAudit(Long userId, Booking booking, CheckMethod method) {
        PartnerProfile owner = booking.getHotel().getOwner();
        BookingCheckOutAudit audit = new BookingCheckOutAudit();
        audit.setBooking(booking);
        audit.setPartnerProfileId(owner != null ? owner.getId() : resolveProfileId(userId));
        audit.setPartnerUserId(userId);
        audit.setOperation("CHECK_OUT");
        audit.setMethod(method);
        auditRepo.save(audit);
    }

    /** Fallback profile resolution (owner is always non-null past the ownership check; defensive only). */
    private Long resolveProfileId(Long userId) {
        return partnerProfiles.findByUserId(userId).map(PartnerProfile::getId).orElse(null);
    }

    private CheckOutResponse toResponse(Booking b, String message) {
        return new CheckOutResponse(
            true,
            b.getBookingCode(),
            b.getStatus().name(),
            b.getActualCheckOutAt(),
            b.getHotel().getName(),
            b.getRoom().getRoomName(),
            b.getUser().getFullName(),
            message
        );
    }

    private static String trimToNull(String s) {
        if (s == null) return null;
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }
}
