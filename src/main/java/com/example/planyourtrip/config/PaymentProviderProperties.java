package com.example.planyourtrip.config;

import com.example.planyourtrip.model.PaymentProvider;
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

    /** Configuration is necessary but not sufficient: the selected adapter must also support live payments. */
    public boolean isLiveEnabled(PaymentProvider provider) {
        Provider config = switch (provider) {
            case VNPAY -> vnpay;
            case PAYOS -> payos;
            case STRIPE -> stripe;
            case MOMO -> momo;
            default -> null;
        };
        return config != null && config.isLiveEnabled()
            && hasLiveSecret(config.getWebhookSecret())
            && hasLiveCheckoutUrl(config.getCheckoutBaseUrl());
    }

    private static boolean hasLiveSecret(String secret) {
        if (secret == null || secret.isBlank()) return false;
        String normalized = secret.toLowerCase(java.util.Locale.ROOT);
        return !normalized.contains("test-secret")
            && !normalized.contains("not-real")
            && !normalized.contains("placeholder")
            && !normalized.contains("example");
    }

    private static boolean hasLiveCheckoutUrl(String checkoutBaseUrl) {
        if (checkoutBaseUrl == null || checkoutBaseUrl.isBlank()) return false;
        String normalized = checkoutBaseUrl.toLowerCase(java.util.Locale.ROOT);
        if (normalized.contains(".test") || normalized.contains("sandbox")
                || normalized.contains("example") || normalized.contains("localhost")) return false;
        try {
            java.net.URI uri = java.net.URI.create(checkoutBaseUrl);
            return "https".equalsIgnoreCase(uri.getScheme()) && uri.getHost() != null;
        } catch (IllegalArgumentException ex) {
            return false;
        }
    }

    @Getter
    @Setter
    public static class Provider {
        /** Explicit production opt-in; still requires a live-capable adapter. */
        private boolean liveEnabled;
        /** Shared secret the provider signs its webhook payload with (HMAC key). */
        private String webhookSecret = "test-secret-not-real";
        /** Base URL used to build the offline, deterministic mock checkout URL. */
        private String checkoutBaseUrl = "https://sandbox.example.test/checkout/";
    }
}
