package com.example.planyourtrip.model;

/**
 * Phase 7.20 — Loyalty Points Redemption.
 * Redemption eligibility gate on a {@link LoyaltyAccount}. Earning/granting is
 * never gated by this (backward compatible — every account defaults to ACTIVE);
 * only redemption reservation requires ACTIVE.
 * <ul>
 *   <li>{@code ACTIVE} — may redeem points (default).</li>
 *   <li>{@code SUSPENDED} — temporarily blocked from redeeming (still earns).</li>
 *   <li>{@code CLOSED} — permanently blocked from redeeming.</li>
 * </ul>
 */
public enum LoyaltyAccountStatus {
    ACTIVE, SUSPENDED, CLOSED
}
