package com.example.planyourtrip.service.mail;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * Phase A — the production {@link EmailSender} until a real provider exists. It is never available:
 * Partner registration, verification resend and password reset answer 503 rather than accept a
 * request whose email can never arrive. A warning is logged once at start-up so the gap is visible.
 */
@Component
@Profile("prod")
public class UnconfiguredEmailSender implements EmailSender {

    private static final Logger log = LoggerFactory.getLogger(UnconfiguredEmailSender.class);

    public UnconfiguredEmailSender() {
        log.warn("No email provider is configured: Partner registration, email verification resend "
            + "and password reset will answer 503 until one is added.");
    }

    @Override
    public boolean isAvailable() {
        return false;
    }

    @Override
    public void send(AccountEmail email) {
        throw new IllegalStateException("No email provider is configured");
    }
}
