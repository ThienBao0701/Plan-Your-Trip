package com.example.planyourtrip.service.gateway;

import com.example.planyourtrip.config.PaymentProviderProperties;
import com.example.planyourtrip.model.CallbackOutcome;
import com.example.planyourtrip.model.PaymentProvider;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;

import java.util.Map;

/**
 * Phase 7.27 — PayOS adapter.
 *
 * <p><b>Real signature scheme.</b> PayOS signs the webhook's inner {@code data} object with
 * {@code HMAC_SHA256(checksumKey, sortedFormEncoded(dataFields))} — the data fields sorted
 * alphabetically and joined as {@code key=value&…} — and places the hex digest in the
 * top-level {@code signature} field. This adapter implements that exact algorithm.
 *
 * <p>Success is {@code data.code == "00"}; the session is identified by
 * {@code data.sessionId} and the provider reference is {@code data.reference}.
 */
@Component
public class PayOSGateway extends AbstractOfflineGateway {

    private final PaymentProviderProperties props;

    public PayOSGateway(ObjectMapper mapper, PaymentProviderProperties props) {
        super(mapper);
        this.props = props;
    }

    @Override
    public PaymentProvider provider() {
        return PaymentProvider.PAYOS;
    }

    @Override
    protected String checkoutBaseUrl() {
        return props.getPayos().getCheckoutBaseUrl();
    }

    @Override
    public WebhookVerification verifyWebhook(String rawBody, String signatureHeader) {
        JsonNode body = parseJson(rawBody);
        if (body == null) return WebhookVerification.invalid();

        JsonNode data = body.get("data");
        String presented = body.path("signature").asText(null);
        if (data == null || !data.isObject() || presented == null) return WebhookVerification.invalid();

        Map<String, String> dataFields = asFlatMap(data);
        String canonical = HmacSignatureVerifier.sortedFormEncoded(dataFields);
        String expected = HmacSignatureVerifier.hmacHex(
            HmacSignatureVerifier.HMAC_SHA256, props.getPayos().getWebhookSecret(), canonical);
        if (!HmacSignatureVerifier.constantTimeEquals(expected, presented)) return WebhookVerification.invalid();

        String sessionId = data.path("sessionId").asText(null);
        if (sessionId == null) return WebhookVerification.invalid();
        CallbackOutcome outcome = "00".equals(data.path("code").asText())
            ? CallbackOutcome.AUTHORIZED : CallbackOutcome.FAILED;
        return WebhookVerification.of(sessionId, outcome, data.path("reference").asText(null));
    }
}
