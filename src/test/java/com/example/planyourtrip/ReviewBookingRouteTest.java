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
 * Phase 7.43 — Customer Review Foundation (additive extension of the existing Review system).
 *
 * Exercises the NEW booking-scoped alias route {@code POST /api/me/bookings/{bookingId}/review}
 * plus the additive gaps: 409-on-duplicate, partner notification, REVIEW_SUBMITTED timeline event,
 * media reuse via MediaOwnerType.REVIEW, and public-response sanitization.
 *
 * Uses the SUITE-KNG room, which no other test class books, so day windows here never collide
 * with other test classes' inventory.
 */
@SpringBootTest
@AutoConfigureMockMvc
class ReviewBookingRouteTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;

    private String adminToken;
    private String userToken;
    private String partnerToken;
    private Long suiteRoomId;
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
        suiteRoomId = hotelRoomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "SUITE-KNG".equals(r.getRoomCode()))
            .findFirst().orElseThrow().getId();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // NEW booking-scoped alias route — happy path
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void bookingRoute_create_forCompletedOwnBooking_returns201_andPersists() throws Exception {
        Long bookingId = createCompletedBooking();

        JsonNode res = createBookingReview(bookingId, 5, 4, 5, 4, 5, 4, "Lovely", "Would return");

        assertNotNull(res.get("id"));
        assertEquals(bookingId, res.get("bookingId").asLong());
        assertEquals("PENDING", res.get("status").asText());
        assertEquals(5, res.get("ratingOverall").asInt());
        assertEquals(4, res.get("ratingCleanliness").asInt());
    }

    @Test
    void bookingRoute_create_returns201_persistsAndUpdatesPlaceAggregate() throws Exception {
        JsonNode placeBefore = getPlace();
        int countBefore = placeBefore.get("ratingCount").asInt();

        Long bookingId = createCompletedBooking();
        JsonNode review = createBookingReview(bookingId, 4, null, null, null, null, null, "Nice", "Clean room");

        assertNotNull(review.get("id"));
        assertEquals(bookingId, review.get("bookingId").asLong());
        assertEquals("PENDING", review.get("status").asText());
        assertEquals(4, review.get("ratingOverall").asInt());

        // Approve so the Place aggregate updates (reused existing aggregate logic).
        moderate(review.get("id").asLong(), "APPROVED", null);
        JsonNode placeAfter = getPlace();
        assertEquals(countBefore + 1, placeAfter.get("ratingCount").asInt(),
            "Approving the booking-route review must bump the reused Place aggregate reviewCount");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // Duplicate → 409 (both routes consistent)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void bookingRoute_duplicate_returns409() throws Exception {
        Long bookingId = createCompletedBooking();
        createBookingReview(bookingId, 4, null, null, null, null, null, null, null);

        postBookingReview(bookingId, userToken, 4, null, null, null, null, null, null, null)
            .andExpect(status().isConflict());
    }

    @Test
    void bodyRoute_thenBookingRoute_duplicate_returns409_consistent() throws Exception {
        Long bookingId = createCompletedBooking();
        // First create via the body-based /api/reviews route.
        mvc.perform(post("/api/reviews")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"ratingOverall\":5}"))
            .andExpect(status().isCreated());
        // Duplicate via the new booking-scoped route → 409 as well.
        postBookingReview(bookingId, userToken, 5, null, null, null, null, null, null, null)
            .andExpect(status().isConflict());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // Ownership / role rejections
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void bookingRoute_otherUser_partner_cannotReview_returns403() throws Exception {
        Long bookingId = createCompletedBooking();
        // Partner is not the booking's customer (and also happens to be the hotel owner) → rejected.
        postBookingReview(bookingId, partnerToken, 5, null, null, null, null, null, null, null)
            .andExpect(status().isForbidden());
    }

    @Test
    void bookingRoute_admin_cannotReview_returns403() throws Exception {
        Long bookingId = createCompletedBooking();
        // Admin is not the booking's customer → ownership check rejects before any admin bypass.
        postBookingReview(bookingId, adminToken, 5, null, null, null, null, null, null, null)
            .andExpect(status().isForbidden());
    }

    @Test
    void bookingRoute_anonymous_returns401() throws Exception {
        mvc.perform(post("/api/me/bookings/1/review")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"ratingOverall\":5}"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // Validation
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void bookingRoute_ratingOutOfRange_returns400() throws Exception {
        Long bookingId = createCompletedBooking();
        postBookingReview(bookingId, userToken, 6, null, null, null, null, null, null, null)
            .andExpect(status().isBadRequest());
    }

    @Test
    void bookingRoute_categoryRatingOutOfRange_returns400() throws Exception {
        Long bookingId = createCompletedBooking();
        postBookingReview(bookingId, userToken, 5, 0, null, null, null, null, null, null)
            .andExpect(status().isBadRequest());
    }

    @Test
    void bookingRoute_commentTooLong_returns400() throws Exception {
        Long bookingId = createCompletedBooking();
        String tooLong = "x".repeat(5001);
        postBookingReview(bookingId, userToken, 5, null, null, null, null, null, null, tooLong)
            .andExpect(status().isBadRequest());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // Booking-state gating
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void bookingRoute_checkedOutNotCompleted_returns422() throws Exception {
        Long bookingId = createCheckedOutBooking();
        postBookingReview(bookingId, userToken, 5, null, null, null, null, null, null, null)
            .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void bookingRoute_cancelledBooking_returns422() throws Exception {
        Long bookingId = createCancelledBooking();
        postBookingReview(bookingId, userToken, 5, null, null, null, null, null, null, null)
            .andExpect(status().isUnprocessableEntity());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // Media reuse — MediaOwnerType.REVIEW via the generic media flow (no review-specific code)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void reviewMedia_attachAndReadBack_viaGenericMediaFlow() throws Exception {
        Long bookingId = createCompletedBooking();
        Long reviewId = createBookingReview(bookingId, 5, null, null, null, null, null, null, null)
            .get("id").asLong();

        String body = mvc.perform(post("/api/admin/media")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"ownerType\":\"REVIEW\",\"ownerId\":" + reviewId
                    + ",\"url\":\"https://cdn.example.com/reviews/photo.jpg\",\"mediaType\":\"IMAGE\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        JsonNode asset = mapper.readTree(body);
        assertEquals("REVIEW", asset.get("ownerType").asText());
        assertEquals(reviewId, asset.get("ownerId").asLong());
        assertEquals("IMAGE", asset.get("mediaType").asText());
        assertTrue(asset.get("active").asBoolean());
        assertNotNull(asset.get("id"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // Public response sanitization + ordering
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void publicPlaceReviews_areSanitized_andNewestFirst() throws Exception {
        // Create + approve two reviews so ordering can be asserted.
        Long b1 = createCompletedBooking();
        Long r1 = createBookingReview(b1, 4, null, null, null, null, null, "First", "aaa").get("id").asLong();
        moderate(r1, "APPROVED", null);

        Long b2 = createCompletedBooking();
        Long r2 = createBookingReview(b2, 5, null, null, null, null, null, "Second", "bbb").get("id").asLong();
        moderate(r2, "APPROVED", null);

        String body = mvc.perform(get("/api/places/" + hotelPlaceId + "/reviews"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode arr = mapper.readTree(body);

        assertTrue(arr.isArray() && arr.size() >= 2);
        // Sanitization: summary must NOT leak sensitive/internal fields.
        for (JsonNode n : arr) {
            assertFalse(n.has("email"), "public review must not expose email");
            assertFalse(n.has("bookingCode"), "public review must not expose bookingCode");
            assertFalse(n.has("bookingId"), "public review must not expose bookingId");
            assertFalse(n.has("content"), "summary must not expose free-text content");
            assertFalse(n.has("rejectReason"), "public review must not expose moderation notes");
            assertFalse(n.has("token"), "public review must not expose any token");
            assertFalse(n.has("payment"), "public review must not expose payment data");
            assertEquals("APPROVED", n.get("status").asText());
        }
        // Ordering newest-first: index of r2 (created later) must precede r1.
        int idxR1 = indexOfId(arr, r1);
        int idxR2 = indexOfId(arr, r2);
        assertTrue(idxR2 >= 0 && idxR1 >= 0 && idxR2 < idxR1,
            "place reviews must be ordered newest-first (createdAt desc)");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // Partner notification
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partnerNotified_onReviewSubmission() throws Exception {
        Long bookingId = createCompletedBooking();
        createBookingReview(bookingId, 5, null, null, null, null, null, "Great", "Superb stay");

        // The partner (partner@planyourtrip.com) owns Grand Palace Hotel → gets the notification.
        String body = mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + partnerToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode arr = mapper.readTree(body);

        boolean found = false;
        for (JsonNode n : arr) {
            if ("New review submitted".equals(n.get("title").asText())
                    && n.get("message").asText().contains("A new review has been submitted")) {
                found = true;
                break;
            }
        }
        assertTrue(found, "Hotel owner (partner) must receive 'A new review has been submitted' notification");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // REVIEW_SUBMITTED timeline event
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void reviewSubmitted_appearsOnBookingTimeline() throws Exception {
        Long bookingId = createCompletedBooking();

        // Before review: no REVIEW_SUBMITTED event.
        assertFalse(timelineHasEvent(bookingId, "REVIEW_SUBMITTED"),
            "REVIEW_SUBMITTED must not exist before a review is submitted");

        createBookingReview(bookingId, 5, null, null, null, null, null, null, null);

        // After review: REVIEW_SUBMITTED derived from the review's createdAt.
        assertTrue(timelineHasEvent(bookingId, "REVIEW_SUBMITTED"),
            "REVIEW_SUBMITTED must appear on the booking timeline after a review is submitted");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private boolean timelineHasEvent(Long bookingId, String event) throws Exception {
        String body = mvc.perform(get("/api/bookings/" + bookingId + "/timeline")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode events = mapper.readTree(body).get("events");
        for (JsonNode e : events) {
            if (event.equals(e.get("event").asText())) return true;
        }
        return false;
    }

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
                    suiteRoomId, ci, co)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    /** Pay + confirm, then check-in / check-out but stop BEFORE complete → status CHECKED_OUT. */
    private Long createCheckedOutBooking() throws Exception {
        Long bookingId = payAndConfirm(createPendingBooking());
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/check-in")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/check-out")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());
        return bookingId;
    }

    private Long createCompletedBooking() throws Exception {
        Long bookingId = createCheckedOutBooking();
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/complete")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());
        return bookingId;
    }

    private Long createCancelledBooking() throws Exception {
        Long bookingId = createPendingBooking();
        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"cancelReason\":\"changed plans\"}"))
            .andExpect(status().isOk());
        return bookingId;
    }

    private Long payAndConfirm(Long bookingId) throws Exception {
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
        return bookingId;
    }

    private JsonNode createBookingReview(Long bookingId, Integer overall, Integer cleanliness, Integer service,
                                          Integer location, Integer value, Integer facilities,
                                          String title, String content) throws Exception {
        String body = postBookingReview(bookingId, userToken, overall, cleanliness, service,
                location, value, facilities, title, content)
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private org.springframework.test.web.servlet.ResultActions postBookingReview(
            Long bookingId, String token, Integer overall, Integer cleanliness, Integer service,
            Integer location, Integer value, Integer facilities,
            String title, String content) throws Exception {
        return mvc.perform(post("/api/me/bookings/" + bookingId + "/review")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(reviewJson(overall, cleanliness, service, location, value, facilities, title, content)));
    }

    private String reviewJson(Integer overall, Integer cleanliness, Integer service,
                              Integer location, Integer value, Integer facilities,
                              String title, String content) {
        StringBuilder sb = new StringBuilder("{");
        sb.append("\"ratingOverall\":").append(overall);
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

    private int indexOfId(JsonNode arr, Long id) {
        for (int i = 0; i < arr.size(); i++) {
            if (arr.get(i).get("id").asLong() == id) return i;
        }
        return -1;
    }
}
