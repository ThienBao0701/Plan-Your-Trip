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
import org.springframework.test.web.servlet.ResultActions;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class AdminPlaceCrudTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired PlaceRepository placeRepo;

    private String adminToken;
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

        accCategoryId = categoryRepo.findBySlug("accommodation").orElseThrow().getId();
        locationId    = locationRepo.findByCode("VT").orElseThrow().getId();
    }

    // ─── Admin GET /{id} ──────────────────────────────────────────────────────

    @Test
    void adminGetById_publishedPlace_returnsFullDetail() throws Exception {
        Long id = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();

        mvc.perform(get("/api/admin/places/" + id)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(id))
            .andExpect(jsonPath("$.slug").value("grand-palace-hotel-vung-tau"))
            .andExpect(jsonPath("$.status").value("PUBLISHED"))
            .andExpect(jsonPath("$.tags").isArray())
            .andExpect(jsonPath("$.amenities").isArray())
            .andExpect(jsonPath("$.openingHours").isArray())
            .andExpect(jsonPath("$.groupedOpeningHours").isArray())
            .andExpect(jsonPath("$.location").exists());
    }

    @Test
    void adminGetById_draftPlace_returnsFullDetail() throws Exception {
        JsonNode created = adminCreate(uniq("AdminGetDraft"), "DRAFT", false, false);
        Long id = created.get("id").asLong();

        mvc.perform(get("/api/admin/places/" + id)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(id))
            .andExpect(jsonPath("$.status").value("DRAFT"))
            .andExpect(jsonPath("$.tags").isArray())
            .andExpect(jsonPath("$.amenities").isArray())
            .andExpect(jsonPath("$.openingHours").isArray());
    }

    @Test
    void adminGetById_withoutAuth_returns401() throws Exception {
        Long id = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        mvc.perform(get("/api/admin/places/" + id))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void adminGetById_nonExistentId_returns404() throws Exception {
        mvc.perform(get("/api/admin/places/999999")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.status").value(404));
    }

    // ─── Slug uniqueness ──────────────────────────────────────────────────────

    @Test
    void create_duplicateSlug_appendsSuffix2() throws Exception {
        String name = "Slug Collision " + UUID.randomUUID().toString().substring(0, 8);
        JsonNode first  = adminCreate(name, "DRAFT", false, false);
        JsonNode second = adminCreate(name, "DRAFT", false, false);

        String slug1 = first.get("slug").asText();
        String slug2 = second.get("slug").asText();
        assertNotEquals(slug1, slug2, "Duplicate name must produce different slugs");
        assertEquals(slug1 + "-2", slug2, "Second duplicate must get -2 suffix");
    }

    @Test
    void create_tripleCollision_appendsSuffix3() throws Exception {
        String name = "Triple Slug " + UUID.randomUUID().toString().substring(0, 8);
        JsonNode first  = adminCreate(name, "DRAFT", false, false);
        JsonNode second = adminCreate(name, "DRAFT", false, false);
        JsonNode third  = adminCreate(name, "DRAFT", false, false);

        String slug1 = first.get("slug").asText();
        String slug3 = third.get("slug").asText();
        assertEquals(slug1 + "-3", slug3, "Third duplicate must get -3 suffix");
    }

    // ─── Subcategory parent validation ────────────────────────────────────────

    @Test
    void create_subcategoryNotUnderCategory_returns400() throws Exception {
        Long coffeeCategoryId = categoryRepo.findBySlug("coffee").orElseThrow().getId();

        String req = """
                {
                  "name": "Bad Subcat Place",
                  "categoryId": %d,
                  "subcategoryId": %d,
                  "administrativeUnitId": %d,
                  "address": "Test Address",
                  "priceLevel": 0,
                  "featured": false,
                  "verified": false
                }
                """.formatted(accCategoryId, coffeeCategoryId, locationId);

        mvc.perform(post("/api/admin/places")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400));
    }

    // ─── Status transitions ───────────────────────────────────────────────────

    @Test
    void statusTransition_draftToPendingReview_succeeds() throws Exception {
        Long id = adminCreate(uniq("TransDraft2PR"), "DRAFT", false, false).get("id").asLong();

        adminPatchStatus(id, "PENDING_REVIEW")
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("PENDING_REVIEW"));
    }

    @Test
    void statusTransition_draftToHidden_succeeds() throws Exception {
        Long id = adminCreate(uniq("TransDraft2Hidden"), "DRAFT", false, false).get("id").asLong();

        adminPatchStatus(id, "HIDDEN")
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("HIDDEN"));
    }

    @Test
    void statusTransition_approvedToPublished_succeeds() throws Exception {
        Long id = adminCreate(uniq("TransApproved2Pub"), "DRAFT", false, false).get("id").asLong();

        adminPatchStatus(id, "APPROVED").andExpect(status().isOk());

        adminPatchStatus(id, "PUBLISHED")
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("PUBLISHED"));
    }

    @Test
    void statusTransition_invalid_publishedToDraft_returns400() throws Exception {
        Long id = adminCreate(uniq("PubToDraft"), "PUBLISHED", false, false).get("id").asLong();

        adminPatchStatus(id, "DRAFT")
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400))
            .andExpect(jsonPath("$.message").isString());
    }

    @Test
    void statusTransition_invalid_archivedToPublished_returns400() throws Exception {
        Long id = adminCreate(uniq("ArchivedBlock"), "DRAFT", false, false).get("id").asLong();

        adminPatchStatus(id, "ARCHIVED").andExpect(status().isOk());

        adminPatchStatus(id, "PUBLISHED")
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void statusTransition_invalid_publishedToPendingReview_returns400() throws Exception {
        Long id = adminCreate(uniq("PubToPR"), "PUBLISHED", false, false).get("id").asLong();

        adminPatchStatus(id, "PENDING_REVIEW")
            .andExpect(status().isBadRequest());
    }

    @Test
    void statusTransition_sameStatus_isNoOp() throws Exception {
        Long id = adminCreate(uniq("SameStatus"), "DRAFT", false, false).get("id").asLong();

        adminPatchStatus(id, "DRAFT")
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("DRAFT"));
    }

    // ─── Featured / verified guards ───────────────────────────────────────────

    @Test
    void updateFeatured_trueOnDraft_returns400() throws Exception {
        Long id = adminCreate(uniq("FeaturedDraftFail"), "DRAFT", false, false).get("id").asLong();

        mvc.perform(patch("/api/admin/places/" + id + "/featured")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"value\":true}"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void updateFeatured_trueOnPublished_succeeds() throws Exception {
        Long id = adminCreate(uniq("FeaturedPubOk"), "PUBLISHED", false, false).get("id").asLong();

        mvc.perform(patch("/api/admin/places/" + id + "/featured")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"value\":true}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.featured").value(true));
    }

    @Test
    void updateFeatured_falseOnDraft_succeeds() throws Exception {
        Long id = adminCreate(uniq("FeaturedFalseDraft"), "DRAFT", false, false).get("id").asLong();

        mvc.perform(patch("/api/admin/places/" + id + "/featured")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"value\":false}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.featured").value(false));
    }

    @Test
    void updateVerified_trueOnDraft_returns400() throws Exception {
        Long id = adminCreate(uniq("VerifiedDraftFail"), "DRAFT", false, false).get("id").asLong();

        mvc.perform(patch("/api/admin/places/" + id + "/verified")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"value\":true}"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void updateVerified_trueOnApproved_succeeds() throws Exception {
        Long id = adminCreate(uniq("VerifiedApprovedOk"), "DRAFT", false, false).get("id").asLong();
        adminPatchStatus(id, "APPROVED").andExpect(status().isOk());

        mvc.perform(patch("/api/admin/places/" + id + "/verified")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"value\":true}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.verified").value(true));
    }

    @Test
    void create_withFeaturedTrueOnDraft_returns400() throws Exception {
        String req = """
                {
                  "name": "Featured Draft Create",
                  "categoryId": %d,
                  "administrativeUnitId": %d,
                  "address": "Test Address",
                  "priceLevel": 0,
                  "featured": true,
                  "verified": false,
                  "status": "DRAFT"
                }
                """.formatted(accCategoryId, locationId);

        mvc.perform(post("/api/admin/places")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400));
    }

    // ─── Public vs admin visibility ───────────────────────────────────────────

    @Test
    void publicEndpoint_hiddenPlace_returns404() throws Exception {
        Long id = adminCreate(uniq("HiddenVis"), "DRAFT", false, false).get("id").asLong();
        adminPatchStatus(id, "HIDDEN").andExpect(status().isOk());

        mvc.perform(get("/api/places/" + id))
            .andExpect(status().isNotFound());
    }

    @Test
    void publicEndpoint_archivedPlace_returns404() throws Exception {
        Long id = adminCreate(uniq("ArchivedVis"), "DRAFT", false, false).get("id").asLong();
        adminPatchStatus(id, "ARCHIVED").andExpect(status().isOk());

        mvc.perform(get("/api/places/" + id))
            .andExpect(status().isNotFound());
    }

    @Test
    void adminEndpoint_canSeeHiddenPlace() throws Exception {
        Long id = adminCreate(uniq("HiddenAdmin"), "DRAFT", false, false).get("id").asLong();
        adminPatchStatus(id, "HIDDEN").andExpect(status().isOk());

        mvc.perform(get("/api/admin/places/" + id)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("HIDDEN"));
    }

    @Test
    void adminEndpoint_canSeeArchivedPlace() throws Exception {
        Long id = adminCreate(uniq("ArchivedAdmin"), "DRAFT", false, false).get("id").asLong();
        adminPatchStatus(id, "ARCHIVED").andExpect(status().isOk());

        mvc.perform(get("/api/admin/places/" + id)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("ARCHIVED"));
    }

    @Test
    void adminSearch_canSeeHiddenPlacesWithStatusFilter() throws Exception {
        Long id = adminCreate(uniq("HiddenFilter"), "DRAFT", false, false).get("id").asLong();
        adminPatchStatus(id, "HIDDEN").andExpect(status().isOk());

        String body = mvc.perform(get("/api/admin/places")
                .header("Authorization", "Bearer " + adminToken)
                .param("status", "HIDDEN"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode content = mapper.readTree(body).get("content");
        assertTrue(content.size() >= 1, "Expected at least 1 HIDDEN place");
        for (JsonNode place : content) {
            assertEquals("HIDDEN", place.get("status").asText());
        }
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private JsonNode adminCreate(String name, String status, boolean featured, boolean verified) throws Exception {
        String req = """
                {
                  "name": "%s",
                  "categoryId": %d,
                  "administrativeUnitId": %d,
                  "address": "Test Address",
                  "priceLevel": 0,
                  "featured": %b,
                  "verified": %b,
                  "status": "%s"
                }
                """.formatted(name, accCategoryId, locationId, featured, verified, status);

        String resp = mvc.perform(post("/api/admin/places")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp);
    }

    private ResultActions adminPatchStatus(Long id, String status) throws Exception {
        return mvc.perform(patch("/api/admin/places/" + id + "/status")
            .header("Authorization", "Bearer " + adminToken)
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"status\":\"" + status + "\"}"));
    }

    private String uniq(String prefix) {
        return prefix + "-" + UUID.randomUUID().toString().substring(0, 8);
    }
}
