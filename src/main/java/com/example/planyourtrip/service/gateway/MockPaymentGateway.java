package com.example.planyourtrip.service.gateway;

import com.example.planyourtrip.model.PaymentProvider;
import com.example.planyourtrip.model.PaymentSession;
import org.springframework.stereotype.Component;

/**
 * Phase 7.26 — the ONLY concrete {@link PaymentGateway} implemented in this phase.
 * No external HTTP calls: it fabricates a deterministic checkout URL and validates the
 * callback by comparing the presented {@code callbackToken} to the session's secret
 * (a real provider would verify a cryptographic signature instead). {@link #capture}
 * and {@link #cancel} are no-ops — there is no external provider to call.
 *
 * <p>Registered as a Spring bean so {@code PaymentGatewayService} discovers it via
 * constructor injection of {@code List<PaymentGateway>} and indexes it by
 * {@link #provider()}. Future providers are added the same way with zero changes to the
 * service (see {@link PaymentGateway} javadoc).
 */
@Component
public class MockPaymentGateway implements PaymentGateway {

    private static final String CHECKOUT_BASE = "https://mock-gateway.planyourtrip.local/checkout/";

    @Override
    public PaymentProvider provider() {
        return PaymentProvider.MOCK;
    }

    @Override
    public String createCheckoutUrl(PaymentSession session) {
        return CHECKOUT_BASE + session.getSessionId();
    }

    @Override
    public CallbackVerification verifyCallback(PaymentSession session, GatewayCallback callback) {
        if (callback == null || callback.callbackToken() == null
                || !session.getCallbackToken().equals(callback.callbackToken())) {
            return CallbackVerification.invalid();
        }
        String reference = callback.providerReference() != null
            ? callback.providerReference()
            : "MOCK-" + session.getSessionId();
        return CallbackVerification.of(callback.outcome(), reference);
    }

    @Override
    public void capture(PaymentSession session) {
        // No external provider — capture is a no-op for the mock gateway.
    }

    @Override
    public void cancel(PaymentSession session) {
        // No external provider — cancel/void is a no-op for the mock gateway.
    }
}
