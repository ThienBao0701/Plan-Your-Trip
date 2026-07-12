package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PaymentSessionDto.WebhookAck;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.PaymentProvider;
import com.example.planyourtrip.service.PaymentGatewayService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

/**
 * Phase 7.27 — REAL provider webhook receiver.
 *
 * <p><b>Unauthenticated by design.</b> A payment provider's server cannot present a user's
 * JWT, so these endpoints are permitted through the security filter (see {@code
 * SecurityConfig}'s {@code /api/webhooks/**} rule) and are instead authenticated by the
 * provider's cryptographic SIGNATURE over the raw request body — verified inside
 * {@code PaymentGatewayService.processWebhook} by the selected gateway. This is the key
 * difference from the Phase-7.26 {@code /api/payment-sessions/{id}/callback} simulation
 * endpoint, which is JWT-authenticated and token-gated.
 *
 * <p>The body is consumed as the RAW string so the signature is computed over the exact
 * bytes the provider signed (re-serializing a parsed object would change key order/spacing
 * and break verification).
 */
@RestController
@RequestMapping("/api/webhooks/payments")
@Tag(name = "Payment Webhooks", description = "Signature-verified real provider webhooks (Phase 7.27)")
public class PaymentWebhookController {

    private final PaymentGatewayService service;

    public PaymentWebhookController(PaymentGatewayService service) { this.service = service; }

    @PostMapping("/{provider}")
    @Operation(summary = "Receive a signed provider webhook (unauthenticated; signature-verified; idempotent)")
    public WebhookAck receive(@PathVariable String provider,
                              @RequestBody(required = false) String rawBody,
                              @RequestHeader(value = "Stripe-Signature", required = false) String stripeSignature,
                              @RequestHeader(value = "X-Signature", required = false) String genericSignature) {
        PaymentProvider parsed = parseProvider(provider);
        String signature = stripeSignature != null ? stripeSignature : genericSignature;
        return service.processWebhook(parsed, rawBody == null ? "" : rawBody, signature);
    }

    private PaymentProvider parseProvider(String provider) {
        try {
            return PaymentProvider.valueOf(provider.trim().toUpperCase());
        } catch (IllegalArgumentException | NullPointerException e) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Unknown payment provider: " + provider);
        }
    }
}
