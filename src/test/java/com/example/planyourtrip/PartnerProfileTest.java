package com.example.planyourtrip;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * PartnerProfileTest — Phase 6.1.
 * Each scenario registers a fresh throwaway user (unique email per test) rather than reusing
 * demo@planyourtrip.com, since approving a profile mutates the owning user's role and the H2
 * database is shared across the whole test run.
 */
@SpringBootTest
@AutoConfigureMockMvc
class PartnerProfileTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;

    private String adminToken;
    private static final AtomicInteger counter = new AtomicInteger(1);

    // ═══════════════════════════════════════════════════════════════════════════
    // CREATE / UPDATE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void user_createsDraftProfile() throws Exception {
        String token = registerAndLogin();

        JsonNode res = createProfile(token, "Sunrise Hotel", "HOTEL");

        assertNotNull(res.get("id"));
        assertEquals("DRAFT", res.get("verificationStatus").asText());
        assertEquals("Sunrise Hotel", res.get("businessName").asText());
    }

    @Test
    void user_cannotCreateDuplicateProfile() throws Exception {
        String token = registerAndLogin();

        JsonNode first = createProfile(token, "Sunrise Hotel", "HOTEL");
        JsonNode second = createProfile(token, "Sunrise Hotel Updated", "HOTEL");

        assertEquals(first.get("id").asLong(), second.get("id").asLong(),
            "Creating twice must update the same profile, never a duplicate row");
        assertEquals("Sunrise Hotel Updated", second.get("businessName").asText());

        long matching = countAdminProfilesWithUserEmail(currentEmail);
        assertEquals(1, matching, "Only one profile row must exist for this user");
    }

    @Test
    void user_updatesRejectedProfile() throws Exception {
        String token = registerAndLogin();
        Long id = createProfile(token, "Sunrise Hotel", "HOTEL").get("id").asLong();
        submit(token);
        reject(id, "Missing tax code");

        JsonNode updated = createProfile(token, "Sunrise Hotel V2", "HOTEL");
        assertEquals("Sunrise Hotel V2", updated.get("businessName").asText());
        assertEquals("REJECTED", updated.get("verificationStatus").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SUBMIT
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void submit_draftProfile() throws Exception {
        String token = registerAndLogin();
        createProfile(token, "Sunrise Hotel", "HOTEL");

        JsonNode res = submit(token);
        assertEquals("SUBMITTED", res.get("verificationStatus").asText());
        assertNotNull(res.get("submittedAt"));
    }

    @Test
    void cannotEditSubmittedProfile() throws Exception {
        String token = registerAndLogin();
        createProfile(token, "Sunrise Hotel", "HOTEL");
        submit(token);

        mvc.perform(post("/api/partner/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(profileJson("Sunrise Hotel Edited", "HOTEL")))
            .andExpect(status().isUnprocessableEntity());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ADMIN LIST / APPROVE / REJECT / SUSPEND
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void admin_listsPartnerProfiles() throws Exception {
        String token = registerAndLogin();
        createProfile(token, "Sunrise Hotel", "HOTEL");
        submit(token);

        String body = mvc.perform(get("/api/admin/partners")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());
        assertTrue(arr.size() >= 1);
    }

    @Test
    void admin_approvesSubmittedProfile() throws Exception {
        String token = registerAndLogin();
        Long id = createProfile(token, "Sunrise Hotel", "HOTEL").get("id").asLong();
        submit(token);

        JsonNode res = approve(id);
        assertEquals("APPROVED", res.get("verificationStatus").asText());
        assertFalse(res.get("approvedAt").isNull());
    }

    @Test
    void approval_changesRoleToPartner() throws Exception {
        String email = "partner-test-" + counter.getAndIncrement() + "@test.com";
        String token = registerAndLogin(email);
        Long id = createProfile(token, "Sunrise Hotel", "HOTEL").get("id").asLong();
        submit(token);
        approve(id);

        String loginBody = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"password123\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals("PARTNER", mapper.readTree(loginBody).get("user").get("role").asText());
    }

    @Test
    void admin_rejectsWithReason() throws Exception {
        String token = registerAndLogin();
        Long id = createProfile(token, "Sunrise Hotel", "HOTEL").get("id").asLong();
        submit(token);

        JsonNode res = reject(id, "Missing tax code");
        assertEquals("REJECTED", res.get("verificationStatus").asText());
        assertFalse(res.get("rejectedAt").isNull());
        assertEquals("Missing tax code", res.get("rejectReason").asText());
    }

    @Test
    void rejectedUser_canUpdateAndResubmit() throws Exception {
        String token = registerAndLogin();
        Long id = createProfile(token, "Sunrise Hotel", "HOTEL").get("id").asLong();
        submit(token);
        reject(id, "Missing tax code");

        createProfile(token, "Sunrise Hotel V2", "HOTEL");
        JsonNode res = submit(token);
        assertEquals("SUBMITTED", res.get("verificationStatus").asText());
    }

    @Test
    void admin_suspendsApprovedProfile() throws Exception {
        String token = registerAndLogin();
        Long id = createProfile(token, "Sunrise Hotel", "HOTEL").get("id").asLong();
        submit(token);
        approve(id);

        String body = mvc.perform(post("/api/admin/partners/" + id + "/suspend")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals("SUSPENDED", mapper.readTree(body).get("verificationStatus").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // NOTIFICATIONS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void notification_createdOnSubmit() throws Exception {
        String token = registerAndLogin();
        createProfile(token, "Sunrise Hotel", "HOTEL");
        submit(token);

        String body = mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertTrue(containsTitle(mapper.readTree(body), "New partner application submitted"));
    }

    @Test
    void notification_createdOnApproveAndReject() throws Exception {
        String token1 = registerAndLogin();
        Long id1 = createProfile(token1, "Sunrise Hotel", "HOTEL").get("id").asLong();
        submit(token1);
        approve(id1);

        String approvedBody = mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + token1))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertTrue(containsTitle(mapper.readTree(approvedBody), "Your partner profile has been approved"));

        String token2 = registerAndLogin();
        Long id2 = createProfile(token2, "Sunset Cafe", "CAFE").get("id").asLong();
        submit(token2);
        reject(id2, "Not relevant");

        String rejectedBody = mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + token2))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertTrue(containsTitle(mapper.readTree(rejectedBody), "Your partner profile was rejected"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // AUTH / AUTHORIZATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void unauthenticated_returns401() throws Exception {
        mvc.perform(post("/api/partner/profile")
                .contentType(MediaType.APPLICATION_JSON)
                .content(profileJson("Sunrise Hotel", "HOTEL")))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void nonAdmin_cannotApprove() throws Exception {
        String token = registerAndLogin();
        Long id = createProfile(token, "Sunrise Hotel", "HOTEL").get("id").asLong();
        submit(token);

        mvc.perform(post("/api/admin/partners/" + id + "/approve")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SEED VERIFICATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void seed_approvedPartnerProfileExists() throws Exception {
        String body = mvc.perform(get("/api/admin/partners")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        boolean found = false;
        for (JsonNode n : arr) {
            if ("partner@planyourtrip.com".equals(n.get("userEmail").asText())
                    && "APPROVED".equals(n.get("verificationStatus").asText())) {
                found = true;
                break;
            }
        }
        assertTrue(found, "Seeded approved partner profile must exist for partner@planyourtrip.com");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private String currentEmail;

    private String adminToken() throws Exception {
        if (adminToken == null) adminToken = login("admin@planyourtrip.com", "admin123456");
        return adminToken;
    }

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private String registerAndLogin() throws Exception {
        return registerAndLogin("partner-test-" + counter.getAndIncrement() + "@test.com");
    }

    private String registerAndLogin(String email) throws Exception {
        currentEmail = email;
        String body = mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"Partner Tester\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private String profileJson(String businessName, String businessType) {
        return String.format(
            "{\"businessName\":\"%s\",\"businessType\":\"%s\",\"representativeName\":\"Nguyen Van A\"," +
            "\"phone\":\"0901234567\",\"email\":\"contact@example.com\",\"address\":\"123 Le Loi, Da Nang\"}",
            businessName, businessType);
    }

    private JsonNode createProfile(String token, String businessName, String businessType) throws Exception {
        String body = mvc.perform(post("/api/partner/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(profileJson(businessName, businessType)))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode submit(String token) throws Exception {
        String body = mvc.perform(post("/api/partner/profile/submit")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode approve(Long id) throws Exception {
        String body = mvc.perform(post("/api/admin/partners/" + id + "/approve")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode reject(Long id, String reason) throws Exception {
        String body = mvc.perform(post("/api/admin/partners/" + id + "/reject")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"rejectReason\":\"" + reason + "\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private long countAdminProfilesWithUserEmail(String email) throws Exception {
        String body = mvc.perform(get("/api/admin/partners")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode arr = mapper.readTree(body);
        long count = 0;
        for (JsonNode n : arr) {
            if (email.equals(n.get("userEmail").asText())) count++;
        }
        return count;
    }

    private boolean containsTitle(JsonNode arr, String title) {
        for (JsonNode n : arr) {
            if (title.equals(n.get("title").asText())) return true;
        }
        return false;
    }
}
