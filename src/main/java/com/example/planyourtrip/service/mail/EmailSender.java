package com.example.planyourtrip.service.mail;

/**
 * Phase A — delivery of account emails. There is no real email provider in the project yet.
 *
 * <ul>
 *   <li>{@link DevelopmentLogEmailSender} (every profile except {@code prod}) writes the link to the
 *       application log for a developer to open. Nothing is sent.</li>
 *   <li>{@link UnconfiguredEmailSender} ({@code prod}) reports itself unavailable, so the flows that
 *       need an email answer 503 instead of pretending a message went out.</li>
 * </ul>
 *
 * A production provider is a new implementation of this interface; no caller changes.
 */
public interface EmailSender {

    /** Whether {@link #send} can deliver right now. Callers check this before creating anything. */
    boolean isAvailable();

    /** Delivers {@code email}. Throws when the sender is not available. */
    void send(AccountEmail email);
}
