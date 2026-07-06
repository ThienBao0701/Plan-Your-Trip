package com.example.planyourtrip;

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

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class HotelExperienceTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;

    private String adminToken;
    private Long hotelPlaceId;

    @BeforeEach
    void setup() throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"admin@planyourtrip.com\",\"password\":\"admin123456\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        adminToken = mapper.readTree(body).get("token").asText();
        hotelPlaceId = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
    }

    // ─── Seed verification ────────────────────────────────────────────────────

    @Test
    void seed_grandPalaceHotel_hasExperienceData() throws Exception {
        String body = mvc.perform(get("/api/admin/hotels/" + hotelPlaceId + "/experience")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.facilities").isArray())
            .andExpect(jsonPath("$.services").isArray())
            .andExpect(jsonPath("$.languages").isArray())
            .andExpect(jsonPath("$.paymentMethods").isArray())
            .andReturn().getResponse().getContentAsString();

        JsonNode exp = mapper.readTree(body);
        assertTrue(exp.get("facilities").size() >= 9, "Expected at least 9 seeded facilities");
        assertTrue(exp.get("services").size() >= 6,   "Expected at least 6 seeded services");
        assertTrue(exp.get("languages").size() >= 2,  "Expected at least 2 languages");
        assertTrue(exp.get("paymentMethods").size() >= 4, "Expected at least 4 payment methods");
    }

    @Test
    void seed_hasExpectedFacilities() throws Exception {
        String body = mvc.perform(get("/api/admin/hotels/" + hotelPlaceId + "/experience")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        List<String> names = new ArrayList<>();
        for (JsonNode f : mapper.readTree(body).get("facilities")) {
            names.add(f.get("facilityName").asText());
        }
        assertTrue(names.contains("Pool"),          "Pool expected");
        assertTrue(names.contains("Spa"),           "Spa expected");
        assertTrue(names.contains("Gym"),           "Gym expected");
        assertTrue(names.contains("Restaurant"),    "Restaurant expected");
        assertTrue(names.contains("Bar"),           "Bar expected");
        assertTrue(names.contains("Beach Access"),  "Beach Access expected");
    }

    @Test
    void seed_hasExpectedServices() throws Exception {
        String body = mvc.perform(get("/api/admin/hotels/" + hotelPlaceId + "/experience")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        List<String> names = new ArrayList<>();
        for (JsonNode s : mapper.readTree(body).get("services")) {
            names.add(s.get("serviceName").asText());
        }
        assertTrue(names.contains("Room Service"),       "Room Service expected");
        assertTrue(names.contains("Laundry"),            "Laundry expected");
        assertTrue(names.contains("Airport Shuttle"),    "Airport Shuttle expected");
        assertTrue(names.contains("Daily Housekeeping"), "Daily Housekeeping expected");
    }

    @Test
    void seed_hasLanguagesAndPayments() throws Exception {
        String body = mvc.perform(get("/api/admin/hotels/" + hotelPlaceId + "/experience")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode exp = mapper.readTree(body);

        List<String> langs = new ArrayList<>();
        for (JsonNode l : exp.get("languages")) langs.add(l.asText());
        assertTrue(langs.contains("Vietnamese"), "Vietnamese language expected");
        assertTrue(langs.contains("English"),    "English language expected");

        List<String> payments = new ArrayList<>();
        for (JsonNode p : exp.get("paymentMethods")) payments.add(p.asText());
        assertTrue(payments.contains("Cash"),         "Cash payment expected");
        assertTrue(payments.contains("Visa"),         "Visa expected");
        assertTrue(payments.contains("MasterCard"),   "MasterCard expected");
        assertTrue(payments.contains("Apple Pay"),    "Apple Pay expected");
    }

    @Test
    void seed_hasParkingAndInternet() throws Exception {
        String body = mvc.perform(get("/api/admin/hotels/" + hotelPlaceId + "/experience")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.parking.parkingAvailable").value(true))
            .andExpect(jsonPath("$.internet.wifiAvailable").value(true))
            .andExpect(jsonPath("$.internet.wifiFree").value(true))
            .andReturn().getResponse().getContentAsString();

        JsonNode exp = mapper.readTree(body);
        assertNotNull(exp.get("parking").get("parkingDescription").asText());
        assertNotNull(exp.get("internet").get("internetDescription").asText());
    }

    // ─── GET ──────────────────────────────────────────────────────────────────

    @Test
    void get_experience_requiresAdminAuth() throws Exception {
        mvc.perform(get("/api/admin/hotels/" + hotelPlaceId + "/experience"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void get_nonExistentHotel_returns404() throws Exception {
        mvc.perform(get("/api/admin/hotels/99999/experience")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.status").value(404));
    }

    // ─── UPDATE ───────────────────────────────────────────────────────────────

    @Test
    void update_experience_returns200() throws Exception {
        String body = mvc.perform(put("/api/admin/hotels/" + hotelPlaceId + "/experience")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(experiencePayload()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.facilities").isArray())
            .andExpect(jsonPath("$.services").isArray())
            .andReturn().getResponse().getContentAsString();

        JsonNode exp = mapper.readTree(body);
        assertEquals(2, exp.get("facilities").size());
        assertEquals(2, exp.get("services").size());
        assertEquals("Korean", exp.get("languages").get(0).asText());

        // Restore seed data
        mvc.perform(put("/api/admin/hotels/" + hotelPlaceId + "/experience")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(seedPayload()))
            .andExpect(status().isOk());
    }

    @Test
    void update_replacesFacilitiesAtomically() throws Exception {
        // Replace with only 1 facility
        mvc.perform(put("/api/admin/hotels/" + hotelPlaceId + "/experience")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "facilities": [
                        { "facilityName": "Pool Only", "facilityGroup": "WELLNESS", "sortOrder": 1 }
                      ]
                    }
                    """))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.facilities.length()").value(1))
            .andExpect(jsonPath("$.facilities[0].facilityName").value("Pool Only"));

        // Restore
        mvc.perform(put("/api/admin/hotels/" + hotelPlaceId + "/experience")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(seedPayload()))
            .andExpect(status().isOk());
    }

    @Test
    void update_updatesLanguagesAndPayments() throws Exception {
        mvc.perform(put("/api/admin/hotels/" + hotelPlaceId + "/experience")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "languages": ["Japanese", "French"],
                      "paymentMethods": ["UnionPay"]
                    }
                    """))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.languages[0]").value("Japanese"))
            .andExpect(jsonPath("$.paymentMethods[0]").value("UnionPay"));

        // Restore
        mvc.perform(put("/api/admin/hotels/" + hotelPlaceId + "/experience")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(seedPayload()))
            .andExpect(status().isOk());
    }

    @Test
    void update_nonExistentHotel_returns404() throws Exception {
        mvc.perform(put("/api/admin/hotels/99999/experience")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}"))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.status").value(404));
    }

    // ─── PlaceDetail integration ──────────────────────────────────────────────

    @Test
    void placeDetail_hotel_includesExperience() throws Exception {
        String body = mvc.perform(get("/api/places/" + hotelPlaceId))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.hotelDetail").exists())
            .andExpect(jsonPath("$.hotelDetail.facilities").isArray())
            .andExpect(jsonPath("$.hotelDetail.services").isArray())
            .andExpect(jsonPath("$.hotelDetail.languages").isArray())
            .andExpect(jsonPath("$.hotelDetail.paymentMethods").isArray())
            .andExpect(jsonPath("$.hotelDetail.parking").exists())
            .andExpect(jsonPath("$.hotelDetail.internet").exists())
            .andReturn().getResponse().getContentAsString();

        JsonNode detail = mapper.readTree(body).get("hotelDetail");
        assertTrue(detail.get("facilities").size() > 0, "Facilities must be present in public detail");
        assertTrue(detail.get("services").size() > 0,   "Services must be present in public detail");
        assertTrue(detail.get("languages").size() > 0,  "Languages must be present in public detail");
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private String experiencePayload() {
        return """
            {
              "facilities": [
                { "facilityName": "Test Pool", "facilityGroup": "WELLNESS", "icon": "pool", "sortOrder": 1 },
                { "facilityName": "Test Gym",  "facilityGroup": "WELLNESS", "icon": "gym",  "sortOrder": 2 }
              ],
              "services": [
                { "serviceName": "Test Service A", "available": true },
                { "serviceName": "Test Service B", "available": false }
              ],
              "languages": ["Korean", "Chinese"],
              "paymentMethods": ["JCB", "Google Pay"],
              "parking": { "parkingAvailable": false, "parkingFree": false },
              "internet": { "wifiAvailable": true, "wifiFree": true }
            }
            """;
    }

    private String seedPayload() {
        return """
            {
              "facilities": [
                { "facilityName": "Pool",            "facilityGroup": "WELLNESS",     "icon": "pool",              "sortOrder": 1 },
                { "facilityName": "Spa",             "facilityGroup": "WELLNESS",     "icon": "spa",               "sortOrder": 2 },
                { "facilityName": "Gym",             "facilityGroup": "WELLNESS",     "icon": "fitness_center",    "sortOrder": 3 },
                { "facilityName": "Restaurant",      "facilityGroup": "FOOD",         "icon": "restaurant",        "sortOrder": 4 },
                { "facilityName": "Bar",             "facilityGroup": "FOOD",         "icon": "local_bar",         "sortOrder": 5 },
                { "facilityName": "Garden",          "facilityGroup": "OUTDOOR",      "icon": "park",              "sortOrder": 6 },
                { "facilityName": "Conference Room", "facilityGroup": "BUSINESS",     "icon": "meeting_room",      "sortOrder": 7 },
                { "facilityName": "Elevator",        "facilityGroup": "ACCESSIBILITY","icon": "elevator",          "sortOrder": 8 },
                { "facilityName": "Beach Access",    "facilityGroup": "OUTDOOR",      "icon": "beach_access",      "sortOrder": 9 }
              ],
              "services": [
                { "serviceName": "Room Service",       "icon": "room_service",          "available": true },
                { "serviceName": "Laundry",            "icon": "local_laundry_service", "available": true },
                { "serviceName": "Airport Shuttle",    "icon": "airport_shuttle",       "available": true },
                { "serviceName": "Daily Housekeeping", "icon": "cleaning_services",     "available": true },
                { "serviceName": "24h Reception",      "icon": "support_agent",         "available": true },
                { "serviceName": "Wake-up Call",       "icon": "alarm",                 "available": true }
              ],
              "languages": ["Vietnamese", "English"],
              "paymentMethods": ["Cash", "Visa", "MasterCard", "Apple Pay"],
              "parking": { "parkingAvailable": true, "parkingFree": false, "parkingDescription": "Paid parking available on-site" },
              "internet": { "wifiAvailable": true, "wifiFree": true, "internetDescription": "Free high-speed WiFi in all rooms and public areas" }
            }
            """;
    }
}
