package com.example.planyourtrip.service.gateway;

import com.example.planyourtrip.model.PaymentSession;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Phase 7.27 — shared skeleton for the real provider adapters. Holds the parts that are
 * genuinely identical across VNPay / PayOS / Stripe / MoMo:
 *
 * <ul>
 *   <li>{@link #createCheckoutUrl} — an OFFLINE, deterministic mock URL. There is no real
 *       outbound HTTP to a payment gateway in this environment; the mocked boundary is
 *       strictly this "create checkout session" call. Everything else (signature
 *       verification) is production-grade.</li>
 *   <li>{@link #verifyCallback} — the Phase-7.26 token-based simulation callback, kept so
 *       the existing {@code /callback} flow works uniformly for every provider.</li>
 *   <li>{@link #capture}/{@link #cancel} — offline no-ops (a real provider would hit its
 *       capture/void API here).</li>
 * </ul>
 *
 * Each concrete subclass supplies ONLY its provider identity, its checkout base URL, and
 * its provider-specific {@link #verifyWebhook} signature algorithm.
 */
abstract class AbstractOfflineGateway implements PaymentGateway {

    protected final ObjectMapper mapper;

    protected AbstractOfflineGateway(ObjectMapper mapper) {
        this.mapper = mapper;
    }

    /** Provider-specific checkout base (from a provider config object). */
    protected abstract String checkoutBaseUrl();

    @Override
    public String createCheckoutUrl(PaymentSession session) {
        // OFFLINE MOCK — deterministic, no network call. Real credentials/API in a future phase.
        return checkoutBaseUrl() + session.getSessionId();
    }

    @Override
    public CallbackVerification verifyCallback(PaymentSession session, GatewayCallback callback) {
        if (callback == null || callback.callbackToken() == null
                || !session.getCallbackToken().equals(callback.callbackToken())) {
            return CallbackVerification.invalid();
        }
        String reference = callback.providerReference() != null
            ? callback.providerReference()
            : provider().name() + "-" + session.getSessionId();
        return CallbackVerification.of(callback.outcome(), reference);
    }

    @Override
    public void capture(PaymentSession session) {
        // No outbound provider call in this phase — capture is recorded by the service.
    }

    @Override
    public void cancel(PaymentSession session) {
        // No outbound provider call in this phase — cancel/void is recorded by the service.
    }

    // ── shared webhook-parsing helpers ──────────────────────────────────────────

    /** Parse the raw webhook body to a JSON tree, or {@code null} if it is not valid JSON. */
    protected JsonNode parseJson(String rawBody) {
        try {
            return rawBody == null ? null : mapper.readTree(rawBody);
        } catch (Exception e) {
            return null;
        }
    }

    /** Flatten a JSON object node into an insertion-ordered {@code String→String} map. */
    protected Map<String, String> asFlatMap(JsonNode node) {
        Map<String, String> map = new LinkedHashMap<>();
        if (node != null && node.isObject()) {
            node.fields().forEachRemaining(e -> map.put(e.getKey(), e.getValue().asText()));
        }
        return map;
    }
}
