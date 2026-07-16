package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.InventoryReservationDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.Booking;
import com.example.planyourtrip.model.InventoryReservation;
import com.example.planyourtrip.model.InventoryReservationStatus;
import com.example.planyourtrip.repository.BookingRepository;
import com.example.planyourtrip.repository.InventoryReservationRepository;
import com.example.planyourtrip.repository.RoomInventoryRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;

/**
 * Phase 7.28 — Inventory Lock &amp; Room Hold.
 *
 * <p><b>What this is (and is NOT).</b> This service is a TRACKING/EXPIRY layer over the
 * EXISTING room-inventory math. It does NOT compute availability and does NOT contain any
 * inventory arithmetic of its own — the ONLY inventory mutations in the system remain
 * {@code RoomInventoryRepository.decrementInventory} (at booking creation) and
 * {@code RoomInventoryRepository.restoreInventory} (the SAME method
 * {@code BookingService.cancel}/{@code adminUpdateStatus} already call). A reservation row
 * records which decrement is still outstanding and drives its lifecycle.
 *
 * <p><b>Lifecycle wiring (all ADDITIVE single calls at the established hook sites):</b>
 * <ul>
 *   <li>{@link #hold} — {@code BookingService.create}, in the SAME transaction and right
 *       after the existing {@code decrementInventory}. Creates the single HELD row.</li>
 *   <li>{@link #consumeForBooking} — {@code PaymentService.mockSuccess}. HELD → CONSUMED,
 *       a pure status flip; the decrement stays permanent (NO second decrement).</li>
 *   <li>{@link #releaseForBooking} — {@code PaymentService.mockFail}. HELD → RELEASED and
 *       calls {@code restoreInventory}. This one hook covers payment failure AND
 *       session-cancel/session-expiry, because Phase 7.27's
 *       {@code PaymentSettlementBridge.settleFailure} routes all of those through
 *       {@code mockFail}.</li>
 *   <li>{@link #releaseForCancelledBooking} — {@code BookingService.cancel}/
 *       {@code adminUpdateStatus} CANCELLED branch. Transitions to RELEASED WITHOUT
 *       restoring, because those flows already called {@code restoreInventory} directly —
 *       this only marks the hold terminally handled (idempotency guard, see below).</li>
 *   <li>{@link #expireOverdueHolds} — admin/scheduled sweep. HELD → EXPIRED + restore for
 *       holds whose {@code expiresAt} has passed (the "timeout releases reservation" path).</li>
 * </ul>
 *
 * <p><b>Idempotency &amp; no double-restore.</b> Every mutating method loads the row under a
 * pessimistic write lock and acts ONLY when the current status is HELD; a reservation that
 * is already terminal (CONSUMED/RELEASED/EXPIRED) is a safe no-op. That single guard makes
 * the new release path idempotent against itself (duplicate webhook / duplicate release) AND
 * against the pre-existing direct {@code restoreInventory} calls in the cancellation flow:
 * whichever trigger reaches the row first flips it out of HELD, so the other finds a terminal
 * row and does nothing — inventory is never restored twice.
 */
@Service
public class InventoryReservationService {

    /**
     * Hold duration before a reservation is eligible for the expiry sweep. Mirrors
     * {@code PaymentGatewayService.SESSION_TTL_MINUTES} (30) — a booking's hold and its
     * gateway session time out on the same horizon. No {@code PaymentSession} exists yet at
     * booking-creation time (a session is opened later, in a separate request), so the hold
     * uses this fixed policy rather than tying to a session's own expiry.
     */
    static final long HOLD_DURATION_MINUTES = 30;

    private final InventoryReservationRepository reservationRepo;
    private final RoomInventoryRepository inventoryRepo;
    private final BookingRepository bookingRepo;
    private final UserRepository userRepo;

    public InventoryReservationService(InventoryReservationRepository reservationRepo,
                                       RoomInventoryRepository inventoryRepo,
                                       BookingRepository bookingRepo,
                                       UserRepository userRepo) {
        this.reservationRepo = reservationRepo;
        this.inventoryRepo = inventoryRepo;
        this.bookingRepo = bookingRepo;
        this.userRepo = userRepo;
    }

    // ═════════════════════════════════════════════════════════════════════
    // HOLD (booking creation)
    // ═════════════════════════════════════════════════════════════════════

    /**
     * Create the single HELD reservation for a freshly-created booking. Runs INSIDE the
     * caller's ({@code BookingService.create}) transaction — the same transaction as the
     * existing {@code decrementInventory}, so a rolled-back booking leaves neither a
     * decrement nor a hold. Idempotent: the one-reservation-per-booking unique constraint is
     * pre-checked so a re-entry returns the existing row instead of throwing.
     */
    @Transactional(propagation = Propagation.REQUIRED)
    public InventoryReservation hold(Booking booking) {
        Optional<InventoryReservation> existing = reservationRepo.findByBookingId(booking.getId());
        if (existing.isPresent()) return existing.get(); // no duplicate reservations

        InventoryReservation reservation = new InventoryReservation();
        reservation.setBooking(booking);
        reservation.setRoom(booking.getRoom());
        reservation.setCheckInDate(booking.getCheckInDate());
        reservation.setCheckOutDate(booking.getCheckOutDate());
        reservation.setNumberOfRooms(booking.getNumberOfRooms());
        reservation.setStatus(InventoryReservationStatus.HELD);
        reservation.setExpiresAt(Instant.now().plus(HOLD_DURATION_MINUTES, ChronoUnit.MINUTES));
        return reservationRepo.save(reservation);
    }

    // ═════════════════════════════════════════════════════════════════════
    // MODIFY (Phase 7.34 — customer modification of a PENDING booking)
    // ═════════════════════════════════════════════════════════════════════

    /**
     * Phase 7.34 — guard used by {@code BookingService.modify} BEFORE any inventory mutation: a
     * booking may only be modified while its hold is still HELD. A PENDING booking whose hold was
     * already RELEASED (payment failed / session cancelled) or EXPIRED (timeout sweep) no longer
     * holds any inventory, so restoring "its" inventory would double-restore — reject instead (422).
     * Read-only; the authoritative HELD re-check happens under the write lock in
     * {@link #updateHoldForModification}.
     */
    @Transactional(readOnly = true)
    public void assertHeldForModification(Long bookingId) {
        InventoryReservation reservation = reservationRepo.findByBookingId(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "No active inventory hold exists for booking " + bookingId + " — cannot modify"));
        if (reservation.getStatus() != InventoryReservationStatus.HELD)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Inventory hold for booking " + bookingId + " is no longer active (status "
                    + reservation.getStatus() + ") — cannot modify");
    }

    /**
     * Phase 7.34 — after {@code BookingService.modify} has restored the old inventory and
     * decremented the new inventory (the SAME primitives create/cancel use), REPLACE the booking's
     * hold so it covers the new dates/room count, all in the caller's transaction. Performs NO
     * inventory math of its own (mirrors {@link #hold}).
     *
     * <p>A reservation row is intentionally immutable (Phase 7.28 maps its dates/room-count as
     * {@code updatable = false}), so a modification does NOT edit the row in place — it deletes the
     * existing HELD row and creates a fresh HELD row via {@link #hold}, keeping one reservation per
     * booking and never touching the Phase 7.28 entity mapping. The old row is loaded under the
     * per-row write lock and HELD is re-asserted there, so this never races the
     * payment/cancel/expiry paths; a hold that has slipped out of HELD is rejected (422), rolling
     * the whole modification back.
     */
    @Transactional(propagation = Propagation.REQUIRED)
    public void updateHoldForModification(Booking booking) {
        InventoryReservation reservation = reservationRepo.findByBookingIdForUpdate(booking.getId())
            .orElseThrow(() -> new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "No active inventory hold exists for booking " + booking.getId() + " — cannot modify"));
        if (reservation.getStatus() != InventoryReservationStatus.HELD)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Inventory hold for booking " + booking.getId() + " is no longer active (status "
                    + reservation.getStatus() + ") — cannot modify");

        // Replace the immutable HELD row (delete + flush so the unique booking_id constraint is
        // clear) with a fresh HELD row over the new dates.
        reservationRepo.delete(reservation);
        reservationRepo.flush();
        hold(booking);
    }

    // ═════════════════════════════════════════════════════════════════════
    // CONSUME (payment success)
    // ═════════════════════════════════════════════════════════════════════

    /**
     * Payment succeeded — {@code PaymentService.mockSuccess} hook. HELD → CONSUMED, a pure
     * status transition: the decrement made at booking creation becomes permanent and is
     * NOT re-applied. Idempotent no-op when there is no hold or it is already terminal.
     */
    @Transactional(propagation = Propagation.REQUIRED)
    public void consumeForBooking(Long bookingId) {
        InventoryReservation reservation = reservationRepo.findByBookingIdForUpdate(bookingId).orElse(null);
        if (reservation == null) return;
        if (reservation.getStatus() != InventoryReservationStatus.HELD) return; // terminal → no-op

        reservation.setStatus(InventoryReservationStatus.CONSUMED);
        reservation.setConsumedAt(Instant.now());
        reservationRepo.save(reservation);
    }

    // ═════════════════════════════════════════════════════════════════════
    // RELEASE (payment failure / session cancel / session expiry)
    // ═════════════════════════════════════════════════════════════════════

    /**
     * Payment did not complete — {@code PaymentService.mockFail} hook. HELD → RELEASED and
     * restores inventory via the EXISTING {@code restoreInventory} method. Covers direct
     * payment failure AND session-cancel/session-expiry (Phase 7.27 routes those through
     * {@code mockFail}). Idempotent no-op when there is no hold or it is already terminal —
     * this is what prevents a double-restore against a duplicate webhook/release.
     */
    @Transactional(propagation = Propagation.REQUIRED)
    public void releaseForBooking(Long bookingId) {
        InventoryReservation reservation = reservationRepo.findByBookingIdForUpdate(bookingId).orElse(null);
        if (reservation == null) return;
        if (reservation.getStatus() != InventoryReservationStatus.HELD) return; // terminal → no-op

        inventoryRepo.restoreInventory(reservation.getRoom().getId(),
            reservation.getCheckInDate(), reservation.getCheckOutDate(), reservation.getNumberOfRooms());

        reservation.setStatus(InventoryReservationStatus.RELEASED);
        reservation.setReleasedAt(Instant.now());
        reservationRepo.save(reservation);
    }

    /**
     * Booking cancellation — {@code BookingService.cancel}/{@code adminUpdateStatus} hook.
     * Transitions a non-terminal hold to RELEASED WITHOUT restoring inventory, because those
     * flows already call {@code restoreInventory} directly at the same site (this is the ONE
     * additive call per site, mirroring {@code releaseCheckoutBenefits}). Marking the hold
     * terminal here means any later stray payment-failure trigger sees a terminal row and is
     * a no-op, so the cancellation's own restore is never doubled. Idempotent.
     */
    @Transactional(propagation = Propagation.REQUIRED)
    public void releaseForCancelledBooking(Long bookingId) {
        InventoryReservation reservation = reservationRepo.findByBookingIdForUpdate(bookingId).orElse(null);
        if (reservation == null) return;
        if (reservation.getStatus().isTerminal()) return; // already handled → no-op (no double-restore)

        // NOTE: deliberately NO restoreInventory here — the cancellation flow already did it.
        reservation.setStatus(InventoryReservationStatus.RELEASED);
        reservation.setReleasedAt(Instant.now());
        reservationRepo.save(reservation);
    }

    // ═════════════════════════════════════════════════════════════════════
    // EXPIRE (timeout sweep)
    // ═════════════════════════════════════════════════════════════════════

    /**
     * Time-based expiry sweep (admin-triggered; no scheduler in this phase, mirroring
     * {@code PaymentGatewayService.processExpirations} / {@code GiftCardService}). Each
     * still-HELD hold past its {@code expiresAt} transitions HELD → EXPIRED and restores
     * inventory via the EXISTING {@code restoreInventory}. Re-checked under the per-row write
     * lock so it never races the payment/cancel paths.
     */
    @Transactional
    public ExpirationResultResponse expireOverdueHolds() {
        Instant now = Instant.now();
        var candidates = reservationRepo.findExpirationCandidates(now, InventoryReservationStatus.HELD);
        int expired = 0;
        for (InventoryReservation candidate : candidates) {
            InventoryReservation reservation =
                reservationRepo.findByBookingIdForUpdate(candidate.getBooking().getId()).orElseThrow();
            if (reservation.getStatus() != InventoryReservationStatus.HELD) continue;
            if (reservation.getExpiresAt() == null || !reservation.getExpiresAt().isBefore(now)) continue;

            inventoryRepo.restoreInventory(reservation.getRoom().getId(),
                reservation.getCheckInDate(), reservation.getCheckOutDate(), reservation.getNumberOfRooms());

            reservation.setStatus(InventoryReservationStatus.EXPIRED);
            reservation.setExpiredAt(now);
            reservationRepo.save(reservation);
            expired++;
        }
        return new ExpirationResultResponse(expired);
    }

    // ═════════════════════════════════════════════════════════════════════
    // READS
    // ═════════════════════════════════════════════════════════════════════

    /** Customer reservation-status endpoint — owner-scoped (admin also allowed). */
    @Transactional(readOnly = true)
    public ReservationResponse getForBooking(Long userId, Long bookingId) {
        InventoryReservation reservation = reservationRepo.findByBookingId(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "No inventory reservation exists for booking " + bookingId));
        Long ownerId = reservation.getBooking().getUser().getId();
        if (!ownerId.equals(userId)) {
            var requester = userRepo.findById(userId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));
            if (!"ADMIN".equals(requester.getRole()))
                throw new ApiException(HttpStatus.FORBIDDEN, "Access denied");
        }
        return toResponse(reservation);
    }

    @Transactional(readOnly = true)
    public com.example.planyourtrip.dto.PageResponse<ReservationResponse> adminList(
            InventoryReservationStatus status, Integer page, Integer size) {
        Pageable pageable = PageRequest.of(page == null ? 0 : Math.max(0, page),
            size == null ? 20 : Math.min(Math.max(1, size), 200));
        Page<InventoryReservation> result = (status != null)
            ? reservationRepo.findByStatusOrderByCreatedAtDesc(status, pageable)
            : reservationRepo.findAllByOrderByCreatedAtDesc(pageable);
        return com.example.planyourtrip.dto.PageResponse.of(result.map(this::toResponse));
    }

    @Transactional(readOnly = true)
    public ReservationResponse adminGetByBooking(Long bookingId) {
        return toResponse(reservationRepo.findByBookingId(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "No inventory reservation exists for booking " + bookingId)));
    }

    // ═════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═════════════════════════════════════════════════════════════════════

    private ReservationResponse toResponse(InventoryReservation r) {
        Booking b = r.getBooking();
        return new ReservationResponse(
            r.getId(),
            b.getId(),
            b.getBookingCode(),
            r.getRoom().getId(),
            r.getRoom().getRoomCode(),
            r.getCheckInDate(),
            r.getCheckOutDate(),
            r.getNumberOfRooms(),
            r.getStatus(),
            r.getExpiresAt(),
            r.getConsumedAt(),
            r.getReleasedAt(),
            r.getExpiredAt(),
            r.getCreatedAt(),
            r.getUpdatedAt()
        );
    }
}
