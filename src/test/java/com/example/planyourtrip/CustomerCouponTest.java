package com.example.planyourtrip;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * CustomerCouponTest — Phase 7.14 (Customer Coupons &amp; Travel Credits Foundation).
 * Covers admin coupon-definition CRUD, case-insensitive code handling,
 * claim lifecycle/validation, ownership (404 — never 403 — on another user's
 * coupon), the read-only discount preview, the claim notification and the
 * seeded WELCOME10 coupon. Every scenario registers its own throwaway user(s)
 * and creates its own uniquely-coded coupon definitions so state never leaks
 * across tests — mirrors TravelWalletTest's conventions.
 */
@SpringBootTest
@AutoConfigureMockMvc
class CustomerCouponTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;

    private static final AtomicInteger counter = new AtomicInteger(1);
    private static final LocalDate TODAY = LocalDate.now();

    // ═══════════════════════════════════════════════════════════════════════════
    // 1-2: ADMIN COUPON DEFINITIONS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void adminCreatesCouponDefinition() throws Exception {
        String code = uniqueCode("create");

        JsonNode res = createCoupon(couponPayload(code.toLowerCase(), "PERCENTAGE", "10",
            "300000", "500000", TODAY.minusDays(1), TODAY.plusDays(30), true, null, 2));

        assertNotNull(res.get("id"));
        assertEquals(code, res.get("code").asText(), "code is normalized to upper-case");
        assertEquals("PERCENTAGE", res.get("discountType").asText());
        assertTrue(res.get("active").asBoolean());
        assertEquals(2, res.get("usageLimitPerUser").asInt());
        assertEquals(0, res.get("currentUsageCount").asInt());
        assertDecimal("10", res.get("discountValue"));
        assertDecimal("300000", res.get("maxDiscountAmount"));
        assertDecimal("500000", res.get("minimumSpend"));
    }

    @Test
    void duplicateCouponCodeRejectedCaseInsensitively() throws Exception {
        String code = uniqueCode("dup");
        createCoupon(couponPayload(code, "PERCENTAGE", "10", null, null,
            TODAY.minusDays(1), TODAY.plusDays(30), true, null, 1));

        mvc.perform(post("/api/admin/coupon-definitions")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(couponPayload(code.toLowerCase(), "PERCENTAGE", "5", null, null,
                    TODAY.minusDays(1), TODAY.plusDays(30), true, null, 1)))
            .andExpect(status().isConflict());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 3-7: CLAIM LIFECYCLE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void customerClaimsActiveCoupon() throws Exception {
        String code = uniqueCode("claim");
        createCoupon(couponPayload(code, "PERCENTAGE", "10", null, null,
            TODAY.minusDays(1), TODAY.plusDays(30), true, null, 1));
        String token = registerAndLogin("coupon-claim");

        // Claim with a differently-cased code — matching must be case-insensitive.
        JsonNode res = claim(token, code.toLowerCase(), status().isCreated());

        assertNotNull(res.get("id"));
        assertEquals("AVAILABLE", res.get("status").asText());
        assertEquals("AVAILABLE", res.get("effectiveStatus").asText());
        assertEquals(code, res.get("coupon").get("code").asText());
        assertNotNull(res.get("claimedAt"));
        assertTrue(res.get("usedAt") == null || res.get("usedAt").isNull());
        assertEquals(1, res.get("coupon").get("currentUsageCount").asInt());
    }

    @Test
    void duplicateClaimBeyondPerUserLimitRejected() throws Exception {
        String code = uniqueCode("limit");
        createCoupon(couponPayload(code, "PERCENTAGE", "10", null, null,
            TODAY.minusDays(1), TODAY.plusDays(30), true, null, 1));
        String token = registerAndLogin("coupon-limit");

        claim(token, code, status().isCreated());
        claim(token, code, status().isConflict());
    }

    @Test
    void inactiveCouponCannotBeClaimed() throws Exception {
        String code = uniqueCode("inactive");
        createCoupon(couponPayload(code, "PERCENTAGE", "10", null, null,
            TODAY.minusDays(1), TODAY.plusDays(30), false, null, 1));
        String token = registerAndLogin("coupon-inactive");

        claim(token, code, status().isBadRequest());
    }

    @Test
    void expiredCouponCannotBeClaimed() throws Exception {
        String code = uniqueCode("expired");
        createCoupon(couponPayload(code, "PERCENTAGE", "10", null, null,
            TODAY.minusDays(10), TODAY.minusDays(1), true, null, 1));
        String token = registerAndLogin("coupon-expired");

        claim(token, code, status().isBadRequest());
    }

    @Test
    void futureCouponCannotBeClaimed() throws Exception {
        String code = uniqueCode("future");
        createCoupon(couponPayload(code, "PERCENTAGE", "10", null, null,
            TODAY.plusDays(5), TODAY.plusDays(30), true, null, 1));
        String token = registerAndLogin("coupon-future");

        claim(token, code, status().isBadRequest());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 8-9: OWNERSHIP
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void customerListsOnlyOwnCoupons() throws Exception {
        String codeA = uniqueCode("owna");
        String codeB = uniqueCode("ownb");
        createCoupon(couponPayload(codeA, "PERCENTAGE", "10", null, null,
            TODAY.minusDays(1), TODAY.plusDays(30), true, null, 1));
        createCoupon(couponPayload(codeB, "PERCENTAGE", "10", null, null,
            TODAY.minusDays(1), TODAY.plusDays(30), true, null, 1));

        String userA = registerAndLogin("coupon-list-a");
        String userB = registerAndLogin("coupon-list-b");
        claim(userA, codeA, status().isCreated());
        claim(userB, codeB, status().isCreated());

        JsonNode listA = mapper.readTree(mvc.perform(get("/api/me/coupons")
                .header("Authorization", "Bearer " + userA))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());

        assertEquals(1, listA.size());
        assertEquals(codeA, listA.get(0).get("coupon").get("code").asText());
    }

    @Test
    void anotherUsersCouponReturns404() throws Exception {
        String code = uniqueCode("own404");
        createCoupon(couponPayload(code, "PERCENTAGE", "10", null, null,
            TODAY.minusDays(1), TODAY.plusDays(30), true, null, 1));
        String owner = registerAndLogin("coupon-owner-404");
        String stranger = registerAndLogin("coupon-stranger-404");
        Long id = claim(owner, code, status().isCreated()).get("id").asLong();

        mvc.perform(get("/api/me/coupons/" + id)
                .header("Authorization", "Bearer " + stranger))
            .andExpect(status().isNotFound());

        mvc.perform(post("/api/me/coupons/" + id + "/preview")
                .header("Authorization", "Bearer " + stranger)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"orderAmount\":1000000}"))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 10-14: PREVIEW CALCULATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void percentageCouponPreviewCalculatesCorrectly() throws Exception {
        String code = uniqueCode("pct");
        createCoupon(couponPayload(code, "PERCENTAGE", "10", null, null,
            TODAY.minusDays(1), TODAY.plusDays(30), true, null, 1));
        String token = registerAndLogin("coupon-pct");
        Long id = claim(token, code, status().isCreated()).get("id").asLong();

        JsonNode res = preview(token, id, "1000000");

        assertTrue(res.get("eligible").asBoolean());
        assertDecimal("1000000", res.get("originalAmount"));
        assertDecimal("100000", res.get("discountAmount"));
        assertDecimal("900000", res.get("finalAmount"));
    }

    @Test
    void fixedCouponPreviewCalculatesCorrectly() throws Exception {
        String code = uniqueCode("fixed");
        createCoupon(couponPayload(code, "FIXED_AMOUNT", "150000", null, null,
            TODAY.minusDays(1), TODAY.plusDays(30), true, null, 2));
        String token = registerAndLogin("coupon-fixed");
        Long id = claim(token, code, status().isCreated()).get("id").asLong();

        JsonNode res = preview(token, id, "1000000");
        assertTrue(res.get("eligible").asBoolean());
        assertDecimal("150000", res.get("discountAmount"));
        assertDecimal("850000", res.get("finalAmount"));

        // Fixed discount larger than the order — capped at the order amount, never negative.
        JsonNode small = preview(token, id, "100000");
        assertTrue(small.get("eligible").asBoolean());
        assertDecimal("100000", small.get("discountAmount"));
        assertDecimal("0", small.get("finalAmount"));
    }

    @Test
    void maxDiscountCapEnforced() throws Exception {
        String code = uniqueCode("cap");
        createCoupon(couponPayload(code, "PERCENTAGE", "50", "200000", null,
            TODAY.minusDays(1), TODAY.plusDays(30), true, null, 1));
        String token = registerAndLogin("coupon-cap");
        Long id = claim(token, code, status().isCreated()).get("id").asLong();

        JsonNode res = preview(token, id, "1000000");

        assertTrue(res.get("eligible").asBoolean());
        assertDecimal("200000", res.get("discountAmount"), "50% of 1,000,000 = 500,000, capped at 200,000");
        assertDecimal("800000", res.get("finalAmount"));
    }

    @Test
    void minimumSpendEnforced() throws Exception {
        String code = uniqueCode("minspend");
        createCoupon(couponPayload(code, "PERCENTAGE", "10", null, "500000",
            TODAY.minusDays(1), TODAY.plusDays(30), true, null, 1));
        String token = registerAndLogin("coupon-minspend");
        Long id = claim(token, code, status().isCreated()).get("id").asLong();

        JsonNode res = preview(token, id, "300000");

        assertFalse(res.get("eligible").asBoolean());
        assertTrue(res.get("reason").asText().contains("Minimum spend"));
        assertDecimal("0", res.get("discountAmount"));
        assertDecimal("300000", res.get("finalAmount"), "no discount applied when ineligible");
    }

    @Test
    void previewDoesNotMarkCouponUsed() throws Exception {
        String code = uniqueCode("previewro");
        createCoupon(couponPayload(code, "PERCENTAGE", "10", null, null,
            TODAY.minusDays(1), TODAY.plusDays(30), true, null, 1));
        String token = registerAndLogin("coupon-preview-ro");
        Long id = claim(token, code, status().isCreated()).get("id").asLong();

        preview(token, id, "1000000");
        preview(token, id, "2000000");

        JsonNode after = mapper.readTree(mvc.perform(get("/api/me/coupons/" + id)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());

        assertEquals("AVAILABLE", after.get("status").asText());
        assertEquals("AVAILABLE", after.get("effectiveStatus").asText());
        assertTrue(after.get("usedAt") == null || after.get("usedAt").isNull());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // NOTIFICATION / SEED / SECURITY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void couponClaimNotificationCreated() throws Exception {
        String code = uniqueCode("notify");
        createCoupon(couponPayload(code, "PERCENTAGE", "10", null, null,
            TODAY.minusDays(1), TODAY.plusDays(30), true, null, 1));
        String token = registerAndLogin("coupon-notify");
        claim(token, code, status().isCreated());

        JsonNode notifications = mapper.readTree(mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());

        JsonNode found = null;
        for (JsonNode n : notifications) {
            if ("Coupon added".equals(n.get("title").asText())) found = n;
        }
        assertNotNull(found, "claim must create a 'Coupon added' notification");
        assertEquals("PROMOTION", found.get("notificationType").asText());
        assertTrue(found.get("message").asText().contains(code));
    }

    @Test
    void seededWelcome10CouponExistsAndIsClaimable() throws Exception {
        JsonNode all = mapper.readTree(mvc.perform(get("/api/admin/coupon-definitions")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());

        JsonNode welcome = null;
        for (JsonNode d : all) {
            if ("WELCOME10".equals(d.get("code").asText())) welcome = d;
        }
        assertNotNull(welcome, "WELCOME10 must be seeded");
        assertTrue(welcome.get("active").asBoolean());
        assertEquals("PERCENTAGE", welcome.get("discountType").asText());
        assertDecimal("10", welcome.get("discountValue"));
        assertDecimal("300000", welcome.get("maxDiscountAmount"));
        assertDecimal("500000", welcome.get("minimumSpend"));

        // Claimable right now by a fresh customer (case-insensitively), and previews correctly.
        String token = registerAndLogin("coupon-welcome");
        Long id = claim(token, "welcome10", status().isCreated()).get("id").asLong();
        JsonNode res = preview(token, id, "1000000");
        assertTrue(res.get("eligible").asBoolean());
        assertDecimal("100000", res.get("discountAmount"));
    }

    @Test
    void nonAdminCouponAdminEndpointsRejected() throws Exception {
        String token = registerAndLogin("coupon-nonadmin");

        mvc.perform(get("/api/admin/coupon-definitions")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());

        mvc.perform(post("/api/admin/coupon-definitions")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(couponPayload(uniqueCode("forbidden"), "PERCENTAGE", "10", null, null,
                    TODAY.minusDays(1), TODAY.plusDays(30), true, null, 1)))
            .andExpect(status().isForbidden());
    }

    @Test
    void unauthenticatedCouponEndpointsRejected() throws Exception {
        mvc.perform(get("/api/me/coupons")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/me/coupons/claim")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"WELCOME10\"}"))
            .andExpect(status().isUnauthorized());
        mvc.perform(get("/api/admin/coupon-definitions")).andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private String adminTokenCache;

    private String adminToken() throws Exception {
        if (adminTokenCache == null) {
            String body = mvc.perform(post("/api/auth/login")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("{\"email\":\"admin@planyourtrip.com\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
            adminTokenCache = mapper.readTree(body).get("token").asText();
        }
        return adminTokenCache;
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

    private String uniqueCode(String prefix) {
        return ("CPN-" + prefix + "-" + counter.getAndIncrement()).toUpperCase();
    }

    private String couponPayload(String code, String discountType, String discountValue,
                                  String maxDiscountAmount, String minimumSpend,
                                  LocalDate validFrom, LocalDate validUntil,
                                  Boolean active, Integer totalUsageLimit, Integer usageLimitPerUser) {
        return String.format("""
                {"code":"%s","name":"Coupon %s","description":"Test coupon",
                 "discountType":"%s","discountValue":%s,"maxDiscountAmount":%s,"minimumSpend":%s,
                 "validFrom":"%s","validUntil":"%s","active":%s,"totalUsageLimit":%s,"usageLimitPerUser":%s}
                """,
            code, code, discountType, discountValue,
            maxDiscountAmount == null ? "null" : maxDiscountAmount,
            minimumSpend == null ? "null" : minimumSpend,
            validFrom, validUntil,
            active == null ? "null" : active.toString(),
            totalUsageLimit == null ? "null" : totalUsageLimit.toString(),
            usageLimitPerUser == null ? "null" : usageLimitPerUser.toString());
    }

    private JsonNode createCoupon(String payload) throws Exception {
        String body = mvc.perform(post("/api/admin/coupon-definitions")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode claim(String token, String code,
                            org.springframework.test.web.servlet.ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/me/coupons/claim")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"" + code + "\"}"))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
    }

    private JsonNode preview(String token, Long couponId, String orderAmount) throws Exception {
        String body = mvc.perform(post("/api/me/coupons/" + couponId + "/preview")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"orderAmount\":" + orderAmount + "}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private void assertDecimal(String expected, JsonNode actual) {
        assertDecimal(expected, actual, null);
    }

    private void assertDecimal(String expected, JsonNode actual, String message) {
        assertNotNull(actual, message);
        assertEquals(0, new BigDecimal(expected).compareTo(new BigDecimal(actual.asText())),
            (message != null ? message + " — " : "") + "expected " + expected + " but was " + actual.asText());
    }
}
