package com.example.planyourtrip.service.mail;

/**
 * Phase A — one account email: who it is for, what it is, and the single action link it carries.
 * The link holds a one-time token in its fragment, so it must be treated as a credential by every
 * {@link EmailSender} implementation.
 */
public record AccountEmail(String to, Kind kind, String actionUrl) {

    public enum Kind {
        EMAIL_VERIFICATION,
        PASSWORD_RESET
    }
}
