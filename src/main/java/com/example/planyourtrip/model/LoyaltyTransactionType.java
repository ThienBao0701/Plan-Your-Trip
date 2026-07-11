package com.example.planyourtrip.model;

/**
 * Phase 7.18 — Loyalty Points Foundation.
 * Direction is derived from the type, never from a signed point count
 * ({@code LoyaltyPointsTransaction#points} is always positive):
 * <ul>
 *   <li>{@code EARN_BOOKING} — plain, unmultiplied points awarded on booking
 *       completion ({@code LoyaltyService#awardBookingPoints}); increases both
 *       {@code currentBalance} and {@code lifetimePointsEarned}.</li>
 *   <li>{@code EARN_REVIEW} — a distinct earn path for review-bonus points
 *       ({@code LoyaltyService#awardReviewBonus}), kept separate from
 *       {@code EARN_BOOKING} specifically so a future tier multiplier can apply
 *       to one and not the other; also increases both balances.</li>
 *   <li>{@code GRANT} — admin-only manual award ({@code LoyaltyService#adminGrant});
 *       increases both balances, never multiplied.</li>
 *   <li>{@code ADJUSTMENT}, {@code REVERSAL} — reserved for future ledger
 *       operations (manual balance correction, reversing an erroneous earn/grant).
 *       Not wired to any endpoint or service method in this phase — no redemption
 *       or decrease path exists yet, so nothing currently produces these types.
 *       Included now only so the enum doesn't need a breaking change later.</li>
 * </ul>
 *
 * <p><b>Phase 7.20 — Loyalty Points Redemption.</b> Three explicit
 * redemption-related types are added. Direction is still derived from the type
 * (not a sign — {@code LoyaltyPointsTransaction#points} stays positive):
 * <ul>
 *   <li>{@code REDEMPTION_DEBIT} — points consumed to reserve a discount against
 *       a booking; the ONLY type that DECREASES {@code currentBalance}. Never
 *       touches {@code lifetimePointsEarned} (monotonic guarantee preserved).</li>
 *   <li>{@code REDEMPTION_RELEASE} — points restored because a RESERVED
 *       redemption was released/cancelled/expired before being applied;
 *       increases {@code currentBalance} only.</li>
 *   <li>{@code REDEMPTION_REFUND} — points restored because an APPLIED
 *       redemption's booking was later cancelled/refunded; increases
 *       {@code currentBalance} only.</li>
 * </ul>
 * The last two are increases but, unlike EARN/GRANT, must NEVER increase
 * {@code lifetimePointsEarned} — they merely give back previously-spent points.
 */
public enum LoyaltyTransactionType {
    EARN_BOOKING, EARN_REVIEW, GRANT, ADJUSTMENT, REVERSAL,
    REDEMPTION_DEBIT, REDEMPTION_RELEASE, REDEMPTION_REFUND
}
