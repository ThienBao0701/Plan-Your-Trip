package com.example.planyourtrip;

import com.example.planyourtrip.model.CustomerMembership;
import com.example.planyourtrip.repository.CustomerMembershipRepository;
import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.dto.MembershipDto.CustomerMembershipResponse;
import com.example.planyourtrip.service.CustomerMembershipService;
import com.example.planyourtrip.service.LoyaltyService;
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
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * MembershipTierTest — Phase 7.19 (Membership Tier &amp; Loyalty Qualification).
 * Covers explicit/idempotent enrollment, initial-tier calculation, progress
 * (bounded 0-100), benefits/history reads, admin tier/benefit definition CRUD,
 * inactive-tier exclusion, the upgrade-only automatic evaluation hook (no
 * duplicate history, resets validity), the downgrade grace period (automatic
 * hook never lowers the tier — only an explicit admin reevaluation does),
 * manual assignment/clear, expiry-as-a-read-time-projection, the booking
 * points-multiplier integration (review bonus / admin grant deliberately
 * unmultiplied; no membership ⇒ 1.00), the refined MEMBER coupon-eligibility
 * signal, notifications and seed-data idempotency. Every scenario registers
 * its own throwaway user(s) so state never leaks across tests — mirrors
 * LoyaltyPointsTest's conventions. Booking date windows use a large, unique
 * per-test day offset so room inventory never collides with LoyaltyPointsTest
 * or other tests in this class.
 */
@SpringBootTest
@AutoConfigureMockMvc
class MembershipTierTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired LoyaltyService loyaltyService;
    @Autowired CustomerMembershipService customerMembershipService;
    @Autowired CustomerMembershipRepository membershipRepo;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;

    private static final AtomicInteger counter = new AtomicInteger(1);
    // Room inventory is only seeded 90 days out (DataInitializer#seedRoomInventory);
    // stay within that window. availableInventory is 18/day, so a small, distinct
    // per-call 3-day step is generous headroom against other test classes' usage.
    private static final AtomicInteger dayOffset = new AtomicInteger(3);
    private static final LocalDate TODAY = LocalDate.now();

    private Long stdTwinRoomId;

    // ═══════════════════════════════════════════════════════════════════════════
    // 1-4: ENROLLMENT / IDEMPOTENCY / PREREQUISITE / INITIAL TIER
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void customerEnrollsInMembership() throws Exception {
        JsonNode user = registerUser("mem-enroll");
        String token = user.get("token").asText();
        getJson(token, "/api/me/loyalty");

        JsonNode enrolled = enroll(token, status().isCreated());
        assertNotNull(enrolled.get("id"));
        assertEquals("BRONZE", enrolled.get("currentTier").asText());
        assertEquals("BRONZE", enrolled.get("effectiveTier").asText());
        assertFalse(enrolled.get("manuallyAssigned").asBoolean());
        assertFalse(enrolled.get("expired").asBoolean());
    }

    @Test
    void duplicateEnrollmentIsIdempotent() throws Exception {
        JsonNode user = registerUser("mem-enroll-dup");
        String token = user.get("token").asText();
        getJson(token, "/api/me/loyalty");

        JsonNode first = enroll(token, status().isCreated());
        JsonNode second = enroll(token, status().isCreated());
        assertEquals(first.get("id").asLong(), second.get("id").asLong());
    }

    @Test
    void enrollmentRequiresActiveLoyaltyAccount() throws Exception {
        JsonNode user = registerUser("mem-enroll-noaccount");
        String token = user.get("token").asText();
        // Deliberately never touch /api/me/loyalty first — no LoyaltyAccount exists.
        mvc.perform(post("/api/me/membership/enroll").header("Authorization", "Bearer " + token))
            .andExpect(status().isBadRequest());
    }

    @Test
    void initialTierCalculatedCorrectly() throws Exception {
        JsonNode user = registerUser("mem-initial");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();

        grant(userId, grantPayload(1000, "Pre-enroll boost", null), status().isCreated());
        completeBooking(createBookingId(token));
        completeBooking(createBookingId(token));

        JsonNode enrolled = enroll(token, status().isCreated());
        assertEquals("SILVER", enrolled.get("currentTier").asText(),
            "initial tier must be calculated from pre-existing metrics, not default to BRONZE");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 5-9: CUSTOMER READS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void customerGetsOwnMembership() throws Exception {
        JsonNode user = registerUser("mem-get");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        getJson(token, "/api/me/loyalty");
        enroll(token, status().isCreated());

        JsonNode membership = getJson(token, "/api/me/membership");
        assertEquals(userId, membership.get("userId").asLong());
        assertEquals("BRONZE", membership.get("currentTier").asText());
    }

    @Test
    void membershipProgressReturnsNextTier() throws Exception {
        JsonNode user = registerUser("mem-progress-next");
        String token = user.get("token").asText();
        getJson(token, "/api/me/loyalty");
        enroll(token, status().isCreated());

        JsonNode progress = getJson(token, "/api/me/membership/progress");
        assertEquals("SILVER", progress.get("nextTier").asText());
        assertEquals(1000, progress.get("pointsRequiredForNextTier").asLong());
        assertEquals(2, progress.get("bookingsRequiredForNextTier").asLong());
    }

    @Test
    void progressPercentageIsBounded0To100() throws Exception {
        JsonNode user = registerUser("mem-progress-bounds");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();

        // Fresh user, 0 points — progress toward SILVER must be exactly 0, never negative.
        JsonNode fresh = getJson(token, "/api/me/membership/progress");
        assertEquals(0.0, fresh.get("progressPercentage").asDouble(), 0.001);

        // Way more points than SILVER needs, but the booking gate isn't met — still BRONZE
        // effective, and the raw ratio (5000/1000 = 500%) must clamp down to 100, never overshoot.
        grant(userId, grantPayload(5000, "Overshoot", null), status().isCreated());
        JsonNode overshoot = getJson(token, "/api/me/membership/progress");
        double pct = overshoot.get("progressPercentage").asDouble();
        assertTrue(pct >= 0.0 && pct <= 100.0, "progressPercentage must stay within [0,100], was " + pct);
    }

    @Test
    void customerListsBenefitsForEffectiveTier() throws Exception {
        JsonNode user = registerUser("mem-benefits");
        String token = user.get("token").asText();
        getJson(token, "/api/me/loyalty");
        enroll(token, status().isCreated());

        JsonNode benefits = getJson(token, "/api/me/membership/benefits");
        assertTrue(benefits.isArray());
        boolean hasMemberCoupons = false;
        for (JsonNode b : benefits) {
            assertEquals("BRONZE", b.get("tier").asText());
            if ("MEMBER_ONLY_COUPONS".equals(b.get("benefitType").asText())) hasMemberCoupons = true;
        }
        assertTrue(hasMemberCoupons, "seeded BRONZE benefit must be present");
    }

    @Test
    void customerListsImmutableTierHistory() throws Exception {
        JsonNode user = registerUser("mem-history");
        String token = user.get("token").asText();
        getJson(token, "/api/me/loyalty");
        enroll(token, status().isCreated());

        JsonNode history = getJson(token, "/api/me/membership/history");
        assertEquals(1, history.size());
        assertEquals("INITIAL_ENROLLMENT", history.get(0).get("changeType").asText());
        assertTrue(history.get(0).get("previousTier").isNull());
        assertEquals("BRONZE", history.get(0).get("newTier").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 10-12: ADMIN TIER DEFINITIONS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void adminCreatesAndUpdatesTierDefinition() throws Exception {
        // All 5 canonical tiers are already seeded at startup — CREATE-for-a-new-tier
        // isn't reachable with a fixed 5-value enum (see #11 for the duplicate-create path).
        // UPDATE is the exercised mutation here.
        String payload = tierDefPayload("GOLD", "Gold Elite", "Updated description", 5000, 5, "1.30", true, 3);
        JsonNode updated = putJson("/api/admin/membership/tiers/GOLD", payload);
        assertEquals("Gold Elite", updated.get("displayName").asText());
        assertEquals(1.30, updated.get("pointsMultiplier").asDouble(), 0.001);

        JsonNode reread = getJsonAdmin("/api/admin/membership/tiers/GOLD");
        assertEquals("Gold Elite", reread.get("displayName").asText());

        // Restore for other tests.
        putJson("/api/admin/membership/tiers/GOLD",
            tierDefPayload("GOLD", "Gold", "Reached after 5,000 lifetime points and 5 completed bookings.",
                5000, 5, "1.25", true, 3));
    }

    @Test
    void duplicateTierDefinitionRejected() throws Exception {
        String payload = tierDefPayload("BRONZE", "Bronze Dup", "dup", 0, 0, "1.00", true, 1);
        mvc.perform(post("/api/admin/membership/tiers")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isConflict());
    }

    @Test
    void inactiveTierExcludedFromQualification() throws Exception {
        mvc.perform(patch("/api/admin/membership/tiers/SILVER/deactivate")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk());
        try {
            JsonNode user = registerUser("mem-inactive-tier");
            String token = user.get("token").asText();
            Long userId = user.get("user").get("id").asLong();

            grant(userId, grantPayload(1000, "Would qualify SILVER if active", null), status().isCreated());
            completeBooking(createBookingId(token));
            completeBooking(createBookingId(token));

            JsonNode membership = getJson(token, "/api/me/membership/progress");
            // SILVER is inactive, GOLD's thresholds (5000/5) aren't met — must fall back to BRONZE.
            assertEquals("BRONZE", membership.get("effectiveTier").asText());
        } finally {
            mvc.perform(patch("/api/admin/membership/tiers/SILVER/activate")
                    .header("Authorization", "Bearer " + adminToken()))
                .andExpect(status().isOk());
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 13-17: AUTOMATIC UPGRADE / DOWNGRADE GRACE PERIOD
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void loyaltyPointsAwardTriggersAutomaticUpgrade() throws Exception {
        JsonNode user = registerUser("mem-auto-upgrade");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        getJson(token, "/api/me/loyalty");
        enroll(token, status().isCreated());

        grant(userId, grantPayload(1000, "Boost", null), status().isCreated());
        completeBooking(createBookingId(token));
        completeBooking(createBookingId(token));

        JsonNode membership = getJson(token, "/api/me/membership");
        assertEquals("SILVER", membership.get("currentTier").asText());

        JsonNode history = getJson(token, "/api/me/membership/history");
        assertEquals(2, history.size(), "INITIAL_ENROLLMENT + exactly one AUTOMATIC_UPGRADE");
    }

    @Test
    void repeatedEvaluationCreatesNoDuplicateHistory() throws Exception {
        JsonNode user = registerUser("mem-no-dup-history");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        getJson(token, "/api/me/loyalty");
        enroll(token, status().isCreated());
        grant(userId, grantPayload(1000, "Boost", null), status().isCreated());
        completeBooking(createBookingId(token));
        completeBooking(createBookingId(token));

        int countBefore = getJson(token, "/api/me/membership/history").size();
        adminReevaluate(userId);
        int countAfterFirst = getJson(token, "/api/me/membership/history").size();
        adminReevaluate(userId);
        int countAfterSecond = getJson(token, "/api/me/membership/history").size();

        assertEquals(countBefore, countAfterFirst, "no tier change ⇒ no new history row");
        assertEquals(countBefore, countAfterSecond, "repeated no-op reevaluation must not accumulate history");
    }

    @Test
    void completedBookingThresholdEnforced() throws Exception {
        JsonNode user = registerUser("mem-booking-threshold");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        getJson(token, "/api/me/loyalty");
        enroll(token, status().isCreated());

        // Enough POINTS for SILVER but zero completed bookings.
        grant(userId, grantPayload(1000, "Points only", null), status().isCreated());

        JsonNode membership = getJson(token, "/api/me/membership");
        assertEquals("BRONZE", membership.get("currentTier").asText(),
            "points threshold alone must not qualify — booking threshold also required");
    }

    @Test
    void automaticUpgradeResetsValidityPeriod() throws Exception {
        JsonNode user = registerUser("mem-validity-reset");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        getJson(token, "/api/me/loyalty");
        JsonNode enrolled = enroll(token, status().isCreated());
        Instant validFromBefore = Instant.parse(enrolled.get("validFrom").asText());
        Instant validUntilBefore = Instant.parse(enrolled.get("validUntil").asText());

        grant(userId, grantPayload(1000, "Boost", null), status().isCreated());
        completeBooking(createBookingId(token));
        completeBooking(createBookingId(token));

        JsonNode after = getJson(token, "/api/me/membership");
        assertEquals("SILVER", after.get("currentTier").asText());
        Instant validFromAfter = Instant.parse(after.get("validFrom").asText());
        Instant validUntilAfter = Instant.parse(after.get("validUntil").asText());
        assertFalse(validFromAfter.isBefore(validFromBefore), "validFrom must be reset forward on automatic upgrade");
        assertFalse(validUntilAfter.isBefore(validUntilBefore), "validUntil must be reset forward on automatic upgrade");
    }

    @Test
    void pointsDeductionDoesNotImmediatelyDowngrade() throws Exception {
        JsonNode user = registerUser("mem-no-immediate-downgrade");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        getJson(token, "/api/me/loyalty");
        enroll(token, status().isCreated());
        adminAssign(userId, "GOLD", "Simulate a tier that no longer matches current metrics", null, status().isOk());

        // Any further point award runs the automatic hook — it must never downgrade.
        grant(userId, grantPayload(1, "Tiny award", null), status().isCreated());

        JsonNode membership = getJson(token, "/api/me/membership");
        assertEquals("GOLD", membership.get("currentTier").asText(),
            "the automatic post-award hook is upgrade-only; grace period preserves the current tier");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 18-21: MANUAL ASSIGNMENT / ADMIN REEVALUATION / CLEAR
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void adminManualAssignmentWorks() throws Exception {
        JsonNode user = registerUser("mem-manual-assign");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        getJson(token, "/api/me/loyalty");
        enroll(token, status().isCreated());

        JsonNode assigned = adminAssign(userId, "PLATINUM", "VIP customer support gesture", null, status().isOk());
        assertEquals("PLATINUM", assigned.get("currentTier").asText());
        assertTrue(assigned.get("manuallyAssigned").asBoolean());
    }

    @Test
    void manualAssignmentCreatesHistory() throws Exception {
        JsonNode user = registerUser("mem-manual-history");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        getJson(token, "/api/me/loyalty");
        enroll(token, status().isCreated());
        adminAssign(userId, "PLATINUM", "VIP customer support gesture", null, status().isOk());

        JsonNode history = getJson(token, "/api/me/membership/history");
        boolean found = false;
        for (JsonNode h : history) {
            if ("MANUAL_UPGRADE".equals(h.get("changeType").asText()) && "PLATINUM".equals(h.get("newTier").asText()))
                found = true;
        }
        assertTrue(found, "manual assignment must create a MANUAL_UPGRADE history row");
    }

    @Test
    void adminReevaluationCalculatesTier() throws Exception {
        JsonNode user = registerUser("mem-admin-reevaluate");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        getJson(token, "/api/me/loyalty");
        enroll(token, status().isCreated());
        grant(userId, grantPayload(1000, "Boost", null), status().isCreated());
        completeBooking(createBookingId(token));
        completeBooking(createBookingId(token));

        // Force back down to BRONZE even though metrics still justify SILVER.
        adminAssign(userId, "BRONZE", "Reset for reevaluate test", null, status().isOk());

        JsonNode result = adminReevaluate(userId);
        assertEquals("SILVER", result.get("newTier").asText());
        assertTrue(result.get("changed").asBoolean());

        JsonNode membership = getJson(token, "/api/me/membership");
        assertEquals("SILVER", membership.get("currentTier").asText());
        assertFalse(membership.get("manuallyAssigned").asBoolean());
    }

    @Test
    void clearManualAssignmentRestoresCalculatedTier() throws Exception {
        JsonNode user = registerUser("mem-clear-manual");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        getJson(token, "/api/me/loyalty");
        enroll(token, status().isCreated());
        adminAssign(userId, "PLATINUM", "Manual override with no matching metrics", null, status().isOk());

        JsonNode cleared = clearManualAssignment(userId);
        assertEquals("BRONZE", cleared.get("newTier").asText());

        JsonNode membership = getJson(token, "/api/me/membership");
        assertEquals("BRONZE", membership.get("currentTier").asText());
        assertFalse(membership.get("manuallyAssigned").asBoolean());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 22: EXPIRY IS A READ-TIME PROJECTION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void expiredMembershipReturnsEffectiveBronze() throws Exception {
        JsonNode user = registerUser("mem-expired");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        getJson(token, "/api/me/loyalty");
        enroll(token, status().isCreated());
        adminAssign(userId, "GOLD", "Setup for expiry test", null, status().isOk());

        CustomerMembership m = membershipRepo.findByUserIdAndActiveTrue(userId).orElseThrow();
        m.setValidUntil(Instant.now().minusSeconds(3600));
        membershipRepo.save(m);

        JsonNode membership = getJson(token, "/api/me/membership");
        assertEquals("GOLD", membership.get("currentTier").asText(), "stored tier is untouched by mere expiry");
        assertEquals("BRONZE", membership.get("effectiveTier").asText(), "effective tier falls back to BRONZE once expired");
        assertTrue(membership.get("expired").asBoolean());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 23-26: POINTS MULTIPLIER INTEGRATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void bookingLoyaltyAwardAppliesTierMultiplier() throws Exception {
        JsonNode user = registerUser("mem-multiplier");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        getJson(token, "/api/me/loyalty");
        enroll(token, status().isCreated());

        grant(userId, grantPayload(1000, "Boost to SILVER threshold", null), status().isCreated());
        // Two bookings cross the completed-bookings gate (still BRONZE-multiplied at award time).
        completeBooking(createBookingId(token));
        completeBooking(createBookingId(token));

        JsonNode membership = getJson(token, "/api/me/membership");
        assertEquals("SILVER", membership.get("currentTier").asText());

        // Third booking is now awarded AFTER the upgrade — SILVER's 1.10 multiplier applies.
        JsonNode b3 = createBooking(token);
        BigDecimal finalPrice = new BigDecimal(b3.get("finalPrice").asText());
        long basePoints = finalPrice.divide(BigDecimal.valueOf(10_000), 0, RoundingMode.FLOOR).longValueExact();
        long expectedMultiplied = Math.max(
            BigDecimal.valueOf(basePoints).multiply(new BigDecimal("1.10"))
                .setScale(0, RoundingMode.FLOOR).longValueExact(),
            1L);
        assertTrue(expectedMultiplied > basePoints, "test fixture must produce a visible multiplier effect");
        completeBooking(b3.get("id").asLong());

        JsonNode page = getJson(token, "/api/me/loyalty/transactions?type=EARN_BOOKING");
        JsonNode latest = page.get("content").get(0); // newest first
        assertEquals(expectedMultiplied, latest.get("points").asLong());
    }

    @Test
    void reviewBonusIsNotMultiplied() throws Exception {
        JsonNode user = registerUser("mem-review-unmultiplied");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        getJson(token, "/api/me/loyalty");
        enroll(token, status().isCreated());
        adminAssign(userId, "SILVER", "Force a multiplier > 1.00 to prove review bonus ignores it", null, status().isOk());

        loyaltyService.awardReviewBonus(userId, 424242L, 50, "Great review");

        JsonNode page = getJson(token, "/api/me/loyalty/transactions?type=EARN_REVIEW");
        assertEquals(50, page.get("content").get(0).get("points").asLong(), "review bonus must never be multiplied");
    }

    @Test
    void adminGrantIsNotMultiplied() throws Exception {
        JsonNode user = registerUser("mem-grant-unmultiplied");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        getJson(token, "/api/me/loyalty");
        enroll(token, status().isCreated());
        adminAssign(userId, "SILVER", "Force a multiplier > 1.00 to prove grant ignores it", null, status().isOk());

        JsonNode tx = grant(userId, grantPayload(200, "Support goodwill", null), status().isCreated());
        assertEquals(200, tx.get("points").asLong(), "admin grant must never be multiplied");
    }

    @Test
    void userWithoutMembershipReceivesMultiplierOfOne() throws Exception {
        JsonNode user = registerUser("mem-no-membership-baseline");
        String token = user.get("token").asText();
        // Deliberately never enroll.

        JsonNode booking = createBooking(token);
        BigDecimal finalPrice = new BigDecimal(booking.get("finalPrice").asText());
        long expectedPoints = Math.max(
            finalPrice.divide(BigDecimal.valueOf(10_000), 0, RoundingMode.FLOOR).longValueExact(), 1L);
        completeBooking(booking.get("id").asLong());

        JsonNode page = getJson(token, "/api/me/loyalty/transactions?type=EARN_BOOKING");
        assertEquals(expectedPoints, page.get("content").get(0).get("points").asLong(),
            "no CustomerMembership row ⇒ multiplier 1.00, identical to the unmultiplied 7.18 formula");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 27-29: MEMBER COUPON-ELIGIBILITY SIGNAL (refined)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void memberCouponEligibleWithActiveMembership() throws Exception {
        JsonNode user = registerUser("mem-coupon-yes");
        String token = user.get("token").asText();
        getJson(token, "/api/me/loyalty");
        enroll(token, status().isCreated());

        String code = uniqueCode("mem-coupon-yes");
        postMemberCoupon(code);
        mvc.perform(post("/api/me/coupons/claim")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"" + code + "\"}"))
            .andExpect(status().isCreated());
    }

    @Test
    void memberCouponIneligibleWithLoyaltyAccountOnly() throws Exception {
        JsonNode user = registerUser("mem-coupon-no");
        String token = user.get("token").asText();
        getJson(token, "/api/me/loyalty"); // LoyaltyAccount exists, but never enrolled in membership.

        String code = uniqueCode("mem-coupon-no");
        postMemberCoupon(code);
        mvc.perform(post("/api/me/coupons/claim")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"" + code + "\"}"))
            .andExpect(status().isBadRequest());
    }

    @Test
    void memberEligibilityCheckDoesNotAutoEnroll() throws Exception {
        JsonNode user = registerUser("mem-coupon-noauto");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        getJson(token, "/api/me/loyalty");

        String code = uniqueCode("mem-coupon-noauto");
        postMemberCoupon(code);
        mvc.perform(post("/api/me/coupons/claim")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"" + code + "\"}"))
            .andExpect(status().isBadRequest());

        // Never enrolled — admin support view must 404, proving eligibility evaluation created nothing.
        mvc.perform(get("/api/admin/users/" + userId + "/membership")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 30-32: NOTIFICATIONS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void enrollmentNotificationCreated() throws Exception {
        JsonNode user = registerUser("mem-notify-enroll");
        String token = user.get("token").asText();
        getJson(token, "/api/me/loyalty");
        enroll(token, status().isCreated());

        assertNotificationTitleExists(token, "Membership activated");
    }

    @Test
    void upgradeNotificationCreated() throws Exception {
        JsonNode user = registerUser("mem-notify-upgrade");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        getJson(token, "/api/me/loyalty");
        enroll(token, status().isCreated());
        grant(userId, grantPayload(1000, "Boost", null), status().isCreated());
        completeBooking(createBookingId(token));
        completeBooking(createBookingId(token));

        assertNotificationTitleExists(token, "Membership upgraded");
    }

    @Test
    void manualAssignmentNotificationCreated() throws Exception {
        JsonNode user = registerUser("mem-notify-manual");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        getJson(token, "/api/me/loyalty");
        enroll(token, status().isCreated());
        adminAssign(userId, "GOLD", "Support gesture", null, status().isOk());

        assertNotificationTitleExists(token, "Membership tier updated");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 33-34: SEED DATA
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void seededTierDefinitionsExist() throws Exception {
        JsonNode tiers = getJsonAdmin("/api/admin/membership/tiers");
        assertEquals(5, tiers.size());
        assertTierSeed(tiers, "BRONZE", 0, 0, 1.00);
        assertTierSeed(tiers, "SILVER", 1000, 2, 1.10);
        assertTierSeed(tiers, "GOLD", 5000, 5, 1.25);
        assertTierSeed(tiers, "PLATINUM", 15000, 10, 1.50);
        assertTierSeed(tiers, "DIAMOND", 40000, 20, 2.00);
    }

    @Test
    void seededDemoMembershipIsRestartIdempotent() throws Exception {
        String demoToken = login("demo@planyourtrip.com", "demo123456");
        JsonNode membership = getJson(demoToken, "/api/me/membership");
        assertEquals("BRONZE", membership.get("currentTier").asText(),
            "demo account carries only the seeded 50 loyalty points — not enough for SILVER");
        Long demoUserId = membership.get("userId").asLong();
        long beforeId = membership.get("id").asLong();

        CustomerMembershipResponse replay = customerMembershipService.enroll(demoUserId);
        assertEquals(beforeId, replay.id(), "replaying enrollment must not create a second membership row");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 35-36: SECURITY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void nonAdminMembershipAdminEndpointsRejected() throws Exception {
        JsonNode user = registerUser("mem-nonadmin");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();

        mvc.perform(get("/api/admin/membership/tiers").header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
        mvc.perform(post("/api/admin/membership/tiers").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(tierDefPayload("BRONZE", "x", "x", 0, 0, "1.00", true, 1)))
            .andExpect(status().isForbidden());
        mvc.perform(get("/api/admin/membership/benefits").header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
        mvc.perform(get("/api/admin/users/" + userId + "/membership").header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
        mvc.perform(post("/api/admin/users/" + userId + "/membership/assign")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(assignPayload("GOLD", "self promote", null)))
            .andExpect(status().isForbidden());
        mvc.perform(post("/api/admin/users/" + userId + "/membership/reevaluate")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
    }

    @Test
    void unauthenticatedMembershipCustomerEndpointsRejected() throws Exception {
        mvc.perform(get("/api/me/membership")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/me/membership/progress")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/me/membership/benefits")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/me/membership/history")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/me/membership/enroll")).andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 37: FULL REGRESSION IS VERIFIED BY THE OVERALL ./mvnw test RUN
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

    private synchronized Long resolveStdTwinRoomId() {
        if (stdTwinRoomId != null) return stdTwinRoomId;
        Long placeId = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        stdTwinRoomId = hotelRoomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "STD-TWIN".equals(r.getRoomCode()))
            .findFirst().orElseThrow().getId();
        return stdTwinRoomId;
    }

    private JsonNode createBooking(String token) throws Exception {
        int offset = dayOffset.getAndAdd(3);
        LocalDate ci = TODAY.plusDays(offset);
        LocalDate co = TODAY.plusDays(offset + 2);
        Long roomId = resolveStdTwinRoomId();
        String payload = String.format(
            "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\",\"adults\":1,\"children\":0,\"numberOfRooms\":1}",
            roomId, ci, co);
        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private Long createBookingId(String token) throws Exception {
        return createBooking(token).get("id").asLong();
    }

    private void completeBooking(Long bookingId) throws Exception {
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/status")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"COMPLETED\"}"))
            .andExpect(status().isOk());
    }

    private String grantPayload(long points, String description, String idempotencyKey) {
        return String.format("""
                {"points":%d,"description":"%s",
                 "referenceType":"ADMIN","referenceId":null,
                 "idempotencyKey":%s}
                """,
            points, description,
            idempotencyKey == null ? "null" : "\"" + idempotencyKey + "\"");
    }

    private JsonNode grant(Long userId, String payload, ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/admin/users/" + userId + "/loyalty/grant")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
    }

    private JsonNode enroll(String token, ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/me/membership/enroll").header("Authorization", "Bearer " + token))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private String assignPayload(String tier, String reason, String validUntilIso) {
        return String.format("{\"tier\":\"%s\",\"reason\":\"%s\",\"validUntil\":%s,\"idempotencyKey\":null}",
            tier, reason, validUntilIso == null ? "null" : "\"" + validUntilIso + "\"");
    }

    private JsonNode adminAssign(Long userId, String tier, String reason, String validUntilIso,
                                  ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/admin/users/" + userId + "/membership/assign")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(assignPayload(tier, reason, validUntilIso)))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode adminReevaluate(Long userId) throws Exception {
        String body = mvc.perform(post("/api/admin/users/" + userId + "/membership/reevaluate")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode clearManualAssignment(Long userId) throws Exception {
        String body = mvc.perform(post("/api/admin/users/" + userId + "/membership/clear-manual-assignment")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private String tierDefPayload(String tier, String displayName, String description,
                                   long minPoints, int minBookings, String multiplier, boolean active, int sortOrder) {
        return String.format("""
                {"tier":"%s","displayName":"%s","description":"%s",
                 "minimumLifetimePoints":%d,"minimumCompletedBookings":%d,
                 "pointsMultiplier":%s,"active":%b,"sortOrder":%d}
                """,
            tier, displayName, description, minPoints, minBookings, multiplier, active, sortOrder);
    }

    private JsonNode putJson(String url, String payload) throws Exception {
        String body = mvc.perform(put(url)
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode getJson(String token, String url) throws Exception {
        String body = mvc.perform(get(url).header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode getJsonAdmin(String url) throws Exception {
        String body = mvc.perform(get(url).header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private String uniqueCode(String prefix) {
        return ("MTIER-" + prefix + "-" + counter.getAndIncrement()).toUpperCase();
    }

    private void postMemberCoupon(String code) throws Exception {
        String payload = String.format("""
                {"code":"%s","name":"Member coupon %s","description":"Phase 7.19 test coupon",
                 "discountType":"PERCENTAGE","discountValue":10,
                 "validFrom":"%s","validUntil":"%s","active":true,"usageLimitPerUser":3,
                 "customerSegment":"MEMBER"}
                """,
            code, code, TODAY.minusDays(1), TODAY.plusDays(300));
        mvc.perform(post("/api/admin/coupon-definitions")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isCreated());
    }

    private void assertNotificationTitleExists(String token, String title) throws Exception {
        JsonNode notifications = getJson(token, "/api/me/notifications");
        boolean found = false;
        for (JsonNode n : notifications) {
            if (title.equals(n.get("title").asText())) found = true;
        }
        assertTrue(found, "expected a notification titled '" + title + "'");
    }

    private void assertTierSeed(JsonNode tiers, String tier, long minPoints, int minBookings, double multiplier) {
        JsonNode match = null;
        for (JsonNode t : tiers) if (tier.equals(t.get("tier").asText())) match = t;
        assertNotNull(match, "seeded tier definition missing: " + tier);
        assertEquals(minPoints, match.get("minimumLifetimePoints").asLong());
        assertEquals(minBookings, match.get("minimumCompletedBookings").asInt());
        assertEquals(multiplier, match.get("pointsMultiplier").asDouble(), 0.001);
        assertTrue(match.get("active").asBoolean());
    }
}
