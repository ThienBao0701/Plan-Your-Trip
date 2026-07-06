package com.example.planyourtrip;

import com.example.planyourtrip.model.BudgetLevel;
import com.example.planyourtrip.model.TravelStyle;
import com.example.planyourtrip.repository.CategoryRepository;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
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

@SpringBootTest
@AutoConfigureMockMvc
class PlaceMetadataTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;

    private String adminToken;
    private Long hotelPlaceId;
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
        accCategoryId = categoryRepo.findBySlug("accommodation").orElseThrow().getId();
        locationId    = locationRepo.findByCode("VT").orElseThrow().getId();
        scratchPlaceId = createPlace("MetaTest-" + UUID.randomUUID(), "PUBLISHED");
    }

    // ─── Seed data verification ───────────────────────────────────────────────

    @Test
    void getDetail_hotelIncludesSeededMetadata() throws Exception {
        String body = mvc.perform(get("/api/places/" + hotelPlaceId))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.metadata").exists())
            .andReturn().getResponse().getContentAsString();

        JsonNode meta = mapper.readTree(body).get("metadata");
        assertNotNull(meta, "metadata must not be null for hotel");
        assertFalse(meta.isNull(), "metadata must be a JSON object, not null");
        assertTrue(meta.get("romantic").asBoolean(), "hotel must be romantic=true");
        assertTrue(meta.get("photographySpot").asBoolean(), "hotel must be photographySpot=true");
        assertFalse(meta.get("petFriendly").asBoolean(), "hotel must be petFriendly=false");
        assertEquals("HIGH", meta.get("estimatedBudgetLevel").asText());
        assertTrue(meta.get("travelStyles").isArray());
        assertTrue(meta.get("travelStyles").size() > 0);
    }

    // ─── Null metadata when not set ───────────────────────────────────────────

    @Test
    void getDetail_scratchPlace_metadataIsNull() throws Exception {
        String body = mvc.perform(get("/api/places/" + scratchPlaceId))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode node = mapper.readTree(body);
        assertTrue(node.has("metadata"), "metadata field must be present in response");
        assertTrue(node.get("metadata").isNull(), "metadata must be null for place with no metadata set");
    }

    // ─── PUT /api/admin/places/{id}/metadata ─────────────────────────────────

    @Test
    void setMetadata_validRequest_returns200() throws Exception {
        String body = mvc.perform(put("/api/admin/places/" + scratchPlaceId + "/metadata")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(fullMetadataPayload()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").isNumber())
            .andExpect(jsonPath("$.romantic").value(true))
            .andExpect(jsonPath("$.photographySpot").value(true))
            .andExpect(jsonPath("$.estimatedBudgetLevel").value("MEDIUM"))
            .andExpect(jsonPath("$.estimatedVisitMinutes").value(90))
            .andExpect(jsonPath("$.travelStyles").isArray())
            .andReturn().getResponse().getContentAsString();

        JsonNode result = mapper.readTree(body);
        assertTrue(result.get("id").asLong() > 0);
        assertTrue(result.get("travelStyles").size() >= 2);
    }

    @Test
    void setMetadata_appearsInPlaceDetail() throws Exception {
        mvc.perform(put("/api/admin/places/" + scratchPlaceId + "/metadata")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(fullMetadataPayload()))
            .andExpect(status().isOk());

        String body = mvc.perform(get("/api/places/" + scratchPlaceId))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode meta = mapper.readTree(body).get("metadata");
        assertFalse(meta.isNull(), "metadata must appear in place detail after PUT");
        assertTrue(meta.get("romantic").asBoolean());
        assertEquals("MEDIUM", meta.get("estimatedBudgetLevel").asText());
    }

    @Test
    void setMetadata_isIdempotent_updateInPlace() throws Exception {
        // First PUT
        String first = mvc.perform(put("/api/admin/places/" + scratchPlaceId + "/metadata")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(fullMetadataPayload()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        long firstId = mapper.readTree(first).get("id").asLong();

        // Second PUT with different values — build a new payload rather than string-replacing
        String updatedPayload = """
            {
              "travelStyles": ["SOLO"],
              "bestVisitTimes": ["EVENING"],
              "bestSeasons": ["WINTER"],
              "weatherTypes": ["RAINY"],
              "estimatedVisitMinutes": 120,
              "estimatedBudgetLevel": "LOW",
              "difficultyLevel": "HARD",
              "accessibilityLevel": "LOW",
              "crowdLevel": "HIGH",
              "romantic": false,
              "familyFriendly": true,
              "kidFriendly": false,
              "petFriendly": true,
              "wheelchairFriendly": false,
              "photographySpot": false,
              "sunsetSpot": true,
              "sunriseSpot": false,
              "indoor": false,
              "outdoor": true,
              "rainyDaySuitable": true,
              "notes": "Updated metadata"
            }
            """;
        String second = mvc.perform(put("/api/admin/places/" + scratchPlaceId + "/metadata")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(updatedPayload))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode updated = mapper.readTree(second);
        assertEquals(firstId, updated.get("id").asLong(), "Must update existing row, not create new one");
        assertFalse(updated.get("romantic").asBoolean(), "romantic must be updated to false");
        assertEquals(120, updated.get("estimatedVisitMinutes").asInt());
    }

    // ─── Validation ───────────────────────────────────────────────────────────

    @Test
    void setMetadata_negativeVisitMinutes_returns400() throws Exception {
        mvc.perform(put("/api/admin/places/" + scratchPlaceId + "/metadata")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "estimatedVisitMinutes": -1,
                      "romantic": false, "familyFriendly": false, "kidFriendly": false,
                      "petFriendly": false, "wheelchairFriendly": false, "photographySpot": false,
                      "sunsetSpot": false, "sunriseSpot": false, "indoor": false,
                      "outdoor": false, "rainyDaySuitable": false
                    }
                    """))
            .andExpect(status().isBadRequest());
    }

    // ─── Auth ─────────────────────────────────────────────────────────────────

    @Test
    void setMetadata_requiresAdminToken_returns401() throws Exception {
        mvc.perform(put("/api/admin/places/" + scratchPlaceId + "/metadata")
                .contentType(MediaType.APPLICATION_JSON)
                .content(fullMetadataPayload()))
            .andExpect(status().isUnauthorized());
    }

    // ─── Not found ────────────────────────────────────────────────────────────

    @Test
    void setMetadata_nonExistentPlace_returns404() throws Exception {
        mvc.perform(put("/api/admin/places/99999/metadata")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(fullMetadataPayload()))
            .andExpect(status().isNotFound());
    }

    // ─── Enum coverage ────────────────────────────────────────────────────────

    @Test
    void enumValues_budgetLevelHasExpectedValues() {
        BudgetLevel[] values = BudgetLevel.values();
        assertEquals(5, values.length);
        assertArrayEquals(
            new BudgetLevel[]{BudgetLevel.FREE, BudgetLevel.LOW, BudgetLevel.MEDIUM, BudgetLevel.HIGH, BudgetLevel.LUXURY},
            values
        );
    }

    @Test
    void enumValues_travelStyleHasExpectedValues() {
        TravelStyle[] values = TravelStyle.values();
        assertEquals(7, values.length);
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

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

    private String fullMetadataPayload() {
        return """
            {
              "travelStyles": ["SOLO", "COUPLE"],
              "bestVisitTimes": ["MORNING", "AFTERNOON"],
              "bestSeasons": ["SPRING", "AUTUMN"],
              "weatherTypes": ["SUNNY"],
              "estimatedVisitMinutes": 90,
              "estimatedBudgetLevel": "MEDIUM",
              "difficultyLevel": "EASY",
              "accessibilityLevel": "HIGH",
              "crowdLevel": "LOW",
              "romantic": true,
              "familyFriendly": false,
              "kidFriendly": false,
              "petFriendly": false,
              "wheelchairFriendly": false,
              "photographySpot": true,
              "sunsetSpot": false,
              "sunriseSpot": false,
              "indoor": true,
              "outdoor": false,
              "rainyDaySuitable": false,
              "notes": "Test metadata"
            }
            """;
    }
}
