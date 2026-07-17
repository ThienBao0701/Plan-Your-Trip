package com.example.planyourtrip.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.List;
import java.util.Locale;
import java.util.Optional;

/**
 * Phase 7.38 (security-hardening) — versioned, HMAC-signed voucher QR payload signer/verifier.
 *
 * <p>The customer digital voucher's {@code qrPayload} is NOT authentication and does NOT resolve any
 * booking data. A valid signature proves ONLY that <em>this platform</em> generated the payload; it
 * does not replace partner/staff auth or the ownership/status checks that a future partner
 * verification endpoint (Phase 7.39) will perform. This component exposes {@link #sign} (used now by
 * the voucher) and {@link #verifyAndExtractBookingCode} (exposed now for Phase 7.39 reuse — no
 * partner endpoint is added here).
 *
 * <p><b>Payload format</b>: {@code PYT-V1.<bookingCode>.<base64urlSignature>} where
 * {@code signature = HMAC-SHA256(secret, "PYT-V1|" + bookingCode)}, Base64URL-encoded without padding.
 *
 * <p><b>Stability</b>: only the immutable {@code Booking.bookingCode} is signed — never a mutable
 * booking field (dates/occupancy/price/status) — so the payload is identical across repeated reads
 * and survives a Phase 7.34 modification unchanged.
 *
 * <p><b>Crypto mechanics</b>: this reuses the SAME primitives already used twice in the codebase —
 * {@code Mac.getInstance("HmacSHA256")} + {@code SecretKeySpec(secret.getBytes(UTF_8), "HmacSHA256")}
 * and {@code Base64.getUrlEncoder().withoutPadding()} (identical to {@link JwtService}), plus
 * constant-time equality via {@link MessageDigest#isEqual} (the same primitive
 * {@code service.gateway.HmacSignatureVerifier} uses for its webhook comparison). The raw {@code Mac}
 * calls are inlined here rather than routed through {@code HmacSignatureVerifier} because that helper
 * only exposes a lower-case-hex HMAC + hex/string compare, whereas the voucher contract needs raw
 * signature BYTES (for Base64URL encoding and for a byte-level constant-time compare of the decoded
 * signature) — so reusing it would mean re-encoding hex, not a clean fit. The algorithm is identical.
 */
@Service
public class VoucherSignatureService {

    private static final String HMAC_SHA256 = "HmacSHA256";
    private static final String VERSION = "PYT-V1";
    /** Payload prefix (version segment + dot separator): {@code "PYT-V1."}. */
    private static final String PREFIX = VERSION + ".";
    /** Signed-input separator: signature covers {@code "PYT-V1|" + bookingCode}. */
    private static final String SIGNED_INPUT_SEP = "|";
    /** Defensive upper bound so a hostile/oversized payload is rejected before any work. */
    private static final int MAX_PAYLOAD_LENGTH = 4096;

    /**
     * Minimum accepted secret length, in CHARACTERS (measured on the trimmed value). 32 chars matches
     * the char-based convention the jwt secret already documents
     * ({@code change-this-development-secret-at-least-32-characters}); the secret is later encoded as
     * UTF-8 bytes for the HMAC key, so 32 ASCII chars = 32 bytes = 256 bits of key material.
     */
    private static final int MIN_SECRET_LENGTH = 32;

    /**
     * Known-placeholder blacklist (compared case-insensitively against the trimmed value). Kept small:
     * the exact old committed dev fallback, plus a couple of obvious placeholders. Any value merely
     * CONTAINING {@code change-me}/{@code changeme} is also rejected below — this covers the committed
     * fallback family without enumerating every variant.
     */
    private static final List<String> BLACKLISTED_SECRETS = List.of(
            "voucher-dev-signing-secret-change-me-at-least-32-chars",
            "changeme",
            "change-me");

    private final String signingSecret;

    public VoucherSignatureService(@Value("${app.voucher.signing-secret}") String signingSecret) {
        validateSecret(signingSecret);
        this.signingSecret = signingSecret;
    }

    /**
     * Fails fast (bean-creation failure → Spring context refuses to start) when the resolved voucher
     * secret is unusable. Rejects: null/unresolved, blank, shorter than {@link #MIN_SECRET_LENGTH}
     * chars, or a known placeholder. The thrown message NAMES the property/env var but NEVER echoes the
     * supplied value (or its length) — the secret is not logged or leaked anywhere.
     */
    private static void validateSecret(String secret) {
        // Named once so every branch throws with the same secret-free, property-naming message.
        final String where = "app.voucher.signing-secret (env VOUCHER_SIGNING_SECRET)";
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
        boolean placeholder = BLACKLISTED_SECRETS.stream().anyMatch(lower::contains);
        if (placeholder) {
            throw new IllegalStateException(
                "Refusing to start: " + where + " is a known placeholder. Set it to a fixed random "
                + "secret of at least " + MIN_SECRET_LENGTH + " characters.");
        }
        if (trimmed.length() < MIN_SECRET_LENGTH) {
            throw new IllegalStateException(
                "Too short: " + where + " must be at least " + MIN_SECRET_LENGTH + " characters.");
        }
    }

    /**
     * Signs a booking code into the full versioned payload
     * {@code PYT-V1.<bookingCode>.<base64urlSignature>}. Pure computation — no persistence.
     */
    public String sign(String bookingCode) {
        String signature = base64Url(hmac(signedInput(bookingCode)));
        return PREFIX + bookingCode + "." + signature;
    }

    /**
     * Verifies a payload and returns the embedded bookingCode ONLY if every check passes:
     * exactly the {@code PYT-V1.<code>.<sig>} structure (three dot-separated segments), the version
     * segment is exactly {@code PYT-V1}, the signature Base64URL-decodes successfully, and the
     * recomputed HMAC over {@code "PYT-V1|" + bookingCode} matches the provided signature in
     * CONSTANT TIME. Any malformed / altered / unsupported-version input yields {@link Optional#empty}
     * — never a thrown exception.
     */
    public Optional<String> verifyAndExtractBookingCode(String payload) {
        if (payload == null || payload.isEmpty() || payload.length() > MAX_PAYLOAD_LENGTH) {
            return Optional.empty();
        }
        // Exactly three segments: version, bookingCode, signature. limit=-1 keeps trailing empties so
        // "a.b." (empty sig) or extra dots are seen as the wrong segment count and rejected.
        String[] parts = payload.split("\\.", -1);
        if (parts.length != 3) return Optional.empty();

        String version = parts[0];
        String bookingCode = parts[1];
        String providedSig = parts[2];
        if (!VERSION.equals(version)) return Optional.empty();      // unsupported/absent version → reject
        if (bookingCode.isEmpty() || providedSig.isEmpty()) return Optional.empty();

        byte[] providedSigBytes;
        try {
            providedSigBytes = Base64.getUrlDecoder().decode(providedSig);
        } catch (IllegalArgumentException e) {
            return Optional.empty();                                 // malformed Base64URL → reject safely
        }

        byte[] expectedSigBytes = hmac(signedInput(bookingCode));
        // Constant-time comparison of the raw signature bytes (never String.equals on the signature).
        if (!MessageDigest.isEqual(expectedSigBytes, providedSigBytes)) return Optional.empty();
        return Optional.of(bookingCode);
    }

    /** Convenience boolean wrapper over {@link #verifyAndExtractBookingCode}. */
    public boolean verify(String payload) {
        return verifyAndExtractBookingCode(payload).isPresent();
    }

    /** The exact string the HMAC is computed over: {@code "PYT-V1|" + bookingCode}. */
    private String signedInput(String bookingCode) {
        return VERSION + SIGNED_INPUT_SEP + bookingCode;
    }

    private byte[] hmac(String data) {
        try {
            Mac mac = Mac.getInstance(HMAC_SHA256);
            mac.init(new SecretKeySpec(signingSecret.getBytes(StandardCharsets.UTF_8), HMAC_SHA256));
            return mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            throw new IllegalStateException("Voucher HMAC computation failed", e);
        }
    }

    private static String base64Url(byte[] data) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(data);
    }
}
