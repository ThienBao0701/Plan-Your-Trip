package com.example.planyourtrip;

import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultMatcher;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * MembershipRedemptionIntegrationTest — Phase 7.21 (Membership Tiers &amp;
 * Benefits, additive extension of Phase 7.19/7.20).
 *
 * <p>Covers exactly the two scoped-down 7.21 integrations, built ENTIRELY on
 * top of the existing Phase 7.19 {@code CustomerMembership}/{@code MembershipTierDefinition}
 * model and Phase 7.20 {@code LoyaltyRedemptionService} — no new membership
 * entities, no new endpoints:
 * <ul>
 *   <li>{@code CouponDefinition#minimumTier} gating, evaluated by
 *       {@code CustomerCouponService}'s centralized eligibility evaluator
 *       (same place the MEMBER customer segment is evaluated), including the
 *       "no auto-enroll" read-only guarantee;</li>
 *   <li>the {@code MembershipTierDefinition#redemptionDiscountMultiplier}
 *       applied by {@code LoyaltyRedemptionService} to both preview and
 *       reserve, with a no-membership user staying at the 1.00 baseline.</li>
 * </ul>
 *
 * <p>Admin manual tier assignment ({@code POST /api/admin/users/{id}/membership/assign})
 * is used throughout as the fastest, most direct way to put a throwaway test
 * user at a specific tier — it works even without a prior {@code /enroll} call
 * (see {@code CustomerMembershipService#adminAssign} javadoc), so tests don't
 * need to manufacture lifetime points/completed bookings just to reach GOLD.
 * Every scenario registers its own throwaway user(s) so state never leaks
 * across tests — mirrors MembershipTierTest/LoyaltyRedemptionTest conventions.
 */
@SpringBootTest
@AutoConfigureMockMvc
class MembershipRedemptionIntegrationTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;

    private static final AtomicInteger counter = new AtomicInteger(1);
    private static final AtomicInteger dayCounter = new AtomicInteger(0);
    private static final LocalDate TODAY = LocalDate.now();

    private Long stdTwinRoomId;

    // ═══════════════════════════════════════════════════════════════════════════
    // 1-5: COUPON minimumTier GATING
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void minimumTierCouponRejectsUserWithNoMembership() throws Exception {
        String code = uniqueCode("mintier-none");
        createMinimumTierCoupon(code, "GOLD");

        String token = registerUser("mintier-none-user").get("token").asText();
        claim(token, code, status().isBadRequest());
    }

    @Test
    void minimumTierCouponAcceptsUserAtRequiredTier() throws Exception {
        String code = uniqueCode("mintier-gold-ok");
        createMinimumTierCoupon(code, "GOLD");

        JsonNode user = registerUser("mintier-gold-user");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        adminAssign(userId, "GOLD", "Fast-track to GOLD for minimumTier coupon test");

        claim(token, code, status().isCreated());
    }

    @Test
    void minimumTierCouponRejectsUserBelowRequiredTier() throws Exception {
        String code = uniqueCode("mintier-silver-reject");
        createMinimumTierCoupon(code, "GOLD");

        JsonNode user = registerUser("mintier-silver-user");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        adminAssign(userId, "SILVER", "Below GOLD requirement");

        claim(token, code, status().isBadRequest());
    }

    @Test
    void couponWithNoMinimumTierIsUnaffectedByFeature() throws Exception {
        // Deliberately omits minimumTier entirely — must behave exactly like a pre-7.21 coupon,
        // claimable even by a user with no membership at all (below BRONZE).
        String code = uniqueCode("no-mintier");
        createPlainCoupon(code);

        String token = registerUser("no-mintier-user").get("token").asText();
        claim(token, code, status().isCreated());
    }

    @Test
    void minimumTierEligibilityCheckDoesNotAutoEnroll() throws Exception {
        String code = uniqueCode("mintier-noauto");
        createMinimumTierCoupon(code, "GOLD");

        JsonNode user = registerUser("mintier-noauto-user");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();

        claim(token, code, status().isBadRequest());

        // Never enrolled/assigned — admin support view must 404, proving the
        // minimumTier check created no CustomerMembership as a side effect.
        mvc.perform(get("/api/admin/users/" + userId + "/membership")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 6-8: REDEMPTION DISCOUNT MULTIPLIER
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void redemptionDiscountMultipliedForHigherTierUser() throws Exception {
        // Baseline: no membership ⇒ multiplier 1.00 ⇒ 1000 pts * 1000.00 / 100 = 10000.00.
        JsonNode baselineUser = registerUser("redeem-mult-baseline");
        String baselineToken = baselineUser.get("token").asText();
        Long baselineUserId = baselineUser.get("user").get("id").asLong();
        grantLoyaltyPoints(baselineUserId, 5000);
        Long baselineBookingId = createBooking(baselineToken).get("id").asLong();
        JsonNode baselineRes = reserve(baselineToken, reservePayload(baselineBookingId, 1000, uniqueKey()),
            status().isCreated());
        assertDecimal(new BigDecimal("10000.00"), baselineRes.get("discountAmount"));

        // GOLD (seeded redemptionDiscountMultiplier 1.10): same 1000 points ⇒ 11000.00.
        JsonNode goldUser = registerUser("redeem-mult-gold");
        String goldToken = goldUser.get("token").asText();
        Long goldUserId = goldUser.get("user").get("id").asLong();
        grantLoyaltyPoints(goldUserId, 5000);
        adminAssign(goldUserId, "GOLD", "Force GOLD to observe the redemption discount multiplier");
        Long goldBookingId = createBooking(goldToken).get("id").asLong();
        JsonNode goldRes = reserve(goldToken, reservePayload(goldBookingId, 1000, uniqueKey()), status().isCreated());
        assertDecimal(new BigDecimal("11000.00"), goldRes.get("discountAmount"),
            "GOLD's seeded 1.10 redemptionDiscountMultiplier must boost the base 10000.00 discount");
    }

    @Test
    void redemptionDiscountForNoMembershipUserStaysAtBaselineMultiplier() throws Exception {
        JsonNode user = registerUser("redeem-mult-none");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        grantLoyaltyPoints(userId, 5000);
        // Deliberately never enroll / never assigned a tier.

        Long bookingId = createBooking(token).get("id").asLong();
        JsonNode res = reserve(token, reservePayload(bookingId, 1000, uniqueKey()), status().isCreated());
        assertDecimal(new BigDecimal("10000.00"), res.get("discountAmount"),
            "no CustomerMembership row ⇒ multiplier 1.00, identical to the pre-7.21 unmultiplied formula");
    }

    @Test
    void previewEndpointReflectsMultipliedDiscountToo() throws Exception {
        JsonNode user = registerUser("redeem-mult-preview");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        grantLoyaltyPoints(userId, 5000);
        adminAssign(userId, "GOLD", "Force GOLD to observe the multiplier in the preview response");

        JsonNode res = preview(token, previewByAmountPayload("500000", "1000"), status().isOk());
        assertEquals(1000, res.get("acceptedPoints").asLong());
        assertDecimal(new BigDecimal("11000.00"), res.get("discountAmount"),
            "preview must reflect the same GOLD multiplier as reserve, not just the unmultiplied base");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 9: SEEDED TIER DEFINITIONS CARRY redemptionDiscountMultiplier
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void seededTierDefinitionsCarryRedemptionDiscountMultiplier() throws Exception {
        JsonNode tiers = getJsonAdmin("/api/admin/membership/tiers");
        assertEquals(5, tiers.size());
        assertRedemptionMultiplier(tiers, "BRONZE", 1.00);
        assertRedemptionMultiplier(tiers, "SILVER", 1.05);
        assertRedemptionMultiplier(tiers, "GOLD", 1.10);
        assertRedemptionMultiplier(tiers, "PLATINUM", 1.15);
        assertRedemptionMultiplier(tiers, "DIAMOND", 1.25);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 10: FULL REGRESSION IS VERIFIED BY THE OVERALL ./mvnw test RUN
    // ═══════════════════════════════════════════════════════════════════════════

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private String adminTokenCache;

    private String adminToken() throws Exception {
        if (adminTokenCache == null) adminTokenCache = login("admin@planyourtrip.com", "admin123456");
        return adminTokenCache;
    }

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private JsonNode registerUser(String namePrefix) throws Exception {
        String email = namePrefix + "-" + counter.getAndIncrement() + "@test.com";
        String body = mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"" + namePrefix + " Tester\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private void adminAssign(Long userId, String tier, String reason) throws Exception {
        String payload = String.format(
            "{\"tier\":\"%s\",\"reason\":\"%s\",\"validUntil\":null,\"idempotencyKey\":null}", tier, reason);
        mvc.perform(post("/api/admin/users/" + userId + "/membership/assign")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isOk());
    }

    private void grantLoyaltyPoints(Long userId, long points) throws Exception {
        mvc.perform(post("/api/admin/users/" + userId + "/loyalty/grant")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format(
                    "{\"points\":%d,\"description\":\"Phase 7.21 test grant\"," +
                    "\"referenceType\":\"ADMIN\",\"referenceId\":null,\"idempotencyKey\":null}", points)))
            .andExpect(status().isCreated());
    }

    // ── Coupons ──────────────────────────────────────────────────────────────

    private void createMinimumTierCoupon(String code, String minimumTier) throws Exception {
        String payload = String.format("""
                {"code":"%s","name":"Min tier coupon %s","description":"Phase 7.21 test coupon",
                 "discountType":"PERCENTAGE","discountValue":10,
                 "validFrom":"%s","validUntil":"%s","active":true,"usageLimitPerUser":3,
                 "minimumTier":"%s"}
                """,
            code, code, TODAY.minusDays(1), TODAY.plusDays(300), minimumTier);
        mvc.perform(post("/api/admin/coupon-definitions")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isCreated());
    }

    private void createPlainCoupon(String code) throws Exception {
        String payload = String.format("""
                {"code":"%s","name":"Plain coupon %s","description":"Phase 7.21 test coupon",
                 "discountType":"PERCENTAGE","discountValue":10,
                 "validFrom":"%s","validUntil":"%s","active":true,"usageLimitPerUser":3}
                """,
            code, code, TODAY.minusDays(1), TODAY.plusDays(300));
        mvc.perform(post("/api/admin/coupon-definitions")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isCreated());
    }

    private void claim(String token, String code, ResultMatcher expected) throws Exception {
        mvc.perform(post("/api/me/coupons/claim")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"" + code + "\"}"))
            .andExpect(expected);
    }

    // ── Bookings / redemption ────────────────────────────────────────────────

    /** Mirrors LoyaltyRedemptionTest/MembershipTierTest's room resolution. */
    private synchronized Long resolveStdTwinRoomId() {
        if (stdTwinRoomId != null) return stdTwinRoomId;
        Long placeId = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        stdTwinRoomId = hotelRoomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "STD-TWIN".equals(r.getRoomCode()))
            .findFirst().orElseThrow().getId();
        return stdTwinRoomId;
    }

    private LocalDate nextCheckIn() {
        return TODAY.plusDays(5 + (dayCounter.getAndIncrement() % 80));
    }

    private JsonNode createBooking(String token) throws Exception {
        LocalDate ci = nextCheckIn();
        LocalDate co = ci.plusDays(1);
        String payload = String.format(
            "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\",\"adults\":2,\"children\":0,\"numberOfRooms\":1}",
            resolveStdTwinRoomId(), ci, co);
        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private String reservePayload(Long bookingId, long points, String idempotencyKey) {
        return String.format("{\"bookingId\":%d,\"requestedPoints\":%d,\"idempotencyKey\":\"%s\"}",
            bookingId, points, idempotencyKey);
    }

    private JsonNode reserve(String token, String payload, ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/loyalty/redemptions/reserve")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
    }

    private String previewByAmountPayload(String eligibleAmount, String requestedPoints) {
        return String.format("{\"bookingId\":null,\"eligibleAmount\":%s,\"requestedPoints\":%s}",
            eligibleAmount, requestedPoints);
    }

    private JsonNode preview(String token, String payload, ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/loyalty/redemptions/preview")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private String uniqueKey() {
        return "mri-test-key-" + counter.getAndIncrement();
    }

    // ── Misc ─────────────────────────────────────────────────────────────────

    private JsonNode getJsonAdmin(String url) throws Exception {
        String body = mvc.perform(get(url).header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private String uniqueCode(String prefix) {
        return ("MRI-" + prefix + "-" + counter.getAndIncrement()).toUpperCase();
    }

    private void assertDecimal(BigDecimal expected, JsonNode actual) {
        assertDecimal(expected, actual, null);
    }

    private void assertDecimal(BigDecimal expected, JsonNode actual, String message) {
        assertNotNull(actual, message);
        assertFalse(actual.isNull(), (message != null ? message + " — " : "") + "expected a value but was null");
        assertEquals(0, expected.compareTo(new BigDecimal(actual.asText())),
            (message != null ? message + " — " : "")
                + "expected " + expected.toPlainString() + " but was " + actual.asText());
    }

    private void assertRedemptionMultiplier(JsonNode tiers, String tier, double expected) {
        JsonNode match = null;
        for (JsonNode t : tiers) if (tier.equals(t.get("tier").asText())) match = t;
        assertNotNull(match, "seeded tier definition missing: " + tier);
        assertEquals(expected, match.get("redemptionDiscountMultiplier").asDouble(), 0.001);
    }
}
