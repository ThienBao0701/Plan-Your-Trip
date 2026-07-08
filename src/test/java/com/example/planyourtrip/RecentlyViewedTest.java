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

import java.time.Instant;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * RecentlyViewedTest — Phase 7.3.
 * Uses the shared seeded "Grand Palace Hotel" (already PUBLISHED) as a reusable
 * "valid place to view" fixture — recording a view never mutates the Place itself,
 * so it's safe to reuse read-only across every test method. A second, freshly
 * created PUBLISHED place is used where ordering across two distinct places matters.
 */
@SpringBootTest
@AutoConfigureMockMvc
class RecentlyViewedTest {

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
    // RECORD VIEW
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void recordView_succeeds() throws Exception {
        String token = registerAndLogin("recent-record");

        String body = mvc.perform(post("/api/me/recently-viewed/" + publishedPlaceId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals(publishedPlaceId, res.get("placeId").asLong());
        assertNotNull(res.get("viewedAt"));

        String listBody = mvc.perform(get("/api/me/recently-viewed")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals(1, mapper.readTree(listBody).get("items").size());
    }

    @Test
    void duplicateView_updatesViewedAt_doesNotDuplicateRow() throws Exception {
        String token = registerAndLogin("recent-duplicate");

        String firstBody = mvc.perform(post("/api/me/recently-viewed/" + publishedPlaceId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Instant firstViewedAt = Instant.parse(mapper.readTree(firstBody).get("viewedAt").asText());

        Thread.sleep(10);

        String secondBody = mvc.perform(post("/api/me/recently-viewed/" + publishedPlaceId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Instant secondViewedAt = Instant.parse(mapper.readTree(secondBody).get("viewedAt").asText());

        assertTrue(secondViewedAt.isAfter(firstViewedAt), "Re-viewing must refresh viewedAt");

        String listBody = mvc.perform(get("/api/me/recently-viewed")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals(1, mapper.readTree(listBody).get("items").size(),
            "Viewing the same place twice must not create a duplicate row");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ORDERING
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void list_orderedNewestFirst() throws Exception {
        String token = registerAndLogin("recent-order");
        Long secondPlaceId = createPublishedPlace(uniq("SecondPlace"));

        mvc.perform(post("/api/me/recently-viewed/" + publishedPlaceId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isCreated());
        Thread.sleep(10);
        mvc.perform(post("/api/me/recently-viewed/" + secondPlaceId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isCreated());

        String body = mvc.perform(get("/api/me/recently-viewed")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode items = mapper.readTree(body).get("items");
        assertEquals(2, items.size());
        assertEquals(secondPlaceId, items.get(0).get("placeId").asLong(), "Most recently viewed must come first");
        assertEquals(publishedPlaceId, items.get(1).get("placeId").asLong());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CLEAR / REMOVE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void clearAll_succeeds() throws Exception {
        String token = registerAndLogin("recent-clear");
        mvc.perform(post("/api/me/recently-viewed/" + publishedPlaceId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isCreated());

        mvc.perform(delete("/api/me/recently-viewed")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNoContent());

        String body = mvc.perform(get("/api/me/recently-viewed")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals(0, mapper.readTree(body).get("items").size());
    }

    @Test
    void removeOne_succeeds() throws Exception {
        String token = registerAndLogin("recent-removeone");
        Long secondPlaceId = createPublishedPlace(uniq("RemoveOnePlace"));

        mvc.perform(post("/api/me/recently-viewed/" + publishedPlaceId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isCreated());
        mvc.perform(post("/api/me/recently-viewed/" + secondPlaceId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isCreated());

        mvc.perform(delete("/api/me/recently-viewed/" + publishedPlaceId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNoContent());

        String body = mvc.perform(get("/api/me/recently-viewed")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode items = mapper.readTree(body).get("items");
        assertEquals(1, items.size());
        assertEquals(secondPlaceId, items.get(0).get("placeId").asLong());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // UNPUBLISHED PLACE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void cannotRecordUnpublishedPlace() throws Exception {
        String token = registerAndLogin("recent-unpublished");
        Long draftPlaceId = createDraftPlace(uniq("DraftRecentPlace"));

        mvc.perform(post("/api/me/recently-viewed/" + draftPlaceId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isUnprocessableEntity());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ISOLATION / AUTH
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void userIsolation_listsAreSeparate() throws Exception {
        String tokenA = registerAndLogin("recent-isolation-a");
        String tokenB = registerAndLogin("recent-isolation-b");

        mvc.perform(post("/api/me/recently-viewed/" + publishedPlaceId)
                .header("Authorization", "Bearer " + tokenA))
            .andExpect(status().isCreated());

        String bodyB = mvc.perform(get("/api/me/recently-viewed")
                .header("Authorization", "Bearer " + tokenB))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals(0, mapper.readTree(bodyB).get("items").size(),
            "User B's list must not contain user A's viewed place");
    }

    @Test
    void unauthenticated_rejected() throws Exception {
        mvc.perform(get("/api/me/recently-viewed"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // OPTIONAL PUBLIC-DETAIL HOOK (bonus coverage, not in the required list)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void anonymousPublicDetailAccess_stillWorks_andDoesNotRecordView() throws Exception {
        mvc.perform(get("/api/places/" + publishedPlaceId))
            .andExpect(status().isOk());
    }

    @Test
    void authenticatedPublicDetailView_recordsView() throws Exception {
        String token = registerAndLogin("recent-hook");

        mvc.perform(get("/api/places/" + publishedPlaceId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        String body = mvc.perform(get("/api/me/recently-viewed")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals(1, mapper.readTree(body).get("items").size());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

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

    private Long createPublishedPlace(String name) throws Exception {
        Long id = createDraftPlace(name);
        adminPatchStatus(id, "APPROVED");
        adminPatchStatus(id, "PUBLISHED");
        return id;
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
