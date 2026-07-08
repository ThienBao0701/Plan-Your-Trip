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
 * CustomerProfileTest — Phase 7.1.
 * Every scenario registers its own throwaway user (never touching shared seed data)
 * so tests stay isolated from each other and from other test classes sharing the
 * same H2 instance.
 */
@SpringBootTest
@AutoConfigureMockMvc
class CustomerProfileTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;

    private String adminToken;
    private static final AtomicInteger counter = new AtomicInteger(1);

    private static final String FULL_UPDATE_PAYLOAD = """
            {"avatarUrl":"https://cdn.example.com/avatar.png","preferredLanguage":"vi","preferredCurrency":"USD",
             "preferredPaymentMethod":"CARD","nationality":"Vietnamese","passportNumber":"B1234567",
             "emergencyContactName":"Jane Doe","emergencyContactPhone":"0909999999",
             "accessibilityNeeds":"Wheelchair access","dietaryPreference":"Vegetarian","travelStyle":"Adventure",
             "marketingConsent":true}
            """;

    // ═══════════════════════════════════════════════════════════════════════════
    // DEFAULT PROFILE / UPDATE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void createsDefaultProfile() throws Exception {
        String token = registerAndLogin("profile-default");

        String body = mvc.perform(get("/api/me/profile")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("en", res.get("preferredLanguage").asText());
        assertEquals("VND", res.get("preferredCurrency").asText());
        assertFalse(res.get("marketingConsent").asBoolean());
        assertFalse(res.get("profileCompleted").asBoolean());
        // preferredLanguage/preferredCurrency default to non-blank values (2 of the
        // 11 tracked fields), so a brand-new profile is already partially "complete".
        assertEquals(18, res.get("completionPercentage").asInt());
        assertTrue(res.get("passportNumberMasked").isNull());
    }

    @Test
    void updateProfile() throws Exception {
        String token = registerAndLogin("profile-update");

        String body = mvc.perform(put("/api/me/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(FULL_UPDATE_PAYLOAD))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("vi", res.get("preferredLanguage").asText());
        assertEquals("USD", res.get("preferredCurrency").asText());
        assertEquals("CARD", res.get("preferredPaymentMethod").asText());
        assertEquals("Vietnamese", res.get("nationality").asText());
        assertEquals("Jane Doe", res.get("emergencyContactName").asText());
        assertTrue(res.get("marketingConsent").asBoolean());

        // Persisted across requests, not just echoed back.
        String getBody = mvc.perform(get("/api/me/profile")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals("vi", mapper.readTree(getBody).get("preferredLanguage").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // COMPLETION PERCENTAGE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void completionPercentage_reflectsFilledFields() throws Exception {
        String token = registerAndLogin("profile-completion");

        String body = mvc.perform(put("/api/me/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(FULL_UPDATE_PAYLOAD))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals(100, res.get("completionPercentage").asInt());
        assertTrue(res.get("profileCompleted").asBoolean());
    }

    @Test
    void completionPercentage_partialFieldsGiveLessThan100() throws Exception {
        String token = registerAndLogin("profile-partial");

        String body = mvc.perform(put("/api/me/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"nationality":"Vietnamese","marketingConsent":false}
                        """))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertTrue(res.get("completionPercentage").asInt() > 0);
        assertTrue(res.get("completionPercentage").asInt() < 100);
        assertFalse(res.get("profileCompleted").asBoolean());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PASSPORT MASKING
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void passportNumber_isMasked() throws Exception {
        String token = registerAndLogin("profile-passport");

        String body = mvc.perform(put("/api/me/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"passportNumber\":\"P123456789\",\"marketingConsent\":false}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        String masked = mapper.readTree(body).get("passportNumberMasked").asText();
        assertEquals(10, masked.length(), "Masked value must preserve the original length");
        assertTrue(masked.endsWith("6789"), "Only the last 4 characters must be visible");
        assertFalse(masked.contains("P123456789"), "The full passport number must never be exposed");
        assertEquals("******6789", masked);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // OWNERSHIP
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void ownership_userSeesOnlyOwnProfile() throws Exception {
        String tokenA = registerAndLogin("profile-owner-a");
        String tokenB = registerAndLogin("profile-owner-b");

        mvc.perform(put("/api/me/profile")
                .header("Authorization", "Bearer " + tokenA)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"nationality\":\"American\",\"marketingConsent\":false}"))
            .andExpect(status().isOk());

        String bodyB = mvc.perform(get("/api/me/profile")
                .header("Authorization", "Bearer " + tokenB))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode resB = mapper.readTree(bodyB);
        assertTrue(resB.get("nationality").isNull(), "Partner B's profile must not see partner A's data");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ADMIN
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void admin_canReadAnyProfile() throws Exception {
        String token = registerAndLogin("profile-adminread");

        String updateBody = mvc.perform(put("/api/me/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"nationality\":\"Japanese\",\"marketingConsent\":false}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        Long userId = mapper.readTree(updateBody).get("userId").asLong();

        String body = mvc.perform(get("/api/admin/users/" + userId + "/profile")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals("Japanese", mapper.readTree(body).get("nationality").asText());
    }

    @Test
    void admin_readOnly_neverExposesFullPassport() throws Exception {
        String token = registerAndLogin("profile-adminpassport");

        String updateBody = mvc.perform(put("/api/me/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"passportNumber\":\"X987654321\",\"marketingConsent\":false}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        Long userId = mapper.readTree(updateBody).get("userId").asLong();

        String body = mvc.perform(get("/api/admin/users/" + userId + "/profile")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        String masked = mapper.readTree(body).get("passportNumberMasked").asText();
        assertFalse(masked.contains("X987654321"));
        assertTrue(masked.endsWith("4321"));
    }

    @Test
    void nonAdmin_cannotReadOthersProfile() throws Exception {
        String token = registerAndLogin("profile-nonadmin");
        Long userId = mapper.readTree(mvc.perform(get("/api/me/profile")
                .header("Authorization", "Bearer " + token))
            .andReturn().getResponse().getContentAsString()).get("userId").asLong();

        String strangerToken = registerAndLogin("profile-stranger");
        mvc.perform(get("/api/admin/users/" + userId + "/profile")
                .header("Authorization", "Bearer " + strangerToken))
            .andExpect(status().isForbidden());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // AUTH
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void unauthenticated_rejected() throws Exception {
        mvc.perform(get("/api/me/profile"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

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

    private String registerAndLogin(String namePrefix) throws Exception {
        String email = namePrefix + "-" + counter.getAndIncrement() + "@test.com";
        String body = mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"" + namePrefix + " Tester\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }
}
