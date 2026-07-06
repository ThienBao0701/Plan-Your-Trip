package com.example.planyourtrip;

import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.CategoryRepository;
import com.example.planyourtrip.repository.HotelDetailRepository;
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
class HotelDetailTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;

    private String adminToken;
    private Long hotelPlaceId;
    private Long accCategoryId;
    private Long hotelSubcategoryId;
    private Long cafeCategoryId;
    private Long locationId;

    @BeforeEach
    void setup() throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"admin@planyourtrip.com\",\"password\":\"admin123456\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        adminToken = mapper.readTree(body).get("token").asText();

        hotelPlaceId      = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        accCategoryId     = categoryRepo.findBySlug("accommodation").orElseThrow().getId();
        hotelSubcategoryId = categoryRepo.findBySlug("hotel").orElseThrow().getId();
        cafeCategoryId    = categoryRepo.findBySlug("cafe").orElseThrow().getId();
        locationId        = locationRepo.findByCode("VT").orElseThrow().getId();
    }

    // ─── Seed verification ────────────────────────────────────────────────────

    @Test
    void seed_grandPalaceHotel_hasHotelDetail() throws Exception {
        String body = mvc.perform(get("/api/admin/hotels/" + hotelPlaceId)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").isNumber())
            .andExpect(jsonPath("$.starRating").value(4))
            .andExpect(jsonPath("$.distanceToBeachMeters").value(250))
            .andExpect(jsonPath("$.distanceToCityCenterMeters").value(900))
            .andExpect(jsonPath("$.totalRooms").value(120))
            .andExpect(jsonPath("$.availableRooms").value(38))
            .andExpect(jsonPath("$.breakfastIncluded").value(true))
            .andExpect(jsonPath("$.airportShuttle").value(true))
            .andExpect(jsonPath("$.freeCancellation").value(false))
            .andReturn().getResponse().getContentAsString();

        JsonNode detail = mapper.readTree(body);
        assertTrue(detail.get("id").asLong() > 0);
        assertNotNull(detail.get("checkInTime"));
        assertNotNull(detail.get("checkOutTime"));
        assertNotNull(detail.get("createdAt"));
    }

    // ─── GET ──────────────────────────────────────────────────────────────────

    @Test
    void get_nonExistentPlace_returns404() throws Exception {
        mvc.perform(get("/api/admin/hotels/99999")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.status").value(404));
    }

    @Test
    void get_hotelPlaceWithNoDetail_returns404() throws Exception {
        Long freshHotelId = createHotelPlace("HotelNoDetailGet-" + uid());

        mvc.perform(get("/api/admin/hotels/" + freshHotelId)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.status").value(404));
    }

    @Test
    void get_requiresAdminAuth() throws Exception {
        mvc.perform(get("/api/admin/hotels/" + hotelPlaceId))
            .andExpect(status().isUnauthorized());
    }

    // ─── CREATE ───────────────────────────────────────────────────────────────

    @Test
    void create_newHotelPlace_returns201() throws Exception {
        Long freshHotelId = createHotelPlace("HotelCreate-" + uid());

        String body = mvc.perform(post("/api/admin/hotels")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(hotelPayload(freshHotelId)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.id").isNumber())
            .andExpect(jsonPath("$.starRating").value(4))
            .andExpect(jsonPath("$.distanceToBeachMeters").value(300))
            .andExpect(jsonPath("$.totalRooms").value(80))
            .andExpect(jsonPath("$.breakfastIncluded").value(true))
            .andReturn().getResponse().getContentAsString();

        assertTrue(mapper.readTree(body).get("id").asLong() > 0);
    }

    @Test
    void create_duplicateHotelDetail_returns409() throws Exception {
        // Grand Palace Hotel already has a seeded detail
        mvc.perform(post("/api/admin/hotels")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(hotelPayload(hotelPlaceId)))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.status").value(409));
    }

    @Test
    void create_wrongCategory_returns400() throws Exception {
        Long cafePlaceId = createCafePlace("CafeWrongCat-" + uid());

        mvc.perform(post("/api/admin/hotels")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(hotelPayload(cafePlaceId)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void create_invalidStarRating_returns400() throws Exception {
        Long freshHotelId = createHotelPlace("HotelStarInvalid-" + uid());

        mvc.perform(post("/api/admin/hotels")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "placeId": %d,
                      "starRating": 0,
                      "checkInTime": "14:00:00",
                      "checkOutTime": "12:00:00",
                      "breakfastIncluded": false,
                      "airportShuttle": false
                    }
                    """.formatted(freshHotelId)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void create_starRatingAboveMax_returns400() throws Exception {
        Long freshHotelId = createHotelPlace("HotelStarMax-" + uid());

        mvc.perform(post("/api/admin/hotels")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "placeId": %d,
                      "starRating": 6,
                      "checkInTime": "14:00:00",
                      "checkOutTime": "12:00:00",
                      "breakfastIncluded": false,
                      "airportShuttle": false
                    }
                    """.formatted(freshHotelId)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void create_missingCheckInTime_returns400() throws Exception {
        Long freshHotelId = createHotelPlace("HotelNoCheckIn-" + uid());

        mvc.perform(post("/api/admin/hotels")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "placeId": %d,
                      "starRating": 3,
                      "checkOutTime": "12:00:00",
                      "breakfastIncluded": false,
                      "airportShuttle": false
                    }
                    """.formatted(freshHotelId)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400));
    }

    // ─── UPDATE ───────────────────────────────────────────────────────────────

    @Test
    void update_existingDetail_returns200() throws Exception {
        mvc.perform(put("/api/admin/hotels/" + hotelPlaceId)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "starRating": 5,
                      "checkInTime": "15:00:00",
                      "checkOutTime": "11:00:00",
                      "distanceToBeachMeters": 100,
                      "totalRooms": 150,
                      "availableRooms": 50,
                      "breakfastIncluded": true,
                      "airportShuttle": true,
                      "freeCancellation": true
                    }
                    """))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.starRating").value(5))
            .andExpect(jsonPath("$.distanceToBeachMeters").value(100))
            .andExpect(jsonPath("$.totalRooms").value(150))
            .andExpect(jsonPath("$.freeCancellation").value(true));

        // Restore original values so other tests are not affected
        mvc.perform(put("/api/admin/hotels/" + hotelPlaceId)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "starRating": 4,
                      "checkInTime": "14:00:00",
                      "checkOutTime": "12:00:00",
                      "distanceToBeachMeters": 250,
                      "distanceToCityCenterMeters": 900,
                      "totalRooms": 120,
                      "availableRooms": 38,
                      "breakfastIncluded": true,
                      "airportShuttle": true,
                      "freeCancellation": false
                    }
                    """))
            .andExpect(status().isOk());
    }

    @Test
    void update_nonExistentDetail_returns404() throws Exception {
        Long freshHotelId = createHotelPlace("HotelUpdateMissing-" + uid());

        mvc.perform(put("/api/admin/hotels/" + freshHotelId)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "starRating": 3,
                      "checkInTime": "14:00:00",
                      "checkOutTime": "12:00:00",
                      "breakfastIncluded": false,
                      "airportShuttle": false
                    }
                    """))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.status").value(404));
    }

    // ─── PlaceDetail integration ──────────────────────────────────────────────

    @Test
    void placeDetail_hotel_includesHotelDetail() throws Exception {
        String body = mvc.perform(get("/api/places/" + hotelPlaceId))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.hotelDetail").exists())
            .andReturn().getResponse().getContentAsString();

        JsonNode hotelDetail = mapper.readTree(body).get("hotelDetail");
        assertFalse(hotelDetail.isNull(), "hotelDetail must be a JSON object, not null");
        assertEquals(4, hotelDetail.get("starRating").asInt());
        assertEquals(250, hotelDetail.get("distanceToBeachMeters").asInt());
        assertEquals(120, hotelDetail.get("totalRooms").asInt());
        assertTrue(hotelDetail.get("breakfastIncluded").asBoolean());
        assertTrue(hotelDetail.get("airportShuttle").asBoolean());
    }

    @Test
    void placeDetail_nonHotelPlace_hotelDetailIsNull() throws Exception {
        Long cafePlaceId = placeRepo.findBySlug("the-dreamer-cafe-da-lat").orElseThrow().getId();

        String body = mvc.perform(get("/api/places/" + cafePlaceId))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode node = mapper.readTree(body);
        assertTrue(node.has("hotelDetail"), "hotelDetail field must be present in response");
        assertTrue(node.get("hotelDetail").isNull(),
            "hotelDetail must be null for non-hotel place");
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private Long createHotelPlace(String name) throws Exception {
        String body = mvc.perform(post("/api/admin/places")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "name": "%s",
                      "categoryId": %d,
                      "subcategoryId": %d,
                      "administrativeUnitId": %d,
                      "address": "Test Hotel Address",
                      "priceLevel": 2,
                      "status": "PUBLISHED"
                    }
                    """.formatted(name, accCategoryId, hotelSubcategoryId, locationId)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private Long createCafePlace(String name) throws Exception {
        String body = mvc.perform(post("/api/admin/places")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "name": "%s",
                      "categoryId": %d,
                      "administrativeUnitId": %d,
                      "address": "Test Cafe Address",
                      "priceLevel": 1,
                      "status": "PUBLISHED"
                    }
                    """.formatted(name, cafeCategoryId, locationId)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private String hotelPayload(Long placeId) {
        return """
            {
              "placeId": %d,
              "starRating": 4,
              "checkInTime": "14:00:00",
              "checkOutTime": "12:00:00",
              "distanceToBeachMeters": 300,
              "distanceToCityCenterMeters": 500,
              "totalRooms": 80,
              "availableRooms": 20,
              "freeCancellation": true,
              "breakfastIncluded": true,
              "airportShuttle": false,
              "prepaymentRequired": false
            }
            """.formatted(placeId);
    }

    private String uid() {
        return UUID.randomUUID().toString().substring(0, 8);
    }
}
