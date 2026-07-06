package com.example.planyourtrip;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class PlaceSearchTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;

    private String adminToken;

    @BeforeEach
    void obtainAdminToken() throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"admin@planyourtrip.com\",\"password\":\"admin123456\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        adminToken = mapper.readTree(body).get("token").asText();
    }

    // ─── PageResponse structure ────────────────────────────────────────────────

    @Test
    void search_noFilters_returnsPageResponseStructure() throws Exception {
        String body = mvc.perform(get("/api/places/search"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.content").isArray())
            .andExpect(jsonPath("$.page").value(0))
            .andExpect(jsonPath("$.size").value(20))
            .andExpect(jsonPath("$.totalElements").isNumber())
            .andExpect(jsonPath("$.totalPages").isNumber())
            .andReturn().getResponse().getContentAsString();

        assertTrue(mapper.readTree(body).get("totalElements").asInt() >= 4,
            "Expected at least 4 seeded places");
    }

    @Test
    void search_summaryItemContainsExpectedFields() throws Exception {
        String body = mvc.perform(get("/api/places/search"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode first = mapper.readTree(body).get("content").get(0);
        assertNotNull(first.get("id"));
        assertNotNull(first.get("name"));
        assertNotNull(first.get("slug"));
        assertNotNull(first.get("category"));
        assertNotNull(first.get("administrativeUnit"));
        assertNotNull(first.get("address"));
        assertNotNull(first.get("priceLevel"));
        assertNotNull(first.get("ratingAvg"));
        assertNotNull(first.get("featured"));
        assertNotNull(first.get("verified"));
    }

    // ─── Keyword search ───────────────────────────────────────────────────────

    @Test
    void search_q_ascii_vung_matchesVungTauPlace() throws Exception {
        String body = mvc.perform(get("/api/places/search").param("q", "vung"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertTrue(containsSlugSubstring(mapper.readTree(body).get("content"), "vung-tau"),
            "q='vung' should match Grand Palace Hotel Vũng Tàu");
    }

    @Test
    void search_q_ascii_daLat_matchesDaLatPlace() throws Exception {
        String body = mvc.perform(get("/api/places/search").param("q", "da lat"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertTrue(containsSlugSubstring(mapper.readTree(body).get("content"), "da-lat"),
            "q='da lat' should match The Dreamer Café Đà Lạt");
    }

    @Test
    void search_q_ascii_baNa_matchesBaNaHills() throws Exception {
        String body = mvc.perform(get("/api/places/search").param("q", "ba na"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertTrue(containsSlugSubstring(mapper.readTree(body).get("content"), "ba-na-hills"),
            "q='ba na' should match Bà Nà Hills via nameNormalized");
    }

    @Test
    void search_q_vietnamese_accented_normalizesAndMatches() throws Exception {
        // "Vũng Tàu" normalizes → "vung tau"; nameNormalized field matches
        String body = mvc.perform(get("/api/places/search").param("q", "Vũng Tàu"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertTrue(containsSlugSubstring(mapper.readTree(body).get("content"), "vung-tau"),
            "Accented Vietnamese q='Vũng Tàu' should match via normalization");
    }

    @Test
    void search_q_description_asciiTermInDescription_matchesPlace() throws Exception {
        // "Hang Sửng Sốt" description contains English text "Surprise Cave"
        String body = mvc.perform(get("/api/places/search").param("q", "surprise cave"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertTrue(containsSlugSubstring(mapper.readTree(body).get("content"), "hang-sung-sot"),
            "q='surprise cave' should match via description search");
    }

    @Test
    void search_q_noMatch_returnsEmptyContent() throws Exception {
        mvc.perform(get("/api/places/search").param("q", "xyznonexistent99"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.totalElements").value(0))
            .andExpect(jsonPath("$.content").isEmpty());
    }

    // ─── Category filters ─────────────────────────────────────────────────────

    @Test
    void search_categorySlug_cafe_returnsOnlyCafePlaces() throws Exception {
        String body = mvc.perform(get("/api/places/search").param("categorySlug", "cafe"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode content = mapper.readTree(body).get("content");
        assertTrue(content.size() >= 1, "Expected at least 1 cafe place");
        for (JsonNode place : content) {
            assertEquals("cafe", place.get("category").get("slug").asText(),
                "All results must have category slug 'cafe'");
        }
    }

    // ─── Boolean filters ──────────────────────────────────────────────────────

    @Test
    void search_featured_true_returnsOnlyFeaturedPlaces() throws Exception {
        String body = mvc.perform(get("/api/places/search").param("featured", "true"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode content = mapper.readTree(body).get("content");
        assertTrue(content.size() >= 1);
        for (JsonNode place : content) {
            assertTrue(place.get("featured").asBoolean(), "All results must be featured=true");
        }
    }

    @Test
    void search_verified_true_returnsOnlyVerifiedPlaces() throws Exception {
        String body = mvc.perform(get("/api/places/search").param("verified", "true"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        for (JsonNode place : mapper.readTree(body).get("content")) {
            assertTrue(place.get("verified").asBoolean(), "All results must be verified=true");
        }
    }

    // ─── Price filter ─────────────────────────────────────────────────────────

    @Test
    void search_maxPriceLevel_filtersCorrectly() throws Exception {
        // seed: Hotel=3, Cafe=1, BaNa=2, HaLong=1 → maxPriceLevel=2 excludes Hotel(3)
        String body = mvc.perform(get("/api/places/search").param("maxPriceLevel", "2"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        for (JsonNode place : mapper.readTree(body).get("content")) {
            assertTrue(place.get("priceLevel").asInt() <= 2,
                "All results must have priceLevel <= 2");
        }
    }

    // ─── Sort ─────────────────────────────────────────────────────────────────

    @Test
    void search_sort_newest_returns200() throws Exception {
        mvc.perform(get("/api/places/search").param("sort", "newest"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.content").isArray());
    }

    @Test
    void search_sort_ratingDesc_returns200() throws Exception {
        mvc.perform(get("/api/places/search").param("sort", "rating_desc"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.content").isArray());
    }

    @Test
    void search_sort_priceAsc_returnsPriceLevelNonDecreasing() throws Exception {
        String body = mvc.perform(get("/api/places/search").param("sort", "price_asc"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        int prev = -1;
        for (JsonNode place : mapper.readTree(body).get("content")) {
            int price = place.get("priceLevel").asInt();
            assertTrue(price >= prev, "price_asc order violated: " + prev + " > " + price);
            prev = price;
        }
    }

    @Test
    void search_sort_priceDesc_returnsPriceLevelNonIncreasing() throws Exception {
        String body = mvc.perform(get("/api/places/search").param("sort", "price_desc"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        int prev = Integer.MAX_VALUE;
        for (JsonNode place : mapper.readTree(body).get("content")) {
            int price = place.get("priceLevel").asInt();
            assertTrue(price <= prev, "price_desc order violated: " + prev + " < " + price);
            prev = price;
        }
    }

    @Test
    void search_sort_nameAsc_returns200WithContent() throws Exception {
        mvc.perform(get("/api/places/search").param("sort", "name_asc"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.content").isArray());
    }

    // ─── Pagination ───────────────────────────────────────────────────────────

    @Test
    void search_pagination_sizeTwoPage0_returnsExactlyTwoItems() throws Exception {
        String body = mvc.perform(get("/api/places/search")
                .param("page", "0").param("size", "2"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.page").value(0))
            .andExpect(jsonPath("$.size").value(2))
            .andReturn().getResponse().getContentAsString();

        JsonNode node = mapper.readTree(body);
        assertEquals(2, node.get("content").size(), "Page 0 with size=2 must return exactly 2 items");
        assertTrue(node.get("totalElements").asInt() >= 4);
        assertTrue(node.get("totalPages").asInt() >= 2);
    }

    @Test
    void search_pagination_page0AndPage1_containDistinctPlaces() throws Exception {
        String b0 = mvc.perform(get("/api/places/search").param("page", "0").param("size", "2"))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        String b1 = mvc.perform(get("/api/places/search").param("page", "1").param("size", "2"))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();

        JsonNode page0 = mapper.readTree(b0).get("content");
        JsonNode page1 = mapper.readTree(b1).get("content");
        for (JsonNode p0 : page0) {
            for (JsonNode p1 : page1) {
                assertNotEquals(p0.get("id").asLong(), p1.get("id").asLong(),
                    "Same place ID appeared on two different pages");
            }
        }
    }

    // ─── Validation ───────────────────────────────────────────────────────────

    @Test
    void search_invalidPage_negative_returns400() throws Exception {
        mvc.perform(get("/api/places/search").param("page", "-1"))
            .andExpect(status().isBadRequest());
    }

    @Test
    void search_invalidSize_zero_returns400() throws Exception {
        mvc.perform(get("/api/places/search").param("size", "0"))
            .andExpect(status().isBadRequest());
    }

    @Test
    void search_invalidSize_overMax_returns400() throws Exception {
        mvc.perform(get("/api/places/search").param("size", "101"))
            .andExpect(status().isBadRequest());
    }

    @Test
    void search_invalidMinRating_aboveFive_returns400() throws Exception {
        mvc.perform(get("/api/places/search").param("minRating", "5.5"))
            .andExpect(status().isBadRequest());
    }

    @Test
    void search_invalidMaxPriceLevel_aboveFour_returns400() throws Exception {
        mvc.perform(get("/api/places/search").param("maxPriceLevel", "5"))
            .andExpect(status().isBadRequest());
    }

    // ─── Slug lookup ──────────────────────────────────────────────────────────

    @Test
    void getBySlug_existingPublishedSlug_returnsFullDetail() throws Exception {
        mvc.perform(get("/api/places/slug/grand-palace-hotel-vung-tau"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.slug").value("grand-palace-hotel-vung-tau"))
            .andExpect(jsonPath("$.name").isString())
            .andExpect(jsonPath("$.category").exists())
            .andExpect(jsonPath("$.location").exists())
            .andExpect(jsonPath("$.openNow").isBoolean())
            .andExpect(jsonPath("$.galleryImages").isArray())
            .andExpect(jsonPath("$.openingHours").isArray());
    }

    @Test
    void getBySlug_unknownSlug_returns404WithErrorBody() throws Exception {
        mvc.perform(get("/api/places/slug/this-place-does-not-exist"))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.status").value(404))
            .andExpect(jsonPath("$.message").isString());
    }

    // ─── Admin search ─────────────────────────────────────────────────────────

    @Test
    void adminSearch_withoutAuth_returns401() throws Exception {
        mvc.perform(get("/api/admin/places"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void adminSearch_withAdminJwt_returns200WithPageStructure() throws Exception {
        mvc.perform(get("/api/admin/places")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.content").isArray())
            .andExpect(jsonPath("$.page").value(0))
            .andExpect(jsonPath("$.size").value(20))
            .andExpect(jsonPath("$.totalElements").isNumber());
    }

    @Test
    void adminSearch_filterStatusPublished_returnsOnlyPublished() throws Exception {
        String body = mvc.perform(get("/api/admin/places")
                .header("Authorization", "Bearer " + adminToken)
                .param("status", "PUBLISHED"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode content = mapper.readTree(body).get("content");
        assertTrue(content.size() >= 4, "Expected at least 4 seeded PUBLISHED places");
        for (JsonNode place : content) {
            assertEquals("PUBLISHED", place.get("status").asText(),
                "Admin filter status=PUBLISHED must return only PUBLISHED places");
        }
    }

    @Test
    void adminSearch_filterByKeyword_returnsMatchingOnly() throws Exception {
        String body = mvc.perform(get("/api/admin/places")
                .header("Authorization", "Bearer " + adminToken)
                .param("q", "vung"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertTrue(containsSlugSubstring(mapper.readTree(body).get("content"), "vung-tau"),
            "Admin search q='vung' must match Vũng Tàu place");
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private boolean containsSlugSubstring(JsonNode content, String slugFragment) {
        for (JsonNode place : content) {
            if (place.get("slug").asText().contains(slugFragment)) return true;
        }
        return false;
    }
}
