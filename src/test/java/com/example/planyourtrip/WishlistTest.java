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
 * WishlistTest — Phase 7.2.
 * Uses the shared seeded "Grand Palace Hotel" (already PUBLISHED) as the reusable
 * "valid place to wishlist" fixture — wishlisting never mutates the Place itself, so
 * this is safe to reuse read-only across every test method without cross-test
 * pollution. Each scenario still registers its own throwaway user.
 */
@SpringBootTest
@AutoConfigureMockMvc
class WishlistTest {

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
    // DEFAULT WISHLIST / ADD / DUPLICATE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void getEmptyWishlist_createsDefault() throws Exception {
        String token = registerAndLogin("wishlist-default");

        String body = mvc.perform(get("/api/me/wishlist")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertNotNull(res.get("id"));
        assertTrue(res.get("items").isArray());
        assertEquals(0, res.get("items").size());
    }

    @Test
    void addPlace_succeeds() throws Exception {
        String token = registerAndLogin("wishlist-add");

        String body = mvc.perform(post("/api/me/wishlist/items")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"placeId\":" + publishedPlaceId + ",\"note\":\"Honeymoon spot\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals(publishedPlaceId, res.get("place").get("id").asLong());
        assertEquals("Honeymoon spot", res.get("note").asText());

        String listBody = mvc.perform(get("/api/me/wishlist")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals(1, mapper.readTree(listBody).get("items").size());
    }

    @Test
    void duplicatePlace_rejected() throws Exception {
        String token = registerAndLogin("wishlist-duplicate");

        mvc.perform(post("/api/me/wishlist/items")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"placeId\":" + publishedPlaceId + "}"))
            .andExpect(status().isCreated());

        mvc.perform(post("/api/me/wishlist/items")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"placeId\":" + publishedPlaceId + "}"))
            .andExpect(status().isConflict());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // REMOVE / NOTE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void removePlace_succeeds() throws Exception {
        String token = registerAndLogin("wishlist-remove");
        mvc.perform(post("/api/me/wishlist/items")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"placeId\":" + publishedPlaceId + "}"))
            .andExpect(status().isCreated());

        mvc.perform(delete("/api/me/wishlist/items/" + publishedPlaceId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNoContent());

        String body = mvc.perform(get("/api/me/wishlist")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals(0, mapper.readTree(body).get("items").size());
    }

    @Test
    void updateNote_succeeds() throws Exception {
        String token = registerAndLogin("wishlist-note");
        mvc.perform(post("/api/me/wishlist/items")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"placeId\":" + publishedPlaceId + "}"))
            .andExpect(status().isCreated());

        String body = mvc.perform(put("/api/me/wishlist/items/" + publishedPlaceId + "/note")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"note\":\"Book for anniversary\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals("Book for anniversary", mapper.readTree(body).get("note").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // UNPUBLISHED PLACE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void cannotAddUnpublishedPlace() throws Exception {
        String token = registerAndLogin("wishlist-unpublished");
        Long draftPlaceId = createDraftPlace(uniq("DraftPlace"));

        mvc.perform(post("/api/me/wishlist/items")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"placeId\":" + draftPlaceId + "}"))
            .andExpect(status().isUnprocessableEntity());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ISOLATION / AUTH
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void userIsolation_wishlistsAreSeparate() throws Exception {
        String tokenA = registerAndLogin("wishlist-isolation-a");
        String tokenB = registerAndLogin("wishlist-isolation-b");

        mvc.perform(post("/api/me/wishlist/items")
                .header("Authorization", "Bearer " + tokenA)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"placeId\":" + publishedPlaceId + "}"))
            .andExpect(status().isCreated());

        String bodyB = mvc.perform(get("/api/me/wishlist")
                .header("Authorization", "Bearer " + tokenB))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals(0, mapper.readTree(bodyB).get("items").size(),
            "User B's wishlist must not contain user A's saved place");
    }

    @Test
    void unauthenticated_rejected() throws Exception {
        mvc.perform(get("/api/me/wishlist"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // RESPONSE SHAPE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void response_includesPlaceSummary() throws Exception {
        String token = registerAndLogin("wishlist-summary");

        String body = mvc.perform(post("/api/me/wishlist/items")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"placeId\":" + publishedPlaceId + "}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        JsonNode place = mapper.readTree(body).get("place");
        assertNotNull(place.get("id"));
        assertNotNull(place.get("name"));
        assertNotNull(place.get("slug"));
        assertNotNull(place.get("categoryName"));
        assertNotNull(place.get("address"));
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

    private String uniq(String prefix) {
        return prefix + "-" + UUID.randomUUID().toString().substring(0, 8);
    }
}
