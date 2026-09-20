package com.example.planyourtrip.service;

import com.example.planyourtrip.config.AuthProperties;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.AuthToken;
import com.example.planyourtrip.model.AuthTokenPurpose;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.AuthTokenRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.Optional;

/**
 * Phase A — issues and consumes one-time account tokens (email verification, password reset).
 *
 * <ul>
 *   <li><b>Never stored raw.</b> A token is 32 bytes from {@link SecureRandom}, handed back to the
 *       caller once for the email link; only its SHA-256 hash is persisted.</li>
 *   <li><b>One active token per account and purpose.</b> Issuing retires every earlier unused token
 *       of the same purpose, and consuming retires the rest, so an older link stops working.</li>
 *   <li><b>Issuance cooldown.</b> No new token within {@code app.auth.token-issue-cooldown} of the
 *       previous one. The account row is locked for the check, so concurrent requests cannot both
 *       pass it. Callers decide what to tell the client — usually nothing, to avoid enumeration.</li>
 *   <li><b>One-time, expiring.</b> Consumption is a conditional update, so a replayed or raced token
 *       is refused even when two requests arrive together.</li>
 * </ul>
 */
@Service
public class AuthTokenService {

    /** A freshly issued token. {@code rawToken} goes into the email link and nowhere else. */
    public record IssuedToken(String rawToken, Instant expiresAt) {}

    private static final SecureRandom RANDOM = new SecureRandom();
    private static final int TOKEN_BYTES = 32;

    private final AuthTokenRepository tokens;
    private final UserRepository users;
    private final AuthProperties properties;
    private final Clock clock;

    public AuthTokenService(AuthTokenRepository tokens, UserRepository users,
                            AuthProperties properties, Clock clock) {
        this.tokens = tokens;
        this.users = users;
        this.properties = properties;
        this.clock = clock;
    }

    /**
     * Issues a token of {@code purpose} for {@code user}, valid for {@code ttl}, or returns empty
     * when the previous one is younger than the cooldown.
     */
    @Transactional
    public Optional<IssuedToken> issue(User user, AuthTokenPurpose purpose, Duration ttl) {
        users.lockById(user.getId());
        Instant now = clock.instant();

        Optional<AuthToken> latest =
            tokens.findFirstByUserIdAndPurposeOrderByCreatedAtDescIdDesc(user.getId(), purpose);
        if (latest.isPresent()
                && latest.get().getCreatedAt().isAfter(now.minus(properties.getTokenIssueCooldown()))) {
            return Optional.empty();
        }

        tokens.retireActive(user.getId(), purpose, now);

        String raw = newRawToken();
        AuthToken token = new AuthToken();
        token.setUser(users.getReferenceById(user.getId()));
        token.setPurpose(purpose);
        token.setTokenHash(hash(raw));
        token.setCreatedAt(now);
        token.setExpiresAt(now.plus(ttl));
        tokens.save(token);
        return Optional.of(new IssuedToken(raw, token.getExpiresAt()));
    }

    /**
     * Consumes {@code rawToken} for {@code purpose} and returns its account.
     *
     * @throws ApiException 400 {@code TOKEN_INVALID} for an unknown, wrong-purpose, used, superseded
     *         or disabled-account token; 400 {@code TOKEN_EXPIRED} for an expired one
     */
    @Transactional
    public User consume(String rawToken, AuthTokenPurpose purpose) {
        if (rawToken == null || rawToken.isBlank()) throw invalid();
        AuthToken token = tokens.findByTokenHash(hash(rawToken.trim())).orElseThrow(AuthTokenService::invalid);
        if (token.getPurpose() != purpose || token.getConsumedAt() != null) throw invalid();

        Instant now = clock.instant();
        if (!token.getExpiresAt().isAfter(now)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "TOKEN_EXPIRED", "This link has expired");
        }

        Long userId = token.getUser().getId();
        if (tokens.consumeIfUnused(token.getId(), now) != 1) throw invalid();
        tokens.retireActive(userId, purpose, now);

        User user = users.findById(userId).orElseThrow(AuthTokenService::invalid);
        if (!user.isEnabled()) throw invalid();
        return user;
    }

    /** Retires every unused token of {@code purpose} for the account, e.g. after its password changed. */
    @Transactional
    public void retireAll(User user, AuthTokenPurpose purpose) {
        tokens.retireActive(user.getId(), purpose, clock.instant());
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    private static ApiException invalid() {
        return new ApiException(HttpStatus.BAD_REQUEST, "TOKEN_INVALID", "This link is invalid or has already been used");
    }

    private static String newRawToken() {
        byte[] bytes = new byte[TOKEN_BYTES];
        RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    /** Lowercase hex SHA-256 — the only form of a token that is ever persisted. */
    static String hash(String rawToken) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(rawToken.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 is not available", e);
        }
    }
}
