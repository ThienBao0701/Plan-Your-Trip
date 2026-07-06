package com.example.planyourtrip;

import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.CategoryRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Integration tests for the media asset system.
 *
 * Isolation strategy:
 *  - hotelPlaceId    → READ-ONLY (never modified in these tests)
 *  - haLongPlaceId   → NEVER TOUCHED (has 0 seeded media, needed by PlaceDetailTest null-cover check)
 *  - scratchPlaceId  → a fresh PUBLISHED place created in @BeforeEach for all write operations
 */
@SpringBootTest
@AutoConfigureMockMvc
class MediaAssetTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;

    private String adminToken;
    private Long hotelPlaceId;
    private Long haLongPlaceId;
    private Long scratchPlaceId;
    private Long accCategoryId;
    private Long locationId;

    @BeforeEach
    void setup() throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"admin@planyourtrip.com\",\"password\":\"admin123456\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        adminToken = mapper.readTree(body).get("token").asText();

        hotelPlaceId  = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        haLongPlaceId = placeRepo.findBySlug("hang-sung-sot---vinh-ha-long").orElseThrow().getId();
        accCategoryId = categoryRepo.findBySlug("accommodation").orElseThrow().getId();
        locationId    = locationRepo.findByCode("VT").orElseThrow().getId();
        scratchPlaceId = createPlace("MediaTest-" + UUID.randomUUID(), "PUBLISHED");
    }

    // ─── Public GET /api/places/{placeId}/media ───────────────────────────────

    @Test
    void publicListMedia_publishedPlace_returns200WithActiveMedia() throws Exception {
        String body = mvc.perform(get("/api/places/" + hotelPlaceId + "/media"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray(), "Response must be an array");
        assertTrue(arr.size() >= 3, "Hotel must have at least 3 seeded active media assets");
        JsonNode first = arr.get(0);
        assertTrue(first.has("id"));
        assertTrue(first.has("url"));
        assertTrue(first.has("mediaType"));
        assertTrue(first.has("cover"));
        assertTrue(first.has("active"));
    }

    @Test
    void publicListMedia_hiddenPlace_returns404() throws Exception {
        Long hiddenId = createPlace("HiddenMediaTest-" + UUID.randomUUID(), "HIDDEN");

        mvc.perform(get("/api/places/" + hiddenId + "/media"))
            .andExpect(status().isNotFound());
    }

    @Test
    void publicListMedia_nonExistentPlace_returns404() throws Exception {
        mvc.perform(get("/api/places/99999/media"))
            .andExpect(status().isNotFound());
    }

    // ─── Admin GET /api/admin/places/{placeId}/media ─────────────────────────

    @Test
    void adminListMedia_anyPlace_returnsMedia() throws Exception {
        String body = mvc.perform(get("/api/admin/places/" + hotelPlaceId + "/media")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());
        assertTrue(arr.size() >= 3, "Hotel should have at least 3 seeded media");
    }

    @Test
    void adminListMedia_requiresAdminRole() throws Exception {
        mvc.perform(get("/api/admin/places/" + hotelPlaceId + "/media"))
            .andExpect(status().isUnauthorized());
    }

    // ─── Admin POST /api/admin/media ─────────────────────────────────────────

    @Test
    void createMedia_validRequest_returns201WithResponse() throws Exception {
        String body = mvc.perform(post("/api/admin/media")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "ownerType": "PLACE",
                      "ownerId": %d,
                      "url": "https://example.com/test-image.jpg",
                      "mediaType": "IMAGE",
                      "altText": "Test image",
                      "sortOrder": 5,
                      "cover": false
                    }
                    """.formatted(scratchPlaceId)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.id").isNumber())
            .andExpect(jsonPath("$.url").value("https://example.com/test-image.jpg"))
            .andExpect(jsonPath("$.mediaType").value("IMAGE"))
            .andExpect(jsonPath("$.active").value(true))
            .andExpect(jsonPath("$.ownerType").value("PLACE"))
            .andReturn().getResponse().getContentAsString();

        assertTrue(mapper.readTree(body).get("id").asLong() > 0);
    }

    @Test
    void createMedia_invalidPlaceId_returns404() throws Exception {
        mvc.perform(post("/api/admin/media")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"ownerType":"PLACE","ownerId":99999,"url":"https://example.com/img.jpg","mediaType":"IMAGE"}
                    """))
            .andExpect(status().isNotFound());
    }

    // ─── Admin PATCH /api/admin/media/cover ──────────────────────────────────

    @Test
    void setCover_unsetsExistingCover_onlyOneCoverPerOwner() throws Exception {
        // Use scratch place to avoid modifying shared seed hotel state
        Long coverId   = addMedia(scratchPlaceId, "https://example.com/cover.jpg", true, 1);
        Long galleryId = addMedia(scratchPlaceId, "https://example.com/gallery.jpg", false, 2);

        // Set gallery as the new cover
        mvc.perform(patch("/api/admin/media/cover")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"mediaId\":" + galleryId + "}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.cover").value(true));

        // Verify exactly 1 cover now
        String listAfter = mvc.perform(get("/api/admin/places/" + scratchPlaceId + "/media")
                .header("Authorization", "Bearer " + adminToken))
            .andReturn().getResponse().getContentAsString();

        long coverCount = 0;
        for (JsonNode n : mapper.readTree(listAfter)) {
            if (n.get("cover").asBoolean()) coverCount++;
        }
        assertEquals(1, coverCount, "Exactly one cover must exist after setCover");
    }

    // ─── Admin PATCH /api/admin/media/reorder ────────────────────────────────

    @Test
    void reorderMedia_validRequest_updatesSortOrders() throws Exception {
        Long id1 = addMedia(scratchPlaceId, "https://example.com/r1.jpg", false, 1);
        Long id2 = addMedia(scratchPlaceId, "https://example.com/r2.jpg", false, 2);

        String body = mvc.perform(patch("/api/admin/media/reorder")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"items":[{"mediaId":%d,"sortOrder":10},{"mediaId":%d,"sortOrder":20}]}
                    """.formatted(id1, id2)))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode result = mapper.readTree(body);
        assertTrue(result.isArray());
        for (JsonNode n : result) {
            if (n.get("id").asLong() == id1) assertEquals(10, n.get("sortOrder").asInt());
            if (n.get("id").asLong() == id2) assertEquals(20, n.get("sortOrder").asInt());
        }
    }

    @Test
    void reorderMedia_mixedOwners_returns400() throws Exception {
        // Create a second scratch place so we can mix media across owners
        Long scratch2PlaceId = createPlace("MediaTestB-" + UUID.randomUUID(), "PUBLISHED");

        Long mediaA = addMedia(scratchPlaceId,  "https://example.com/a.jpg", false, 1);
        Long mediaB = addMedia(scratch2PlaceId, "https://example.com/b.jpg", false, 1);

        mvc.perform(patch("/api/admin/media/reorder")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"items":[{"mediaId":%d,"sortOrder":1},{"mediaId":%d,"sortOrder":2}]}
                    """.formatted(mediaA, mediaB)))
            .andExpect(status().isBadRequest());
    }

    // ─── Admin PATCH /api/admin/media/{id}/deactivate ────────────────────────

    @Test
    void deactivateMedia_hidesFromPublicResponse() throws Exception {
        Long newMediaId = addMedia(scratchPlaceId, "https://example.com/deact-test.jpg", false, 50);

        // Must appear in public list
        String before = mvc.perform(get("/api/places/" + scratchPlaceId + "/media"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        boolean foundBefore = false;
        for (JsonNode n : mapper.readTree(before)) {
            if (n.get("id").asLong() == newMediaId) { foundBefore = true; break; }
        }
        assertTrue(foundBefore, "Media must appear in public list before deactivation");

        // Deactivate
        mvc.perform(patch("/api/admin/media/" + newMediaId + "/deactivate")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.active").value(false));

        // Must NOT appear in public list anymore
        String after = mvc.perform(get("/api/places/" + scratchPlaceId + "/media"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        for (JsonNode n : mapper.readTree(after)) {
            assertNotEquals(newMediaId.longValue(), n.get("id").asLong(),
                "Deactivated media must not appear in public response");
        }
    }

    // ─── Place response integration ───────────────────────────────────────────

    @Test
    void placeSummary_includesCoverImageUrl() throws Exception {
        String body = mvc.perform(get("/api/places"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());

        JsonNode hotel = null;
        for (JsonNode n : arr) {
            if ("grand-palace-hotel-vung-tau".equals(n.get("slug").asText())) {
                hotel = n; break;
            }
        }
        assertNotNull(hotel, "Hotel must appear in public list");
        assertTrue(hotel.has("coverImageUrl"), "PlaceSummaryResponse must include coverImageUrl field");
        assertFalse(hotel.get("coverImageUrl").isNull(),
            "Hotel coverImageUrl must not be null (has seeded media)");
        // Seeded hotel cover image — may change if other tests alter it, so just verify it's from hotel CDN
        assertTrue(hotel.get("coverImageUrl").asText().contains("grand-palace-hotel"),
            "coverImageUrl must reference a hotel image");
    }

    @Test
    void placeDetail_includesGalleryImages() throws Exception {
        String body = mvc.perform(get("/api/places/" + hotelPlaceId))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.galleryImages").isArray())
            .andReturn().getResponse().getContentAsString();

        JsonNode gallery = mapper.readTree(body).get("galleryImages");
        assertTrue(gallery.size() >= 1, "Hotel must have gallery images");

        JsonNode firstImg = gallery.get(0);
        assertTrue(firstImg.has("id"));
        assertTrue(firstImg.has("url"));
        assertTrue(firstImg.has("sortOrder"));
        assertTrue(firstImg.has("cover"));
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private Long createPlace(String name, String status) throws Exception {
        String body = mvc.perform(post("/api/admin/places")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "name": "%s",
                      "categoryId": %d,
                      "administrativeUnitId": %d,
                      "address": "Test Address",
                      "priceLevel": 1,
                      "status": "%s"
                    }
                    """.formatted(name, accCategoryId, locationId, status)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private Long addMedia(Long placeId, String url, boolean cover, int sortOrder) throws Exception {
        String body = mvc.perform(post("/api/admin/media")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"ownerType":"PLACE","ownerId":%d,"url":"%s","mediaType":"IMAGE","cover":%b,"sortOrder":%d}
                    """.formatted(placeId, url, cover, sortOrder)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }
}
