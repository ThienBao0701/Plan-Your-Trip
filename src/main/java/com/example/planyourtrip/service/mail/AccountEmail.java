package com.example.planyourtrip.service.mail;

/**
 * Phase A — one account email: who it is for, what it is, and the single action link it carries.
 * The link holds a one-time token in its fragment, so it must be treated as a credential by every
 * {@link EmailSender} implementation.
 */
public record AccountEmail(String to, Kind kind, String actionUrl) {

    public enum Kind {
        EMAIL_VERIFICATION,
        PASSWORD_RESET,
        /** RBAC R4 — an invitation to join a partner team; the address may not have an account yet. */
        PARTNER_INVITATION
    }

    /**
     * RBAC R4 hardening — never prints the link: a record's default {@code toString} would put the one-time token
     * into any log, exception message or debugger dump that renders this object. Only a sender that deliberately
     * reads {@link #actionUrl()} handles the link (the dev-only {@link DevelopmentLogEmailSender} prints it by design).
     */
    @Override
    public String toString() {
        return "AccountEmail[to=" + to + ", kind=" + kind + ", actionUrl=(redacted)]";
    }
}
