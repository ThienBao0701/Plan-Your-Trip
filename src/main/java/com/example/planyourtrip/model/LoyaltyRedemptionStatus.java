package com.example.planyourtrip.model;

import java.util.EnumSet;
import java.util.Set;

/**
 * Phase 7.20 — Loyalty Points Redemption.
 * Lifecycle of a {@link LoyaltyPointsRedemption}. Points are debited on RESERVE;
 * an unapplied reservation may be RELEASED / CANCELLED / EXPIRED (points
 * restored); a confirmed booking moves the reservation to APPLIED; an applied
 * redemption whose booking is later cancelled/refunded moves to REFUNDED
 * (points restored). Restoration NEVER touches {@code lifetimePointsEarned}.
 *
 * <p>Valid transitions (any other is rejected as an invalid transition, 409):
 * <ul>
 *   <li>RESERVED &rarr; APPLIED</li>
 *   <li>RESERVED &rarr; RELEASED</li>
 *   <li>RESERVED &rarr; CANCELLED</li>
 *   <li>RESERVED &rarr; EXPIRED</li>
 *   <li>APPLIED &rarr; REFUNDED</li>
 * </ul>
 * Terminal (no outgoing transitions): RELEASED, REFUNDED, CANCELLED, EXPIRED.
 */
public enum LoyaltyRedemptionStatus {
    RESERVED, APPLIED, RELEASED, REFUNDED, CANCELLED, EXPIRED;

    private static final Set<LoyaltyRedemptionStatus> TERMINAL =
        EnumSet.of(RELEASED, REFUNDED, CANCELLED, EXPIRED);

    /** Non-terminal statuses hold points/booking exclusivity — see {@code LoyaltyPointsRedemption}. */
    public static final Set<LoyaltyRedemptionStatus> NON_TERMINAL =
        EnumSet.of(RESERVED, APPLIED);

    public boolean isTerminal() { return TERMINAL.contains(this); }

    /** Whether this status may legally transition to {@code target}. */
    public boolean canTransitionTo(LoyaltyRedemptionStatus target) {
        return switch (this) {
            case RESERVED -> target == APPLIED || target == RELEASED
                || target == CANCELLED || target == EXPIRED;
            case APPLIED -> target == REFUNDED;
            default -> false;
        };
    }
}
