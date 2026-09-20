package com.example.planyourtrip;

import com.example.planyourtrip.model.AdminActivityLog;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.AdminActivityLogRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

/**
 * Phase A — Admin sign-in is recorded in the administrative audit trail.
 *
 * <p>Privacy rule: a refused sign-in is recorded only when the address belongs to an ADMIN account. An
 * unknown address, or a traveller or Partner account, leaves no row — the trail never becomes a log of
 * addresses someone tried. No row contains a password or a token.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class AdminAuthAuditTest {

    private static final String PASSWORD = "Admin-Audit-123";

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired UserRepository users;
    @Autowired PasswordEncoder encoder;
    @Autowired AdminActivityLogRepository auditRepo;

    @Test
    void aSuccessfulAdminSignInIsRecordedOnceWithoutSecrets() throws Exception {
        User admin = account("ADMIN");
        MvcResult result = login(admin.getEmail(), PASSWORD, 200);
        String token = mapper.readTree(result.getResponse().getContentAsString()).get("token").asText();

        List<AdminActivityLog> rows = rows(admin, "ADMIN_LOGIN_SUCCESS");
        assertEquals(1, rows.size());
        AdminActivityLog row = rows.get(0);
        assertEquals(admin.getId(), row.getActorUserId());
        assertEquals(admin.getEmail(), row.getActorEmail());
        assertEquals("USER", row.getTargetType());
        assertEquals(admin.getId(), row.getTargetId());
        assertNoSecrets(row, PASSWORD, token);
    }

    @Test
    void aRefusedAdminSignInIsRecorded() throws Exception {
        User admin = account("ADMIN");
        login(admin.getEmail(), "Wrong-Pass-000", 401);

        List<AdminActivityLog> rows = rows(admin, "ADMIN_LOGIN_FAILED");
        assertEquals(1, rows.size());
        assertNoSecrets(rows.get(0), PASSWORD, "Wrong-Pass-000");
        assertTrue(rows(admin, "ADMIN_LOGIN_SUCCESS").isEmpty());

        admin.setEnabled(false);
        users.saveAndFlush(admin);
        login(admin.getEmail(), PASSWORD, 403);
        assertEquals(2, rows(admin, "ADMIN_LOGIN_FAILED").size(), "a disabled admin's attempt is recorded too");
    }

    @Test
    void unknownAddressesAndNonAdminAccountsLeaveNoRow() throws Exception {
        User traveller = account("USER");
        User partner = account("PARTNER");
        long before = auditRepo.count();

        login("nobody-" + UUID.randomUUID() + "@test.com", PASSWORD, 401);
        login(traveller.getEmail(), "Wrong-Pass-000", 401);
        login(partner.getEmail(), "Wrong-Pass-000", 401);
        login(traveller.getEmail(), PASSWORD, 200);
        login(partner.getEmail(), PASSWORD, 200);

        assertEquals(before, auditRepo.count(), "only ADMIN accounts are audited at sign-in");
    }

    @Test
    void anUnknownAddressGetsExactlyTheSameAnswerAsAWrongAdminPassword() throws Exception {
        User admin = account("ADMIN");
        String unknown = body(login("nobody-" + UUID.randomUUID() + "@test.com", PASSWORD, 401));
        String wrong = body(login(admin.getEmail(), "Wrong-Pass-000", 401));
        assertEquals(stripVolatile(unknown), stripVolatile(wrong));
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    private User account(String role) {
        User u = new User();
        u.setFullName("Audit Probe");
        u.setEmail("admin-audit-" + UUID.randomUUID() + "@test.com");
        u.setPasswordHash(encoder.encode(PASSWORD));
        u.setRole(role);
        u.setEmailVerifiedAt(Instant.now());
        return users.saveAndFlush(u);
    }

    private MvcResult login(String email, String password, int expectedStatus) throws Exception {
        MvcResult result = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(Map.of("email", email, "password", password))))
            .andReturn();
        assertEquals(expectedStatus, result.getResponse().getStatus(), result.getResponse().getContentAsString());
        return result;
    }

    private static String body(MvcResult result) throws Exception {
        return result.getResponse().getContentAsString(StandardCharsets.UTF_8);
    }

    /** The error body without its timestamp, which differs between any two responses. */
    private String stripVolatile(String json) throws Exception {
        var node = (com.fasterxml.jackson.databind.node.ObjectNode) mapper.readTree(json);
        node.remove("timestamp");
        return node.toString();
    }

    private List<AdminActivityLog> rows(User actor, String action) {
        return auditRepo.search(actor.getId(), action, null, null, null, null, PageRequest.of(0, 50)).getContent();
    }

    private static void assertNoSecrets(AdminActivityLog row, String... secrets) {
        String text = row.getAction() + " " + row.getDescription() + " " + row.getBeforeState() + " " + row.getAfterState();
        for (String secret : secrets) {
            assertFalse(text.contains(secret), "audit row contains credential material");
        }
        assertFalse(text.toLowerCase().contains("eyj"), "no JWT-shaped text");
    }
}
