package com.example.planyourtrip.service.gateway;

import com.example.planyourtrip.config.PaymentProviderProperties;
import com.example.planyourtrip.model.CallbackOutcome;
import com.example.planyourtrip.model.PaymentProvider;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;

/**
 * Phase 7.27 — MoMo adapter.
 *
 * <p><b>Real signature scheme.</b> MoMo (v2 IPN) signs a documented raw string built from a
 * fixed, alphabetically-ordered set of fields with {@code HMAC_SHA256(secretKey, raw)} and
 * places the hex digest in the {@code signature} field:
 * <pre>
 *   accessKey=..&amount=..&extraData=..&message=..&orderId=..&orderInfo=..&orderType=..
 *   &partnerCode=..&payType=..&requestId=..&responseTime=..&resultCode=..&transId=..
 * </pre>
 * This adapter builds that exact raw string and verifies it.
 *
 * <p>Success is {@code resultCode == "0"}; the session is identified by {@code orderId} and
 * the provider reference is {@code transId}.
 */
@Component
public class MoMoGateway extends AbstractOfflineGateway {

    private final PaymentProviderProperties props;

    public MoMoGateway(ObjectMapper mapper, PaymentProviderProperties props) {
        super(mapper);
        this.props = props;
    }

    @Override
    public PaymentProvider provider() {
        return PaymentProvider.MOMO;
    }

    @Override
    protected String checkoutBaseUrl() {
        return props.getMomo().getCheckoutBaseUrl();
    }

    @Override
    public WebhookVerification verifyWebhook(String rawBody, String signatureHeader) {
        JsonNode b = parseJson(rawBody);
        if (b == null) return WebhookVerification.invalid();

        String presented = b.path("signature").asText(null);
        String orderId = b.path("orderId").asText(null);
        if (presented == null || orderId == null) return WebhookVerification.invalid();

        // MoMo's documented, alphabetically-ordered raw signing string.
        String raw = "accessKey=" + b.path("accessKey").asText()
            + "&amount=" + b.path("amount").asText()
            + "&extraData=" + b.path("extraData").asText()
            + "&message=" + b.path("message").asText()
            + "&orderId=" + orderId
            + "&orderInfo=" + b.path("orderInfo").asText()
            + "&orderType=" + b.path("orderType").asText()
            + "&partnerCode=" + b.path("partnerCode").asText()
            + "&payType=" + b.path("payType").asText()
            + "&requestId=" + b.path("requestId").asText()
            + "&responseTime=" + b.path("responseTime").asText()
            + "&resultCode=" + b.path("resultCode").asText()
            + "&transId=" + b.path("transId").asText();

        String expected = HmacSignatureVerifier.hmacHex(
            HmacSignatureVerifier.HMAC_SHA256, props.getMomo().getWebhookSecret(), raw);
        if (!HmacSignatureVerifier.constantTimeEquals(expected, presented)) return WebhookVerification.invalid();

        CallbackOutcome outcome = "0".equals(b.path("resultCode").asText())
            ? CallbackOutcome.AUTHORIZED : CallbackOutcome.FAILED;
        return WebhookVerification.of(orderId, outcome, b.path("transId").asText(null));
    }
}
