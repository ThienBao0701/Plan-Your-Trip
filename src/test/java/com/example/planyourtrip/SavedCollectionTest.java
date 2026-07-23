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
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * SavedCollectionTest — customer "Saved Collections" feature (multiple named place lists).
 * Reuses the shared seeded "Grand Palace Hotel" (already PUBLISHED) as a read-only "valid
 * place to add" fixture — collection membership never mutates the Place — while each scenario
 * registers its own throwaway user. Separate from, and additive to, WishlistTest.
 */
@SpringBootTest
@AutoConfigureMockMvc
class SavedCollectionTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;

    private String adminToken;
    private static final AtomicInteger counter = new AtomicInteger(1);

    private Long publishedPlaceId;
    private Long accCategoryId;
    private Long hotelSubcategoryId;
    private Long locationId;

    @BeforeEach
    void setup() {
        publishedPlaceId = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        accCategoryId = categoryRepo.findBySlug("accommodation").orElseThrow().getId();
        hotelSubcategoryId = categoryRepo.findBySlug("hotel").orElseThrow().getId();
        locationId = locationRepo.findByCode("VT").orElseThrow().getId();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CREATE / LIST / DETAIL
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void createCollection_persistsWithOwnerAndDefaults() throws Exception {
        String token = registerAndLogin("coll-create");

        String body = mvc.perform(post("/api/me/collections")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"Japan 2027\",\"description\":\"Trip planning\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertNotNull(res.get("id"));
        assertEquals("Japan 2027", res.get("name").asText());
        assertEquals("Trip planning", res.get("description").asText());
        assertTrue(res.get("privateCollection").asBoolean(), "private is the default");
        assertEquals(0, res.get("placeCount").asLong());
        assertTrue(res.get("places").isArray());
        assertEquals(0, res.get("places").size());
    }

    @Test
    void createCollection_honorsExplicitPrivacyAndSortOrder() throws Exception {
        String token = registerAndLogin("coll-create-flags");

        String body = mvc.perform(post("/api/me/collections")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"Public Beaches\",\"privateCollection\":false,\"sortOrder\":5,"
                    + "\"coverImageUrl\":\"https://cdn.example.com/beach.jpg\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertFalse(res.get("privateCollection").asBoolean());
        assertEquals(5, res.get("sortOrder").asInt());
        assertEquals("https://cdn.example.com/beach.jpg", res.get("coverImageUrl").asText());
    }

    @Test
    void listCollections_orderedBySortOrderThenCreatedAt_withPlaceCounts() throws Exception {
        String token = registerAndLogin("coll-list");

        Long second = createCollection(token, "{\"name\":\"B\",\"sortOrder\":2}");
        Long first = createCollection(token, "{\"name\":\"A\",\"sortOrder\":1}");
        addPlace(token, first, publishedPlaceId, 201);

        String body = mvc.perform(get("/api/me/collections")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertEquals(2, arr.size());
        assertEquals(first, arr.get(0).get("id").asLong(), "sortOrder 1 comes first");
        assertEquals(second, arr.get(1).get("id").asLong());
        assertEquals(1, arr.get(0).get("placeCount").asLong());
        assertEquals(0, arr.get(1).get("placeCount").asLong());
    }

    @Test
    void getDetail_emptyCollection_returnsEmptyPlacesListNotNull() throws Exception {
        String token = registerAndLogin("coll-detail-empty");
        Long id = createCollection(token, "{\"name\":\"Empty\"}");

        String body = mvc.perform(get("/api/me/collections/" + id)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertTrue(res.get("places").isArray());
        assertEquals(0, res.get("places").size());
        assertEquals(0, res.get("placeCount").asLong());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // UPDATE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void updateCollection_editsNameDescriptionCoverPrivacy() throws Exception {
        String token = registerAndLogin("coll-update");
        Long id = createCollection(token, "{\"name\":\"Old\",\"privateCollection\":true}");

        String body = mvc.perform(put("/api/me/collections/" + id)
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"New Name\",\"description\":\"Updated\","
                    + "\"coverImageUrl\":\"https://cdn.example.com/x.jpg\",\"privateCollection\":false}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("New Name", res.get("name").asText());
        assertEquals("Updated", res.get("description").asText());
        assertEquals("https://cdn.example.com/x.jpg", res.get("coverImageUrl").asText());
        assertFalse(res.get("privateCollection").asBoolean());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // DELETE — never cascades to Place
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void deleteCollection_removesCollectionButNeverThePlace() throws Exception {
        String token = registerAndLogin("coll-delete");
        Long id = createCollection(token, "{\"name\":\"ToDelete\"}");
        addPlace(token, id, publishedPlaceId, 201);

        mvc.perform(delete("/api/me/collections/" + id)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNoContent());

        mvc.perform(get("/api/me/collections/" + id)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNotFound());

        // The Place it contained must still exist in the database.
        assertTrue(placeRepo.findById(publishedPlaceId).isPresent(),
            "Deleting a collection must NEVER delete the underlying Place");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PLACES — add / duplicate / remove / ordering
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void addPlace_succeeds_andAppearsInDetailWithSummary() throws Exception {
        String token = registerAndLogin("coll-add");
        Long id = createCollection(token, "{\"name\":\"Adds\"}");

        String body = addPlace(token, id, publishedPlaceId, 201);
        JsonNode added = mapper.readTree(body);
        assertEquals(publishedPlaceId, added.get("placeId").asLong());
        assertNotNull(added.get("name"));
        assertNotNull(added.get("slug"));
        assertNotNull(added.get("categoryName"));
        assertNotNull(added.get("address"));
        assertEquals(0, added.get("position").asInt());

        String detail = mvc.perform(get("/api/me/collections/" + id)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals(1, mapper.readTree(detail).get("places").size());
    }

    @Test
    void addDuplicatePlace_rejectedWith409() throws Exception {
        String token = registerAndLogin("coll-dup");
        Long id = createCollection(token, "{\"name\":\"Dups\"}");
        addPlace(token, id, publishedPlaceId, 201);
        addPlace(token, id, publishedPlaceId, 409);
    }

    @Test
    void addNonexistentPlace_returns404() throws Exception {
        String token = registerAndLogin("coll-badplace");
        Long id = createCollection(token, "{\"name\":\"BadPlace\"}");
        addPlace(token, id, 99999999L, 404);
    }

    @Test
    void removePlace_removesLinkButPlaceStillExists() throws Exception {
        String token = registerAndLogin("coll-remove");
        Long id = createCollection(token, "{\"name\":\"Removes\"}");
        addPlace(token, id, publishedPlaceId, 201);

        mvc.perform(delete("/api/me/collections/" + id + "/places/" + publishedPlaceId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNoContent());

        String detail = mvc.perform(get("/api/me/collections/" + id)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals(0, mapper.readTree(detail).get("places").size());
        assertTrue(placeRepo.findById(publishedPlaceId).isPresent(),
            "Removing a place from a collection must NEVER delete the Place");
    }

    @Test
    void removePlace_notInCollection_returns404() throws Exception {
        String token = registerAndLogin("coll-remove-missing");
        Long id = createCollection(token, "{\"name\":\"Empty\"}");
        mvc.perform(delete("/api/me/collections/" + id + "/places/" + publishedPlaceId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNotFound());
    }

    @Test
    void insertionOrderingStable_acrossMultipleAdds() throws Exception {
        String token = registerAndLogin("coll-order");
        Long id = createCollection(token, "{\"name\":\"Ordered\"}");

        // Distinct published places, added in a known order.
        Long p1 = publishedPlaceId;
        Long p2 = createPublishedPlace(uniq("OrderPlace2"));
        Long p3 = createPublishedPlace(uniq("OrderPlace3"));
        addPlace(token, id, p1, 201);
        addPlace(token, id, p2, 201);
        addPlace(token, id, p3, 201);

        JsonNode places = detailPlaces(token, id);
        assertEquals(3, places.size());
        assertEquals(p1, places.get(0).get("placeId").asLong());
        assertEquals(p2, places.get(1).get("placeId").asLong());
        assertEquals(p3, places.get(2).get("placeId").asLong());
        assertEquals(0, places.get(0).get("position").asInt());
        assertEquals(1, places.get(1).get("position").asInt());
        assertEquals(2, places.get(2).get("position").asInt());
    }

    @Test
    void insertionOrderingHolds_afterRemoveAndReAdd() throws Exception {
        String token = registerAndLogin("coll-order2");
        Long id = createCollection(token, "{\"name\":\"Ordered2\"}");
        Long p1 = publishedPlaceId;
        Long p2 = createPublishedPlace(uniq("ReAddPlace"));

        addPlace(token, id, p1, 201);
        addPlace(token, id, p2, 201);
        // remove first, then re-add it — it should now sort last (highest position).
        mvc.perform(delete("/api/me/collections/" + id + "/places/" + p1)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNoContent());
        addPlace(token, id, p1, 201);

        JsonNode places = detailPlaces(token, id);
        assertEquals(2, places.size());
        assertEquals(p2, places.get(0).get("placeId").asLong());
        assertEquals(p1, places.get(1).get("placeId").asLong());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // OWNER-SCOPED 404 (no existence leak)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void foreignCollection_get_put_delete_addPlace_allReturn404() throws Exception {
        String tokenA = registerAndLogin("coll-owner-a");
        String tokenB = registerAndLogin("coll-owner-b");
        Long id = createCollection(tokenA, "{\"name\":\"A's private\"}");

        mvc.perform(get("/api/me/collections/" + id)
                .header("Authorization", "Bearer " + tokenB))
            .andExpect(status().isNotFound());

        mvc.perform(put("/api/me/collections/" + id)
                .header("Authorization", "Bearer " + tokenB)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"hijack\"}"))
            .andExpect(status().isNotFound());

        mvc.perform(delete("/api/me/collections/" + id)
                .header("Authorization", "Bearer " + tokenB))
            .andExpect(status().isNotFound());

        addPlace(tokenB, id, publishedPlaceId, 404);

        // And it must NOT appear in B's own listing.
        String listB = mvc.perform(get("/api/me/collections")
                .header("Authorization", "Bearer " + tokenB))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals(0, mapper.readTree(listB).size());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // AUTH
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void anonymous_rejectedWith401() throws Exception {
        mvc.perform(get("/api/me/collections")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/me/collections")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"x\"}"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // VALIDATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void blankName_rejectedWith400() throws Exception {
        String token = registerAndLogin("coll-blank");
        mvc.perform(post("/api/me/collections")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"   \"}"))
            .andExpect(status().isBadRequest());
    }

    @Test
    void overlongName_rejectedWith400() throws Exception {
        String token = registerAndLogin("coll-longname");
        String longName = "x".repeat(200);
        mvc.perform(post("/api/me/collections")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"" + longName + "\"}"))
            .andExpect(status().isBadRequest());
    }

    @Test
    void overlongDescription_rejectedWith400() throws Exception {
        String token = registerAndLogin("coll-longdesc");
        String longDesc = "y".repeat(1200);
        mvc.perform(post("/api/me/collections")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"ok\",\"description\":\"" + longDesc + "\"}"))
            .andExpect(status().isBadRequest());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // LIMITS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void maxCollectionsPerUser_exceeded_returns409() throws Exception {
        String token = registerAndLogin("coll-limit");
        // MAX_COLLECTIONS_PER_USER = 100; create the limit, then the 101st must fail.
        for (int i = 0; i < 100; i++) {
            createCollection(token, "{\"name\":\"C" + i + "\"}");
        }
        mvc.perform(post("/api/me/collections")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"over the limit\"}"))
            .andExpect(status().isConflict());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private JsonNode detailPlaces(String token, Long id) throws Exception {
        String detail = mvc.perform(get("/api/me/collections/" + id)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(detail).get("places");
    }

    private Long createCollection(String token, String json) throws Exception {
        String body = mvc.perform(post("/api/me/collections")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private String addPlace(String token, Long collectionId, Long placeId, int expectedStatus) throws Exception {
        return mvc.perform(post("/api/me/collections/" + collectionId + "/places/" + placeId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().is(expectedStatus))
            .andReturn().getResponse().getContentAsString();
    }

    private String adminToken() throws Exception {
        if (adminToken == null) adminToken = login("admin@planyourtrip.com", "admin123456");
        return adminToken;
    }

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private String registerAndLogin(String namePrefix) throws Exception {
        String email = namePrefix + "-" + counter.getAndIncrement() + "@test.com";
        String body = mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"" + namePrefix + " Tester\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    /** Creates a DRAFT place then transitions it DRAFT→APPROVED→PUBLISHED, returning its id. */
    private Long createPublishedPlace(String name) throws Exception {
        Long id = createDraftPlace(name);
        adminPatchStatus(id, "APPROVED");
        adminPatchStatus(id, "PUBLISHED");
        return id;
    }

    private Long createDraftPlace(String name) throws Exception {
        String req = """
                {
                  "name": "%s",
                  "categoryId": %d,
                  "subcategoryId": %d,
                  "administrativeUnitId": %d,
                  "address": "123 Test Street, Test City",
                  "priceLevel": 2,
                  "featured": false,
                  "verified": false,
                  "status": "DRAFT"
                }
                """.formatted(name, accCategoryId, hotelSubcategoryId, locationId);

        String resp = mvc.perform(post("/api/admin/places")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp).get("id").asLong();
    }

    private void adminPatchStatus(Long id, String status) throws Exception {
        mvc.perform(patch("/api/admin/places/" + id + "/status")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"" + status + "\"}"))
            .andExpect(status().isOk());
    }

    private String uniq(String prefix) {
        return prefix + "-" + UUID.randomUUID().toString().substring(0, 8);
    }
}
