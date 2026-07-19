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
 * ReviewMediaTest — Phase 7.45.
 *
 * Customer-facing review media: attach/remove media on one's OWN review and expose
 * a review's active media in the review read models. Reuses the existing
 * MediaAsset / MediaAssetService (URL/metadata registration — no multipart), and the
 * booking→review setup pattern from {@link ReviewTest} (FAM-DBL room, its own day
 * windows so it never collides with other test classes).
 */
@SpringBootTest
@AutoConfigureMockMvc
class ReviewMediaTest {

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
    // FAM-DBL is seeded with 18 available rooms/night over a 90-day horizon, so sharing
    // day windows with ReviewTest never exhausts inventory. Start low to stay inside the
    // 90-day inventory horizon; each booking consumes only 1 of 18 rooms for its 2 nights.
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
    // UPLOAD / ATTACH
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void uploadImage_toOwnReview_returns201AndPersistsReviewOwnedAsset() throws Exception {
        Long reviewId = createReviewId(5);

        JsonNode media = addReviewMedia(reviewId, userToken,
            "{\"url\":\"https://example.com/rev-img.jpg\",\"mediaType\":\"IMAGE\",\"altText\":\"My stay\",\"sortOrder\":0}");

        assertTrue(media.get("id").asLong() > 0);
        assertEquals("REVIEW", media.get("ownerType").asText());
        assertEquals(reviewId, media.get("ownerId").asLong());
        assertEquals("IMAGE", media.get("mediaType").asText());
        assertTrue(media.get("active").asBoolean());

        // It surfaces in the review read model.
        JsonNode review = getReview(reviewId, userToken);
        JsonNode arr = review.get("media");
        assertTrue(arr.isArray());
        assertTrue(containsId(arr, media.get("id").asLong()), "Uploaded media must appear in review.media");
    }

    @Test
    void uploadVideo_toOwnReview_returns201() throws Exception {
        Long reviewId = createReviewId(4);

        JsonNode media = addReviewMedia(reviewId, userToken,
            "{\"url\":\"https://example.com/rev-clip.mp4\",\"mediaType\":\"VIDEO\"}");

        assertEquals("VIDEO", media.get("mediaType").asText());
        assertEquals("REVIEW", media.get("ownerType").asText());
    }

    @Test
    void multipleMedia_keepStableSortOrder() throws Exception {
        Long reviewId = createReviewId(5);

        Long b = addReviewMedia(reviewId, userToken,
            "{\"url\":\"https://example.com/b.jpg\",\"mediaType\":\"IMAGE\",\"sortOrder\":2}").get("id").asLong();
        Long a = addReviewMedia(reviewId, userToken,
            "{\"url\":\"https://example.com/a.jpg\",\"mediaType\":\"IMAGE\",\"sortOrder\":1}").get("id").asLong();
        Long c = addReviewMedia(reviewId, userToken,
            "{\"url\":\"https://example.com/c.jpg\",\"mediaType\":\"IMAGE\",\"sortOrder\":3}").get("id").asLong();

        JsonNode arr = getReview(reviewId, userToken).get("media");
        assertEquals(3, arr.size());
        assertEquals(a, arr.get(0).get("id").asLong());
        assertEquals(b, arr.get(1).get("id").asLong());
        assertEquals(c, arr.get(2).get("id").asLong());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // DELETE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void owner_deletesOwnMedia_softDeletesAndDropsFromReview() throws Exception {
        Long reviewId = createReviewId(5);
        Long mediaId = addReviewMedia(reviewId, userToken,
            "{\"url\":\"https://example.com/del.jpg\",\"mediaType\":\"IMAGE\"}").get("id").asLong();

        mvc.perform(delete("/api/me/reviews/" + reviewId + "/media/" + mediaId)
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.active").value(false));

        JsonNode arr = getReview(reviewId, userToken).get("media");
        assertFalse(containsId(arr, mediaId), "Soft-deleted media must not appear in review.media");
    }

    @Test
    void delete_mediaNotBelongingToReview_returns404() throws Exception {
        Long reviewA = createReviewId(5);
        Long reviewB = createReviewId(4);
        Long mediaOnB = addReviewMedia(reviewB, userToken,
            "{\"url\":\"https://example.com/onB.jpg\",\"mediaType\":\"IMAGE\"}").get("id").asLong();

        mvc.perform(delete("/api/me/reviews/" + reviewA + "/media/" + mediaOnB)
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // OWNERSHIP / SECURITY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void otherUser_cannotUploadToSomeoneElsesReview_returns403() throws Exception {
        Long reviewId = createReviewId(5);

        mvc.perform(post("/api/me/reviews/" + reviewId + "/media")
                .header("Authorization", "Bearer " + partnerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"url\":\"https://example.com/x.jpg\",\"mediaType\":\"IMAGE\"}"))
            .andExpect(status().isForbidden());
    }

    @Test
    void otherUser_cannotDeleteSomeoneElsesReviewMedia_returns403() throws Exception {
        Long reviewId = createReviewId(5);
        Long mediaId = addReviewMedia(reviewId, userToken,
            "{\"url\":\"https://example.com/mine.jpg\",\"mediaType\":\"IMAGE\"}").get("id").asLong();

        mvc.perform(delete("/api/me/reviews/" + reviewId + "/media/" + mediaId)
                .header("Authorization", "Bearer " + partnerToken))
            .andExpect(status().isForbidden());
    }

    @Test
    void anonymous_cannotUpload_returns401() throws Exception {
        Long reviewId = createReviewId(5);

        mvc.perform(post("/api/me/reviews/" + reviewId + "/media")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"url\":\"https://example.com/x.jpg\",\"mediaType\":\"IMAGE\"}"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // VALIDATION (reuses MediaAssetService / bean-validation on the request DTO)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void upload_blankUrl_returns400() throws Exception {
        Long reviewId = createReviewId(5);

        mvc.perform(post("/api/me/reviews/" + reviewId + "/media")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"url\":\"\",\"mediaType\":\"IMAGE\"}"))
            .andExpect(status().isBadRequest());
    }

    @Test
    void upload_missingMediaType_returns400() throws Exception {
        Long reviewId = createReviewId(5);

        // mediaType is @NotNull on the request DTO — bean validation → 400.
        mvc.perform(post("/api/me/reviews/" + reviewId + "/media")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"url\":\"https://example.com/x.jpg\"}"))
            .andExpect(status().isBadRequest());
    }

    @Test
    void upload_nonImageAsCover_returns400() throws Exception {
        Long reviewId = createReviewId(5);

        mvc.perform(post("/api/me/reviews/" + reviewId + "/media")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"url\":\"https://example.com/x.mp4\",\"mediaType\":\"VIDEO\",\"cover\":true}"))
            .andExpect(status().isBadRequest());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // READ MODELS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void reviewWithNoMedia_serializesEmptyListNotNull() throws Exception {
        Long reviewId = createReviewId(5);

        JsonNode arr = getReview(reviewId, userToken).get("media");
        assertNotNull(arr, "media field must be present");
        assertFalse(arr.isNull(), "media must be an empty array, not null");
        assertTrue(arr.isArray());
        assertEquals(0, arr.size());
    }

    @Test
    void myReviews_exposesMedia() throws Exception {
        Long reviewId = createReviewId(5);
        Long mediaId = addReviewMedia(reviewId, userToken,
            "{\"url\":\"https://example.com/mine-list.jpg\",\"mediaType\":\"IMAGE\"}").get("id").asLong();

        String body = mvc.perform(get("/api/me/reviews")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        boolean found = false;
        for (JsonNode n : arr) {
            if (n.get("id").asLong() == reviewId) {
                assertTrue(containsId(n.get("media"), mediaId), "my-review summary must carry its media");
                found = true;
            }
        }
        assertTrue(found, "Newly created review must appear in /api/me/reviews");
    }

    @Test
    void publicPlaceReviews_exposeMediaForApprovedReview() throws Exception {
        Long reviewId = createReviewId(4);
        Long mediaId = addReviewMedia(reviewId, userToken,
            "{\"url\":\"https://example.com/public.jpg\",\"mediaType\":\"IMAGE\"}").get("id").asLong();
        moderate(reviewId, "APPROVED", null);

        String body = mvc.perform(get("/api/places/" + hotelPlaceId + "/reviews"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        boolean found = false;
        for (JsonNode n : arr) {
            if (n.get("id").asLong() == reviewId) {
                assertTrue(containsId(n.get("media"), mediaId), "Approved review must expose its media publicly");
                found = true;
            }
        }
        assertTrue(found, "Approved review must be listed publicly");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // NON-INTERFERENCE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void addingMedia_doesNotChangePlaceRatingOrReviewCount() throws Exception {
        Long reviewId = createReviewId(4);
        moderate(reviewId, "APPROVED", null);

        JsonNode before = getPlace();
        double avgBefore = before.get("ratingAvg").asDouble();
        int countBefore = before.get("ratingCount").asInt();

        addReviewMedia(reviewId, userToken,
            "{\"url\":\"https://example.com/no-rating-change.jpg\",\"mediaType\":\"IMAGE\"}");

        JsonNode after = getPlace();
        assertEquals(avgBefore, after.get("ratingAvg").asDouble(), 0.0001,
            "Attaching media must not change ratingAvg");
        assertEquals(countBefore, after.get("ratingCount").asInt(),
            "Attaching media must not change reviewCount");
    }

    @Test
    void existingAdminMediaSurface_stillWorks() throws Exception {
        // Sanity: the generic admin media create is unchanged by this phase.
        mvc.perform(get("/api/admin/places/" + hotelPlaceId + "/media")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());
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

    /** Create a COMPLETED booking + a PENDING review, returning the review id. */
    private Long createReviewId(int overall) throws Exception {
        Long bookingId = createCompletedBooking();
        String body = mvc.perform(post("/api/reviews")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"ratingOverall\":" + overall + "}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private Long createCompletedBooking() throws Exception {
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
        Long bookingId = mapper.readTree(body).get("id").asLong();

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

    private JsonNode addReviewMedia(Long reviewId, String token, String json) throws Exception {
        String body = mvc.perform(post("/api/me/reviews/" + reviewId + "/media")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode getReview(Long reviewId, String token) throws Exception {
        String body = mvc.perform(get("/api/reviews/" + reviewId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
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

    private JsonNode getPlace() throws Exception {
        String body = mvc.perform(get("/api/places/" + hotelPlaceId))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private boolean containsId(JsonNode arr, long id) {
        if (arr == null || !arr.isArray()) return false;
        for (JsonNode n : arr) {
            if (n.get("id").asLong() == id) return true;
        }
        return false;
    }
}
