package com.example.planyourtrip.model;

/**
 * Phase 7.28 — Inventory Lock &amp; Room Hold.
 *
 * <p>Lifecycle status of an {@link InventoryReservation} — a TRACKING/EXPIRY layer over the
 * EXISTING {@code RoomInventoryRepository.decrementInventory}/{@code restoreInventory}
 * calls. The room-inventory math itself is unchanged: the decrement already happened
 * synchronously at booking creation (see {@code BookingService.create}); this status only
 * records whether that hold is still outstanding, has been permanently consumed, or has
 * been given back.
 *
 * <p>State machine (terminal states are CONSUMED / RELEASED / EXPIRED):
 * <pre>
 *   HELD ──────► CONSUMED   (terminal — payment succeeded; the decrement is now permanent)
 *    │
 *    ├─────────► RELEASED   (terminal — payment failure / session cancel / session expiry /
 *    │                       booking cancellation; inventory restored)
 *    │
 *    └─────────► EXPIRED    (terminal — hold timed out via the expiry sweep; inventory restored)
 * </pre>
 *
 * <p><b>Important:</b> whether inventory is actually restored on the terminal transition
 * depends on the trigger, NOT the target status alone — a booking-cancellation transition
 * to RELEASED does NOT restore inventory a second time because the cancellation flow
 * ({@code BookingService.cancel}/{@code adminUpdateStatus}) already called
 * {@code restoreInventory} directly. The RELEASED status merely marks the hold as
 * terminally handled so any later duplicate trigger is a no-op.
 */
public enum InventoryReservationStatus {
    /** Room inventory is held for a booking whose payment is still pending. */
    HELD,
    /** Payment succeeded — the hold is permanently consumed; the decrement stays. */
    CONSUMED,
    /** Hold released (payment failure / cancellation) — inventory returned to availability. */
    RELEASED,
    /** Hold timed out before payment completed — inventory returned to availability. */
    EXPIRED;

    public boolean isTerminal() {
        return this == CONSUMED || this == RELEASED || this == EXPIRED;
    }
}
