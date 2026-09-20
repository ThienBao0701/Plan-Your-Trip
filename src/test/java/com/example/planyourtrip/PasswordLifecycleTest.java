package com.example.planyourtrip;

import com.example.planyourtrip.config.AuthProperties;
import com.example.planyourtrip.model.AdminActivityLog;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.AdminActivityLogRepository;
import com.example.planyourtrip.repository.UserRepository;
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
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;

/**
 * Phase A — password reset by email link and password change by the signed-in account.
 *
 * <ul>
 *   <li><b>Forgot password</b> answers the same 202 for every address and sends a link only for an enabled
 *       account, to the surface of its role, at most once per cooldown.</li>
 *   <li><b>Reset</b> is one-time and expiring; a newer link retires the older one; success changes the
 *       password and ends every existing session (token version bump).</li>
 *   <li><b>Change</b> requires the current password, takes the account from the session (a body id is
 *       ignored), ends other sessions and returns a fresh token for this one.</li>
 *   <li>An ADMIN change or reset writes one audit row with no credential material.</li>
 * </ul>
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class PasswordLifecycleTest {

    private static final String OLD_PASSWORD = "Old-Password-123";
    private static final String NEW_PASSWORD = "New-Password-456";

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired UserRepository users;
    @Autowired PasswordEncoder encoder;
    @Autowired AuthProperties authProperties;
    @Autowired AdminActivityLogRepository auditRepo;
    @Autowired EntityManager em;
    @MockitoBean EmailSender emailSender;

    @BeforeEach
    void emailDeliveryAvailable() {
        when(emailSender.isAvailable()).thenReturn(true);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // Forgot password
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void forgotPasswordAnswersTheSameForEveryAddressAndSendsOnlyForARealAccount() throws Exception {
        User user = account("USER");
        User disabled = account("USER");
        disabled.setEnabled(false);
        users.saveAndFlush(disabled);
        String unknown = "nobody-" + UUID.randomUUID() + "@test.com";

        String reference = null;
        for (String address : List.of(unknown, disabled.getEmail(), "  " + user.getEmail().toUpperCase() + " ")) {
            MvcResult result = post("/api/auth/forgot-password", Map.of("email", address));
            assertEquals(202, result.getResponse().getStatus(), address);
            String message = json(result).get("message").asText();
            if (reference == null) reference = message;
            assertEquals(reference, message, "identical body for " + address);
        }

        ArgumentCaptor<AccountEmail> sent = ArgumentCaptor.forClass(AccountEmail.class);
        verify(emailSender, times(1)).send(sent.capture());
        assertEquals(user.getEmail(), sent.getValue().to());
        assertEquals(AccountEmail.Kind.PASSWORD_RESET, sent.getValue().kind());
    }

    @Test
    void theResetLinkGoesToTheSurfaceOfTheAccountsRole() throws Exception {
        assertTrue(resetLinkFor(account("USER")).startsWith(authProperties.getUserAppUrl() + "/reset-password#token="));
        assertTrue(resetLinkFor(account("PARTNER")).startsWith(authProperties.getPartnerAppUrl() + "/reset-password#token="));
        assertTrue(resetLinkFor(account("ADMIN")).startsWith(authProperties.getAdminAppUrl() + "/reset-password#token="));
    }

    @Test
    void forgotPasswordWithinTheCooldownSendsNothingMore() throws Exception {
        User user = account("USER");
        post("/api/auth/forgot-password", Map.of("email", user.getEmail()));
        post("/api/auth/forgot-password", Map.of("email", user.getEmail()));
        verify(emailSender, times(1)).send(any());
    }

    @Test
    void withoutEmailDeliveryForgotPasswordIs503ForEveryAddressAlike() throws Exception {
        User user = account("USER");
        when(emailSender.isAvailable()).thenReturn(false);
        for (String address : List.of(user.getEmail(), "nobody-" + UUID.randomUUID() + "@test.com")) {
            MvcResult result = post("/api/auth/forgot-password", Map.of("email", address));
            assertEquals(503, result.getResponse().getStatus());
            assertEquals("EMAIL_DELIVERY_UNAVAILABLE", json(result).get("code").asText());
        }
        verify(emailSender, never()).send(any());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // Reset
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void aValidResetChangesThePasswordAndEndsEverySession() throws Exception {
        User user = account("USER");
        String session = login(user.getEmail(), OLD_PASSWORD, 200);
        assertEquals(200, status(get("/api/me"), session));
        String token = tokenOf(resetLinkFor(user));

        MvcResult reset = post("/api/auth/reset-password", Map.of("token", token, "newPassword", NEW_PASSWORD));
        assertEquals(200, reset.getResponse().getStatus(), reset.getResponse().getContentAsString());
        assertFalse(reset.getResponse().getContentAsString().contains(NEW_PASSWORD));

        assertEquals(401, status(get("/api/me"), session), "a session from before the reset is over");
        login(user.getEmail(), OLD_PASSWORD, 401);
        String fresh = login(user.getEmail(), NEW_PASSWORD, 200);
        assertEquals(200, status(get("/api/me"), fresh));
        assertEquals(1, reload(user).getTokenVersion());
    }

    @Test
    void aResetTokenWorksOnceAndNotAfterItExpires() throws Exception {
        User user = account("USER");
        String token = tokenOf(resetLinkFor(user));
        assertEquals(200, post("/api/auth/reset-password", Map.of("token", token, "newPassword", NEW_PASSWORD))
            .getResponse().getStatus());
        MvcResult replay = post("/api/auth/reset-password", Map.of("token", token, "newPassword", "Another-Pass-789"));
        assertEquals(400, replay.getResponse().getStatus());
        assertEquals("TOKEN_INVALID", json(replay).get("code").asText());
        login(user.getEmail(), NEW_PASSWORD, 200);

        User other = account("USER");
        String expiring = tokenOf(resetLinkFor(other));
        em.flush();
        em.createQuery("UPDATE AuthToken t SET t.expiresAt = :past WHERE t.user.id = :id")
            .setParameter("past", Instant.now().minusSeconds(1)).setParameter("id", other.getId()).executeUpdate();
        em.clear();
        MvcResult expired = post("/api/auth/reset-password", Map.of("token", expiring, "newPassword", NEW_PASSWORD));
        assertEquals(400, expired.getResponse().getStatus());
        assertEquals("TOKEN_EXPIRED", json(expired).get("code").asText());
        login(other.getEmail(), OLD_PASSWORD, 200);
    }

    @Test
    void anInvalidNewPasswordIsRefusedWithoutUsingUpTheLink() throws Exception {
        User user = account("USER");
        String token = tokenOf(resetLinkFor(user));
        MvcResult weak = post("/api/auth/reset-password", Map.of("token", token, "newPassword", "short"));
        assertEquals(400, weak.getResponse().getStatus());
        assertEquals("VALIDATION_FAILED", json(weak).get("code").asText());
        MvcResult tooLong = post("/api/auth/reset-password", Map.of("token", token, "newPassword", "y".repeat(73)));
        assertEquals(400, tooLong.getResponse().getStatus());

        assertEquals(200, post("/api/auth/reset-password", Map.of("token", token, "newPassword", NEW_PASSWORD))
            .getResponse().getStatus(), "the link is still usable after a refused attempt");
    }

    @Test
    void aNewerResetLinkRetiresTheOlderOne() throws Exception {
        User user = account("USER");
        String first = tokenOf(resetLinkFor(user));
        ageTokens(user, authProperties.getTokenIssueCooldown().plusSeconds(60));
        String second = tokenOf(resetLinkFor(user));
        assertNotEquals(first, second);

        MvcResult old = post("/api/auth/reset-password", Map.of("token", first, "newPassword", NEW_PASSWORD));
        assertEquals("TOKEN_INVALID", json(old).get("code").asText());
        assertEquals(200, post("/api/auth/reset-password", Map.of("token", second, "newPassword", NEW_PASSWORD))
            .getResponse().getStatus());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // Change
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void changingThePasswordRequiresASession() throws Exception {
        MvcResult result = mvc.perform(put("/api/me/password")
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(Map.of("currentPassword", OLD_PASSWORD, "newPassword", NEW_PASSWORD))))
            .andReturn();
        assertEquals(401, result.getResponse().getStatus());
    }

    @Test
    void aSuccessfulChangeEndsOtherSessionsAndReturnsAFreshOne() throws Exception {
        User user = account("PARTNER");
        String other = login(user.getEmail(), OLD_PASSWORD, 200);
        String current = login(user.getEmail(), OLD_PASSWORD, 200);

        MvcResult changed = change(current, OLD_PASSWORD, NEW_PASSWORD);
        assertEquals(200, changed.getResponse().getStatus(), changed.getResponse().getContentAsString());
        String raw = changed.getResponse().getContentAsString();
        assertFalse(raw.contains(NEW_PASSWORD) || raw.contains(OLD_PASSWORD));
        String fresh = json(changed).get("token").asText();

        assertEquals(401, status(get("/api/me"), other), "another session ended");
        assertEquals(401, status(get("/api/me"), current), "the token used for the change is replaced too");
        assertEquals(200, status(get("/api/me"), fresh), "the returned token continues this session");
        login(user.getEmail(), OLD_PASSWORD, 401);
        login(user.getEmail(), NEW_PASSWORD, 200);
        assertEquals(1, reload(user).getTokenVersion());
    }

    @Test
    void aWrongCurrentPasswordOrAnUnchangedPasswordIsRefused() throws Exception {
        User user = account("USER");
        String session = login(user.getEmail(), OLD_PASSWORD, 200);

        MvcResult wrong = change(session, "Not-The-Old-1", NEW_PASSWORD);
        assertEquals(400, wrong.getResponse().getStatus());
        JsonNode body = json(wrong);
        assertEquals("CURRENT_PASSWORD_INCORRECT", body.get("code").asText());
        assertEquals("currentPassword", body.get("fieldErrors").get(0).get("field").asText());

        MvcResult same = change(session, OLD_PASSWORD, OLD_PASSWORD);
        assertEquals("PASSWORD_UNCHANGED", json(same).get("code").asText());

        MvcResult weak = change(session, OLD_PASSWORD, "short");
        assertEquals("VALIDATION_FAILED", json(weak).get("code").asText());

        assertEquals(200, status(get("/api/me"), session), "nothing changed, the session is intact");
        assertEquals(0, reload(user).getTokenVersion());
    }

    @Test
    void theAccountComesFromTheSessionNotTheBody() throws Exception {
        User caller = account("USER");
        User victim = account("USER");
        String session = login(caller.getEmail(), OLD_PASSWORD, 200);

        MvcResult result = mvc.perform(put("/api/me/password")
                .header("Authorization", "Bearer " + session)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(Map.of(
                    "userId", victim.getId(), "email", victim.getEmail(),
                    "currentPassword", OLD_PASSWORD, "newPassword", NEW_PASSWORD))))
            .andReturn();
        assertEquals(200, result.getResponse().getStatus());

        login(caller.getEmail(), NEW_PASSWORD, 200);
        login(victim.getEmail(), OLD_PASSWORD, 200);
        assertEquals(0, reload(victim).getTokenVersion());
    }

    @Test
    void changingThePasswordRetiresAnOutstandingResetLink() throws Exception {
        User user = account("USER");
        String resetToken = tokenOf(resetLinkFor(user));
        String session = login(user.getEmail(), OLD_PASSWORD, 200);
        assertEquals(200, change(session, OLD_PASSWORD, NEW_PASSWORD).getResponse().getStatus());

        MvcResult stale = post("/api/auth/reset-password", Map.of("token", resetToken, "newPassword", "Third-Pass-999"));
        assertEquals("TOKEN_INVALID", json(stale).get("code").asText());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // Admin audit
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void anAdminChangeAndResetAreEachAuditedOnceWithoutSecrets() throws Exception {
        User admin = account("ADMIN");
        String session = login(admin.getEmail(), OLD_PASSWORD, 200);
        assertEquals(200, change(session, OLD_PASSWORD, NEW_PASSWORD).getResponse().getStatus());
        List<AdminActivityLog> changes = audit(admin, "ADMIN_PASSWORD_CHANGE");
        assertEquals(1, changes.size());

        String token = tokenOf(resetLinkFor(admin));
        assertEquals(200, post("/api/auth/reset-password", Map.of("token", token, "newPassword", "Reset-Pass-789"))
            .getResponse().getStatus());
        List<AdminActivityLog> resets = audit(admin, "ADMIN_PASSWORD_RESET");
        assertEquals(1, resets.size());

        for (AdminActivityLog row : List.of(changes.get(0), resets.get(0))) {
            assertEquals(admin.getId(), row.getActorUserId());
            assertEquals("USER", row.getTargetType());
            assertEquals(admin.getId(), row.getTargetId());
            String text = row.getDescription() + " " + row.getBeforeState() + " " + row.getAfterState();
            for (String secret : List.of(OLD_PASSWORD, NEW_PASSWORD, "Reset-Pass-789", token, session)) {
                assertFalse(text.contains(secret), "audit row must not contain credential material");
            }
        }
    }

    @Test
    void aNonAdminChangeOrResetWritesNoAuditRow() throws Exception {
        User user = account("PARTNER");
        long before = auditRepo.count();
        String session = login(user.getEmail(), OLD_PASSWORD, 200);
        assertEquals(200, change(session, OLD_PASSWORD, NEW_PASSWORD).getResponse().getStatus());
        String token = tokenOf(resetLinkFor(user));
        assertEquals(200, post("/api/auth/reset-password", Map.of("token", token, "newPassword", "Reset-Pass-789"))
            .getResponse().getStatus());
        assertEquals(before, auditRepo.count());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // helpers
    // ══════════════════════════════════════════════════════════════════════════

    private User account(String role) {
        User u = new User();
        u.setFullName("Password Probe");
        u.setEmail("pw-" + UUID.randomUUID() + "@test.com");
        u.setPasswordHash(encoder.encode(OLD_PASSWORD));
        u.setRole(role);
        u.setEmailVerifiedAt(Instant.now());
        return users.saveAndFlush(u);
    }

    private User reload(User user) {
        em.flush();
        em.clear();
        return users.findById(user.getId()).orElseThrow();
    }

    /** Requests a reset for {@code user} and returns the link that would have been emailed. */
    private String resetLinkFor(User user) throws Exception {
        clearInvocations(emailSender);
        assertEquals(202, post("/api/auth/forgot-password", Map.of("email", user.getEmail())).getResponse().getStatus());
        ArgumentCaptor<AccountEmail> sent = ArgumentCaptor.forClass(AccountEmail.class);
        verify(emailSender, times(1)).send(sent.capture());
        return sent.getValue().actionUrl();
    }

    private static String tokenOf(String link) {
        return link.substring(link.indexOf("#token=") + "#token=".length());
    }

    private MvcResult post(String path, Map<String, ?> body) throws Exception {
        return mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post(path)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(body)))
            .andReturn();
    }

    private MvcResult change(String session, String current, String next) throws Exception {
        return mvc.perform(put("/api/me/password")
                .header("Authorization", "Bearer " + session)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(Map.of("currentPassword", current, "newPassword", next))))
            .andReturn();
    }

    private String login(String email, String password, int expectedStatus) throws Exception {
        MvcResult result = post("/api/auth/login", Map.of("email", email, "password", password));
        assertEquals(expectedStatus, result.getResponse().getStatus(), result.getResponse().getContentAsString());
        return expectedStatus == 200 ? json(result).get("token").asText() : null;
    }

    private int status(MockHttpServletRequestBuilder request, String token) throws Exception {
        return mvc.perform(request.header("Authorization", "Bearer " + token)).andReturn().getResponse().getStatus();
    }

    private JsonNode json(MvcResult result) throws Exception {
        return mapper.readTree(result.getResponse().getContentAsString(StandardCharsets.UTF_8));
    }

    private List<AdminActivityLog> audit(User actor, String action) {
        return auditRepo.search(actor.getId(), action, null, null, null, null, PageRequest.of(0, 50)).getContent();
    }

    private void ageTokens(User user, Duration age) {
        em.flush();
        em.createNativeQuery("UPDATE auth_tokens SET created_at = ? WHERE user_id = ?")
            .setParameter(1, OffsetDateTime.now(ZoneOffset.UTC).minus(age))
            .setParameter(2, user.getId())
            .executeUpdate();
        em.clear();
    }
}
