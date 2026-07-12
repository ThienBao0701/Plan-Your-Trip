package com.example.planyourtrip.model;

/**
 * Phase 7.29 — cancellation policy attached to a rate plan.
 *
 * <ul>
 *   <li>{@code FREE_CANCELLATION} — no penalty before the deadline; full penalty after.</li>
 *   <li>{@code PARTIALLY_REFUNDABLE} — configurable penalty percentage.</li>
 *   <li>{@code NON_REFUNDABLE} — 100% penalty always.</li>
 *   <li>{@code CUSTOM} — metadata only in this phase.</li>
 * </ul>
 *
 * <p>This phase EXPOSES cancellation terms and PREVIEWS penalty amounts only — it does
 * not rewrite actual refund processing (that stays in the existing booking/payment flow).
 */
public enum CancellationPolicyType {
    FREE_CANCELLATION, PARTIALLY_REFUNDABLE, NON_REFUNDABLE, CUSTOM
}
