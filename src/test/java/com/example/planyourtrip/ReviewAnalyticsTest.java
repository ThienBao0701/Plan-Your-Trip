package com.example.planyourtrip;

import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultMatcher;

import java.time.LocalDate;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Phase 7.46 — Review Analytics (READ-ONLY).
 *
 * Two additive endpoints, no new review/moderation logic and zero mutation:
 *   • GET /api/partner/places/{placeId}/reviews/analytics — single owned place, detailed breakdown.
 *   • GET /api/admin/reviews/analytics/overview          — platform-wide aggregates.
 *
 * Reuses the seeded partner (owns grand-palace) + FAM-DBL booking/review/approve/reply flow, mirroring
 * {@link ReviewTest} / {@link PartnerReviewReplyTest}. Because the H2 instance is shared across test
 * classes, place-level assertions use before/after DELTAS rather than absolute counts. Deterministic
 * zero-data behaviour is proven against a freshly-created owned place that has no reviews at all.
 */
@SpringBootTest
@AutoConfigureMockMvc
class ReviewAnalyticsTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;
    @Autowired UserRepository userRepo;
    @Autowired PartnerProfileRepository partnerProfileRepo;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;

    private String adminToken;
    private String userToken;      // demo — the review author
    private String partnerToken;   // seeded partner — OWNS grand-palace
    private Long famDblRoomId;
    private Long hotelPlaceId;

    private static final LocalDate TODAY = LocalDate.now();
    private static final AtomicInteger dayCursor = new AtomicInteger(1);
    private static final AtomicInteger counter = new AtomicInteger(1);

    @BeforeEach
    void setup() throws Exception {
        adminToken   = login("admin@planyourtrip.com",   "admin123456");
        userToken    = login("demo@planyourtrip.com",    "demo123456");
        partnerToken = login("partner@planyourtrip.com", "partner123456");

        hotelPlaceId = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(hotelPlaceId).orElseThrow().getId();
        famDblRoomId = hotelRoomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "FAM-DBL".equals(r.getRoomCode()))
            .findFirst().orElseThrow().getId();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PARTNER — per-place detailed analytics (happy path, deltas)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partner_placeReviewAnalytics_reflectsStatusBreakdownAveragesStarsAndReplies() throws Exception {
        JsonNode before = placeAnalytics(partnerToken, hotelPlaceId, null, null, status().isOk());

        // Two APPROVED (with category ratings), one REJECTED, one PENDING.
        Long r1 = createReviewFull(createCompletedBooking(), 5, 5, 4, 5, 4, 3, "Excellent").get("id").asLong();
        moderate(r1, "APPROVED", null);
        Long r2 = createReviewFull(createCompletedBooking(), 4, 4, 4, 4, 4, 4, "Very good").get("id").asLong();
        moderate(r2, "APPROVED", null);
        Long r3 = createReviewFull(createCompletedBooking(), 2, null, null, null, null, null, "Poor").get("id").asLong();
        moderate(r3, "REJECTED", "Off topic");
        createReviewFull(createCompletedBooking(), 3, null, null, null, null, null, "Pending"); // left PENDING

        // Partner replies to one APPROVED review.
        reply(partnerToken, r1, "Thank you!");

        JsonNode after = placeAnalytics(partnerToken, hotelPlaceId, null, null, status().isOk());

        assertEquals(hotelPlaceId, after.get("placeId").asLong());
        assertEquals("Grand Palace Hotel Vũng Tàu", after.get("placeName").asText());

        assertEquals(before.get("totalReviews").asLong() + 4, after.get("totalReviews").asLong());
        assertEquals(before.get("approvedReviews").asLong() + 2, after.get("approvedReviews").asLong());
        assertEquals(before.get("pendingReviews").asLong() + 1, after.get("pendingReviews").asLong());
        assertEquals(before.get("rejectedReviews").asLong() + 1, after.get("rejectedReviews").asLong());
        assertEquals(before.get("hiddenReviews").asLong(), after.get("hiddenReviews").asLong());
        assertEquals(before.get("reportedReviews").asLong(), after.get("reportedReviews").asLong());

        // Star distribution is over APPROVED reviews; the two we approved were 5★ and 4★.
        assertTrue(after.get("starDistribution").get("5").asLong()
            >= before.get("starDistribution").get("5").asLong() + 1);
        assertTrue(after.get("starDistribution").get("4").asLong()
            >= before.get("starDistribution").get("4").asLong() + 1);

        // Averages over APPROVED are in-band and category averages are now populated.
        double avg = after.get("averageOverallRating").asDouble();
        assertTrue(avg >= 1.0 && avg <= 5.0, "avg overall must be a valid star mean");
        assertTrue(after.get("averageCleanliness").asDouble() > 0.0);
        assertTrue(after.get("averageService").asDouble() > 0.0);
        assertTrue(after.get("averageLocation").asDouble() > 0.0);
        assertTrue(after.get("averageValue").asDouble() > 0.0);
        assertTrue(after.get("averageFacilities").asDouble() > 0.0);

        assertEquals(before.get("partnerReplyCount").asLong() + 1, after.get("partnerReplyCount").asLong());
        double rate = after.get("partnerReplyRate").asDouble();
        assertTrue(rate >= 0.0 && rate <= 100.0, "reply rate is a 0–100 percentage");

        assertFalse(after.get("latestReviewAt").isNull(), "latestReviewAt present once reviews exist");
        assertEquals(before.get("reviewsInRange").asLong() + 4, after.get("reviewsInRange").asLong());
        double avgInRange = after.get("averageRatingInRange").asDouble();
        assertTrue(avgInRange >= 1.0 && avgInRange <= 5.0);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PARTNER — date-range filtering
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partner_placeReviewAnalytics_dateRange_excludesOutOfRangeReviews() throws Exception {
        // Ensure at least one review exists for the place.
        Long r = createReviewFull(createCompletedBooking(), 5, null, null, null, null, null, "Ranged").get("id").asLong();
        moderate(r, "APPROVED", null);

        // A window entirely in the past cannot contain any freshly-created (today) review.
        JsonNode past = placeAnalytics(partnerToken, hotelPlaceId, "2000-01-01", "2000-12-31", status().isOk());
        assertTrue(past.get("totalReviews").asLong() >= 1, "totalReviews is all-time, not range-scoped");
        assertEquals(0L, past.get("reviewsInRange").asLong(), "no reviews were created in the year 2000");
        assertEquals(0.0, past.get("averageRatingInRange").asDouble(), "empty range → 0.0, no divide-by-zero");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PARTNER — zero-data safety (owned place with NO reviews)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partner_placeReviewAnalytics_zeroReviews_returnsDeterministicZeros() throws Exception {
        Long emptyPlaceId = createBarePlaceOwnedBySeededPartner();

        JsonNode res = placeAnalytics(partnerToken, emptyPlaceId, null, null, status().isOk());

        assertEquals(emptyPlaceId, res.get("placeId").asLong());
        assertEquals(0L, res.get("totalReviews").asLong());
        assertEquals(0L, res.get("approvedReviews").asLong());
        assertEquals(0L, res.get("pendingReviews").asLong());
        assertEquals(0L, res.get("rejectedReviews").asLong());
        assertEquals(0L, res.get("hiddenReviews").asLong());
        assertEquals(0L, res.get("reportedReviews").asLong());
        assertEquals(0.0, res.get("averageOverallRating").asDouble());
        assertEquals(0.0, res.get("averageCleanliness").asDouble());
        assertEquals(0.0, res.get("averageService").asDouble());
        assertEquals(0.0, res.get("averageLocation").asDouble());
        assertEquals(0.0, res.get("averageValue").asDouble());
        assertEquals(0.0, res.get("averageFacilities").asDouble());
        assertEquals(0L, res.get("partnerReplyCount").asLong());
        assertEquals(0.0, res.get("partnerReplyRate").asDouble(), "no reviews ⇒ reply rate 0, not NaN");
        assertTrue(res.get("latestReviewAt").isNull(), "no reviews ⇒ latestReviewAt null");
        assertEquals(0L, res.get("reviewsInRange").asLong());
        assertEquals(0.0, res.get("averageRatingInRange").asDouble());
        for (int star = 1; star <= 5; star++) {
            assertEquals(0L, res.get("starDistribution").get(String.valueOf(star)).asLong());
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PARTNER — security / ownership (uniform 404, 403, 401)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partner_placeReviewAnalytics_notOwnedPlace_returns404() throws Exception {
        String stranger = createAndApprovePartner(); // approved, owns NO place
        placeAnalytics(stranger, hotelPlaceId, null, null, status().isNotFound());
    }

    @Test
    void partner_placeReviewAnalytics_unknownPlace_returns404() throws Exception {
        placeAnalytics(partnerToken, 999_999_999L, null, null, status().isNotFound());
    }

    @Test
    void partner_placeReviewAnalytics_customerToken_returns403() throws Exception {
        placeAnalytics(userToken, hotelPlaceId, null, null, status().isForbidden());
    }

    @Test
    void partner_placeReviewAnalytics_anonymous_returns401() throws Exception {
        mvc.perform(get("/api/partner/places/" + hotelPlaceId + "/reviews/analytics"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void partner_placeReviewAnalytics_adminWithoutPartnerProfile_returns404() throws Exception {
        // Admin passes the /api/partner/** role gate but has no partner profile → uniform 404 (no leak).
        placeAnalytics(adminToken, hotelPlaceId, null, null, status().isNotFound());
    }

    @Test
    void partner_placeReviewAnalytics_noSensitiveDataLeak() throws Exception {
        Long r = createReviewFull(createCompletedBooking(), 5, null, null, null, null, null, "Careful").get("id").asLong();
        moderate(r, "APPROVED", null);
        String raw = placeAnalytics(partnerToken, hotelPlaceId, null, null, status().isOk()).toString();
        assertFalse(raw.contains("@"), "no email address in response");
        assertFalse(raw.toLowerCase().contains("password"));
        assertFalse(raw.toLowerCase().contains("token"));
        assertFalse(raw.toLowerCase().contains("bookingcode"));
        assertFalse(raw.toLowerCase().contains("jwt"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ADMIN — platform-wide overview
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void admin_reviewOverview_returnsPlatformAggregates() throws Exception {
        // Seed at least one approved review with categories + a reply so aggregates are non-trivial.
        Long r = createReviewFull(createCompletedBooking(), 5, 5, 5, 5, 5, 5, "Platform").get("id").asLong();
        moderate(r, "APPROVED", null);
        reply(partnerToken, r, "Cheers!");

        JsonNode res = adminOverview(null, null, status().isOk());

        assertTrue(res.get("totalReviews").asLong() >= 1);
        assertEquals(5, res.get("statusBreakdown").size(), "all 5 review statuses present");
        for (JsonNode b : res.get("statusBreakdown")) {
            assertTrue(b.has("label") && b.has("count"));
        }
        for (int star = 1; star <= 5; star++) {
            assertTrue(res.get("ratingDistribution").has(String.valueOf(star)), "rating bucket " + star + " present");
        }
        double avg = res.get("averageOverallRating").asDouble();
        assertTrue(avg >= 0.0 && avg <= 5.0);
        assertTrue(res.get("averageCleanliness").asDouble() >= 0.0);
        double rate = res.get("partnerReplyRate").asDouble();
        assertTrue(rate >= 0.0 && rate <= 100.0);
        assertTrue(res.get("reviewedPlaces").asLong() >= 1);
        assertFalse(res.get("latestReviewAt").isNull());
    }

    @Test
    void admin_reviewOverview_emptyRange_isDeterministicNoDivideByZero() throws Exception {
        JsonNode res = adminOverview("2000-01-01", "2000-12-31", status().isOk());
        assertEquals(0L, res.get("reviewsInRange").asLong(), "no reviews in the year 2000");
        assertEquals(0.0, res.get("averageRatingInRange").asDouble(), "empty range → 0.0, no 500");
        assertTrue(res.get("totalReviews").asLong() >= 0, "all-time total unaffected by the range");
    }

    @Test
    void admin_reviewOverview_customerToken_returns403() throws Exception {
        adminOverview(null, null, status().isForbidden(), userToken);
    }

    @Test
    void admin_reviewOverview_partnerToken_returns403() throws Exception {
        adminOverview(null, null, status().isForbidden(), partnerToken);
    }

    @Test
    void admin_reviewOverview_anonymous_returns401() throws Exception {
        mvc.perform(get("/api/admin/reviews/analytics/overview"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void admin_reviewOverview_noSensitiveDataLeak() throws Exception {
        String raw = adminOverview(null, null, status().isOk()).toString();
        assertFalse(raw.contains("@"), "no email address in response");
        assertFalse(raw.toLowerCase().contains("password"));
        assertFalse(raw.toLowerCase().contains("token"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // READ-ONLY — analytics must not mutate any review/place state
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void analytics_areReadOnly_leaveReviewStateUnchanged() throws Exception {
        Long r = createReviewFull(createCompletedBooking(), 4, null, null, null, null, null, "ReadOnly").get("id").asLong();
        moderate(r, "APPROVED", null);

        long totalBefore = adminOverview(null, null, status().isOk()).get("totalReviews").asLong();
        String statusBefore = adminGetReview(r).get("status").asText();

        // Hit both analytics endpoints.
        placeAnalytics(partnerToken, hotelPlaceId, null, null, status().isOk());
        adminOverview(null, null, status().isOk());

        long totalAfter = adminOverview(null, null, status().isOk()).get("totalReviews").asLong();
        String statusAfter = adminGetReview(r).get("status").asText();

        assertEquals(totalBefore, totalAfter, "analytics must not create/delete reviews");
        assertEquals(statusBefore, statusAfter, "analytics must not change a review's status");
        assertEquals("APPROVED", statusAfter);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // NON-REGRESSION — existing owned-scope summary endpoint still works
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void existingPartnerReviewsSummary_stillWorks() throws Exception {
        String body = mvc.perform(get("/api/partner/analytics/reviews")
                .header("Authorization", "Bearer " + partnerToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode res = mapper.readTree(body);
        assertNotNull(res.get("averageRating"));
        assertNotNull(res.get("reviewCount"));
        assertTrue(res.get("latestReviews").isArray());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private JsonNode placeAnalytics(String token, Long placeId, String from, String to,
                                    ResultMatcher expected) throws Exception {
        var req = get("/api/partner/places/" + placeId + "/reviews/analytics")
            .header("Authorization", "Bearer " + token);
        if (from != null) req = req.param("from", from);
        if (to != null) req = req.param("to", to);
        String body = mvc.perform(req).andExpect(expected).andReturn().getResponse().getContentAsString();
        return body.isBlank() ? mapper.createObjectNode() : mapper.readTree(body);
    }

    private JsonNode adminOverview(String from, String to, ResultMatcher expected) throws Exception {
        return adminOverview(from, to, expected, adminToken);
    }

    private JsonNode adminOverview(String from, String to, ResultMatcher expected, String token) throws Exception {
        var req = get("/api/admin/reviews/analytics/overview").header("Authorization", "Bearer " + token);
        if (from != null) req = req.param("from", from);
        if (to != null) req = req.param("to", to);
        String body = mvc.perform(req).andExpect(expected).andReturn().getResponse().getContentAsString();
        return body.isBlank() ? mapper.createObjectNode() : mapper.readTree(body);
    }

    /** Create a bare DRAFT place owned by the seeded partner's profile (no rooms/bookings/reviews). */
    private Long createBarePlaceOwnedBySeededPartner() {
        User partnerUser = userRepo.findByEmail("partner@planyourtrip.com").orElseThrow();
        PartnerProfile profile = partnerProfileRepo.findByUserId(partnerUser.getId()).orElseThrow();
        Category category = categoryRepo.findBySlug("accommodation").orElseThrow();
        AdministrativeUnit unit = locationRepo.findByCode("VT").orElseThrow();

        String suffix = UUID.randomUUID().toString().substring(0, 8);
        Place p = new Place();
        p.setName("Empty Analytics Place " + suffix);
        p.setNameNormalized("empty analytics place " + suffix);
        p.setSlug("empty-analytics-place-" + suffix);
        p.setCategory(category);
        p.setAdministrativeUnit(unit);
        p.setAddress("1 Test Street, Vung Tau");
        p.setStatus(PlaceStatus.DRAFT);
        p.setOwner(profile);
        p.setCreatedBy(partnerUser);
        p.setActive(true);
        return placeRepo.save(p).getId();
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

    /** Register a fresh user, create+submit+admin-approve a partner profile (owns no place). */
    private String createAndApprovePartner() throws Exception {
        int n = counter.getAndIncrement();
        String email = "analytics-partner-" + n + "@test.com";
        String token = registerAndLogin("Analytics Partner " + n, email);
        String profileReq = """
                {"businessName":"Analytics Test Co %d","businessType":"HOTEL","representativeName":"Analytics Partner",
                 "phone":"0901234567","email":"contact%d@example.com","address":"1 Le Loi, Da Nang"}
                """.formatted(n, n);
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
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());
        return login(email, "password123");
    }

    private Long createPendingBooking() throws Exception {
        LocalDate ci = TODAY.plusDays(dayCursor.getAndAdd(3));
        LocalDate co = ci.plusDays(2);
        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format(
                    "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\",\"adults\":2,\"children\":0,\"numberOfRooms\":1}",
                    famDblRoomId, ci, co)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private Long createCompletedBooking() throws Exception {
        Long bookingId = createPendingBooking();
        String payBody = mvc.perform(post("/api/payments")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"paymentMethod\":\"MOCK\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long paymentId = mapper.readTree(payBody).get("id").asLong();
        mvc.perform(post("/api/payments/" + paymentId + "/mock-success")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/check-in")
                .header("Authorization", "Bearer " + adminToken)).andExpect(status().isOk());
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/check-out")
                .header("Authorization", "Bearer " + adminToken)).andExpect(status().isOk());
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/complete")
                .header("Authorization", "Bearer " + adminToken)).andExpect(status().isOk());
        return bookingId;
    }

    private JsonNode createReviewFull(Long bookingId, int overall, Integer cleanliness, Integer service,
                                      Integer location, Integer value, Integer facilities, String title)
            throws Exception {
        StringBuilder sb = new StringBuilder("{");
        sb.append("\"bookingId\":").append(bookingId);
        sb.append(",\"ratingOverall\":").append(overall);
        if (cleanliness != null) sb.append(",\"ratingCleanliness\":").append(cleanliness);
        if (service != null)     sb.append(",\"ratingService\":").append(service);
        if (location != null)    sb.append(",\"ratingLocation\":").append(location);
        if (value != null)       sb.append(",\"ratingValue\":").append(value);
        if (facilities != null)  sb.append(",\"ratingFacilities\":").append(facilities);
        sb.append(",\"title\":\"").append(title).append("\"}");
        String body = mvc.perform(post("/api/reviews")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(sb.toString()))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode moderate(Long reviewId, String status, String rejectReason) throws Exception {
        String content = rejectReason != null
            ? String.format("{\"status\":\"%s\",\"rejectReason\":\"%s\"}", status, rejectReason)
            : String.format("{\"status\":\"%s\"}", status);
        String body = mvc.perform(patch("/api/admin/reviews/" + reviewId + "/moderate")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(content))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private void reply(String token, Long reviewId, String content) throws Exception {
        mvc.perform(put("/api/partner/reviews/" + reviewId + "/reply")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"content\":\"" + content + "\"}"))
            .andExpect(status().isOk());
    }

    private JsonNode adminGetReview(Long reviewId) throws Exception {
        String body = mvc.perform(get("/api/admin/reviews/" + reviewId)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }
}
