package com.example.planyourtrip;

import com.example.planyourtrip.dto.PartnerProfileDto.PartnerProfileRequest;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.BusinessType;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.PartnerVerificationStatus;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.service.PartnerAccessService;
import com.example.planyourtrip.service.PartnerProfileService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** HTTP and service-level regression coverage for the R7 Admin/Partner boundary. */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class R7AdminPartnerBoundaryTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired UserRepository users;
    @Autowired PartnerProfileRepository profiles;
    @Autowired PartnerProfileService profileService;
    @Autowired PartnerAccessService partnerAccess;
    @Autowired JdbcTemplate jdbc;

    private static final AtomicInteger counter = new AtomicInteger();

    @Test
    void userCanCreateReadUpdateAndSubmitOnboardingProfile() throws Exception {
        String email = "r7-onboarding-" + counter.incrementAndGet() + "@test.com";
        String token = registerUser(email);

        String createdBody = mvc.perform(post("/api/partner/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(profileJson("USER onboarding")))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        long profileId = mapper.readTree(createdBody).get("id").asLong();

        mvc.perform(get("/api/partner/profile").header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(profileId))
            .andExpect(jsonPath("$.verificationStatus").value("DRAFT"));

        mvc.perform(post("/api/partner/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(profileJson("USER onboarding updated")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.businessName").value("USER onboarding updated"));
        mvc.perform(post("/api/partner/profile/submit").header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.verificationStatus").value("SUBMITTED"));
    }

    @Test
    void adminWithoutProfileCannotUseOnboardingHttpOrServicePaths() throws Exception {
        User admin = admin();
        String token = adminToken();
        assertFalse(profiles.existsByUserId(admin.getId()));

        mvc.perform(post("/api/partner/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(profileJson("Blocked create")))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.message").value("Access denied"));
        mvc.perform(get("/api/partner/profile").header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
        mvc.perform(post("/api/partner/profile/submit").header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());

        PartnerProfileRequest request = request("Blocked internal create");
        assertForbidden(() -> profileService.createOrUpdateMyProfile(admin.getId(), request));
        assertForbidden(() -> profileService.getMyProfile(admin.getId()));
        assertForbidden(() -> profileService.submitMyProfile(admin.getId()));
        assertFalse(profiles.existsByUserId(admin.getId()));
    }

    @Test
    void adminWithExistingDraftCannotReadUpdateOrSubmitProfile() throws Exception {
        User admin = admin();
        PartnerProfile draft = seedProfile(admin, PartnerVerificationStatus.DRAFT);
        String token = adminToken();

        mvc.perform(get("/api/partner/profile").header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
        mvc.perform(post("/api/partner/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(profileJson("Attempted update")))
            .andExpect(status().isForbidden());
        mvc.perform(post("/api/partner/profile/submit").header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());

        assertForbidden(() -> profileService.getMyProfile(admin.getId()));
        assertForbidden(() -> profileService.createOrUpdateMyProfile(admin.getId(), request("Internal update")));
        assertForbidden(() -> profileService.submitMyProfile(admin.getId()));
        assertEquals(PartnerVerificationStatus.DRAFT,
            profiles.findById(draft.getId()).orElseThrow().getVerificationStatus());
        assertEquals("Admin boundary fixture", profiles.findById(draft.getId()).orElseThrow().getBusinessName());
    }

    @Test
    void adminWithApprovedProfileCannotUseOperationalPartnerApisOrKernel() throws Exception {
        User admin = admin();
        seedProfile(admin, PartnerVerificationStatus.APPROVED);
        String token = adminToken();

        mvc.perform(get("/api/partner/me/access").header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
        mvc.perform(get("/api/partner/hotels").header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());

        ApiException exception = assertThrows(ApiException.class,
            () -> partnerAccess.requireWorkspace(admin.getId()));
        assertEquals(HttpStatus.FORBIDDEN, exception.status());
        assertEquals(PartnerAccessService.PARTNER_ACCOUNT_REQUIRED, exception.code());
        ApiException registrantException = assertThrows(ApiException.class,
            () -> partnerAccess.requireRegistrantWorkspace(admin.getId()));
        assertEquals(HttpStatus.FORBIDDEN, registrantException.status());
    }

    @Test
    void adminWithPartnerVerifyCannotApproveOwnApplicationOrWriteSuccessEffects() throws Exception {
        User admin = admin();
        PartnerProfile submitted = seedProfile(admin, PartnerVerificationStatus.SUBMITTED);
        Long auditCountBefore = successfulApprovalAuditCount(submitted.getId());

        mvc.perform(post("/api/admin/partners/" + submitted.getId() + "/approve")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.code").value("SELF_APPROVAL_FORBIDDEN"));

        PartnerProfile unchanged = profiles.findById(submitted.getId()).orElseThrow();
        assertEquals(PartnerVerificationStatus.SUBMITTED, unchanged.getVerificationStatus());
        assertNull(unchanged.getApprovedAt());
        assertNull(unchanged.getApprovedBy());
        assertEquals("ADMIN", users.findById(admin.getId()).orElseThrow().getRole());
        assertEquals(auditCountBefore, successfulApprovalAuditCount(submitted.getId()));

        ApiException accessDenied = assertThrows(ApiException.class,
            () -> partnerAccess.requireWorkspace(admin.getId()));
        assertEquals(HttpStatus.FORBIDDEN, accessDenied.status());
        assertEquals(PartnerAccessService.PARTNER_ACCOUNT_REQUIRED, accessDenied.code());
    }

    private User admin() {
        return users.findByEmail("admin@planyourtrip.com").orElseThrow();
    }

    private String adminToken() throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"admin@planyourtrip.com\",\"password\":\"admin123456\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private String registerUser(String email) throws Exception {
        String body = mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"R7 Boundary User\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private PartnerProfile seedProfile(User user, PartnerVerificationStatus status) {
        PartnerProfile profile = new PartnerProfile();
        profile.setUser(user);
        profile.setBusinessName("Admin boundary fixture");
        profile.setBusinessType(BusinessType.HOTEL);
        profile.setRepresentativeName("Admin boundary fixture");
        profile.setPhone("0901234567");
        profile.setEmail("boundary-" + counter.incrementAndGet() + "@example.com");
        profile.setAddress("1 Test Street");
        profile.setVerificationStatus(status);
        if (status == PartnerVerificationStatus.SUBMITTED) profile.setSubmittedAt(Instant.now());
        return profiles.saveAndFlush(profile);
    }

    private Long successfulApprovalAuditCount(Long profileId) {
        return jdbc.queryForObject("select count(*) from admin_activity_logs "
            + "where action = 'PARTNER_APPROVE' and target_type = 'PARTNER_PROFILE' and target_id = ?",
            Long.class, profileId);
    }

    private PartnerProfileRequest request(String name) {
        return new PartnerProfileRequest(name, BusinessType.HOTEL, "Boundary Applicant", "0901234567",
            "boundary-request@example.com", "1 Test Street", null, null);
    }

    private String profileJson(String name) {
        return "{\"businessName\":\"" + name + "\",\"businessType\":\"HOTEL\","
            + "\"representativeName\":\"Boundary Applicant\",\"phone\":\"0901234567\","
            + "\"email\":\"boundary-request@example.com\",\"address\":\"1 Test Street\"}";
    }

    private void assertForbidden(ThrowingRunnable call) {
        ApiException exception = assertThrows(ApiException.class, call::run);
        assertEquals(HttpStatus.FORBIDDEN, exception.status());
        assertEquals("Access denied", exception.getMessage());
    }

    @FunctionalInterface
    private interface ThrowingRunnable {
        void run() throws Exception;
    }
}
