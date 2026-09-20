package com.example.planyourtrip.service.mail;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * Phase A — DEVELOPMENT ONLY. Writes each account email's link to the log instead of sending it.
 *
 * <p>This is the agreed local mechanism for verification and password reset: the developer copies the
 * link (or the token after {@code #token=}) from the backend console. No email is delivered, and
 * nothing claims one was. The link is a one-time credential, which is why this bean can never be
 * active under the {@code prod} profile. No password is ever part of an {@link AccountEmail}.
 */
@Component
@Profile("!prod")
public class DevelopmentLogEmailSender implements EmailSender {

    private static final Logger log = LoggerFactory.getLogger(DevelopmentLogEmailSender.class);

    @Override
    public boolean isAvailable() {
        return true;
    }

    @Override
    public void send(AccountEmail email) {
        log.info("[DEV ONLY — NO EMAIL SENT] {} link for {}: {}", email.kind(), email.to(), email.actionUrl());
    }
}
