package com.example.planyourtrip.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Locale;

/**
 * DB-06 — production fail-fast guard for the JWT signing secret.
 *
 * <p>{@code app.jwt.secret} carries a committed development fallback
 * ({@code change-this-development-secret-at-least-32-characters}) so local dev and the H2 test suite
 * boot with zero setup. That fallback is a PUBLICLY-KNOWN HMAC key: if it ever reached production the
 * platform would sign and accept forgeable auth tokens (full auth bypass). This component runs ONLY
 * under the {@code prod} profile — mirroring {@link com.example.planyourtrip.config.ProductionBootstrap}
 * — and refuses to start the context unless a strong secret has been injected via {@code JWT_SECRET}.
 *
 * <p>{@link JwtService} is intentionally left untouched: gating the strict check on the prod profile
 * keeps the dev/test default working byte-for-byte (it is never instantiated outside prod) while making
 * it impossible to boot prod on the placeholder. The rejection rules mirror
 * {@link VoucherSignatureService#validateSecret}: null/unresolved, blank, a known placeholder, or
 * shorter than {@value #MIN_SECRET_LENGTH} characters. The thrown message NAMES the property/env var
 * but NEVER echoes the supplied value or its length — the secret is not logged or leaked anywhere.
 */
@Component
@Profile("prod")
public class JwtSecretProductionValidator {

    /**
     * Minimum accepted secret length, in CHARACTERS (measured on the trimmed value). 32 chars = 32
     * UTF-8 bytes = 256 bits of HMAC-SHA256 key material, matching {@link VoucherSignatureService} and
     * the char-based convention the jwt secret already documents.
     */
    static final int MIN_SECRET_LENGTH = 32;

    /**
     * Known-placeholder blacklist (compared case-insensitively as a substring of the trimmed value).
     * {@code change-this-development} covers the committed dev fallback
     * ({@code change-this-development-secret-at-least-32-characters}); {@code changeme}/{@code change-me}
     * catch the obvious hand-edited variants without enumerating every one.
     */
    private static final List<String> BLACKLISTED_SECRETS = List.of(
            "change-this-development",
            "changeme",
            "change-me");

    public JwtSecretProductionValidator(@Value("${app.jwt.secret}") String secret) {
        validate(secret);
    }

    /**
     * Fails fast (bean-creation failure → Spring context refuses to start) when the prod JWT secret is
     * unusable. Package-private + static so the behaviour is unit-testable directly (and via the public
     * constructor) without a Spring context.
     */
    static void validate(String secret) {
        // Named once so every branch throws with the same secret-free, property-naming message.
        final String where = "app.jwt.secret (env JWT_SECRET)";
        if (secret == null) {
            throw new IllegalStateException(
                "Missing/unresolved " + where + ": set it to a fixed random secret of at least "
                + MIN_SECRET_LENGTH + " characters.");
        }
        String trimmed = secret.trim();
        if (trimmed.isEmpty()) {
            throw new IllegalStateException(
                "Blank " + where + ": set it to a fixed random secret of at least "
                + MIN_SECRET_LENGTH + " characters.");
        }
        String lower = trimmed.toLowerCase(Locale.ROOT);
        if (BLACKLISTED_SECRETS.stream().anyMatch(lower::contains)) {
            throw new IllegalStateException(
                "Refusing to start: " + where + " is the committed development placeholder. Set it to "
                + "a fixed random secret of at least " + MIN_SECRET_LENGTH + " characters.");
        }
        if (trimmed.length() < MIN_SECRET_LENGTH) {
            throw new IllegalStateException(
                "Too short: " + where + " must be at least " + MIN_SECRET_LENGTH + " characters.");
        }
    }
}
