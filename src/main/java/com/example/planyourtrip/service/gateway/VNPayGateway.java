package com.example.planyourtrip.service.gateway;

import com.example.planyourtrip.config.PaymentProviderProperties;
import com.example.planyourtrip.model.CallbackOutcome;
import com.example.planyourtrip.model.PaymentProvider;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;

import java.util.Map;

/**
 * Phase 7.27 — VNPay adapter.
 *
 * <p><b>Real signature scheme.</b> VNPay signs its return/IPN parameters with
 * {@code HMAC_SHA512(secretKey, sortedFormEncoded(params))}, where all {@code vnp_*}
 * parameters except {@code vnp_SecureHash}/{@code vnp_SecureHashType} are sorted
 * alphabetically and joined as {@code key=value&…}. The computed hash is compared to the
 * {@code vnp_SecureHash} field carried IN the payload (VNPay embeds the signature in the
 * data, not a header). This adapter implements that exact algorithm.
 *
 * <p>Success is {@code vnp_ResponseCode == "00"}; the session is identified by
 * {@code vnp_TxnRef} and the provider reference is {@code vnp_TransactionNo}.
 */
@Component
public class VNPayGateway extends AbstractOfflineGateway {

    private final PaymentProviderProperties props;

    public VNPayGateway(ObjectMapper mapper, PaymentProviderProperties props) {
        super(mapper);
        this.props = props;
    }

    @Override
    public PaymentProvider provider() {
        return PaymentProvider.VNPAY;
    }

    @Override
    protected String checkoutBaseUrl() {
        return props.getVnpay().getCheckoutBaseUrl();
    }

    @Override
    public WebhookVerification verifyWebhook(String rawBody, String signatureHeader) {
        JsonNode body = parseJson(rawBody);
        if (body == null || !body.isObject()) return WebhookVerification.invalid();

        Map<String, String> fields = asFlatMap(body);
        String presented = fields.get("vnp_SecureHash");
        if (presented == null) return WebhookVerification.invalid();

        String canonical = HmacSignatureVerifier.sortedFormEncoded(
            fields, "vnp_SecureHash", "vnp_SecureHashType");
        String expected = HmacSignatureVerifier.hmacHex(
            HmacSignatureVerifier.HMAC_SHA512, props.getVnpay().getWebhookSecret(), canonical);
        if (!HmacSignatureVerifier.constantTimeEquals(expected, presented)) return WebhookVerification.invalid();

        String sessionId = fields.get("vnp_TxnRef");
        if (sessionId == null) return WebhookVerification.invalid();
        CallbackOutcome outcome = "00".equals(fields.get("vnp_ResponseCode"))
            ? CallbackOutcome.AUTHORIZED : CallbackOutcome.FAILED;
        return WebhookVerification.of(sessionId, outcome, fields.get("vnp_TransactionNo"));
    }
}
