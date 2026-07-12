package com.example.planyourtrip.service.gateway;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Map;
import java.util.TreeMap;

/**
 * Phase 7.27 — the ONE shared "compute HMAC and compare" primitive reused by every real
 * provider gateway (VNPay, PayOS, Stripe, MoMo). The provider-specific parts — which HMAC
 * algorithm, which fields, and how the canonical string is built — live in each gateway;
 * the raw crypto mechanics live here exactly once (no copy-pasted {@code Mac} code).
 *
 * <p>These are REAL, production-grade algorithms. The only intentionally-mocked part of the
 * provider integration is the OUTBOUND checkout-API call (see each gateway's
 * {@code createCheckoutUrl}); signature verification is genuine and deterministically
 * testable with a fake test secret.
 */
public final class HmacSignatureVerifier {

    public static final String HMAC_SHA256 = "HmacSHA256";
    public static final String HMAC_SHA512 = "HmacSHA512";

    private HmacSignatureVerifier() {}

    /** Lower-case hex HMAC of {@code data} keyed by {@code secret} using {@code algorithm}. */
    public static String hmacHex(String algorithm, String secret, String data) {
        byte[] raw = hmac(algorithm, secret, data);
        StringBuilder sb = new StringBuilder(raw.length * 2);
        for (byte b : raw) sb.append(Character.forDigit((b >> 4) & 0xF, 16))
                             .append(Character.forDigit(b & 0xF, 16));
        return sb.toString();
    }

    private static byte[] hmac(String algorithm, String secret, String data) {
        try {
            Mac mac = Mac.getInstance(algorithm);
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), algorithm));
            return mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            throw new IllegalStateException("HMAC computation failed for " + algorithm, e);
        }
    }

    /**
     * Constant-time comparison of two signature strings (case-insensitive hex). Returns
     * {@code false} for any null. Uses {@link MessageDigest#isEqual} so verification time
     * does not leak how many leading characters matched.
     */
    public static boolean constantTimeEquals(String expected, String actual) {
        if (expected == null || actual == null) return false;
        byte[] a = expected.toLowerCase().getBytes(StandardCharsets.UTF_8);
        byte[] b = actual.toLowerCase().getBytes(StandardCharsets.UTF_8);
        return MessageDigest.isEqual(a, b);
    }

    /**
     * Canonical {@code k=v&k=v} string with keys sorted lexicographically, excluding the
     * given signature field name(s). This is the shared canonicalization used by the
     * providers that sign a sorted field map (VNPay HMAC-SHA512, PayOS/MoMo HMAC-SHA256).
     */
    public static String sortedFormEncoded(Map<String, String> fields, String... excludeKeys) {
        TreeMap<String, String> sorted = new TreeMap<>(fields);
        for (String ex : excludeKeys) sorted.remove(ex);
        StringBuilder sb = new StringBuilder();
        for (Map.Entry<String, String> e : sorted.entrySet()) {
            if (e.getValue() == null) continue;
            if (sb.length() > 0) sb.append('&');
            sb.append(e.getKey()).append('=').append(e.getValue());
        }
        return sb.toString();
    }
}
