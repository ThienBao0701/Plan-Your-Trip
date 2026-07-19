package com.example.planyourtrip;

import com.example.planyourtrip.model.User;
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

import java.time.LocalDate;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Phase 7.44 — Partner Reply to a Customer Review.
 *
 * Additive extension of the Phase 7.43 Review subsystem: an authorized partner posts/updates
 * exactly ONE reply to a review for a hotel they own via {@code PUT /api/partner/reviews/{id}/reply}.
 * Reuses the same seed fixtures + booking/review/approve flow as {@link ReviewTest}.
 * Uses the FAM-DBL room to avoid day-window collisions with other test classes.
 */
@SpringBootTest
@AutoConfigureMockMvc
class PartnerReviewReplyTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;
    @Autowired UserRepository userRepo;

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
    // CREATE / UPDATE — one reply per review, stored in place
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partnerReply_createReply_returns200AndPersists() throws Exception {
        Long reviewId = approvedReview();

        JsonNode res = reply(partnerToken, reviewId, "Thank you for staying with us!", status().isOk());

        assertEquals(reviewId, res.get("id").asLong());
        JsonNode pr = res.get("partnerReply");
        assertNotNull(pr);
        assertFalse(pr.isNull(), "partnerReply section must be present after a reply");
        assertEquals("Thank you for staying with us!", pr.get("content").asText());
        assertFalse(pr.get("repliedAt").isNull());
        assertFalse(pr.get("updatedAt").isNull());
        assertEquals("Grand Palace Hospitality Co., Ltd.", pr.get("partnerDisplayName").asText());
    }

    @Test
    void partnerReply_updateReply_changesContent_repliedAtUnchanged_updatedAtAdvances() throws Exception {
        Long reviewId = approvedReview();

        JsonNode first = reply(partnerToken, reviewId, "First reply", status().isOk()).get("partnerReply");
        String repliedAt0 = first.get("repliedAt").asText();
        String updatedAt0 = first.get("updatedAt").asText();

        Thread.sleep(10);
        JsonNode second = reply(partnerToken, reviewId, "Edited reply", status().isOk()).get("partnerReply");

        assertEquals("Edited reply", second.get("content").asText());
        // Compare at millisecond granularity: the DB column is microsecond precision, so the raw
        // in-memory value and the DB-round-tripped value can differ sub-microsecond. The 10ms edit
        // gap is far coarser, so this still proves repliedAt is pinned (not bumped to edit-time).
        var repliedAt0Ms = java.time.Instant.parse(repliedAt0).truncatedTo(java.time.temporal.ChronoUnit.MILLIS);
        var repliedAt1Ms = java.time.Instant.parse(second.get("repliedAt").asText())
                .truncatedTo(java.time.temporal.ChronoUnit.MILLIS);
        assertEquals(repliedAt0Ms, repliedAt1Ms, "repliedAt must be pinned to the first reply");
        assertTrue(java.time.Instant.parse(second.get("updatedAt").asText())
                .isAfter(java.time.Instant.parse(updatedAt0)),
            "updatedAt must advance on edit");
    }

    @Test
    void partnerReply_repeatedUpdates_leaveExactlyOneReply() throws Exception {
        Long reviewId = approvedReview();
        reply(partnerToken, reviewId, "v1", status().isOk());
        reply(partnerToken, reviewId, "v2", status().isOk());
        reply(partnerToken, reviewId, "v3", status().isOk());

        // The public place list exposes each review once; assert exactly one reply with the latest content.
        JsonNode arr = getPlaceReviews();
        int replies = 0;
        String content = null;
        for (JsonNode n : arr) {
            if (n.get("id").asLong() == reviewId && !n.get("partnerReply").isNull()) {
                replies++;
                content = n.get("partnerReply").get("content").asText();
            }
        }
        assertEquals(1, replies, "There must be exactly one reply row for the review");
        assertEquals("v3", content);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // NOTIFICATION — first reply only
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partnerReply_firstReply_createsExactlyOneCustomerNotification() throws Exception {
        Long reviewId = approvedReview();
        int before = countNotifications("Hotel replied to your review");
        reply(partnerToken, reviewId, "Thanks!", status().isOk());
        assertEquals(before + 1, countNotifications("Hotel replied to your review"),
            "first reply must create exactly one customer notification");
    }

    @Test
    void partnerReply_edit_createsNoAdditionalNotification() throws Exception {
        Long reviewId = approvedReview();
        reply(partnerToken, reviewId, "Thanks!", status().isOk());
        int afterFirst = countNotifications("Hotel replied to your review");

        reply(partnerToken, reviewId, "Thanks again!", status().isOk());
        reply(partnerToken, reviewId, "Thanks a third time!", status().isOk());

        assertEquals(afterFirst, countNotifications("Hotel replied to your review"),
            "editing a reply must NOT create additional notifications");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // READ MODELS — reply appears where the review is already shown
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partnerReply_appearsInPublicPlaceReviews() throws Exception {
        Long reviewId = approvedReview();
        reply(partnerToken, reviewId, "Public reply text", status().isOk());

        JsonNode arr = getPlaceReviews();
        JsonNode target = findById(arr, reviewId);
        assertNotNull(target, "approved review must be public");
        assertFalse(target.get("partnerReply").isNull());
        assertEquals("Public reply text", target.get("partnerReply").get("content").asText());
    }

    @Test
    void partnerReply_appearsInCustomerMyReviews() throws Exception {
        Long reviewId = approvedReview();
        reply(partnerToken, reviewId, "Reply seen by customer", status().isOk());

        String body = mvc.perform(get("/api/me/reviews")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode arr = mapper.readTree(body);
        JsonNode target = findById(arr, reviewId);
        assertNotNull(target, "the review must be in the author's list");
        assertFalse(target.get("partnerReply").isNull());
        assertEquals("Reply seen by customer", target.get("partnerReply").get("content").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // AUTHORIZATION / OWNERSHIP
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partnerReply_wrongPartner_returns404() throws Exception {
        Long reviewId = approvedReview();
        String otherPartner = createAndApprovePartner();   // approved, owns NO place
        reply(otherPartner, reviewId, "I do not own this hotel", status().isNotFound());
    }

    @Test
    void partnerReply_unknownReview_returns404() throws Exception {
        reply(partnerToken, 999_999_999L, "ghost", status().isNotFound());
    }

    @Test
    void partnerReply_adminWithoutPartnerProfile_returns404() throws Exception {
        Long reviewId = approvedReview();
        // Admin passes the /api/partner/** role gate but has no partner profile → 404 (no leak).
        reply(adminToken, reviewId, "admin has no profile", status().isNotFound());
    }

    @Test
    void partnerReply_unapprovedPartner_returns403() throws Exception {
        Long reviewId = approvedReview();
        String unapproved = createPartnerWithSubmittedProfile();  // PARTNER role, profile NOT approved
        reply(unapproved, reviewId, "not approved yet", status().isForbidden());
    }

    @Test
    void partnerReply_customerToken_returns403() throws Exception {
        Long reviewId = approvedReview();
        // Customer lacks the PARTNER/ADMIN role → blocked at the security gate.
        reply(userToken, reviewId, "I am the customer", status().isForbidden());
    }

    @Test
    void partnerReply_anonymous_returns401() throws Exception {
        Long reviewId = approvedReview();
        mvc.perform(put("/api/partner/reviews/" + reviewId + "/reply")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"content\":\"anon\"}"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ELIGIBILITY (status) + VALIDATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partnerReply_nonVisibleReview_returns422() throws Exception {
        // A PENDING review is not publicly visible → not eligible for reply.
        Long bookingId = createCompletedBooking();
        Long reviewId = createReview(bookingId, 4, "Pending review").get("id").asLong();
        reply(partnerToken, reviewId, "too early", status().isUnprocessableEntity());
    }

    @Test
    void partnerReply_rejectedReview_returns422() throws Exception {
        Long bookingId = createCompletedBooking();
        Long reviewId = createReview(bookingId, 2, "Bad").get("id").asLong();
        moderate(reviewId, "REJECTED", "Off topic");
        reply(partnerToken, reviewId, "replying to rejected", status().isUnprocessableEntity());
    }

    @Test
    void partnerReply_blankContent_returns400() throws Exception {
        Long reviewId = approvedReview();
        mvc.perform(put("/api/partner/reviews/" + reviewId + "/reply")
                .header("Authorization", "Bearer " + partnerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"content\":\"\"}"))
            .andExpect(status().isBadRequest());
    }

    @Test
    void partnerReply_whitespaceContent_returns400() throws Exception {
        Long reviewId = approvedReview();
        mvc.perform(put("/api/partner/reviews/" + reviewId + "/reply")
                .header("Authorization", "Bearer " + partnerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"content\":\"   \"}"))
            .andExpect(status().isBadRequest());
    }

    @Test
    void partnerReply_overlongContent_returns400() throws Exception {
        Long reviewId = approvedReview();
        String tooLong = "x".repeat(5001);
        mvc.perform(put("/api/partner/reviews/" + reviewId + "/reply")
                .header("Authorization", "Bearer " + partnerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"content\":\"" + tooLong + "\"}"))
            .andExpect(status().isBadRequest());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // NON-REGRESSION + NO LEAK
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void adminModeration_stillWorks_afterReplyFeature() throws Exception {
        Long bookingId = createCompletedBooking();
        Long reviewId = createReview(bookingId, 5, "Great").get("id").asLong();
        JsonNode res = moderate(reviewId, "APPROVED", null);
        assertEquals("APPROVED", res.get("status").asText());
        assertFalse(res.get("approvedAt").isNull());
    }

    @Test
    void partnerReply_responseLeaksNoSensitiveData() throws Exception {
        Long reviewId = approvedReview();
        String raw = reply(partnerToken, reviewId, "Careful reply", status().isOk()).toString();
        // No JWT / payment / private partner email leaked into the reply section or response.
        JsonNode pr = mapper.readTree(raw).get("partnerReply");
        assertFalse(pr.toString().contains("@"), "no email in reply section");
        assertFalse(pr.toString().toLowerCase().contains("password"));
        assertFalse(pr.toString().toLowerCase().contains("token"));
        assertFalse(pr.has("partnerProfileId"), "internal partner profile id must not be exposed");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private JsonNode reply(String token, Long reviewId, String content,
                           org.springframework.test.web.servlet.ResultMatcher expected) throws Exception {
        String json = "{\"content\":\"" + content.replace("\"", "\\\"") + "\"}";
        String body = mvc.perform(put("/api/partner/reviews/" + reviewId + "/reply")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? mapper.createObjectNode() : mapper.readTree(body);
    }

    /** Create a completed booking, review it, and admin-approve → returns the APPROVED reviewId. */
    private Long approvedReview() throws Exception {
        Long bookingId = createCompletedBooking();
        Long reviewId = createReview(bookingId, 5, "Nice stay").get("id").asLong();
        moderate(reviewId, "APPROVED", null);
        return reviewId;
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
        String email = "reply-partner-" + n + "@test.com";
        String token = registerAndLogin("Reply Partner " + n, email);
        Long profileId = createAndSubmitProfile(token, n);
        mvc.perform(post("/api/admin/partners/" + profileId + "/approve")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());
        // Re-login so the JWT carries the freshly promoted PARTNER role.
        return login(email, "password123");
    }

    /** Register a partner, submit (NOT approve) the profile, then force PARTNER role so the
     *  security gate passes and the service's approval check (403) is exercised. */
    private String createPartnerWithSubmittedProfile() throws Exception {
        int n = counter.getAndIncrement();
        String email = "unapproved-partner-" + n + "@test.com";
        String token = registerAndLogin("Unapproved Partner " + n, email);
        createAndSubmitProfile(token, n);   // left in SUBMITTED
        User u = userRepo.findByEmail(email).orElseThrow();
        u.setRole("PARTNER");
        userRepo.save(u);
        return login(email, "password123");
    }

    private Long createAndSubmitProfile(String token, int n) throws Exception {
        String profileReq = """
                {"businessName":"Reply Test Co %d","businessType":"HOTEL","representativeName":"Reply Partner",
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
        return profileId;
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

    private JsonNode createReview(Long bookingId, int overall, String title) throws Exception {
        String json = "{\"bookingId\":" + bookingId + ",\"ratingOverall\":" + overall
            + ",\"title\":\"" + title + "\"}";
        String body = mvc.perform(post("/api/reviews")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json))
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

    private JsonNode getPlaceReviews() throws Exception {
        String body = mvc.perform(get("/api/places/" + hotelPlaceId + "/reviews"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private int countNotifications(String title) throws Exception {
        String body = mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode arr = mapper.readTree(body);
        int c = 0;
        for (JsonNode n : arr) if (title.equals(n.get("title").asText())) c++;
        return c;
    }

    private JsonNode findById(JsonNode arr, Long id) {
        for (JsonNode n : arr) if (n.get("id").asLong() == id) return n;
        return null;
    }
}
