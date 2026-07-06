package com.example.planyourtrip;

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
 * ReviewTest — Phase 5.6.
 * Uses the FAM-DBL room, which no other test class books for real reservations
 * (only referenced in an availability-search assertion), so day windows here
 * never collide with other test classes.
 */
@SpringBootTest
@AutoConfigureMockMvc
class ReviewTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;

    private String adminToken;
    private String userToken;
    private String partnerToken;
    private Long famDblRoomId;
    private Long hotelPlaceId;

    private static final LocalDate TODAY = LocalDate.now();
    private static final AtomicInteger dayCursor = new AtomicInteger(1);

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
    // CREATE REVIEW
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void review_create_forCompletedOwnBooking_returns201() throws Exception {
        Long bookingId = createCompletedBooking();

        JsonNode res = createReview(bookingId, 5, 5, 5, 5, 5, 5, "Great stay", "Loved it");

        assertNotNull(res.get("id"));
        assertEquals(bookingId, res.get("bookingId").asLong());
        assertEquals("PENDING", res.get("status").asText());
        assertEquals(5, res.get("ratingOverall").asInt());
    }

    @Test
    void review_create_rejectsNonCompletedBooking_returns422() throws Exception {
        Long bookingId = createPendingBooking();

        mvc.perform(post("/api/reviews")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(reviewJson(bookingId, 5, null, null, null, null, null, null, null)))
            .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void review_create_rejectsDuplicateForSameBooking_returns422() throws Exception {
        Long bookingId = createCompletedBooking();
        createReview(bookingId, 4, null, null, null, null, null, null, null);

        mvc.perform(post("/api/reviews")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(reviewJson(bookingId, 4, null, null, null, null, null, null, null)))
            .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void review_create_rejectsOtherUserBooking_returns403() throws Exception {
        Long bookingId = createCompletedBooking();

        mvc.perform(post("/api/reviews")
                .header("Authorization", "Bearer " + partnerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(reviewJson(bookingId, 5, null, null, null, null, null, null, null)))
            .andExpect(status().isForbidden());
    }

    @Test
    void review_create_validatesRatingRange_returns400() throws Exception {
        Long bookingId = createCompletedBooking();

        mvc.perform(post("/api/reviews")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(reviewJson(bookingId, 6, null, null, null, null, null, null, null)))
            .andExpect(status().isBadRequest());
    }

    @Test
    void review_create_newReview_isPending() throws Exception {
        Long bookingId = createCompletedBooking();
        JsonNode res = createReview(bookingId, 3, null, null, null, null, null, null, null);
        assertEquals("PENDING", res.get("status").asText());
        assertTrue(res.get("approvedAt").isNull());
        assertTrue(res.get("rejectedAt").isNull());
    }

    @Test
    void review_create_unauthenticated_returns401() throws Exception {
        mvc.perform(post("/api/reviews")
                .contentType(MediaType.APPLICATION_JSON)
                .content(reviewJson(1L, 5, null, null, null, null, null, null, null)))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PUBLIC PLACE REVIEWS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void review_publicPlaceReviews_showsOnlyApproved() throws Exception {
        Long bookingId = createCompletedBooking();
        JsonNode review = createReview(bookingId, 4, null, null, null, null, null, "Pending one", null);
        Long reviewId = review.get("id").asLong();

        String beforeBody = mvc.perform(get("/api/places/" + hotelPlaceId + "/reviews"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertFalse(containsId(mapper.readTree(beforeBody), reviewId), "Pending review must not be public yet");

        moderate(reviewId, "APPROVED", null);

        String afterBody = mvc.perform(get("/api/places/" + hotelPlaceId + "/reviews"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode afterArr = mapper.readTree(afterBody);
        assertTrue(containsId(afterArr, reviewId), "Approved review must appear publicly");
        for (JsonNode n : afterArr) {
            assertEquals("APPROVED", n.get("status").asText());
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ADMIN LIST / GET
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void admin_listReviews_returns200() throws Exception {
        Long bookingId = createCompletedBooking();
        createReview(bookingId, 5, null, null, null, null, null, null, null);

        String body = mvc.perform(get("/api/admin/reviews")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());
        assertTrue(arr.size() >= 1);
    }

    @Test
    void admin_listReviews_forbiddenForUser_returns403() throws Exception {
        mvc.perform(get("/api/admin/reviews")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isForbidden());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // GET REVIEW / OWNERSHIP
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void review_getOwn_returns200() throws Exception {
        Long bookingId = createCompletedBooking();
        Long reviewId = createReview(bookingId, 5, null, null, null, null, null, null, null).get("id").asLong();

        mvc.perform(get("/api/reviews/" + reviewId)
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(reviewId));
    }

    @Test
    void review_getOtherUser_returns403() throws Exception {
        Long bookingId = createCompletedBooking();
        Long reviewId = createReview(bookingId, 5, null, null, null, null, null, null, null).get("id").asLong();

        mvc.perform(get("/api/reviews/" + reviewId)
                .header("Authorization", "Bearer " + partnerToken))
            .andExpect(status().isForbidden());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ADMIN MODERATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void admin_approveReview_setsApproved() throws Exception {
        Long bookingId = createCompletedBooking();
        Long reviewId = createReview(bookingId, 5, null, null, null, null, null, null, null).get("id").asLong();

        JsonNode res = moderate(reviewId, "APPROVED", null);
        assertEquals("APPROVED", res.get("status").asText());
        assertFalse(res.get("approvedAt").isNull());
    }

    @Test
    void admin_approve_updatesPlaceRatingAvgAndReviewCount() throws Exception {
        JsonNode placeBefore = getPlace();
        int countBefore = placeBefore.get("ratingCount").asInt();
        double avgBefore = placeBefore.get("ratingAvg").asDouble();

        Long bookingId = createCompletedBooking();
        Long reviewId = createReview(bookingId, 4, null, null, null, null, null, null, null).get("id").asLong();
        moderate(reviewId, "APPROVED", null);

        JsonNode placeAfter = getPlace();
        assertEquals(countBefore + 1, placeAfter.get("ratingCount").asInt());
        double expectedAvg = Math.round(((avgBefore * countBefore) + 4) / (countBefore + 1) * 10) / 10.0;
        assertEquals(expectedAvg, placeAfter.get("ratingAvg").asDouble(), 0.05);
    }

    @Test
    void admin_rejectReview_withReason() throws Exception {
        Long bookingId = createCompletedBooking();
        Long reviewId = createReview(bookingId, 2, null, null, null, null, null, null, null).get("id").asLong();

        JsonNode res = moderate(reviewId, "REJECTED", "Contains inappropriate language");
        assertEquals("REJECTED", res.get("status").asText());
        assertFalse(res.get("rejectedAt").isNull());
        assertEquals("Contains inappropriate language", res.get("rejectReason").asText());
    }

    @Test
    void admin_hiddenOrRejected_recalculatesPlaceRating() throws Exception {
        JsonNode placeBefore = getPlace();
        int countBefore = placeBefore.get("ratingCount").asInt();

        Long bookingId = createCompletedBooking();
        Long reviewId = createReview(bookingId, 3, null, null, null, null, null, null, null).get("id").asLong();

        moderate(reviewId, "APPROVED", null);
        assertEquals(countBefore + 1, getPlace().get("ratingCount").asInt());

        moderate(reviewId, "HIDDEN", null);
        assertEquals(countBefore, getPlace().get("ratingCount").asInt(),
            "Hiding an approved review must recalculate reviewCount back down");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // NOTIFICATION INTEGRATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void notification_created_onApproveAndReject() throws Exception {
        Long bookingId1 = createCompletedBooking();
        Long reviewId1 = createReview(bookingId1, 5, null, null, null, null, null, null, null).get("id").asLong();
        moderate(reviewId1, "APPROVED", null);

        Long bookingId2 = createCompletedBooking();
        Long reviewId2 = createReview(bookingId2, 1, null, null, null, null, null, null, null).get("id").asLong();
        moderate(reviewId2, "REJECTED", "Not relevant");

        String body = mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(containsTitle(arr, "Review approved"), "Approval must notify the user");
        assertTrue(containsTitle(arr, "Review rejected"), "Rejection must notify the user");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SEED VERIFICATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void seed_approvedReviewExists_ifApplicable() throws Exception {
        String body = mvc.perform(get("/api/admin/reviews")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        boolean hasApproved = false;
        for (JsonNode n : arr) {
            if ("APPROVED".equals(n.get("status").asText())) { hasApproved = true; break; }
        }
        assertTrue(hasApproved, "Seeded approved review must exist for the completed booking");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
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

    /** Create a booking, pay/confirm it, then walk it through check-in/check-out/complete. */
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
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/check-out")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/complete")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());

        return bookingId;
    }

    private JsonNode createReview(Long bookingId, Integer overall, Integer cleanliness, Integer service,
                                   Integer location, Integer value, Integer facilities,
                                   String title, String content) throws Exception {
        String body = mvc.perform(post("/api/reviews")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(reviewJson(bookingId, overall, cleanliness, service, location, value, facilities, title, content)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private String reviewJson(Long bookingId, Integer overall, Integer cleanliness, Integer service,
                               Integer location, Integer value, Integer facilities,
                               String title, String content) {
        StringBuilder sb = new StringBuilder("{");
        sb.append("\"bookingId\":").append(bookingId);
        sb.append(",\"ratingOverall\":").append(overall);
        if (cleanliness != null) sb.append(",\"ratingCleanliness\":").append(cleanliness);
        if (service != null)     sb.append(",\"ratingService\":").append(service);
        if (location != null)    sb.append(",\"ratingLocation\":").append(location);
        if (value != null)       sb.append(",\"ratingValue\":").append(value);
        if (facilities != null)  sb.append(",\"ratingFacilities\":").append(facilities);
        if (title != null)       sb.append(",\"title\":\"").append(title).append("\"");
        if (content != null)     sb.append(",\"content\":\"").append(content).append("\"");
        sb.append("}");
        return sb.toString();
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

    private JsonNode getPlace() throws Exception {
        String body = mvc.perform(get("/api/places/" + hotelPlaceId))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private boolean containsId(JsonNode arr, Long id) {
        for (JsonNode n : arr) {
            if (n.get("id").asLong() == id) return true;
        }
        return false;
    }

    private boolean containsTitle(JsonNode arr, String title) {
        for (JsonNode n : arr) {
            if (title.equals(n.get("title").asText())) return true;
        }
        return false;
    }
}
