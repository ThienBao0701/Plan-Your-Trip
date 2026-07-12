package com.example.planyourtrip.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Phase 7.27 — consolidated, additive configuration holder for the real payment providers.
 * Bound from {@code payment.providers.*} in {@code application.properties}. Every value in
 * this repo is an OBVIOUSLY-FAKE placeholder (e.g. {@code test-secret-not-real}); real
 * credentials are supplied via environment variables in a deployment, NEVER committed.
 *
 * <p>Each provider exposes a {@code webhookSecret} (the shared secret its webhook HMAC is
 * keyed with) and a {@code checkoutBaseUrl} (used only to fabricate the deterministic,
 * offline mock checkout URL — no outbound HTTP is ever performed in this phase).
 */
@Component
@ConfigurationProperties(prefix = "payment.providers")
@Getter
@Setter
public class PaymentProviderProperties {

    private Provider vnpay = new Provider();
    private Provider payos = new Provider();
    private Provider stripe = new Provider();
    private Provider momo = new Provider();

    @Getter
    @Setter
    public static class Provider {
        /** Shared secret the provider signs its webhook payload with (HMAC key). */
        private String webhookSecret = "test-secret-not-real";
        /** Base URL used to build the offline, deterministic mock checkout URL. */
        private String checkoutBaseUrl = "https://sandbox.example.test/checkout/";
    }
}
