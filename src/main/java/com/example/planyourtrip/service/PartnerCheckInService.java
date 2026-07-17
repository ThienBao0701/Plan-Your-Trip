package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PartnerCheckInDto.CheckInRequest;
import com.example.planyourtrip.dto.PartnerCheckInDto.CheckInResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.Booking;
import com.example.planyourtrip.model.BookingCheckInAudit;
import com.example.planyourtrip.model.BookingStatus;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.repository.BookingCheckInAuditRepository;
import com.example.planyourtrip.repository.BookingRepository;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.EnumSet;
import java.util.Set;

/**
 * Phase 7.40 — Partner Guest Check-in (the FIRST staff-performed booking MUTATION).
 *
 * <p>The mutation counterpart to the Phase 7.39 read-only verify endpoint. A partner supplies either a
 * signed voucher payload or a raw booking code (exactly one); this service:
 * <ol>
 *   <li>REUSES {@link PartnerVoucherVerificationService#resolveOwnedBookingByPayload} /
 *       {@link PartnerVoucherVerificationService#resolveOwnedBookingByCode} for the identical
 *       signature-verify + booking-resolution + ownership check (uniform 404, no crypto duplicated);</li>
 *   <li>short-circuits IDEMPOTENTLY if the booking is already {@code CHECKED_IN};</li>
 *   <li>enforces eligibility ({@code CONFIRMED} / {@code CHECK_IN_READY} only) and a configurable
 *       check-in time window;</li>
 *   <li>performs the actual {@code → CHECKED_IN} transition via
 *       {@link BookingStatusEngineService#transition} (which sets {@code actualCheckInAt}), never
 *       hand-rolling the state machine;</li>
 *   <li>writes exactly one immutable {@link BookingCheckInAudit} row.</li>
 * </ol>
 *
 * <p>The derived CHECKED_IN timeline event (see {@code BookingService.buildTimeline}) appears
 * automatically once the engine sets {@code actualCheckInAt} — no parallel timeline is built.
 *
 * <p><b>Note on notifications (Phase 7.40 dedup):</b> {@link BookingStatusEngineService} is the SINGLE
 * SOURCE OF TRUTH for customer notifications caused by booking lifecycle transitions — it emits the one
 * "Booking checked in" notification on the CHECKED_IN transition. This service deliberately emits NO
 * notification of its own, so a check-in produces exactly ONE customer notification. It fires only on
 * the real first transition — the idempotent repeat emits none.
 */
@Service
public class PartnerCheckInService {

    /** Statuses a front desk may admit a guest against (identical to the 7.39 eligibility set). */
    private static final Set<BookingStatus> ELIGIBLE_STATUSES =
        EnumSet.of(BookingStatus.CONFIRMED, BookingStatus.CHECK_IN_READY);

    private final PartnerVoucherVerificationService verificationService;
    private final BookingStatusEngineService statusEngine;
    private final BookingRepository bookingRepo;
    private final BookingCheckInAuditRepository auditRepo;
    private final PartnerProfileRepository partnerProfiles;

    /**
     * How many days BEFORE the check-in date a guest may already be admitted (early-check-in window).
     * Default 1 — a guest arriving the day before check-in can be checked in. Configurable via
     * {@code booking.checkin.early-window-days} (env {@code BOOKING_CHECKIN_EARLY_WINDOW_DAYS}).
     */
    private final long earlyWindowDays;

    public PartnerCheckInService(PartnerVoucherVerificationService verificationService,
                                 BookingStatusEngineService statusEngine,
                                 BookingRepository bookingRepo,
                                 BookingCheckInAuditRepository auditRepo,
                                 PartnerProfileRepository partnerProfiles,
                                 @Value("${booking.checkin.early-window-days:1}") long earlyWindowDays) {
        this.verificationService = verificationService;
        this.statusEngine = statusEngine;
        this.bookingRepo = bookingRepo;
        this.auditRepo = auditRepo;
        this.partnerProfiles = partnerProfiles;
        this.earlyWindowDays = earlyWindowDays;
    }

    @Transactional
    public CheckInResponse checkIn(Long userId, CheckInRequest req) {
        String payload = req != null ? trimToNull(req.voucherPayload()) : null;
        String code = req != null ? trimToNull(req.bookingCode()) : null;

        // Exactly one of voucherPayload / bookingCode must be provided.
        if ((payload == null) == (code == null)) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "Provide exactly one of voucherPayload or bookingCode");
        }

        // Reuse Phase 7.39's verify+resolve+ownership (uniform 404 for invalid/unknown/not-owned).
        Booking booking = payload != null
            ? verificationService.resolveOwnedBookingByPayload(userId, payload)
            : verificationService.resolveOwnedBookingByCode(userId, code);

        // IDEMPOTENCY: already checked in and owned by the caller → deterministic 200, NO re-transition,
        // NO re-notify, NO second audit row, checkedInAt unchanged. Checked FIRST, before the engine
        // (which would otherwise throw on CHECKED_IN → CHECKED_IN).
        if (booking.getStatus() == BookingStatus.CHECKED_IN) {
            return toResponse(booking, "Guest is already checked in");
        }

        // Eligibility — only CONFIRMED / CHECK_IN_READY may be admitted; everything else → 422.
        BookingStatus status = booking.getStatus();
        if (!ELIGIBLE_STATUSES.contains(status)) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Cannot check in booking with status: " + status.name());
        }

        // Time window — reject far-future (before the early window opens) and expired (stay over).
        validateCheckInWindow(booking);

        // Actual mutation — REUSE the status engine, which is the SINGLE SOURCE OF TRUTH for the
        // customer lifecycle notification: it sets status=CHECKED_IN + actualCheckInAt AND emits the
        // one "Booking checked in" customer notification. This service deliberately does NOT emit a
        // second notification of its own (Phase 7.40 dedup decision). No state machine hand-rolled.
        statusEngine.transition(booking, BookingStatus.CHECKED_IN);
        Booking saved = bookingRepo.save(booking);

        // Exactly one immutable audit row on the real transition.
        writeAudit(userId, saved);

        return toResponse(saved, "Check-in completed");
    }

    /**
     * Allow check-in when today is within {@code [checkInDate - earlyWindowDays, checkOutDate)} — i.e.
     * from the early-window opening up to (but not on/after) the check-out date. Before the window
     * opens → far-future 422; on/after check-out → expired 422.
     */
    private void validateCheckInWindow(Booking booking) {
        LocalDate today = LocalDate.now();
        LocalDate windowOpens = booking.getCheckInDate().minusDays(earlyWindowDays);
        if (today.isBefore(windowOpens)) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Check-in not available until " + windowOpens);
        }
        if (!today.isBefore(booking.getCheckOutDate())) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Booking has expired: the stay period has ended");
        }
    }

    private void writeAudit(Long userId, Booking booking) {
        PartnerProfile owner = booking.getHotel().getOwner();
        BookingCheckInAudit audit = new BookingCheckInAudit();
        audit.setBooking(booking);
        audit.setPartnerProfileId(owner != null ? owner.getId() : resolveProfileId(userId));
        audit.setPartnerUserId(userId);
        audit.setOperation("CHECK_IN");
        auditRepo.save(audit);
    }

    /** Fallback profile resolution (owner is always non-null past the ownership check; defensive only). */
    private Long resolveProfileId(Long userId) {
        return partnerProfiles.findByUserId(userId).map(PartnerProfile::getId).orElse(null);
    }

    private CheckInResponse toResponse(Booking b, String message) {
        return new CheckInResponse(
            true,
            b.getBookingCode(),
            b.getStatus().name(),
            b.getActualCheckInAt(),
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
