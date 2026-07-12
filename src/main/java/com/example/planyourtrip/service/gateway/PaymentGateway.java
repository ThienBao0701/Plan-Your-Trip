package com.example.planyourtrip.service.gateway;

import com.example.planyourtrip.model.CallbackOutcome;
import com.example.planyourtrip.model.PaymentProvider;
import com.example.planyourtrip.model.PaymentSession;

/**
 * Phase 7.26 — Payment Gateway Foundation.
 *
 * <p>The provider-abstraction contract. ALL provider-specific logic lives behind this
 * interface; {@code PaymentGatewayService} is provider-agnostic and never branches on
 * provider type for behavior — it only SELECTS the right implementation via
 * {@link #provider()} (see {@code PaymentGatewayService}'s {@code Map<PaymentProvider,
 * PaymentGateway>}). A future provider (VNPay, PayOS, Stripe, MoMo, Apple Pay, Google
 * Pay, …) is added by dropping in a new {@code @Component} that implements this
 * interface — no change to {@code PaymentGatewayService}, {@code BookingService} or
 * {@code PaymentService}.
 *
 * <p>Implementations MUST be side-effect-free with respect to persistence: the service
 * owns all {@code PaymentSession}/event persistence, state transitions, idempotency and
 * notifications. A gateway only (a) builds the provider checkout URL, (b) verifies +
 * interprets a raw provider callback, and (c) performs the provider-side capture/void
 * calls (no-ops for the mock — real providers hit their HTTP API here).
 */
public interface PaymentGateway {

    /** The provider this gateway handles — the key used for selection. */
    PaymentProvider provider();

    /** Build the provider-specific checkout URL a customer would be redirected to. */
    String createCheckoutUrl(PaymentSession session);

    /**
     * Verify and interpret a raw provider callback for {@code session}. Implementations
     * validate the callback authenticity (in this phase: the {@code callbackToken}
     * matches the session's secret; a real provider verifies a signature/HMAC) and map
     * the payload onto a normalized {@link CallbackOutcome}.
     */
    CallbackVerification verifyCallback(PaymentSession session, GatewayCallback callback);

    /**
     * Provider-side capture of previously authorized funds. Mock: no-op. Real providers
     * call their capture API here. MUST NOT touch persistence — the service records the
     * AUTHORIZED → CAPTURED transition.
     */
    void capture(PaymentSession session);

    /**
     * Provider-side void/cancel of an uncaptured session. Mock: no-op. Real providers
     * call their void/cancel API here. MUST NOT touch persistence.
     */
    void cancel(PaymentSession session);

    /**
     * Normalized inbound callback payload (provider-agnostic shape). A real gateway would
     * receive the provider's own body and headers and normalize onto this before/while
     * verifying; the mock accepts it directly.
     */
    record GatewayCallback(String callbackToken, CallbackOutcome outcome, String providerReference) {}

    /**
     * A gateway's verified interpretation of a callback.
     */
    record CallbackVerification(boolean valid, CallbackOutcome outcome, String providerReference) {

        static CallbackVerification invalid() {
            return new CallbackVerification(false, null, null);
        }

        static CallbackVerification of(CallbackOutcome outcome, String providerReference) {
            return new CallbackVerification(true, outcome, providerReference);
        }
    }
}
