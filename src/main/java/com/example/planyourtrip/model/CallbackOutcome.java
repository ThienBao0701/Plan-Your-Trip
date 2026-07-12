package com.example.planyourtrip.model;

/**
 * Phase 7.26 — normalized, provider-agnostic outcome carried by a payment-gateway
 * callback. A concrete {@code PaymentGateway} maps its provider's raw webhook payload
 * onto one of these values; {@code PaymentGatewayService} then drives the
 * {@link PaymentSessionStatus} state machine off it, with no provider-specific branching.
 */
public enum CallbackOutcome {
    /** The provider authorized the funds (PENDING → AUTHORIZED). */
    AUTHORIZED,
    /** The provider declined the payment (PENDING/AUTHORIZED → FAILED). */
    FAILED
}
