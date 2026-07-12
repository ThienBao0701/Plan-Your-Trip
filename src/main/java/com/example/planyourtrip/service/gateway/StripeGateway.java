package com.example.planyourtrip.service.gateway;

import com.example.planyourtrip.config.PaymentProviderProperties;
import com.example.planyourtrip.model.CallbackOutcome;
import com.example.planyourtrip.model.PaymentProvider;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;

/**
 * Phase 7.27 — Stripe adapter.
 *
 * <p><b>Real signature scheme.</b> Stripe signs webhooks with the {@code Stripe-Signature}
 * header of the form {@code t=<unix ts>,v1=<hex>} where the HMAC is
 * {@code HMAC_SHA256(webhookSecret, "<t>.<rawBody>")}. This adapter implements that exact
 * algorithm; the outbound checkout-session API call is the only mocked part.
 *
 * <p>Normalized body shape used in this phase's offline tests:
 * {@code {"sessionId":"PS-…","status":"succeeded"|"failed","reference":"pi_…"}}.
 */
@Component
public class StripeGateway extends AbstractOfflineGateway {

    private final PaymentProviderProperties props;

    public StripeGateway(ObjectMapper mapper, PaymentProviderProperties props) {
        super(mapper);
        this.props = props;
    }

    @Override
    public PaymentProvider provider() {
        return PaymentProvider.STRIPE;
    }

    @Override
    protected String checkoutBaseUrl() {
        return props.getStripe().getCheckoutBaseUrl();
    }

    @Override
    public WebhookVerification verifyWebhook(String rawBody, String signatureHeader) {
        JsonNode body = parseJson(rawBody);
        if (body == null || signatureHeader == null) return WebhookVerification.invalid();

        String timestamp = null;
        String v1 = null;
        for (String part : signatureHeader.split(",")) {
            String[] kv = part.trim().split("=", 2);
            if (kv.length != 2) continue;
            if (kv[0].equals("t")) timestamp = kv[1];
            else if (kv[0].equals("v1")) v1 = kv[1];
        }
        if (timestamp == null || v1 == null) return WebhookVerification.invalid();

        String signedPayload = timestamp + "." + rawBody;
        String expected = HmacSignatureVerifier.hmacHex(
            HmacSignatureVerifier.HMAC_SHA256, props.getStripe().getWebhookSecret(), signedPayload);
        if (!HmacSignatureVerifier.constantTimeEquals(expected, v1)) return WebhookVerification.invalid();

        String sessionId = body.path("sessionId").asText(null);
        if (sessionId == null) return WebhookVerification.invalid();
        CallbackOutcome outcome = "succeeded".equalsIgnoreCase(body.path("status").asText())
            ? CallbackOutcome.AUTHORIZED : CallbackOutcome.FAILED;
        return WebhookVerification.of(sessionId, outcome, body.path("reference").asText(null));
    }
}
