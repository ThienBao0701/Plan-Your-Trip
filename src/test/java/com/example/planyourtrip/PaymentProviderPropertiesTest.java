package com.example.planyourtrip;

import com.example.planyourtrip.config.PaymentProviderProperties;
import com.example.planyourtrip.model.PaymentProvider;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PaymentProviderPropertiesTest {

    @Test
    void placeholderWebhookSecretDoesNotQualifyAsLiveProviderConfiguration() {
        PaymentProviderProperties properties = new PaymentProviderProperties();
        PaymentProviderProperties.Provider vnpay = new PaymentProviderProperties.Provider();
        vnpay.setLiveEnabled(true);
        vnpay.setCheckoutBaseUrl("https://payments.acmepay.com/checkout");
        vnpay.setWebhookSecret("known-placeholder-webhook-secret");
        properties.setVnpay(vnpay);

        assertFalse(properties.isLiveEnabled(PaymentProvider.VNPAY));

        vnpay.setWebhookSecret("vnp_live_signing_key_7f32b9e14c");
        assertTrue(properties.isLiveEnabled(PaymentProvider.VNPAY),
            "the live flag and HTTPS URL are otherwise valid; only the placeholder secret should fail");
    }
}
