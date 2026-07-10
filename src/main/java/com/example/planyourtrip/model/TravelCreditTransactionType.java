package com.example.planyourtrip.model;

/**
 * Phase 7.14 — Customer Coupons &amp; Travel Credits Foundation.
 * Direction is derived from the type, never from a signed amount
 * ({@code TravelCreditTransaction#amount} is always positive):
 * <ul>
 *   <li>increase: {@code GRANT}, {@code PROMOTION}, {@code REFUND_CREDIT}, {@code REVERSAL}</li>
 *   <li>decrease: {@code REDEMPTION}, {@code EXPIRATION}</li>
 *   <li>{@code ADJUSTMENT}: direction is chosen explicitly by the admin via the
 *       endpoint used (currently only exposed on the downward
 *       {@code POST /api/admin/users/{userId}/travel-credits/deduct} path) —
 *       see {@code TravelCreditService}.</li>
 * </ul>
 */
public enum TravelCreditTransactionType {
    GRANT, PROMOTION, REFUND_CREDIT, ADJUSTMENT, REDEMPTION, EXPIRATION, REVERSAL
}
