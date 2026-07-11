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

import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * ReferralRewardTest — Phase 7.22 (Referral &amp; Invite Rewards).
 * Covers lazy referral-code creation, code use + validation (self-referral,
 * duplicate, unknown), qualifying-booking reward granting for BOTH parties
 * through the EXISTING Loyalty / Coupon / TravelCredit primitives, idempotency
 * on repeated completion triggers, the minimum-qualifying-amount rule, admin
 * campaign CRUD/activate/deactivate, reward-time notifications and security.
 * Each scenario registers throwaway users and creates its own campaign (which
 * becomes the newest applicable one at use time) so state never leaks.
 */
@SpringBootTest
@AutoConfigureMockMvc
class ReferralRewardTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;

    private static final AtomicInteger counter = new AtomicInteger(1);
    private static final LocalDate TODAY = LocalDate.now();

    private Long stdTwinRoomId;
    private String adminTokenCache;

    // ═══════════════════════════════════════════════════════════════════════
    // 1: LAZY REFERRAL CODE CREATION
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void referralCodeCreatedLazilyAndStableAcrossGets() throws Exception {
        JsonNode user = registerUser("ref-lazy");
        String token = user.get("token").asText();

        JsonNode first = getJson(token, "/api/me/referral");
        String code = first.get("code").asText();
        assertNotNull(code);
        assertFalse(code.isBlank());
        assertEquals(0, first.get("successfulReferrals").asLong());
        assertEquals(0, first.get("pendingReferrals").asLong());

        // Repeat access returns the SAME immutable code (one per user).
        JsonNode again = getJson(token, "/api/me/referral");
        assertEquals(code, again.get("code").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 2: USING A VALID CODE CREATES A USED REFERRAL REWARD
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void usingValidCodeCreatesUsedReferralReward() throws Exception {
        createCampaign(campaign(uniqueCode("ref"), 200L, 100L));
        String inviterCode = codeOf(registerUser("ref-inviter"));
        JsonNode invitee = registerUser("ref-invitee");
        String inviteeToken = invitee.get("token").asText();

        JsonNode reward = useCode(inviteeToken, inviterCode, status().isOk());
        assertEquals("USED", reward.get("status").asText());
        assertEquals("INVITEE", reward.get("role").asText());

        // Shows up in the invitee's history as USED.
        JsonNode history = getJson(inviteeToken, "/api/me/referral/history");
        assertEquals(1, history.size());
        assertEquals("USED", history.get(0).get("status").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 3-5: USE-CODE VALIDATION
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void selfReferralRejected() throws Exception {
        createCampaign(campaign(uniqueCode("ref"), 200L, 100L));
        JsonNode user = registerUser("ref-self");
        String token = user.get("token").asText();
        String ownCode = getJson(token, "/api/me/referral").get("code").asText();

        useCode(token, ownCode, status().isBadRequest());
    }

    @Test
    void duplicateUsageRejected() throws Exception {
        createCampaign(campaign(uniqueCode("ref"), 200L, 100L));
        String firstInviterCode = codeOf(registerUser("ref-dup-a"));
        String secondInviterCode = codeOf(registerUser("ref-dup-b"));
        JsonNode invitee = registerUser("ref-dup-invitee");
        String inviteeToken = invitee.get("token").asText();

        useCode(inviteeToken, firstInviterCode, status().isOk());
        // Using ANY second code (or the same one again) is rejected with 409.
        useCode(inviteeToken, secondInviterCode, status().isConflict());
        useCode(inviteeToken, firstInviterCode, status().isConflict());
    }

    @Test
    void unknownCodeRejected() throws Exception {
        createCampaign(campaign(uniqueCode("ref"), 200L, 100L));
        JsonNode user = registerUser("ref-unknown");
        useCode(user.get("token").asText(), "NOSUCHCODE9", status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 6-8: QUALIFYING BOOKING GRANTS LOYALTY POINTS TO BOTH PARTIES
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void qualifyingBookingGrantsLoyaltyPointsToBothParties() throws Exception {
        createCampaign(campaign(uniqueCode("ref"), 200L, 100L));
        JsonNode inviter = registerUser("ref-pts-inviter");
        String inviterToken = inviter.get("token").asText();
        String inviterCode = getJson(inviterToken, "/api/me/referral").get("code").asText();

        JsonNode invitee = registerUser("ref-pts-invitee");
        String inviteeToken = invitee.get("token").asText();
        useCode(inviteeToken, inviterCode, status().isOk());

        // Invitee's first completed booking triggers qualification.
        JsonNode booking = createBooking(inviteeToken, TODAY.plusDays(70), TODAY.plusDays(72));
        completeBooking(booking.get("id").asLong());

        // Inviter has no booking of their own — their loyalty balance is exactly the referral grant.
        JsonNode inviterAccount = getJson(inviterToken, "/api/me/loyalty");
        assertEquals(200, inviterAccount.get("currentBalance").asLong());
        JsonNode inviterGrants = getJson(inviterToken, "/api/me/loyalty/transactions?type=GRANT");
        assertEquals(1, inviterGrants.get("totalElements").asLong());
        assertEquals(200, inviterGrants.get("content").get(0).get("points").asLong());
        assertEquals("SYSTEM", inviterGrants.get("content").get(0).get("referenceType").asText());

        // Invitee receives their configured 100-point GRANT (separate from the
        // EARN_BOOKING points their own completed booking also awarded).
        JsonNode inviteeGrants = getJson(inviteeToken, "/api/me/loyalty/transactions?type=GRANT");
        assertEquals(1, inviteeGrants.get("totalElements").asLong());
        assertEquals(100, inviteeGrants.get("content").get(0).get("points").asLong());

        // Reward is now REWARDED for both, with the qualifying booking recorded.
        JsonNode inviterHistory = getJson(inviterToken, "/api/me/referral/history");
        assertEquals("REWARDED", inviterHistory.get(0).get("status").asText());
        assertEquals(booking.get("id").asLong(), inviterHistory.get(0).get("qualifyingBookingId").asLong());

        JsonNode myRef = getJson(inviterToken, "/api/me/referral");
        assertEquals(1, myRef.get("successfulReferrals").asLong());
        assertEquals(0, myRef.get("pendingReferrals").asLong());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 9: COUPON REWARD INTEGRATION (reuses CustomerCoupon issuance path)
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void couponRewardIssuedToBothPartiesViaCustomerCouponPath() throws Exception {
        Long couponDefId = createCouponDefinition(uniqueCode("REFCOUP"));
        Map<String, Object> c = campaign(uniqueCode("ref"), null, null);
        c.put("inviterRewardCouponDefinitionId", couponDefId);
        c.put("inviteeRewardCouponDefinitionId", couponDefId);
        createCampaign(c);

        JsonNode inviter = registerUser("ref-coup-inviter");
        String inviterToken = inviter.get("token").asText();
        String inviterCode = getJson(inviterToken, "/api/me/referral").get("code").asText();
        JsonNode invitee = registerUser("ref-coup-invitee");
        String inviteeToken = invitee.get("token").asText();
        useCode(inviteeToken, inviterCode, status().isOk());

        JsonNode booking = createBooking(inviteeToken, TODAY.plusDays(73), TODAY.plusDays(75));
        completeBooking(booking.get("id").asLong());

        // Both parties now hold exactly one AVAILABLE coupon of that definition.
        assertEquals(1, ownedCouponCount(inviterToken, couponDefId));
        assertEquals(1, ownedCouponCount(inviteeToken, couponDefId));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 10: TRAVEL CREDIT REWARD INTEGRATION (reuses TravelCreditService.grant)
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void travelCreditRewardGrantedViaTravelCreditService() throws Exception {
        Map<String, Object> c = campaign(uniqueCode("ref"), null, null);
        c.put("inviterRewardCreditAmount", "50000");
        c.put("inviterRewardCreditCurrency", "VND");
        c.put("inviteeRewardCreditAmount", "25000");
        c.put("inviteeRewardCreditCurrency", "VND");
        createCampaign(c);

        JsonNode inviter = registerUser("ref-cred-inviter");
        String inviterToken = inviter.get("token").asText();
        String inviterCode = getJson(inviterToken, "/api/me/referral").get("code").asText();
        JsonNode invitee = registerUser("ref-cred-invitee");
        String inviteeToken = invitee.get("token").asText();
        useCode(inviteeToken, inviterCode, status().isOk());

        JsonNode booking = createBooking(inviteeToken, TODAY.plusDays(76), TODAY.plusDays(78));
        completeBooking(booking.get("id").asLong());

        JsonNode inviterCredit = getJson(inviterToken, "/api/me/travel-credits");
        assertEquals(0, new java.math.BigDecimal("50000").compareTo(
            new java.math.BigDecimal(inviterCredit.get("balance").asText())));
        JsonNode inviteeCredit = getJson(inviteeToken, "/api/me/travel-credits");
        assertEquals(0, new java.math.BigDecimal("25000").compareTo(
            new java.math.BigDecimal(inviteeCredit.get("balance").asText())));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 11: REWARD GRANTED ONLY ONCE (idempotent on repeated completion trigger)
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void rewardGrantedOnlyOnceOnRepeatedCompletion() throws Exception {
        createCampaign(campaign(uniqueCode("ref"), 200L, 100L));
        JsonNode inviter = registerUser("ref-idem-inviter");
        String inviterToken = inviter.get("token").asText();
        String inviterCode = getJson(inviterToken, "/api/me/referral").get("code").asText();
        JsonNode invitee = registerUser("ref-idem-invitee");
        String inviteeToken = invitee.get("token").asText();
        useCode(inviteeToken, inviterCode, status().isOk());

        JsonNode booking = createBooking(inviteeToken, TODAY.plusDays(79), TODAY.plusDays(81));
        Long bookingId = booking.get("id").asLong();
        completeBooking(bookingId);
        completeBooking(bookingId); // repeated completion trigger
        completeBooking(bookingId);

        // Inviter still has exactly one 200-point grant.
        JsonNode inviterAccount = getJson(inviterToken, "/api/me/loyalty");
        assertEquals(200, inviterAccount.get("currentBalance").asLong(),
            "repeated completion must not re-grant the referral reward");
        JsonNode inviterGrants = getJson(inviterToken, "/api/me/loyalty/transactions?type=GRANT");
        assertEquals(1, inviterGrants.get("totalElements").asLong(), "no second referral grant row");
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 12: NON-QUALIFYING BOOKING (below minimum) DOES NOT TRIGGER REWARD
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void bookingBelowMinimumDoesNotTriggerReward() throws Exception {
        Map<String, Object> c = campaign(uniqueCode("ref"), 200L, 100L);
        c.put("minimumQualifyingBookingAmount", "999999999"); // far above any seeded room price
        createCampaign(c);

        JsonNode inviter = registerUser("ref-min-inviter");
        String inviterToken = inviter.get("token").asText();
        String inviterCode = getJson(inviterToken, "/api/me/referral").get("code").asText();
        JsonNode invitee = registerUser("ref-min-invitee");
        String inviteeToken = invitee.get("token").asText();
        useCode(inviteeToken, inviterCode, status().isOk());

        JsonNode booking = createBooking(inviteeToken, TODAY.plusDays(82), TODAY.plusDays(84));
        completeBooking(booking.get("id").asLong());

        // No referral reward granted — inviter has no loyalty grant, reward stays USED.
        JsonNode inviterGrants = getJson(inviterToken, "/api/me/loyalty/transactions?type=GRANT");
        assertEquals(0, inviterGrants.get("totalElements").asLong());
        JsonNode inviterHistory = getJson(inviterToken, "/api/me/referral/history");
        assertEquals("USED", inviterHistory.get(0).get("status").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 13-14: ADMIN CAMPAIGN CRUD + SECURITY
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void adminCreatesUpdatesActivatesDeactivatesCampaign() throws Exception {
        String code = uniqueCode("ref");
        JsonNode created = createCampaign(campaign(code, 150L, 75L));
        Long id = created.get("id").asLong();
        assertTrue(created.get("active").asBoolean());
        assertEquals(150, created.get("inviterRewardPoints").asLong());

        // Get + list.
        JsonNode got = getJsonAdmin("/api/admin/referral/campaigns/" + id);
        assertEquals(code, got.get("code").asText());
        JsonNode list = getJsonAdmin("/api/admin/referral/campaigns");
        assertTrue(list.isArray() && list.size() >= 1);

        // Update the reward points.
        Map<String, Object> upd = campaign(code, 300L, 120L);
        String updBody = mvc.perform(put("/api/admin/referral/campaigns/" + id)
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(upd)))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals(300, mapper.readTree(updBody).get("inviterRewardPoints").asLong());

        // Deactivate then reactivate.
        mvc.perform(post("/api/admin/referral/campaigns/" + id + "/deactivate")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.active").value(false));
        mvc.perform(post("/api/admin/referral/campaigns/" + id + "/activate")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.active").value(true));

        // Duplicate code rejected.
        mvc.perform(post("/api/admin/referral/campaigns")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(campaign(code, 10L, 10L))))
            .andExpect(status().isConflict());
    }

    @Test
    void nonAdminCannotAccessCampaignAdminEndpoints() throws Exception {
        JsonNode user = registerUser("ref-nonadmin");
        String token = user.get("token").asText();

        mvc.perform(get("/api/admin/referral/campaigns")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
        mvc.perform(post("/api/admin/referral/campaigns")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(campaign(uniqueCode("ref"), 10L, 10L))))
            .andExpect(status().isForbidden());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 15: NOTIFICATIONS AT REWARD TIME FOR BOTH PARTIES
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void notificationsCreatedForBothPartiesAtRewardTime() throws Exception {
        createCampaign(campaign(uniqueCode("ref"), 200L, 100L));
        JsonNode inviter = registerUser("ref-notif-inviter");
        String inviterToken = inviter.get("token").asText();
        String inviterCode = getJson(inviterToken, "/api/me/referral").get("code").asText();
        JsonNode invitee = registerUser("ref-notif-invitee");
        String inviteeToken = invitee.get("token").asText();
        useCode(inviteeToken, inviterCode, status().isOk());

        JsonNode booking = createBooking(inviteeToken, TODAY.plusDays(85), TODAY.plusDays(87));
        completeBooking(booking.get("id").asLong());

        assertTrue(hasNotification(inviterToken, "You earned a referral reward"),
            "inviter must get a referral-reward notification");
        assertTrue(hasNotification(inviteeToken, "Welcome reward unlocked"),
            "invitee must get a welcome-reward notification");
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 16: SECURITY — UNAUTHENTICATED CUSTOMER ENDPOINTS REJECTED
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void unauthenticatedReferralEndpointsRejected() throws Exception {
        mvc.perform(get("/api/me/referral")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/me/referral/history")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/me/referral/use")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"WHATEVER1\"}"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════

    private Map<String, Object> campaign(String code, Long inviterPoints, Long inviteePoints) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("code", code);
        m.put("name", "Campaign " + code);
        m.put("inviterRewardPoints", inviterPoints);
        m.put("inviteeRewardPoints", inviteePoints);
        m.put("active", true);
        return m;
    }

    private JsonNode createCampaign(Map<String, Object> body) throws Exception {
        String resp = mvc.perform(post("/api/admin/referral/campaigns")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(body)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp);
    }

    private Long createCouponDefinition(String code) throws Exception {
        String payload = String.format("""
                {"code":"%s","name":"Referral coupon %s","description":"Phase 7.22 test coupon",
                 "discountType":"PERCENTAGE","discountValue":10,
                 "validFrom":"%s","validUntil":"%s","active":true,"usageLimitPerUser":5}
                """,
            code, code, TODAY.minusDays(1), TODAY.plusDays(200));
        String resp = mvc.perform(post("/api/admin/coupon-definitions")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp).get("id").asLong();
    }

    private int ownedCouponCount(String token, Long couponDefId) throws Exception {
        JsonNode coupons = getJson(token, "/api/me/coupons");
        int count = 0;
        for (JsonNode c : coupons) {
            JsonNode def = c.get("coupon");
            if (def != null && def.get("id").asLong() == couponDefId) count++;
        }
        return count;
    }

    private boolean hasNotification(String token, String title) throws Exception {
        JsonNode notifications = getJson(token, "/api/me/notifications");
        for (JsonNode n : notifications) {
            if (title.equals(n.get("title").asText())) return true;
        }
        return false;
    }

    private String codeOf(JsonNode user) throws Exception {
        return getJson(user.get("token").asText(), "/api/me/referral").get("code").asText();
    }

    private JsonNode useCode(String token, String code,
                             org.springframework.test.web.servlet.ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/me/referral/use")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"" + code + "\"}"))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
    }

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

    private JsonNode createBooking(String token, LocalDate ci, LocalDate co) throws Exception {
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

    private synchronized Long resolveStdTwinRoomId() {
        if (stdTwinRoomId != null) return stdTwinRoomId;
        Long placeId = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        stdTwinRoomId = hotelRoomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "STD-TWIN".equals(r.getRoomCode()))
            .findFirst().orElseThrow().getId();
        return stdTwinRoomId;
    }

    private void completeBooking(Long bookingId) throws Exception {
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/status")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"COMPLETED\"}"))
            .andExpect(status().isOk());
    }

    private JsonNode getJson(String token, String url) throws Exception {
        String body = mvc.perform(get(url)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode getJsonAdmin(String url) throws Exception {
        return getJson(adminToken(), url);
    }

    private String uniqueCode(String prefix) {
        return (prefix + "-" + counter.getAndIncrement()).toUpperCase();
    }
}
