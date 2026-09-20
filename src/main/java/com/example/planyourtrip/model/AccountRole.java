package com.example.planyourtrip.model;

import java.util.Optional;

/**
 * Phase A — the three system roles, and the only authoritative reading of {@link User#getRole()}.
 *
 * <p>The role column is free text. Before Phase A the JWT filter granted {@code "ROLE_" + role} for
 * whatever the column held, so an unrecognised or null value still produced an authenticated
 * principal that passed every "any signed-in user" rule. {@link #parse} is exact and fails closed:
 * an unknown, null, blank or differently-cased value is no role at all, and is never mapped onto
 * USER, PARTNER or ADMIN.
 */
public enum AccountRole {
    USER,
    PARTNER,
    ADMIN;

    /** The role named exactly by {@code raw}, or empty. No trimming, no case folding, no fallback. */
    public static Optional<AccountRole> parse(String raw) {
        if (raw == null) return Optional.empty();
        for (AccountRole role : values()) {
            if (role.name().equals(raw)) return Optional.of(role);
        }
        return Optional.empty();
    }
}
