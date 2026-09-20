package com.example.planyourtrip;

import com.example.planyourtrip.config.AuthProperties;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.service.mail.AccountEmail;
import com.example.planyourtrip.service.mail.EmailSender;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;

/**
 * Phase A — registration (S5) and Partner registration.
 *
 * <p><b>Traveller</b> ({@code POST /api/auth/register}) keeps its V1 behaviour — a USER account signed in
 * immediately — but every malformed input is a 400 with {@code fieldErrors}, never a 500: a null password,
 * one BCrypt cannot hash (over 72 bytes), an unbounded name or address. Emails are trimmed and lowercased.
 * A duplicate is 409, including one that races past the pre-check into the unique index.
 *
 * <p><b>Partner</b> ({@code POST /api/auth/partner/register}) creates a PARTNER account whatever the body
 * says, records explicit terms acceptance and the configured terms version, sends one verification link,
 * returns no session, and cannot sign in until verified.
 *
 * <p>{@link EmailSender} is mocked so the link can be inspected; nothing is delivered in any test.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class AccountRegistrationTest {

    private static final String PASSWORD = "Valid-Pass-123";

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PasswordEncoder encoder;
    @Autowired AuthProperties authProperties;
    @MockitoSpyBean UserRepository users;
    @MockitoBean EmailSender emailSender;

    @BeforeEach
    void emailDeliveryAvailable() {
        when(emailSender.isAvailable()).thenReturn(true);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // Traveller registration
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void aValidTravellerRegistrationStillCreatesAUserAndSignsIn() throws Exception {
        String email = unique();
        MvcResult result = register("/api/auth/register", fields("  Ana Traveller  ", email, PASSWORD), 201);
        String raw = result.getResponse().getContentAsString(StandardCharsets.UTF_8);
        JsonNode body = mapper.readTree(raw);

        assertFalse(body.get("token").asText().isBlank());
        assertEquals("USER", body.get("user").get("role").asText());
        assertEquals("Ana Traveller", body.get("user").get("fullName").asText(), "name is trimmed");
        assertFalse(raw.contains(PASSWORD), "the password never appears in the response");
        assertFalse(raw.toLowerCase().contains("password"), "no password or hash field in the response");

        User stored = users.findByEmail(email).orElseThrow();
        assertEquals("USER", stored.getRole());
        assertNotEquals(PASSWORD, stored.getPasswordHash());
        assertTrue(encoder.matches(PASSWORD, stored.getPasswordHash()));
        assertFalse(stored.isEmailVerificationRequired(), "traveller sign-in is not gated on verification");
        verify(emailSender, never()).send(any());

        assertEquals(200, mvc.perform(get("/api/me").header("Authorization", "Bearer " + body.get("token").asText()))
            .andReturn().getResponse().getStatus());
    }

    @Test
    void emailIsTrimmedAndLowercasedAndSignInFollowsTheSameRule() throws Exception {
        String local = "Mixed.Case-" + UUID.randomUUID();
        register("/api/auth/register", fields("Case Probe", "   " + local + "@Example.COM  ", PASSWORD), 201);

        String canonical = (local + "@example.com").toLowerCase();
        assertTrue(users.findByEmail(canonical).isPresent(), "stored trimmed and lowercased");

        loginStatus("  " + local.toUpperCase() + "@EXAMPLE.com ", PASSWORD, 200);
    }

    @Test
    void passwordPolicyIsA400NeverA500() throws Exception {
        Map<String, Object> missing = fields("No Password", unique(), null);
        missing.remove("password");
        assertFieldError(register("/api/auth/register", missing, 400), "password", "is required");
        assertFieldError(register("/api/auth/register", fields("Null Password", unique(), null), 400),
            "password", "is required");
        assertFieldError(register("/api/auth/register", fields("Short", unique(), "Seven77"), 400),
            "password", "must be at least 8 characters");
        assertFieldError(register("/api/auth/register", fields("Long", unique(), "a".repeat(73)), 400),
            "password", "must be at most 72 bytes");
        // 37 characters, 74 bytes of UTF-8: the limit is BCrypt's, in bytes.
        assertFieldError(register("/api/auth/register", fields("Multibyte", unique(), "é".repeat(37)), 400),
            "password", "must be at most 72 bytes");

        register("/api/auth/register", fields("Exactly 72", unique(), "b".repeat(72)), 201);
        register("/api/auth/register", fields("Exactly 8", unique(), "c".repeat(8)), 201);
    }

    @Test
    void emailAndNameAreValidatedAndBounded() throws Exception {
        assertFieldError(register("/api/auth/register", fields("Null Email", null, PASSWORD), 400), "email", null);
        assertFieldError(register("/api/auth/register", fields("Blank Email", "   ", PASSWORD), 400), "email", null);
        assertFieldError(register("/api/auth/register", fields("Bad Email", "not-an-email", PASSWORD), 400), "email", null);
        String tooLong = "x".repeat(250) + "@t.io";
        assertFieldError(register("/api/auth/register", fields("Long Email", tooLong, PASSWORD), 400), "email", null);

        assertFieldError(register("/api/auth/register", fields("   ", unique(), PASSWORD), 400), "fullName", null);
        assertFieldError(register("/api/auth/register", fields("n".repeat(121), unique(), PASSWORD), 400), "fullName", null);
        register("/api/auth/register", fields("n".repeat(120), unique(), PASSWORD), 201);
    }

    @Test
    void signInWithAnOverlongPasswordIsAPlain401() throws Exception {
        String email = unique();
        register("/api/auth/register", fields("Login Probe", email, PASSWORD), 201);
        loginStatus(email, "z".repeat(200), 401);
    }

    @Test
    void aDuplicateEmailIs409InAnyCase() throws Exception {
        String email = unique();
        register("/api/auth/register", fields("First", email, PASSWORD), 201);

        JsonNode again = body(register("/api/auth/register", fields("Second", email, PASSWORD), 409));
        assertEquals("EMAIL_ALREADY_REGISTERED", again.get("code").asText());
        body(register("/api/auth/register", fields("Third", "  " + email.toUpperCase() + " ", PASSWORD), 409));
        assertEquals(1, users.findAll().stream().filter(u -> email.equals(u.getEmail())).count());
    }

    @Test
    void aDuplicateThatRacesPastThePreCheckIsStill409() throws Exception {
        String email = unique();
        register("/api/auth/register", fields("Winner", email, PASSWORD), 201);

        // Simulate the race: the pre-check sees no account, so the insert reaches the unique index.
        doReturn(false).when(users).existsByEmail(email);
        clearInvocations(users);

        JsonNode loser = body(register("/api/auth/register", fields("Loser", email, PASSWORD), 409));
        assertEquals("EMAIL_ALREADY_REGISTERED", loser.get("code").asText());
        assertEquals("Email already registered", loser.get("message").asText());
        // Proof the 409 came from the unique index, not from the pre-check.
        verify(users).existsByEmail(email);
        verify(users).saveAndFlush(any(User.class));
    }

    @Test
    void aRoleInTheRequestBodyIsIgnored() throws Exception {
        String email = unique();
        Map<String, Object> body = fields("Would-be Admin", email, PASSWORD);
        body.put("role", "ADMIN");
        JsonNode created = body(register("/api/auth/register", body, 201));
        assertEquals("USER", created.get("user").get("role").asText());
        assertEquals("USER", users.findByEmail(email).orElseThrow().getRole());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // Partner registration
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void aValidPartnerRegistrationCreatesAnUnverifiedPartnerWithTermsAndNoSession() throws Exception {
        String email = unique();
        MvcResult result = register("/api/auth/partner/register", partner("  Pat Partner ", email, PASSWORD, true), 201);
        String raw = result.getResponse().getContentAsString(StandardCharsets.UTF_8);
        JsonNode body = mapper.readTree(raw);

        assertEquals(email, body.get("email").asText());
        assertEquals("PENDING_VERIFICATION", body.get("status").asText());
        assertTrue(body.get("verificationRequired").asBoolean());
        assertFalse(body.has("token"), "no session before verification");
        assertFalse(raw.contains(PASSWORD));

        User stored = users.findByEmail(email).orElseThrow();
        assertEquals("PARTNER", stored.getRole());
        assertEquals("Pat Partner", stored.getFullName());
        assertTrue(stored.isEmailVerificationRequired());
        assertNull(stored.getEmailVerifiedAt());
        assertNotNull(stored.getTermsAcceptedAt());
        assertEquals(authProperties.getPartnerTermsVersion(), stored.getTermsVersion());
        assertTrue(encoder.matches(PASSWORD, stored.getPasswordHash()));

        ArgumentCaptor<AccountEmail> sent = ArgumentCaptor.forClass(AccountEmail.class);
        verify(emailSender, times(1)).send(sent.capture());
        assertEquals(email, sent.getValue().to());
        assertEquals(AccountEmail.Kind.EMAIL_VERIFICATION, sent.getValue().kind());
        assertTrue(sent.getValue().actionUrl().startsWith(authProperties.getPartnerAppUrl() + "/verify-email#token="),
            sent.getValue().actionUrl());
    }

    @Test
    void anUnverifiedPartnerCannotSignIn() throws Exception {
        String email = unique();
        register("/api/auth/partner/register", partner("Unverified", email, PASSWORD, true), 201);

        JsonNode refused = mapper.readTree(loginStatus(email, PASSWORD, 403));
        assertEquals("EMAIL_NOT_VERIFIED", refused.get("code").asText());
        assertFalse(refused.has("token"));

        JsonNode wrong = mapper.readTree(loginStatus(email, "Wrong-Pass-123", 401));
        assertEquals("INVALID_CREDENTIALS", wrong.get("code").asText(), "without the password nothing is revealed");
    }

    @Test
    void aRoleInThePartnerBodyIsIgnored() throws Exception {
        String email = unique();
        Map<String, Object> body = partner("Would-be Admin", email, PASSWORD, true);
        body.put("role", "ADMIN");
        register("/api/auth/partner/register", body, 201);
        assertEquals("PARTNER", users.findByEmail(email).orElseThrow().getRole());
    }

    @Test
    void termsMustBeExplicitlyAccepted() throws Exception {
        Map<String, Object> absent = partner("No Terms", unique(), PASSWORD, null);
        absent.remove("acceptTerms");
        assertFieldError(register("/api/auth/partner/register", absent, 400), "acceptTerms", null);
        assertFieldError(register("/api/auth/partner/register", partner("Null Terms", unique(), PASSWORD, null), 400),
            "acceptTerms", null);
        String declined = unique();
        assertFieldError(register("/api/auth/partner/register", partner("Declined", declined, PASSWORD, false), 400),
            "acceptTerms", "must be accepted");
        assertTrue(users.findByEmail(declined).isEmpty(), "nothing is created without acceptance");
        verify(emailSender, never()).send(any());
    }

    @Test
    void partnerRegistrationAppliesTheSameInputRules() throws Exception {
        assertFieldError(register("/api/auth/partner/register", partner("P", unique(), "a".repeat(73), true), 400),
            "password", "must be at most 72 bytes");
        assertFieldError(register("/api/auth/partner/register", partner("P", unique(), null, true), 400),
            "password", "is required");
        assertFieldError(register("/api/auth/partner/register", partner("P", "bad", PASSWORD, true), 400), "email", null);

        String taken = unique();
        register("/api/auth/register", fields("Traveller First", taken, PASSWORD), 201);
        JsonNode dup = body(register("/api/auth/partner/register", partner("Partner Second", taken, PASSWORD, true), 409));
        assertEquals("EMAIL_ALREADY_REGISTERED", dup.get("code").asText());
        assertEquals("USER", users.findByEmail(taken).orElseThrow().getRole(), "the existing account is untouched");
        verify(emailSender, never()).send(any());
    }

    @Test
    void withoutEmailDeliveryPartnerRegistrationIs503AndCreatesNothing() throws Exception {
        when(emailSender.isAvailable()).thenReturn(false);
        String email = unique();
        JsonNode body = body(register("/api/auth/partner/register", partner("No Mail", email, PASSWORD, true), 503));
        assertEquals("EMAIL_DELIVERY_UNAVAILABLE", body.get("code").asText());
        assertTrue(users.findByEmail(email).isEmpty());
        verify(emailSender, never()).send(any());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // helpers
    // ══════════════════════════════════════════════════════════════════════════

    private static String unique() {
        return "reg-" + UUID.randomUUID() + "@test.com";
    }

    private static Map<String, Object> fields(String fullName, String email, String password) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("fullName", fullName);
        m.put("email", email);
        m.put("password", password);
        return m;
    }

    private static Map<String, Object> partner(String fullName, String email, String password, Boolean acceptTerms) {
        Map<String, Object> m = fields(fullName, email, password);
        m.put("acceptTerms", acceptTerms);
        return m;
    }

    private MvcResult register(String path, Map<String, Object> body, int expectedStatus) throws Exception {
        MvcResult result = mvc.perform(post(path)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(body)))
            .andReturn();
        assertEquals(expectedStatus, result.getResponse().getStatus(),
            path + " " + body.keySet() + " -> " + result.getResponse().getContentAsString());
        return result;
    }

    private String loginStatus(String email, String password, int expectedStatus) throws Exception {
        MvcResult result = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(Map.of("email", email, "password", password))))
            .andReturn();
        String body = result.getResponse().getContentAsString(StandardCharsets.UTF_8);
        assertEquals(expectedStatus, result.getResponse().getStatus(), body);
        return body;
    }

    private JsonNode body(MvcResult result) throws Exception {
        return mapper.readTree(result.getResponse().getContentAsString(StandardCharsets.UTF_8));
    }

    /** A 400 whose {@code fieldErrors} names {@code field} (and, when given, with exactly that reason). */
    private void assertFieldError(MvcResult result, String field, String reason) throws Exception {
        JsonNode body = body(result);
        assertEquals("VALIDATION_FAILED", body.get("code").asText(), body.toString());
        boolean found = false;
        for (JsonNode error : body.get("fieldErrors")) {
            if (field.equals(error.get("field").asText())
                    && (reason == null || reason.equals(error.get("message").asText()))) {
                found = true;
            }
        }
        assertTrue(found, "expected " + field + (reason == null ? "" : " '" + reason + "'") + " in " + body);
        assertFalse(body.toString().contains(PASSWORD), "input is never echoed back");
    }
}
