package com.example.planyourtrip.model;

/**
 * Phase 7.26 — Payment Gateway Foundation.
 *
 * <p>Lifecycle status of a PRE-SETTLEMENT gateway {@link PaymentSession}. This is a
 * DIFFERENT concept from {@link PaymentStatus}, which is the SETTLEMENT status of the
 * existing {@link Payment} entity. Nothing in this enum touches or repurposes
 * {@code PaymentStatus} — the two lifecycles are fully decoupled (see
 * {@code PaymentGatewayService} class javadoc).
 *
 * <p>State machine (terminal states are CAPTURED / FAILED / CANCELLED / EXPIRED):
 * <pre>
 *   NEW ──────► PENDING ──────► AUTHORIZED ──────► CAPTURED   (terminal, success)
 *    │             │                │
 *    │             ├──────────────► FAILED         (terminal, provider declined)
 *    │             │                │
 *    ├─────────────┼────────────────┼────────────► CANCELLED  (terminal, voided)
 *    └─────────────┴────────────────┴────────────► EXPIRED    (terminal, timed out)
 * </pre>
 */
public enum PaymentSessionStatus {
    /** Session row just created, before a checkout URL has been generated. */
    NEW,
    /** Checkout URL generated; awaiting a provider callback (customer redirected). */
    PENDING,
    /** Provider callback confirmed the funds are authorized (auth hold placed). */
    AUTHORIZED,
    /** Authorized funds captured — terminal success. */
    CAPTURED,
    /** Provider callback declined the payment — terminal. */
    FAILED,
    /** Session voided by the customer/merchant before capture — terminal. */
    CANCELLED,
    /** Session timed out before authorize/capture — terminal. */
    EXPIRED;

    public boolean isTerminal() {
        return this == CAPTURED || this == FAILED || this == CANCELLED || this == EXPIRED;
    }
}
