package com.example.planyourtrip;

import com.example.planyourtrip.security.VoucherSignatureService;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Phase 7.38 (security-hardening) — unit tests for the versioned, HMAC-signed voucher payload
 * signer/verifier. Pure computation, no Spring context: the service is instantiated directly with a
 * deterministic test secret so signatures are stable and reproducible.
 *
 * <p>Proves the signed-format contract: valid payloads verify and extract the correct bookingCode;
 * any altered bookingCode/signature fails; unsupported versions and malformed payloads are rejected
 * SAFELY (empty Optional / false, never a thrown exception).
 */
class VoucherSignatureServiceTest {

    private static final String SECRET = "unit-test-voucher-signing-secret-at-least-32-chars";
    private final VoucherSignatureService signer = new VoucherSignatureService(SECRET);

    @Test
    void sign_producesVersionedThreeSegmentPayload_withBookingCodeAsMiddleSegment() {
        String code = "PYT-20260717-000042";
        String payload = signer.sign(code);

        assertTrue(payload.matches("^PYT-V1\\..+\\..+$"), "shape PYT-V1.<code>.<sig>: " + payload);
        String[] parts = payload.split("\\.", -1);
        assertEquals(3, parts.length, "exactly three dot-separated segments");
        assertEquals("PYT-V1", parts[0]);
        assertEquals(code, parts[1], "bookingCode is the middle segment verbatim");
        assertFalse(parts[2].isEmpty(), "signature segment present");
        assertNotEquals("PYT-VCHR:" + code, payload, "no longer the raw bookingCode-only payload");
    }

    @Test
    void sign_isStable_sameCodeSameSecretYieldsIdenticalPayload() {
        String code = "PYT-20260717-000042";
        assertEquals(signer.sign(code), signer.sign(code), "signing is deterministic");
    }

    @Test
    void differentSecret_yieldsDifferentSignature() {
        String code = "PYT-20260717-000042";
        VoucherSignatureService other = new VoucherSignatureService("a-totally-different-secret-32-characters-long!!");
        assertNotEquals(signer.sign(code), other.sign(code));
    }

    @Test
    void verify_validPayload_extractsCorrectBookingCode() {
        String code = "PYT-20260717-000042";
        String payload = signer.sign(code);

        Optional<String> extracted = signer.verifyAndExtractBookingCode(payload);
        assertTrue(extracted.isPresent(), "valid payload verifies");
        assertEquals(code, extracted.get());
        assertTrue(signer.verify(payload));
    }

    @Test
    void verify_flippedBookingCodeSegment_fails() {
        String code = "PYT-20260717-000042";
        String[] p = signer.sign(code).split("\\.", -1);
        // Alter one char of the bookingCode segment, keep the original signature.
        String tampered = p[0] + "." + code.replace("000042", "000043") + "." + p[2];
        assertTrue(signer.verifyAndExtractBookingCode(tampered).isEmpty(), "altered bookingCode → reject");
        assertFalse(signer.verify(tampered));
    }

    @Test
    void verify_flippedSignatureSegment_fails() {
        String code = "PYT-20260717-000042";
        String[] p = signer.sign(code).split("\\.", -1);
        char c = p[2].charAt(0);
        char flipped = (c == 'A') ? 'B' : 'A';
        String tampered = p[0] + "." + p[1] + "." + flipped + p[2].substring(1);
        assertTrue(signer.verifyAndExtractBookingCode(tampered).isEmpty(), "altered signature → reject");
    }

    @Test
    void verify_unsupportedVersion_rejected() {
        String code = "PYT-20260717-000042";
        String sig = signer.sign(code).split("\\.", -1)[2];
        assertTrue(signer.verifyAndExtractBookingCode("PYT-V2." + code + "." + sig).isEmpty(),
            "unsupported version PYT-V2 → reject");
        assertTrue(signer.verifyAndExtractBookingCode("." + code + "." + sig).isEmpty(),
            "absent/empty version → reject");
    }

    @Test
    void verify_malformedPayloads_rejectedSafely_noException() {
        // None of these may throw — all yield an empty Optional / false.
        assertTrue(signer.verifyAndExtractBookingCode(null).isEmpty(), "null");
        assertTrue(signer.verifyAndExtractBookingCode("").isEmpty(), "empty");
        assertTrue(signer.verifyAndExtractBookingCode("PYT-V1").isEmpty(), "one segment");
        assertTrue(signer.verifyAndExtractBookingCode("PYT-V1.CODE").isEmpty(), "two segments");
        assertTrue(signer.verifyAndExtractBookingCode("PYT-V1.CODE.sig.extra").isEmpty(), "four segments");
        assertTrue(signer.verifyAndExtractBookingCode("PYT-V1.CODE.").isEmpty(), "empty signature segment");
        assertTrue(signer.verifyAndExtractBookingCode("PYT-V1..sig").isEmpty(), "empty bookingCode segment");
        // Non-Base64URL signature ('*' and '+' are not Base64URL alphabet) must be caught, not thrown.
        assertTrue(signer.verifyAndExtractBookingCode("PYT-V1.CODE.not*base64url+").isEmpty(),
            "malformed Base64URL signature → reject safely");
        assertFalse(signer.verify("PYT-V1.CODE.not*base64url+"));
    }

    @Test
    void verify_oversizedPayload_rejectedSafely() {
        StringBuilder huge = new StringBuilder("PYT-V1.");
        for (int i = 0; i < 5000; i++) huge.append('x');
        huge.append(".sig");
        assertTrue(signer.verifyAndExtractBookingCode(huge.toString()).isEmpty(), "oversized → reject");
    }

    @Test
    void payload_containsNoSecret() {
        String payload = signer.sign("PYT-20260717-000042");
        assertFalse(payload.contains(SECRET), "the signing secret never appears in the payload");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // Phase 7.38 hardening — fail-fast secret validation in the constructor.
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void constructor_validSecret_constructsAndRoundTrips() {
        // A 32+ char, non-placeholder secret constructs and sign/verify still round-trip.
        VoucherSignatureService svc =
            new VoucherSignatureService("another-valid-voucher-secret-with-32plus-characters");
        String payload = svc.sign("PYT-20260717-000099");
        assertTrue(svc.verify(payload), "valid secret → sign/verify round-trip works");
        assertEquals("PYT-20260717-000099", svc.verifyAndExtractBookingCode(payload).orElseThrow());
    }

    @Test
    void constructor_nullSecret_throws() {
        assertThrows(IllegalStateException.class, () -> new VoucherSignatureService(null));
    }

    @Test
    void constructor_blankSecret_throws() {
        assertThrows(IllegalStateException.class, () -> new VoucherSignatureService(""));
        assertThrows(IllegalStateException.class, () -> new VoucherSignatureService("            "));
    }

    @Test
    void constructor_shortSecret_throws() {
        // 31 chars, non-placeholder → below the 32-char minimum → reject.
        String shortSecret = "0123456789012345678901234567890"; // length 31
        assertEquals(31, shortSecret.length());
        assertThrows(IllegalStateException.class, () -> new VoucherSignatureService(shortSecret));
    }

    @Test
    void constructor_knownPlaceholder_throws() {
        // The exact old committed dev fallback must be rejected even though it is >=32 chars.
        String oldFallback = "voucher-dev-signing-secret-change-me-at-least-32-chars";
        assertTrue(oldFallback.length() >= 32);
        assertThrows(IllegalStateException.class, () -> new VoucherSignatureService(oldFallback));
    }

    @Test
    void constructor_exceptionMessage_neverLeaksTheSecret() {
        // A long, distinctive-but-blacklisted secret so we can assert the message excludes it.
        String badSecret = "change-me-please-this-is-a-placeholder-value-32plus";
        IllegalStateException ex = assertThrows(IllegalStateException.class,
            () -> new VoucherSignatureService(badSecret));
        assertNotNull(ex.getMessage());
        assertFalse(ex.getMessage().contains(badSecret),
            "the exception message must NOT echo the supplied secret value");
        // It may (and should) name the property/env var for operability.
        assertTrue(ex.getMessage().contains("VOUCHER_SIGNING_SECRET")
                || ex.getMessage().contains("app.voucher.signing-secret"),
            "the message names the property/env var to fix");
    }

    @Test
    void constructor_shortSecretMessage_doesNotLeakLengthOrValue() {
        String shortSecret = "abc-short-secret-under-32-chars"; // 31 chars, non-placeholder
        IllegalStateException ex = assertThrows(IllegalStateException.class,
            () -> new VoucherSignatureService(shortSecret));
        assertFalse(ex.getMessage().contains(shortSecret),
            "the exception message must NOT echo the supplied secret value");
    }
}
