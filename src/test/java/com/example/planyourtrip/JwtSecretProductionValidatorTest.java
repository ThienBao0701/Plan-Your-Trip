package com.example.planyourtrip;

import com.example.planyourtrip.security.JwtSecretProductionValidator;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * DB-06 — verifies the prod JWT-secret fail-fast guard. Exercised through the public constructor (the
 * same manual-construction style as {@code ProductionBootstrapTest}) so no Spring context — and
 * therefore no SQL Server prod datasource — is required. The bean itself is {@code @Profile("prod")}
 * and so is never instantiated by the normal H2 test contexts.
 */
class JwtSecretProductionValidatorTest {

    /** The exact committed development fallback from application.properties. */
    private static final String COMMITTED_DEV_SECRET = "change-this-development-secret-at-least-32-characters";

    private static IllegalStateException reject(String secret) {
        return assertThrows(IllegalStateException.class,
                () -> new JwtSecretProductionValidator(secret));
    }

    @Test
    void rejectsTheCommittedDevelopmentPlaceholder() {
        // The whole point of the guard: prod must NOT boot on the publicly-known dev secret, even
        // though it is long enough to pass the length check.
        assertTrue(COMMITTED_DEV_SECRET.length() >= 32, "sanity: the dev fallback is long enough");
        IllegalStateException ex = reject(COMMITTED_DEV_SECRET);
        assertTrue(ex.getMessage().contains("app.jwt.secret"), "message must name the property");
        assertTrue(ex.getMessage().contains("JWT_SECRET"), "message must name the env var");
        assertTrue(!ex.getMessage().contains(COMMITTED_DEV_SECRET), "message must NOT echo the secret");
    }

    @Test
    void rejectsNullBlankAndPlaceholderVariants() {
        reject(null);
        reject("");
        reject("   ");
        reject("changeme");
        reject("CHANGE-ME-please-please-please-please-please"); // case-insensitive substring match
    }

    @Test
    void rejectsTooShortSecret() {
        IllegalStateException ex = reject("short-31-characters-1234567890"); // 30 chars, < 32
        assertTrue(ex.getMessage().contains("app.jwt.secret"));
    }

    @Test
    void acceptsAStrongInjectedSecret() {
        // A fixed random-looking secret of >=32 chars that is not a placeholder — prod must start.
        assertDoesNotThrow(() ->
                new JwtSecretProductionValidator("Zx9q2Lp7Rw4Kt6Vn8Ba1Cd3Ef5Gh7Jk9Mn0Pq2Sr"));
    }
}
