package com.example.planyourtrip;

import com.example.planyourtrip.config.AuthProperties;
import com.example.planyourtrip.model.AuthToken;
import com.example.planyourtrip.model.AuthTokenPurpose;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.AuthTokenRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.service.AuthTokenService;
import com.example.planyourtrip.service.mail.AccountEmail;
import com.example.planyourtrip.service.mail.EmailSender;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;

/**
 * Phase A — email verification of self-registered Partners, and the one-time token model behind it.
 *
 * <ul>
 *   <li>Tokens are stored only as a SHA-256 hash; the raw value is in the (mocked) email link, in its
 *       fragment, pointing at the Partner surface.</li>
 *   <li>A valid token verifies once and the Partner can then sign in. Invalid, expired, replayed,
 *       superseded and wrong-purpose tokens are 400 and verify nothing.</li>
 *   <li>Resend is generic (same 202 for every address), issues nothing within the cooldown, and a new
 *       token retires the previous one. Without email delivery it is 503 for every address alike.</li>
 * </ul>
 *
 * Nothing is delivered: {@link EmailSender} is mocked and captured.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class EmailVerificationTest {

    private static final String PASSWORD = "Verify-Me-123";

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired UserRepository users;
    @Autowired AuthTokenRepository tokens;
    @Autowired AuthTokenService tokenService;
    @Autowired AuthProperties authProperties;
    @Autowired PasswordEncoder encoder;
    @Autowired EntityManager em;
    @MockitoBean EmailSender emailSender;

    @BeforeEach
    void emailDeliveryAvailable() {
        when(emailSender.isAvailable()).thenReturn(true);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // Token model
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void theTokenIsStoredOnlyAsItsHashAndTheLinkCarriesItInTheFragment() throws Exception {
        String email = registerPartner();
        AccountEmail sent = lastEmail();
        assertTrue(sent.actionUrl().startsWith(authProperties.getPartnerAppUrl() + "/verify-email#token="));
        String raw = tokenOf(sent);
        assertTrue(raw.length() >= 43, "256 bits of randomness, base64url");

        User user = users.findByEmail(email).orElseThrow();
        List<AuthToken> stored = tokensOf(user, AuthTokenPurpose.EMAIL_VERIFICATION);
        assertEquals(1, stored.size());
        AuthToken token = stored.get(0);
        assertEquals(sha256(raw), token.getTokenHash());
        assertNotEquals(raw, token.getTokenHash());
        assertNull(token.getConsumedAt());
        Duration ttl = Duration.between(token.getCreatedAt(), token.getExpiresAt());
        assertEquals(authProperties.getVerificationTokenTtl(), ttl);
    }

    @Test
    void aValidTokenVerifiesOnceAndThePartnerCanThenSignIn() throws Exception {
        String email = registerPartner();
        String raw = tokenOf(lastEmail());
        loginStatus(email, 403);

        JsonNode verified = verifyToken(raw, 200);
        assertEquals("VERIFIED", verified.get("status").asText());
        User user = users.findByEmail(email).orElseThrow();
        assertNotNull(user.getEmailVerifiedAt());
        assertNotNull(tokensOf(user, AuthTokenPurpose.EMAIL_VERIFICATION).get(0).getConsumedAt());

        JsonNode session = mapper.readTree(loginStatus(email, 200));
        assertEquals("PARTNER", session.get("user").get("role").asText());

        JsonNode replay = verifyToken(raw, 400);
        assertEquals("TOKEN_INVALID", replay.get("code").asText(), "a token works once");
    }

    @Test
    void anUnknownTokenIsInvalidAndABlankOneIsAValidationError() throws Exception {
        assertEquals("TOKEN_INVALID", verifyToken("not-a-real-token-" + UUID.randomUUID(), 400).get("code").asText());
        assertEquals("VALIDATION_FAILED", verifyToken("   ", 400).get("code").asText());
        assertEquals("VALIDATION_FAILED", verifyToken("x".repeat(129), 400).get("code").asText());
    }

    @Test
    void anExpiredTokenIsRefusedAndVerifiesNothing() throws Exception {
        String email = registerPartner();
        String raw = tokenOf(lastEmail());
        User user = users.findByEmail(email).orElseThrow();
        em.flush();
        em.createQuery("UPDATE AuthToken t SET t.expiresAt = :past WHERE t.user.id = :id")
            .setParameter("past", Instant.now().minusSeconds(1))
            .setParameter("id", user.getId())
            .executeUpdate();
        em.clear();

        assertEquals("TOKEN_EXPIRED", verifyToken(raw, 400).get("code").asText());
        assertNull(users.findById(user.getId()).orElseThrow().getEmailVerifiedAt());
        loginStatus(email, 403);
    }

    @Test
    void aTokenForAnotherPurposeIsInvalid() throws Exception {
        String email = registerPartner();
        User user = users.findByEmail(email).orElseThrow();
        String resetToken = tokenService.issue(user, AuthTokenPurpose.PASSWORD_RESET, Duration.ofMinutes(30))
            .orElseThrow().rawToken();

        assertEquals("TOKEN_INVALID", verifyToken(resetToken, 400).get("code").asText());
        assertNull(users.findById(user.getId()).orElseThrow().getEmailVerifiedAt());
    }

    @Test
    void anAlreadyVerifiedAccountIsHandledSafely() throws Exception {
        User verified = account("PARTNER", true);
        String raw = tokenService.issue(verified, AuthTokenPurpose.EMAIL_VERIFICATION, Duration.ofHours(1))
            .orElseThrow().rawToken();
        Instant before = users.findById(verified.getId()).orElseThrow().getEmailVerifiedAt();

        assertEquals("ALREADY_VERIFIED", verifyToken(raw, 200).get("status").asText());
        assertEquals(before, users.findById(verified.getId()).orElseThrow().getEmailVerifiedAt(),
            "the original verification time is kept");

        clearInvocations(emailSender);
        assertEquals(202, resend(verified.getEmail()).getResponse().getStatus());
        verify(emailSender, never()).send(any());
    }

    @Test
    void aDisabledAccountsTokenIsInvalid() throws Exception {
        String email = registerPartner();
        String raw = tokenOf(lastEmail());
        User user = users.findByEmail(email).orElseThrow();
        user.setEnabled(false);
        users.saveAndFlush(user);

        assertEquals("TOKEN_INVALID", verifyToken(raw, 400).get("code").asText());
        assertNull(users.findById(user.getId()).orElseThrow().getEmailVerifiedAt());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // Resend and cooldown
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void resendWithinTheCooldownIssuesNothing() throws Exception {
        String email = registerPartner();
        User user = users.findByEmail(email).orElseThrow();
        clearInvocations(emailSender);

        assertEquals(202, resend(email).getResponse().getStatus());
        assertEquals(202, resend(email).getResponse().getStatus());

        verify(emailSender, never()).send(any());
        assertEquals(1, tokensOf(user, AuthTokenPurpose.EMAIL_VERIFICATION).size());
    }

    @Test
    void afterTheCooldownResendIssuesANewTokenAndRetiresThePreviousOne() throws Exception {
        String email = registerPartner();
        String first = tokenOf(lastEmail());
        User user = users.findByEmail(email).orElseThrow();
        ageTokens(user, authProperties.getTokenIssueCooldown().plusSeconds(60));
        clearInvocations(emailSender);

        assertEquals(202, resend(email).getResponse().getStatus());
        String second = tokenOf(lastEmail());
        assertNotEquals(first, second);

        List<AuthToken> stored = tokensOf(user, AuthTokenPurpose.EMAIL_VERIFICATION);
        assertEquals(2, stored.size());
        assertEquals(1, stored.stream().filter(t -> t.getConsumedAt() == null).count(), "one active token");

        assertEquals("TOKEN_INVALID", verifyToken(first, 400).get("code").asText(), "the previous link no longer works");
        assertEquals("VERIFIED", verifyToken(second, 200).get("status").asText());
    }

    @Test
    void resendAnswersTheSameForEveryAddress() throws Exception {
        String pending = registerPartner();
        ageTokens(users.findByEmail(pending).orElseThrow(), Duration.ofHours(1));
        String traveller = account("USER", false).getEmail();
        String verifiedPartner = account("PARTNER", true).getEmail();
        String unknown = "nobody-" + UUID.randomUUID() + "@test.com";
        clearInvocations(emailSender);

        String reference = null;
        for (String address : List.of(unknown, traveller, verifiedPartner, pending)) {
            MvcResult result = resend(address);
            assertEquals(202, result.getResponse().getStatus(), address);
            String message = mapper.readTree(result.getResponse().getContentAsString()).get("message").asText();
            if (reference == null) reference = message;
            assertEquals(reference, message, "identical body for " + address);
        }

        ArgumentCaptor<AccountEmail> sent = ArgumentCaptor.forClass(AccountEmail.class);
        verify(emailSender, times(1)).send(sent.capture());
        assertEquals(pending, sent.getValue().to(), "only the account waiting for verification gets a link");
    }

    @Test
    void withoutEmailDeliveryResendIs503ForEveryAddressAlike() throws Exception {
        String pending = registerPartner();
        when(emailSender.isAvailable()).thenReturn(false);
        for (String address : List.of(pending, "nobody-" + UUID.randomUUID() + "@test.com")) {
            MvcResult result = resend(address);
            assertEquals(503, result.getResponse().getStatus(), address);
            assertEquals("EMAIL_DELIVERY_UNAVAILABLE",
                mapper.readTree(result.getResponse().getContentAsString()).get("code").asText());
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // helpers
    // ══════════════════════════════════════════════════════════════════════════

    private String registerPartner() throws Exception {
        String email = "verify-" + UUID.randomUUID() + "@test.com";
        MvcResult result = mvc.perform(post("/api/auth/partner/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(Map.of(
                    "fullName", "Verify Partner", "email", email, "password", PASSWORD, "acceptTerms", true))))
            .andReturn();
        assertEquals(201, result.getResponse().getStatus(), result.getResponse().getContentAsString());
        return email;
    }

    private User account(String role, boolean verified) {
        User u = new User();
        u.setFullName("Verification Probe");
        u.setEmail("verify-probe-" + UUID.randomUUID() + "@test.com");
        u.setPasswordHash(encoder.encode(PASSWORD));
        u.setRole(role);
        u.setEmailVerificationRequired("PARTNER".equals(role));
        if (verified) u.setEmailVerifiedAt(Instant.now().minusSeconds(3600));
        return users.saveAndFlush(u);
    }

    private AccountEmail lastEmail() {
        ArgumentCaptor<AccountEmail> captor = ArgumentCaptor.forClass(AccountEmail.class);
        verify(emailSender, atLeastOnce()).send(captor.capture());
        List<AccountEmail> all = captor.getAllValues();
        return all.get(all.size() - 1);
    }

    private static String tokenOf(AccountEmail email) {
        String url = email.actionUrl();
        return url.substring(url.indexOf("#token=") + "#token=".length());
    }

    private JsonNode verifyToken(String token, int expectedStatus) throws Exception {
        MvcResult result = mvc.perform(post("/api/auth/verify-email")
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(Map.of("token", token))))
            .andReturn();
        assertEquals(expectedStatus, result.getResponse().getStatus(), result.getResponse().getContentAsString());
        return mapper.readTree(result.getResponse().getContentAsString(StandardCharsets.UTF_8));
    }

    private MvcResult resend(String email) throws Exception {
        return mvc.perform(post("/api/auth/resend-verification")
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(Map.of("email", email))))
            .andReturn();
    }

    private String loginStatus(String email, int expectedStatus) throws Exception {
        MvcResult result = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(Map.of("email", email, "password", PASSWORD))))
            .andReturn();
        String body = result.getResponse().getContentAsString(StandardCharsets.UTF_8);
        assertEquals(expectedStatus, result.getResponse().getStatus(), body);
        return body;
    }

    private List<AuthToken> tokensOf(User user, AuthTokenPurpose purpose) {
        em.flush();
        em.clear();
        return tokens.findAll().stream()
            .filter(t -> t.getUser().getId().equals(user.getId()) && t.getPurpose() == purpose)
            .toList();
    }

    /** Moves every token of the account back in time, as if issued {@code age} ago. */
    private void ageTokens(User user, Duration age) {
        em.flush();
        em.createNativeQuery("UPDATE auth_tokens SET created_at = ? WHERE user_id = ?")
            .setParameter(1, OffsetDateTime.now(ZoneOffset.UTC).minus(age))
            .setParameter(2, user.getId())
            .executeUpdate();
        em.clear();
    }

    private static String sha256(String raw) throws Exception {
        return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(raw.getBytes(StandardCharsets.UTF_8)));
    }
}
