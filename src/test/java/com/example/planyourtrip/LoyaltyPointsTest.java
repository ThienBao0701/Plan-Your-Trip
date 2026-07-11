package com.example.planyourtrip;

import com.example.planyourtrip.model.LoyaltyReferenceType;
import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.service.LoyaltyService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * LoyaltyPointsTest — Phase 7.18 (Loyalty Points Foundation).
 * Covers the lazily-created loyalty account, booking-completion earn
 * (basePoints = floor(finalPrice/10,000), minimum 1, idempotent), admin
 * grant, the immutable balanceBefore/balanceAfter ledger, idempotency-key
 * replay, the distinct EARN_REVIEW bonus path, the monotonic
 * lifetimePointsEarned guarantee, customer transaction filters, security
 * (customers can never grant their own points), the earn/grant
 * notifications, the MEMBER coupon-segment integration and the idempotent
 * demo seed. Every scenario registers its own throwaway user(s) so account
 * state never leaks across tests — mirrors TravelCreditTest's conventions.
 */
@SpringBootTest
@AutoConfigureMockMvc
class LoyaltyPointsTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired LoyaltyService loyaltyService;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;

    private static final AtomicInteger counter = new AtomicInteger(1);
    private static final LocalDate TODAY = LocalDate.now();

    private Long stdTwinRoomId;

    // ═══════════════════════════════════════════════════════════════════════════
    // 1: LAZY ACCOUNT CREATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void createsDefaultLoyaltyAccountLazilyWithZeroBalance() throws Exception {
        JsonNode user = registerUser("loyalty-lazy");
        JsonNode account = getJson(user.get("token").asText(), "/api/me/loyalty");
        assertNotNull(account.get("id"));
        assertEquals(0, account.get("currentBalance").asLong());
        assertEquals(0, account.get("lifetimePointsEarned").asLong());

        // Repeat access returns the same account (one per user), not a second one.
        JsonNode again = getJson(user.get("token").asText(), "/api/me/loyalty");
        assertEquals(account.get("id").asLong(), again.get("id").asLong());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 2-3: BOOKING-COMPLETION EARN / IDEMPOTENCY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void bookingCompletionAwardsCorrectPoints() throws Exception {
        JsonNode user = registerUser("loyalty-earn");
        String token = user.get("token").asText();

        JsonNode booking = createBooking(token, TODAY.plusDays(60), TODAY.plusDays(62));
        Long bookingId = booking.get("id").asLong();
        BigDecimal finalPrice = new BigDecimal(booking.get("finalPrice").asText());
        long expectedPoints = Math.max(
            finalPrice.divide(BigDecimal.valueOf(10_000), 0, RoundingMode.FLOOR).longValueExact(), 1L);

        completeBooking(bookingId);

        JsonNode account = getJson(token, "/api/me/loyalty");
        assertEquals(expectedPoints, account.get("currentBalance").asLong());
        assertEquals(expectedPoints, account.get("lifetimePointsEarned").asLong());

        JsonNode page = getJson(token, "/api/me/loyalty/transactions");
        assertEquals(1, page.get("totalElements").asLong());
        JsonNode tx = page.get("content").get(0);
        assertEquals("EARN_BOOKING", tx.get("transactionType").asText());
        assertEquals(expectedPoints, tx.get("points").asLong());
        assertEquals("BOOKING", tx.get("referenceType").asText());
        assertEquals(bookingId, tx.get("referenceId").asLong());
    }

    @Test
    void bookingCompletionPointAwardIsIdempotent() throws Exception {
        JsonNode user = registerUser("loyalty-idem-booking");
        String token = user.get("token").asText();

        JsonNode booking = createBooking(token, TODAY.plusDays(63), TODAY.plusDays(65));
        Long bookingId = booking.get("id").asLong();

        completeBooking(bookingId);
        JsonNode afterFirst = getJson(token, "/api/me/loyalty");
        long balanceAfterFirst = afterFirst.get("currentBalance").asLong();

        // Repeated trigger: force-set COMPLETED again via the same status endpoint.
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/status")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"COMPLETED\"}"))
            .andExpect(status().isOk());

        JsonNode afterSecond = getJson(token, "/api/me/loyalty");
        assertEquals(balanceAfterFirst, afterSecond.get("currentBalance").asLong(),
            "repeated completion must not double-award");

        JsonNode page = getJson(token, "/api/me/loyalty/transactions");
        assertEquals(1, page.get("totalElements").asLong(), "no second ledger row");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 4-6: ADMIN GRANT / LEDGER / IDEMPOTENCY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void adminGrantsLoyaltyPoints() throws Exception {
        JsonNode user = registerUser("loyalty-grant");
        Long userId = user.get("user").get("id").asLong();

        JsonNode tx = grant(userId, grantPayload(100, "Support goodwill", null), status().isCreated());

        assertEquals("GRANT", tx.get("transactionType").asText());
        assertEquals(100, tx.get("points").asLong());
        assertEquals(0, tx.get("balanceBefore").asLong());
        assertEquals(100, tx.get("balanceAfter").asLong());

        JsonNode account = getJson(user.get("token").asText(), "/api/me/loyalty");
        assertEquals(100, account.get("currentBalance").asLong());
        assertEquals(100, account.get("lifetimePointsEarned").asLong());
    }

    @Test
    void grantCreatesImmutableLedgerTransaction() throws Exception {
        JsonNode user = registerUser("loyalty-ledger");
        Long userId = user.get("user").get("id").asLong();

        grant(userId, grantPayload(60, "First grant", null), status().isCreated());
        grant(userId, grantPayload(40, "Second grant", null), status().isCreated());

        JsonNode page = getJson(user.get("token").asText(), "/api/me/loyalty/transactions");
        assertEquals(2, page.get("totalElements").asLong());

        // Newest first — the second grant chains exactly off the first one's balanceAfter.
        JsonNode second = page.get("content").get(0);
        JsonNode first = page.get("content").get(1);
        assertEquals(0, first.get("balanceBefore").asLong());
        assertEquals(60, first.get("balanceAfter").asLong());
        assertEquals(60, second.get("balanceBefore").asLong());
        assertEquals(100, second.get("balanceAfter").asLong());
        assertEquals("First grant", first.get("description").asText());

        // Re-reading returns identical ledger rows — nothing rewrote the first transaction.
        JsonNode reread = getJson(user.get("token").asText(), "/api/me/loyalty/transactions");
        assertEquals(first.get("id").asLong(), reread.get("content").get(1).get("id").asLong());
        assertEquals(60, reread.get("content").get(1).get("balanceAfter").asLong());
    }

    @Test
    void duplicateIdempotencyKeyDoesNotDoubleGrant() throws Exception {
        JsonNode user = registerUser("loyalty-idem-grant");
        Long userId = user.get("user").get("id").asLong();
        String key = "loyalty-idem-key-" + counter.getAndIncrement();

        JsonNode firstTx = grant(userId, grantPayload(80, "Idempotent grant", key), status().isCreated());
        JsonNode replayTx = grant(userId, grantPayload(80, "Idempotent grant", key), status().isCreated());

        assertEquals(firstTx.get("id").asLong(), replayTx.get("id").asLong(),
            "replay returns the original transaction");

        JsonNode account = getJson(user.get("token").asText(), "/api/me/loyalty");
        assertEquals(80, account.get("currentBalance").asLong(), "points granted exactly once");

        JsonNode page = getJson(user.get("token").asText(), "/api/me/loyalty/transactions");
        assertEquals(1, page.get("totalElements").asLong(), "no second ledger row");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 7: REVIEW BONUS — DISTINCT EARN_REVIEW PATH
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void reviewBonusAwardedViaDistinctEarnReviewPath() throws Exception {
        JsonNode user = registerUser("loyalty-review");
        Long userId = user.get("user").get("id").asLong();

        loyaltyService.awardReviewBonus(userId, 999L, 15, "Review bonus for a great review");

        JsonNode account = getJson(user.get("token").asText(), "/api/me/loyalty");
        assertEquals(15, account.get("currentBalance").asLong());
        assertEquals(15, account.get("lifetimePointsEarned").asLong());

        JsonNode page = getJson(user.get("token").asText(), "/api/me/loyalty/transactions?type=EARN_REVIEW");
        assertEquals(1, page.get("totalElements").asLong());
        JsonNode tx = page.get("content").get(0);
        assertEquals("EARN_REVIEW", tx.get("transactionType").asText());
        assertEquals("REVIEW", tx.get("referenceType").asText());
        assertEquals(999, tx.get("referenceId").asLong());

        // Separate from EARN_BOOKING — filtering by that type finds nothing.
        JsonNode bookingTypeFiltered = getJson(user.get("token").asText(),
            "/api/me/loyalty/transactions?type=EARN_BOOKING");
        assertEquals(0, bookingTypeFiltered.get("totalElements").asLong());

        // Idempotent on the same review reference — replay does not double-award.
        loyaltyService.awardReviewBonus(userId, 999L, 15, "Review bonus for a great review");
        JsonNode again = getJson(user.get("token").asText(), "/api/me/loyalty");
        assertEquals(15, again.get("currentBalance").asLong(), "same review reference must not double-award");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 8: LIFETIME POINTS EARNED — MONOTONIC
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void lifetimePointsEarnedOnlyIncreasesAndTracksTotalAcrossAwards() throws Exception {
        JsonNode user = registerUser("loyalty-monotonic");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();

        grant(userId, grantPayload(30, "Grant 1", null), status().isCreated());
        JsonNode after1 = getJson(token, "/api/me/loyalty");
        assertEquals(30, after1.get("lifetimePointsEarned").asLong());
        assertEquals(30, after1.get("currentBalance").asLong());

        loyaltyService.awardReviewBonus(userId, 1234L, 20, "Bonus");
        JsonNode after2 = getJson(token, "/api/me/loyalty");
        assertEquals(50, after2.get("lifetimePointsEarned").asLong());
        assertEquals(50, after2.get("currentBalance").asLong());

        JsonNode booking = createBooking(token, TODAY.plusDays(66), TODAY.plusDays(68));
        BigDecimal finalPrice = new BigDecimal(booking.get("finalPrice").asText());
        long bookingPoints = Math.max(
            finalPrice.divide(BigDecimal.valueOf(10_000), 0, RoundingMode.FLOOR).longValueExact(), 1L);
        completeBooking(booking.get("id").asLong());

        JsonNode after3 = getJson(token, "/api/me/loyalty");
        long expectedTotal = 50 + bookingPoints;
        assertEquals(expectedTotal, after3.get("lifetimePointsEarned").asLong());
        assertEquals(expectedTotal, after3.get("currentBalance").asLong());

        // Monotonic — never decreases across the whole sequence.
        assertTrue(after3.get("lifetimePointsEarned").asLong() >= after2.get("lifetimePointsEarned").asLong());
        assertTrue(after2.get("lifetimePointsEarned").asLong() >= after1.get("lifetimePointsEarned").asLong());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 9: TRANSACTION HISTORY FILTERS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void customerListsOwnLoyaltyTransactionsWithFilters() throws Exception {
        JsonNode user = registerUser("loyalty-filters");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();

        grant(userId, grantPayload(200, "Grant tx", null), status().isCreated());
        loyaltyService.awardReviewBonus(userId, 5555L, 10, "Review tx");

        JsonNode all = getJson(token, "/api/me/loyalty/transactions");
        assertEquals(2, all.get("totalElements").asLong());

        JsonNode grantsOnly = getJson(token, "/api/me/loyalty/transactions?type=GRANT");
        assertEquals(1, grantsOnly.get("totalElements").asLong());
        assertEquals("GRANT", grantsOnly.get("content").get(0).get("transactionType").asText());

        JsonNode inRange = getJson(token, "/api/me/loyalty/transactions?from="
            + TODAY.minusDays(1) + "&to=" + TODAY.plusDays(1));
        assertEquals(2, inRange.get("totalElements").asLong());

        JsonNode outOfRange = getJson(token, "/api/me/loyalty/transactions?from=" + TODAY.plusDays(2));
        assertEquals(0, outOfRange.get("totalElements").asLong());

        JsonNode paged = getJson(token, "/api/me/loyalty/transactions?page=0&size=1");
        assertEquals(1, paged.get("content").size());
        assertEquals(2, paged.get("totalElements").asLong());
        assertEquals(2, paged.get("totalPages").asInt());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 10-12: SECURITY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void userCannotGrantTheirOwnPoints() throws Exception {
        JsonNode user = registerUser("loyalty-selfgrant");
        Long userId = user.get("user").get("id").asLong();

        mvc.perform(post("/api/admin/users/" + userId + "/loyalty/grant")
                .header("Authorization", "Bearer " + user.get("token").asText())
                .contentType(MediaType.APPLICATION_JSON)
                .content(grantPayload(999999, "Self grant attempt", null)))
            .andExpect(status().isForbidden());

        JsonNode account = getJson(user.get("token").asText(), "/api/me/loyalty");
        assertEquals(0, account.get("currentBalance").asLong());
    }

    @Test
    void nonAdminLoyaltyAdminEndpointsRejected() throws Exception {
        JsonNode user = registerUser("loyalty-nonadmin");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();

        mvc.perform(get("/api/admin/users/" + userId + "/loyalty")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
        mvc.perform(post("/api/admin/users/" + userId + "/loyalty/grant")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(grantPayload(1000, "Nope", null)))
            .andExpect(status().isForbidden());
    }

    @Test
    void unauthenticatedLoyaltyEndpointsRejected() throws Exception {
        mvc.perform(get("/api/me/loyalty")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/me/loyalty/transactions")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/admin/users/1/loyalty")).andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 13-15: MEMBER COUPON-SEGMENT INTEGRATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void memberSegmentEligibleOnceLoyaltyAccountExists() throws Exception {
        JsonNode user = registerUser("loyalty-member-yes");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();

        // Force account creation via the lazy-create customer path.
        getJson(token, "/api/me/loyalty");
        // Phase 7.19 refinement: MEMBER now requires an active CustomerMembership,
        // not merely a LoyaltyAccount — see CustomerCouponService#evaluateSegment.
        mvc.perform(post("/api/me/membership/enroll").header("Authorization", "Bearer " + token))
            .andExpect(status().isCreated());

        String code = uniqueCode("member-yes");
        postMemberCoupon(code);

        // Claiming a MEMBER-segment coupon succeeds once membership exists.
        mvc.perform(post("/api/me/coupons/claim")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"" + code + "\"}"))
            .andExpect(status().isCreated());
    }

    @Test
    void memberSegmentIneligibleForUserWithNoLoyaltyAccount() throws Exception {
        JsonNode user = registerUser("loyalty-member-no");
        String token = user.get("token").asText();

        String code = uniqueCode("member-no");
        postMemberCoupon(code);

        // No loyalty account has ever been created for this user — claim must fail.
        mvc.perform(post("/api/me/coupons/claim")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"" + code + "\"}"))
            .andExpect(status().isBadRequest());
    }

    @Test
    void memberEligibilityCheckDoesNotAutoCreateLoyaltyAccount() throws Exception {
        JsonNode user = registerUser("loyalty-member-noauto");
        String token = user.get("token").asText();

        String code = uniqueCode("member-noauto");
        postMemberCoupon(code);

        // Attempt the claim (fails — no account) purely to trigger the MEMBER
        // eligibility evaluation path.
        mvc.perform(post("/api/me/coupons/claim")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"" + code + "\"}"))
            .andExpect(status().isBadRequest());

        // The admin support view must still report no account — eligibility
        // evaluation must never have created one as a side effect.
        JsonNode userId2 = user.get("user").get("id");
        JsonNode view = getJsonAdmin("/api/admin/users/" + userId2.asLong() + "/loyalty");
        assertTrue(view.get("account") == null || view.get("account").isNull(),
            "MEMBER eligibility check must not auto-create a LoyaltyAccount");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 16: NOTIFICATIONS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void loyaltyPointAwardNotificationCreated() throws Exception {
        JsonNode user = registerUser("loyalty-notify");
        Long userId = user.get("user").get("id").asLong();

        grant(userId, grantPayload(120, "INTERNAL-ADMIN-NOTE compensation case #42", null), status().isCreated());

        JsonNode notifications = mapper.readTree(mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + user.get("token").asText()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());

        JsonNode found = null;
        for (JsonNode n : notifications) {
            if ("Loyalty points added".equals(n.get("title").asText())) found = n;
        }
        assertNotNull(found, "grant must create a 'Loyalty points added' notification");
        assertEquals("PROMOTION", found.get("notificationType").asText());
        String message = found.get("message").asText();
        assertTrue(message.contains("120"), "message must include the points amount");
        assertFalse(message.contains("INTERNAL-ADMIN-NOTE"),
            "internal admin note must never leak into the user-facing message");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 17: SEED DATA
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void seededDemoLoyaltyAccountExistsAndIsRestartIdempotent() throws Exception {
        String demoToken = login("demo@planyourtrip.com", "demo123456");
        JsonNode account = getJson(demoToken, "/api/me/loyalty");
        assertTrue(account.get("currentBalance").asLong() >= 50,
            "demo account must carry at least the seeded 50-point grant");

        // Idempotent: re-running the seed logic directly must not double-grant.
        Long demoUserId = account.get("userId").asLong();
        long before = account.get("currentBalance").asLong();

        loyaltyService.adminGrant(demoUserId,
            new com.example.planyourtrip.dto.LoyaltyDto.LoyaltyGrantRequest(
                50L, "Seeded demo loyalty points", LoyaltyReferenceType.SYSTEM, null,
                "seed-demo-loyalty-grant"));

        JsonNode after = getJson(demoToken, "/api/me/loyalty");
        assertEquals(before, after.get("currentBalance").asLong(), "replaying the seed key must not double-grant");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 18: FULL REGRESSION IS VERIFIED BY THE OVERALL ./mvnw test RUN
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

    /** Returns the full auth response — token at "token", user id at "user.id". */
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

    private String grantPayload(long points, String description, String idempotencyKey) {
        return String.format("""
                {"points":%d,"description":"%s",
                 "referenceType":"ADMIN","referenceId":null,
                 "idempotencyKey":%s}
                """,
            points, description,
            idempotencyKey == null ? "null" : "\"" + idempotencyKey + "\"");
    }

    private JsonNode grant(Long userId, String payload,
                            org.springframework.test.web.servlet.ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/admin/users/" + userId + "/loyalty/grant")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
    }

    private JsonNode getJson(String token, String url) throws Exception {
        String body = mvc.perform(get(url)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode getJsonAdmin(String url) throws Exception {
        String body = mvc.perform(get(url)
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private String uniqueCode(String prefix) {
        return ("LOY-" + prefix + "-" + counter.getAndIncrement()).toUpperCase();
    }

    private void postMemberCoupon(String code) throws Exception {
        String payload = String.format("""
                {"code":"%s","name":"Member coupon %s","description":"Phase 7.18 test coupon",
                 "discountType":"PERCENTAGE","discountValue":10,
                 "validFrom":"%s","validUntil":"%s","active":true,"usageLimitPerUser":3,
                 "customerSegment":"MEMBER"}
                """,
            code, code, TODAY.minusDays(1), TODAY.plusDays(150));
        mvc.perform(post("/api/admin/coupon-definitions")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isCreated());
    }
}
