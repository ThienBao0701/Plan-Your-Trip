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
 * PartnerSettingsTest — Phase 6.9.
 * Every scenario provisions its own throwaway partner (never touching the shared
 * seeded partner@planyourtrip.com account, except the dedicated seed-verification
 * test) so tests stay isolated from each other and from other test classes sharing
 * the same H2 instance.
 */
@SpringBootTest
@AutoConfigureMockMvc
class PartnerSettingsTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;

    private String adminToken;
    private static final AtomicInteger counter = new AtomicInteger(1);

    private record PartnerCtx(String token, Long profileId) {}

    // ═══════════════════════════════════════════════════════════════════════════
    // SETTINGS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void getDefaultSettings() throws Exception {
        PartnerCtx partner = createAndApprovePartner();

        String body = mvc.perform(get("/api/partner/settings")
                .header("Authorization", "Bearer " + partner.token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("en", res.get("defaultLanguage").asText());
        assertEquals("Asia/Ho_Chi_Minh", res.get("timezone").asText());
        assertTrue(res.get("notificationEmailEnabled").asBoolean());
        assertFalse(res.get("notificationSmsEnabled").asBoolean());
        assertTrue(res.get("bookingNotificationEnabled").asBoolean());
    }

    @Test
    void updateNotificationSettings() throws Exception {
        PartnerCtx partner = createAndApprovePartner();

        String body = mvc.perform(put("/api/partner/settings")
                .header("Authorization", "Bearer " + partner.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"defaultLanguage":"en","timezone":"Asia/Ho_Chi_Minh",
                         "notificationEmailEnabled":false,"notificationSmsEnabled":true,"notificationInAppEnabled":true,
                         "bookingNotificationEnabled":false,"paymentNotificationEnabled":true,
                         "reviewNotificationEnabled":false,"promotionNotificationEnabled":true}
                        """))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertFalse(res.get("notificationEmailEnabled").asBoolean());
        assertTrue(res.get("notificationSmsEnabled").asBoolean());
        assertFalse(res.get("bookingNotificationEnabled").asBoolean());
        assertFalse(res.get("reviewNotificationEnabled").asBoolean());
    }

    @Test
    void updateLanguageAndTimezone() throws Exception {
        PartnerCtx partner = createAndApprovePartner();

        String body = mvc.perform(put("/api/partner/settings")
                .header("Authorization", "Bearer " + partner.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"defaultLanguage":"vi","timezone":"Asia/Bangkok",
                         "notificationEmailEnabled":true,"notificationSmsEnabled":false,"notificationInAppEnabled":true,
                         "bookingNotificationEnabled":true,"paymentNotificationEnabled":true,
                         "reviewNotificationEnabled":true,"promotionNotificationEnabled":true}
                        """))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("vi", res.get("defaultLanguage").asText());
        assertEquals("Asia/Bangkok", res.get("timezone").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PAYOUT ACCOUNT
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void getPayoutAccount() throws Exception {
        PartnerCtx partner = createAndApprovePartner();
        putPayoutAccount(partner.token(), "1234567890123456");

        String body = mvc.perform(get("/api/partner/payout-account")
                .header("Authorization", "Bearer " + partner.token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals("3456", mapper.readTree(body).get("bankAccountLast4").asText());
    }

    @Test
    void updatePayoutAccount_storesOnlyLast4() throws Exception {
        PartnerCtx partner = createAndApprovePartner();

        String body = putPayoutAccount(partner.token(), "9988776655443210");
        JsonNode res = mapper.readTree(body);

        assertEquals("3210", res.get("bankAccountLast4").asText());
        assertNull(res.get("bankAccountNumber"), "Full account number must never be returned");
        assertEquals(4, res.get("bankAccountLast4").asText().length());
    }

    @Test
    void payoutUpdate_createsNotification() throws Exception {
        PartnerCtx partner = createAndApprovePartner();
        putPayoutAccount(partner.token(), "1111222233334444");

        String body = mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + partner.token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertTrue(containsTitle(mapper.readTree(body), "Payout account updated"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // TEAM MANAGEMENT
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void listTeamMembers() throws Exception {
        PartnerCtx partner = createAndApprovePartner();
        addTeamMember(partner.token(), registerPlainUser("teammate"), "MANAGER");

        String body = mvc.perform(get("/api/partner/team")
                .header("Authorization", "Bearer " + partner.token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());
        // Approval now auto-creates an OWNER team member (Phase 6.10), so the list
        // contains that plus the MANAGER just added.
        assertEquals(2, arr.size());
        boolean hasManager = false, hasOwner = false;
        for (JsonNode n : arr) {
            if ("MANAGER".equals(n.get("role").asText())) hasManager = true;
            if ("OWNER".equals(n.get("role").asText())) hasOwner = true;
        }
        assertTrue(hasManager);
        assertTrue(hasOwner);
    }

    @Test
    void addTeamMember_succeeds() throws Exception {
        PartnerCtx partner = createAndApprovePartner();
        String email = registerPlainUser("newmember");

        String body = addTeamMember(partner.token(), email, "FRONT_DESK");
        JsonNode res = mapper.readTree(body);

        assertEquals(email, res.get("userEmail").asText());
        assertEquals("FRONT_DESK", res.get("role").asText());
        assertTrue(res.get("active").asBoolean());
    }

    @Test
    void teamMember_receivesNotification() throws Exception {
        PartnerCtx partner = createAndApprovePartner();
        String email = registerPlainUser("notifyme");
        String memberToken = login(email, "password123");

        addTeamMember(partner.token(), email, "VIEWER");

        String body = mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + memberToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertTrue(containsTitle(mapper.readTree(body), "You were added to a partner team"));
    }

    @Test
    void updateTeamMemberRole() throws Exception {
        PartnerCtx partner = createAndApprovePartner();
        String email = registerPlainUser("rolechange");
        Long memberId = mapper.readTree(addTeamMember(partner.token(), email, "VIEWER")).get("id").asLong();

        String body = mvc.perform(patch("/api/partner/team/" + memberId)
                .header("Authorization", "Bearer " + partner.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"role\":\"MANAGER\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals("MANAGER", mapper.readTree(body).get("role").asText());
    }

    @Test
    void deactivateAndRemoveTeamMember() throws Exception {
        PartnerCtx partner = createAndApprovePartner();
        String email = registerPlainUser("removeme");
        Long memberId = mapper.readTree(addTeamMember(partner.token(), email, "VIEWER")).get("id").asLong();

        String deactivated = mvc.perform(patch("/api/partner/team/" + memberId)
                .header("Authorization", "Bearer " + partner.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"active\":false}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertFalse(mapper.readTree(deactivated).get("active").asBoolean());

        mvc.perform(delete("/api/partner/team/" + memberId)
                .header("Authorization", "Bearer " + partner.token()))
            .andExpect(status().isNoContent());

        String body = mvc.perform(get("/api/partner/team")
                .header("Authorization", "Bearer " + partner.token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        // Approval now auto-creates an OWNER team member (Phase 6.10) which was never
        // removed here — only the explicitly-added-and-deleted VIEWER should be gone.
        JsonNode remaining = mapper.readTree(body);
        assertEquals(1, remaining.size());
        assertEquals("OWNER", remaining.get(0).get("role").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ROLE ENFORCEMENT
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void viewer_cannotUpdateSettings() throws Exception {
        PartnerCtx partner = createAndApprovePartner();
        String email = registerPlainUser("vieweronly");
        String viewerToken = login(email, "password123");
        addTeamMember(partner.token(), email, "VIEWER");

        mvc.perform(put("/api/partner/settings")
                .header("Authorization", "Bearer " + viewerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"defaultLanguage":"en","timezone":"Asia/Ho_Chi_Minh",
                         "notificationEmailEnabled":true,"notificationSmsEnabled":false,"notificationInAppEnabled":true,
                         "bookingNotificationEnabled":true,"paymentNotificationEnabled":true,
                         "reviewNotificationEnabled":true,"promotionNotificationEnabled":true}
                        """))
            .andExpect(status().isForbidden());
    }

    @Test
    void finance_canUpdatePayoutMetadata() throws Exception {
        PartnerCtx partner = createAndApprovePartner();
        String email = registerPlainUser("financeperson");
        String financeToken = login(email, "password123");
        addTeamMember(partner.token(), email, "FINANCE");

        putPayoutAccount(financeToken, "5555666677778888");
        mvc.perform(get("/api/partner/payout-account")
                .header("Authorization", "Bearer " + financeToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.bankAccountLast4").value("8888"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // AUTH / APPROVAL
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void nonApprovedPartner_rejected() throws Exception {
        String draftToken = createDraftPartnerToken();

        mvc.perform(get("/api/partner/settings")
                .header("Authorization", "Bearer " + draftToken))
            .andExpect(status().isForbidden());
    }

    @Test
    void unauthenticated_rejected() throws Exception {
        mvc.perform(get("/api/partner/settings"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SEED
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void seedDefaults_exist() throws Exception {
        String seededPartnerToken = login("partner@planyourtrip.com", "partner123456");

        mvc.perform(get("/api/partner/settings")
                .header("Authorization", "Bearer " + seededPartnerToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.defaultLanguage").exists());

        mvc.perform(get("/api/partner/payout-account")
                .header("Authorization", "Bearer " + seededPartnerToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.bankAccountLast4").value("6789"));

        String teamBody = mvc.perform(get("/api/partner/team")
                .header("Authorization", "Bearer " + seededPartnerToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode team = mapper.readTree(teamBody);
        boolean hasOwner = false;
        for (JsonNode m : team) if ("OWNER".equals(m.get("role").asText())) hasOwner = true;
        assertTrue(hasOwner, "Seeded partner must have an OWNER team member");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private String putPayoutAccount(String token, String accountNumber) throws Exception {
        return mvc.perform(put("/api/partner/payout-account")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"accountHolderName":"Test Holder","bankName":"Test Bank",
                         "bankAccountNumber":"%s","payoutMethod":"BANK_TRANSFER"}
                        """.formatted(accountNumber)))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
    }

    private String addTeamMember(String ownerToken, String email, String role) throws Exception {
        return mvc.perform(post("/api/partner/team")
                .header("Authorization", "Bearer " + ownerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"role\":\"" + role + "\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
    }

    private String registerPlainUser(String namePrefix) throws Exception {
        String email = namePrefix + "-" + counter.getAndIncrement() + "@test.com";
        mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"" + namePrefix + " Tester\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated());
        return email;
    }

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

    private String registerAndLogin(String fullName, String email) throws Exception {
        String body = mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"" + fullName + "\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private String createDraftPartnerToken() throws Exception {
        String email = "partner-settings-draft-" + counter.getAndIncrement() + "@test.com";
        String token = registerAndLogin("Partner Tester", email);
        String profileReq = """
                {"businessName":"Draft Hotel Co","businessType":"HOTEL","representativeName":"Partner Tester",
                 "phone":"0901234567","email":"contact@example.com","address":"123 Le Loi, Da Nang"}
                """;
        mvc.perform(post("/api/partner/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(profileReq))
            .andExpect(status().isOk());
        return token;
    }

    private PartnerCtx createAndApprovePartner() throws Exception {
        String email = "partner-settings-" + counter.getAndIncrement() + "@test.com";
        String token = registerAndLogin("Partner Tester", email);

        String profileReq = """
                {"businessName":"Test Hotel Co %d","businessType":"HOTEL","representativeName":"Partner Tester",
                 "phone":"0901234567","email":"contact@example.com","address":"123 Le Loi, Da Nang"}
                """.formatted(counter.get());
        String profileBody = mvc.perform(post("/api/partner/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(profileReq))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        Long profileId = mapper.readTree(profileBody).get("id").asLong();

        mvc.perform(post("/api/partner/profile/submit")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        mvc.perform(post("/api/admin/partners/" + profileId + "/approve")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk());

        return new PartnerCtx(token, profileId);
    }

    private boolean containsTitle(JsonNode arr, String title) {
        for (JsonNode n : arr) {
            if (title.equals(n.get("title").asText())) return true;
        }
        return false;
    }
}
