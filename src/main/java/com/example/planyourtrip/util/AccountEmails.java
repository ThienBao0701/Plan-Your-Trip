package com.example.planyourtrip.util;

import java.util.Locale;

/**
 * Phase A — the single email normalization used wherever an account is stored or looked up
 * (registration, sign-in, verification, password reset, Admin bootstrap).
 *
 * <p>Trimmed and lowercased with {@link Locale#ROOT}, so the same address always lands on the same
 * row regardless of the server's default locale.
 */
public final class AccountEmails {

    /** Longest address accepted anywhere (RFC 5321 path limit). */
    public static final int MAX_LENGTH = 254;

    private AccountEmails() {}

    /** The canonical form of {@code raw}, or {@code null} when {@code raw} is null. */
    public static String normalize(String raw) {
        return raw == null ? null : raw.trim().toLowerCase(Locale.ROOT);
    }

    /** {@code raw} with surrounding whitespace removed, or null — for request records to apply before validation. */
    public static String trim(String raw) {
        return raw == null ? null : raw.trim();
    }
}
