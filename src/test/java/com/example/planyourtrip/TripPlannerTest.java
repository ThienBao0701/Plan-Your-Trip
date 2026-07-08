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
 * TripPlannerTest — Phase 7.4.
 * Uses the shared seeded "Grand Palace Hotel" (already PUBLISHED) as a reusable
 * "valid place to add to a trip" fixture — trip items never mutate the Place
 * itself, so it's safe to reuse read-only across every test method. Each scenario
 * still registers its own throwaway user and trip.
 */
@SpringBootTest
@AutoConfigureMockMvc
class TripPlannerTest {

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
    // TRIP CRUD
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void createTrip_succeeds() throws Exception {
        String token = registerAndLogin("trip-create");

        String body = mvc.perform(post("/api/me/trips")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(tripPayload("Japan Adventure", "Tokyo", "2026-08-01", "2026-08-10")))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("Japan Adventure", res.get("title").asText());
        assertEquals("Tokyo", res.get("destination").asText());
        assertEquals("PLANNING", res.get("status").asText());
        assertTrue(res.get("days").isArray());
        assertEquals(0, res.get("days").size());
    }

    @Test
    void invalidDateRange_rejected() throws Exception {
        String token = registerAndLogin("trip-baddates");

        mvc.perform(post("/api/me/trips")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(tripPayload("Bad Trip", "Nowhere", "2026-08-10", "2026-08-01")))
            .andExpect(status().isBadRequest());
    }

    @Test
    void updateTrip_succeeds() throws Exception {
        String token = registerAndLogin("trip-update");
        Long tripId = createTrip(token, "Original Title", "Hanoi", "2026-09-01", "2026-09-05");

        String body = mvc.perform(put("/api/me/trips/" + tripId)
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(tripPayload("Updated Title", "Hanoi", "2026-09-01", "2026-09-05")))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals("Updated Title", mapper.readTree(body).get("title").asText());
    }

    @Test
    void duplicateTrip_copiesDaysAndItems() throws Exception {
        String token = registerAndLogin("trip-duplicate");
        Long tripId = createTrip(token, "Vietnam Loop", "Da Nang", "2026-10-01", "2026-10-05");
        Long dayId = addDay(token, tripId, 1, "2026-10-01");
        addItem(token, dayId, "{\"placeId\":" + publishedPlaceId + "}");
        addItem(token, dayId, "{\"customTitle\":\"Street food tour\"}");

        String body = mvc.perform(post("/api/me/trips/" + tripId + "/duplicate")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        JsonNode copy = mapper.readTree(body);
        assertNotEquals(tripId, copy.get("id").asLong());
        assertEquals("Vietnam Loop (Copy)", copy.get("title").asText());
        assertEquals(1, copy.get("days").size());
        JsonNode copyDay = copy.get("days").get(0);
        assertEquals(1, copyDay.get("dayNumber").asInt());
        assertEquals(2, copyDay.get("items").size());
        assertEquals(publishedPlaceId, copyDay.get("items").get(0).get("placeId").asLong());
        assertEquals("Street food tour", copyDay.get("items").get(1).get("customTitle").asText());
    }

    @Test
    void deleteTrip_cascadesDaysAndItems() throws Exception {
        String token = registerAndLogin("trip-delete");
        Long tripId = createTrip(token, "To Delete", "Hue", "2026-11-01", "2026-11-03");
        Long dayId = addDay(token, tripId, 1, "2026-11-01");
        addItem(token, dayId, "{\"customTitle\":\"Visit citadel\"}");

        mvc.perform(delete("/api/me/trips/" + tripId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNoContent());

        mvc.perform(get("/api/me/trips/" + tripId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNotFound());

        // The day's parent trip is gone, so the day itself must no longer be reachable.
        mvc.perform(put("/api/me/trips/days/" + dayId)
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"dayNumber\":1}"))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // DAYS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void addDay_succeeds() throws Exception {
        String token = registerAndLogin("trip-addday");
        Long tripId = createTrip(token, "Day Test Trip", "Sapa", "2026-12-01", "2026-12-05");

        String body = mvc.perform(post("/api/me/trips/" + tripId + "/days")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"dayNumber\":1,\"date\":\"2026-12-01\",\"title\":\"Arrival\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals(1, res.get("dayNumber").asInt());
        assertEquals("Arrival", res.get("title").asText());
    }

    @Test
    void duplicateDayNumber_rejected() throws Exception {
        String token = registerAndLogin("trip-dupday");
        Long tripId = createTrip(token, "Dup Day Trip", "Hoi An", "2026-12-10", "2026-12-15");
        addDay(token, tripId, 1, "2026-12-10");

        mvc.perform(post("/api/me/trips/" + tripId + "/days")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"dayNumber\":1,\"date\":\"2026-12-10\"}"))
            .andExpect(status().isConflict());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ITEMS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void addPlaceItem_succeeds() throws Exception {
        String token = registerAndLogin("trip-placeitem");
        Long tripId = createTrip(token, "Place Item Trip", "Nha Trang", "2027-01-01", "2027-01-05");
        Long dayId = addDay(token, tripId, 1, "2027-01-01");

        String body = addItem(token, dayId, "{\"placeId\":" + publishedPlaceId + ",\"startTime\":\"09:00:00\"}");
        JsonNode res = mapper.readTree(body);
        assertEquals(publishedPlaceId, res.get("placeId").asLong());
        assertNotNull(res.get("placeName"));
        assertEquals(0, res.get("sortOrder").asInt());
    }

    @Test
    void addCustomActivity_succeeds() throws Exception {
        String token = registerAndLogin("trip-customitem");
        Long tripId = createTrip(token, "Custom Item Trip", "Phu Quoc", "2027-02-01", "2027-02-05");
        Long dayId = addDay(token, tripId, 1, "2027-02-01");

        String body = addItem(token, dayId, "{\"customTitle\":\"Sunset boat ride\",\"customDescription\":\"Book locally\"}");
        JsonNode res = mapper.readTree(body);
        assertTrue(res.get("placeId").isNull());
        assertEquals("Sunset boat ride", res.get("customTitle").asText());
    }

    @Test
    void unpublishedPlace_rejected() throws Exception {
        String token = registerAndLogin("trip-unpublished");
        Long tripId = createTrip(token, "Unpublished Trip", "Test City", "2027-03-01", "2027-03-05");
        Long dayId = addDay(token, tripId, 1, "2027-03-01");
        Long draftPlaceId = createDraftPlace(uniq("DraftTripPlace"));

        mvc.perform(post("/api/me/trips/days/" + dayId + "/items")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"placeId\":" + draftPlaceId + "}"))
            .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void moveItem_toAnotherDay() throws Exception {
        String token = registerAndLogin("trip-moveitem");
        Long tripId = createTrip(token, "Move Item Trip", "Test City", "2027-04-01", "2027-04-05");
        Long day1 = addDay(token, tripId, 1, "2027-04-01");
        Long day2 = addDay(token, tripId, 2, "2027-04-02");
        JsonNode created = mapper.readTree(addItem(token, day1, "{\"customTitle\":\"Museum visit\"}"));
        Long itemId = created.get("id").asLong();

        mvc.perform(patch("/api/me/trips/items/" + itemId + "/move")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"targetDayId\":" + day2 + "}"))
            .andExpect(status().isOk());

        String tripBody = mvc.perform(get("/api/me/trips/" + tripId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode days = mapper.readTree(tripBody).get("days");
        assertEquals(0, days.get(0).get("items").size(), "Item must no longer be in day 1");
        assertEquals(1, days.get(1).get("items").size(), "Item must now be in day 2");
        assertEquals("Museum visit", days.get(1).get("items").get(0).get("customTitle").asText());
    }

    @Test
    void reorderDay_appliesNewOrder() throws Exception {
        String token = registerAndLogin("trip-reorder");
        Long tripId = createTrip(token, "Reorder Trip", "Test City", "2027-05-01", "2027-05-05");
        Long dayId = addDay(token, tripId, 1, "2027-05-01");
        Long itemA = mapper.readTree(addItem(token, dayId, "{\"customTitle\":\"A\"}")).get("id").asLong();
        Long itemB = mapper.readTree(addItem(token, dayId, "{\"customTitle\":\"B\"}")).get("id").asLong();
        Long itemC = mapper.readTree(addItem(token, dayId, "{\"customTitle\":\"C\"}")).get("id").asLong();

        String body = mvc.perform(patch("/api/me/trips/days/" + dayId + "/reorder")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"orderedItemIds\":[" + itemC + "," + itemA + "," + itemB + "]}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode items = mapper.readTree(body).get("items");
        assertEquals("C", items.get(0).get("customTitle").asText());
        assertEquals("A", items.get(1).get("customTitle").asText());
        assertEquals("B", items.get(2).get("customTitle").asText());
        assertEquals(0, items.get(0).get("sortOrder").asInt());
        assertEquals(1, items.get(1).get("sortOrder").asInt());
        assertEquals(2, items.get(2).get("sortOrder").asInt());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // OWNERSHIP / AUTH
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void ownershipIsolation_enforced() throws Exception {
        String tokenA = registerAndLogin("trip-owner-a");
        String tokenB = registerAndLogin("trip-owner-b");
        Long tripId = createTrip(tokenA, "Private Trip", "Test City", "2027-06-01", "2027-06-05");

        mvc.perform(get("/api/me/trips/" + tripId)
                .header("Authorization", "Bearer " + tokenB))
            .andExpect(status().isNotFound());
    }

    @Test
    void unauthenticated_rejected() throws Exception {
        mvc.perform(get("/api/me/trips"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private String tripPayload(String title, String destination, String startDate, String endDate) {
        return """
                {"title":"%s","description":"A test trip","destination":"%s","coverImage":"https://cdn.example.com/cover.jpg",
                 "startDate":"%s","endDate":"%s","status":"PLANNING","isPublic":false}
                """.formatted(title, destination, startDate, endDate);
    }

    private Long createTrip(String token, String title, String destination, String startDate, String endDate) throws Exception {
        String body = mvc.perform(post("/api/me/trips")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(tripPayload(title, destination, startDate, endDate)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private Long addDay(String token, Long tripId, int dayNumber, String date) throws Exception {
        String body = mvc.perform(post("/api/me/trips/" + tripId + "/days")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"dayNumber\":" + dayNumber + ",\"date\":\"" + date + "\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private String addItem(String token, Long dayId, String itemJson) throws Exception {
        return mvc.perform(post("/api/me/trips/days/" + dayId + "/items")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(itemJson))
            .andExpect(status().isCreated())
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
