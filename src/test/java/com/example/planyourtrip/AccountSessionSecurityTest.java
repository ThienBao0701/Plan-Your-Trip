package com.example.planyourtrip;

import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.security.JwtService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Arrays;
import java.util.Base64;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;

/**
 * Phase A — who a bearer token authenticates, and when it stops.
 *
 * <ul>
 *   <li><b>S1</b> — a disabled account cannot sign in, and a token issued before it was disabled stops
 *       working on the next request.</li>
 *   <li><b>S3</b> — a token carries the account's token version; after a bump the old token is refused
 *       and a freshly issued one works. Tokens issued before Phase A (no version claim) read as 0.</li>
 *   <li><b>S4</b> — only USER, PARTNER and ADMIN are roles. Anything else stored in the column — unknown,
 *       differently cased, padded, blank or null — authenticates nothing and cannot sign in.</li>
 * </ul>
 *
 * {@code /api/me} is the probe for "any signed-in account" (it is behind {@code authenticated()}),
 * {@code /api/partner/hotels} for PARTNER authority and {@code /api/admin/activity-logs} for ADMIN.
 * The class is {@code @Transactional}, so every probe account is rolled back.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class AccountSessionSecurityTest {

    private static final String PASSWORD = "Correct-Horse-9";

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired UserRepository users;
    @Autowired PasswordEncoder encoder;
    @Autowired JwtService jwt;
    @Value("${app.jwt.secret}") String jwtSecret;

    // ══════════════════════════════════════════════════════════════════════════
    // S1 — account status
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void anEnabledAccountSignsInAndItsTokenWorks() throws Exception {
        User u = account("USER");
        String token = token(login(u.getEmail(), PASSWORD, 200));
        assertEquals(200, status(get("/api/me"), token));
    }

    @Test
    void aDisabledAccountCannotSignIn() throws Exception {
        User u = account("USER");
        u.setEnabled(false);
        users.saveAndFlush(u);

        JsonNode refused = body(login(u.getEmail(), PASSWORD, 403));
        assertEquals("ACCOUNT_DISABLED", refused.get("code").asText());
        assertFalse(refused.has("token"));

        // Without the password, a disabled account is indistinguishable from any wrong password.
        JsonNode wrong = body(login(u.getEmail(), "Not-The-Password-1", 401));
        assertEquals("INVALID_CREDENTIALS", wrong.get("code").asText());
        assertEquals("Invalid email or password", wrong.get("message").asText());
    }

    @Test
    void aTokenIssuedBeforeTheAccountWasDisabledIsRefused() throws Exception {
        User u = account("PARTNER");
        String token = token(login(u.getEmail(), PASSWORD, 200));
        assertEquals(200, status(get("/api/me"), token));

        u.setEnabled(false);
        users.saveAndFlush(u);

        assertEquals(401, status(get("/api/me"), token));
        assertEquals(401, status(get("/api/partner/hotels"), token));
    }

    // ══════════════════════════════════════════════════════════════════════════
    // S3 — token version
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void aVersionBumpRefusesTheOldTokenAndAFreshTokenWorks() throws Exception {
        User u = account("USER");
        String before = token(login(u.getEmail(), PASSWORD, 200));
        assertEquals(200, status(get("/api/me"), before), "valid before the bump");

        u.setTokenVersion(u.getTokenVersion() + 1);
        users.saveAndFlush(u);

        assertEquals(401, status(get("/api/me"), before), "refused after the bump");
        String after = token(login(u.getEmail(), PASSWORD, 200));
        assertEquals(200, status(get("/api/me"), after), "a token issued at the new version works");
    }

    @Test
    void aDisabledAccountStaysBlockedEvenWithATokenOfTheCurrentVersion() throws Exception {
        User u = account("USER");
        u.setTokenVersion(3);
        u.setEnabled(false);
        users.saveAndFlush(u);

        String current = jwt.createToken(u.getId(), u.getEmail(), 3);
        assertEquals(401, status(get("/api/me"), current));
    }

    @Test
    void aTokenWithoutAVersionClaimIsReadAsVersionZero() throws Exception {
        User u = account("USER");
        String legacy = legacyToken(u.getId(), u.getEmail());
        assertEquals(200, status(get("/api/me"), legacy), "a pre-Phase-A token keeps working at version 0");

        u.setTokenVersion(1);
        users.saveAndFlush(u);
        assertEquals(401, status(get("/api/me"), legacy), "and stops once the version moves");
    }

    @Test
    void aTamperedVersionClaimIsRefused() throws Exception {
        User u = account("USER");
        String token = jwt.createToken(u.getId(), u.getEmail(), 0);
        String[] parts = token.split("\\.");
        String payload = new String(Base64.getUrlDecoder().decode(parts[1]), StandardCharsets.UTF_8)
            .replace("\"ver\":0", "\"ver\":7");
        String forged = parts[0] + "." + b64(payload.getBytes(StandardCharsets.UTF_8)) + "." + parts[2];
        u.setTokenVersion(7);
        users.saveAndFlush(u);
        assertEquals(401, status(get("/api/me"), forged), "the signature no longer matches the payload");
    }

    // ══════════════════════════════════════════════════════════════════════════
    // S4 — fail-closed roles
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void theThreeRolesAuthenticateWithTheirOwnAuthority() throws Exception {
        String user = token(login(account("USER").getEmail(), PASSWORD, 200));
        String partner = token(login(account("PARTNER").getEmail(), PASSWORD, 200));
        String admin = token(login(account("ADMIN").getEmail(), PASSWORD, 200));

        assertEquals(200, status(get("/api/me"), user));
        assertEquals(403, status(get("/api/partner/hotels"), user));
        assertEquals(403, status(get("/api/admin/activity-logs"), user));

        assertEquals(200, status(get("/api/me"), partner));
        // PARTNER passes the URL rule; this probe account has no partner profile, so the service says 404.
        assertEquals(404, status(get("/api/partner/hotels"), partner));
        assertEquals(403, status(get("/api/admin/activity-logs"), partner));

        assertEquals(200, status(get("/api/me"), admin));
        assertEquals(200, status(get("/api/admin/activity-logs"), admin));
    }

    @Test
    void anyOtherStoredRoleAuthenticatesNothingAndCannotSignIn() throws Exception {
        for (String role : Arrays.asList("SUPER_ADMIN", "OWNER", "admin", "User", " USER", "PARTNER ", "", "   ", null)) {
            User u = account(role);
            String label = "role [" + role + "]";

            String token = jwt.createToken(u.getId(), u.getEmail(), u.getTokenVersion());
            assertEquals(401, status(get("/api/me"), token), label + " must not pass authenticated()");
            assertEquals(401, status(get("/api/partner/hotels"), token), label);
            assertEquals(401, status(get("/api/admin/activity-logs"), token), label);

            JsonNode refused = body(login(u.getEmail(), PASSWORD, 403));
            assertEquals("ACCOUNT_UNAVAILABLE", refused.get("code").asText(), label);
            assertFalse(refused.has("token"), label);
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // helpers
    // ══════════════════════════════════════════════════════════════════════════

    private User account(String role) {
        User u = new User();
        u.setFullName("Session Probe");
        u.setEmail("session-" + UUID.randomUUID() + "@test.com");
        u.setPasswordHash(encoder.encode(PASSWORD));
        u.setRole(role);
        u.setEmailVerifiedAt(Instant.now());
        return users.saveAndFlush(u);
    }

    private MvcResult login(String email, String password, int expectedStatus) throws Exception {
        MvcResult result = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(java.util.Map.of("email", email, "password", password))))
            .andReturn();
        assertEquals(expectedStatus, result.getResponse().getStatus(), result.getResponse().getContentAsString());
        return result;
    }

    private String token(MvcResult result) throws Exception {
        return body(result).get("token").asText();
    }

    private JsonNode body(MvcResult result) throws Exception {
        return mapper.readTree(result.getResponse().getContentAsString(StandardCharsets.UTF_8));
    }

    private int status(org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder request,
                       String token) throws Exception {
        return mvc.perform(request.header("Authorization", "Bearer " + token)).andReturn().getResponse().getStatus();
    }

    /** A correctly signed token in the pre-Phase-A shape: sub, email, exp — no version claim. */
    private String legacyToken(Long userId, String email) throws Exception {
        String header = b64("{\"alg\":\"HS256\",\"typ\":\"JWT\"}".getBytes(StandardCharsets.UTF_8));
        long exp = Instant.now().plusSeconds(3600).getEpochSecond();
        String payload = b64(("{\"sub\":\"" + userId + "\",\"email\":\"" + email + "\",\"exp\":" + exp + "}")
            .getBytes(StandardCharsets.UTF_8));
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(jwtSecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        String signature = b64(mac.doFinal((header + "." + payload).getBytes(StandardCharsets.UTF_8)));
        return header + "." + payload + "." + signature;
    }

    private static String b64(byte[] bytes) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
}
