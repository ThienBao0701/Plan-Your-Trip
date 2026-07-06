package com.example.planyourtrip;

import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.HotelRoomRepository;
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

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class HotelAvailabilityTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository roomRepo;

    private String adminToken;
    private Long placeId;
    private Long firstRoomId;

    // Far-future dates: no seeded inventory, safe for rate-plan CRUD tests
    private static final String FAR_START = "2030-01-01";
    private static final String FAR_END   = "2030-06-30";

    @BeforeEach
    void setup() throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"admin@planyourtrip.com\",\"password\":\"admin123456\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        adminToken = mapper.readTree(body).get("token").asText();

        placeId    = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        firstRoomId   = roomRepo.findAllByHotelDetailId(detailId).get(0).getId();
    }

    // ─── Rate Plan — CRUD ─────────────────────────────────────────────────────

    @Test
    void ratePlan_create_returns201() throws Exception {
        String body = mvc.perform(post("/api/admin/rooms/" + firstRoomId + "/rate-plans")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(ratePlanPayload("Test Rate", "STANDARD", "750000.00", FAR_START, FAR_END)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.id").isNumber())
            .andExpect(jsonPath("$.rateName").value("Test Rate"))
            .andExpect(jsonPath("$.rateType").value("STANDARD"))
            .andExpect(jsonPath("$.roomId").value(firstRoomId))
            .andReturn().getResponse().getContentAsString();

        assertTrue(mapper.readTree(body).get("id").asLong() > 0);
    }

    @Test
    void ratePlan_list_includesSeedPlans() throws Exception {
        String body = mvc.perform(get("/api/admin/rooms/" + firstRoomId + "/rate-plans")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode plans = mapper.readTree(body);
        assertTrue(plans.isArray());
        assertTrue(plans.size() >= 1, "Should have at least the seeded rate plan");
    }

    @Test
    void ratePlan_getById_returns200() throws Exception {
        // Create a plan first
        String created = mvc.perform(post("/api/admin/rooms/" + firstRoomId + "/rate-plans")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(ratePlanPayload("Get Test", "MEMBER", "600000.00", "2031-01-01", "2031-06-30")))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        Long planId = mapper.readTree(created).get("id").asLong();

        mvc.perform(get("/api/admin/rate-plans/" + planId)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(planId))
            .andExpect(jsonPath("$.rateName").value("Get Test"));
    }

    @Test
    void ratePlan_update_returns200() throws Exception {
        String created = mvc.perform(post("/api/admin/rooms/" + firstRoomId + "/rate-plans")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(ratePlanPayload("Original Name", "PROMOTIONAL", "500000.00", "2032-01-01", "2032-06-30")))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        Long planId = mapper.readTree(created).get("id").asLong();

        mvc.perform(put("/api/admin/rate-plans/" + planId)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(ratePlanPayload("Updated Name", "EARLY_BIRD", "450000.00", "2032-01-01", "2032-06-30")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.rateName").value("Updated Name"))
            .andExpect(jsonPath("$.rateType").value("EARLY_BIRD"))
            .andExpect(jsonPath("$.pricePerNight").value(450000.00));
    }

    @Test
    void ratePlan_delete_returns204() throws Exception {
        String created = mvc.perform(post("/api/admin/rooms/" + firstRoomId + "/rate-plans")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(ratePlanPayload("To Delete", "LAST_MINUTE", "400000.00", "2033-01-01", "2033-06-30")))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        Long planId = mapper.readTree(created).get("id").asLong();

        mvc.perform(delete("/api/admin/rate-plans/" + planId)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNoContent());

        mvc.perform(get("/api/admin/rate-plans/" + planId)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNotFound());
    }

    @Test
    void ratePlan_invalidDates_endBeforeStart_returns400() throws Exception {
        mvc.perform(post("/api/admin/rooms/" + firstRoomId + "/rate-plans")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(ratePlanPayload("Bad Dates", "STANDARD", "500000.00",
                    "2030-06-30", "2030-01-01"))) // end before start
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void ratePlan_nonExistentRoom_returns404() throws Exception {
        mvc.perform(post("/api/admin/rooms/99999/rate-plans")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(ratePlanPayload("Ghost Plan", "STANDARD", "500000.00", FAR_START, FAR_END)))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.status").value(404));
    }

    @Test
    void ratePlan_requiresAdminAuth() throws Exception {
        mvc.perform(post("/api/admin/rooms/" + firstRoomId + "/rate-plans")
                .contentType(MediaType.APPLICATION_JSON)
                .content(ratePlanPayload("Unauth", "STANDARD", "500000.00", FAR_START, FAR_END)))
            .andExpect(status().isUnauthorized());
    }

    // ─── Availability Search ──────────────────────────────────────────────────

    @Test
    void availability_validDates_returnsAllRooms() throws Exception {
        LocalDate checkIn  = LocalDate.now().plusDays(1);
        LocalDate checkOut = LocalDate.now().plusDays(4);

        String body = mvc.perform(get("/api/places/" + placeId + "/availability"
                + "?checkIn=" + checkIn + "&checkOut=" + checkOut
                + "&adults=1&children=0"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.placeId").value(placeId))
            .andExpect(jsonPath("$.nights").value(3))
            .andExpect(jsonPath("$.adults").value(1))
            .andExpect(jsonPath("$.availableRooms").isArray())
            .andReturn().getResponse().getContentAsString();

        JsonNode rooms = mapper.readTree(body).get("availableRooms");
        assertEquals(4, rooms.size(), "All 4 seeded rooms should be available");
    }

    @Test
    void availability_adultsFilter_excludesAllRooms() throws Exception {
        // All seeded rooms have maxAdults=2; requesting adults=3 should exclude all
        LocalDate checkIn  = LocalDate.now().plusDays(1);
        LocalDate checkOut = LocalDate.now().plusDays(3);

        String body = mvc.perform(get("/api/places/" + placeId + "/availability"
                + "?checkIn=" + checkIn + "&checkOut=" + checkOut
                + "&adults=3&children=0"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode rooms = mapper.readTree(body).get("availableRooms");
        assertEquals(0, rooms.size(), "No rooms with maxAdults >= 3");
    }

    @Test
    void availability_guestFilter_limitsResults() throws Exception {
        // adults=1 children=3 → totalGuests=4; only FAM-DBL has maxGuests=4
        LocalDate checkIn  = LocalDate.now().plusDays(1);
        LocalDate checkOut = LocalDate.now().plusDays(3);

        String body = mvc.perform(get("/api/places/" + placeId + "/availability"
                + "?checkIn=" + checkIn + "&checkOut=" + checkOut
                + "&adults=1&children=3"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode rooms = mapper.readTree(body).get("availableRooms");
        assertEquals(1, rooms.size(), "Only FAM-DBL accommodates 4 guests");
        assertEquals("FAM-DBL", rooms.get(0).get("roomCode").asText());
    }

    @Test
    void availability_pastCheckIn_returns400() throws Exception {
        String yesterday = LocalDate.now().minusDays(1).toString();
        String tomorrow  = LocalDate.now().plusDays(1).toString();

        mvc.perform(get("/api/places/" + placeId + "/availability"
                + "?checkIn=" + yesterday + "&checkOut=" + tomorrow))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void availability_sameCheckInAndCheckOut_returns400() throws Exception {
        String date = LocalDate.now().plusDays(2).toString();

        mvc.perform(get("/api/places/" + placeId + "/availability"
                + "?checkIn=" + date + "&checkOut=" + date))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void availability_noInventoryForFarDates_returnsEmpty() throws Exception {
        // Far-future dates have no seeded inventory → 0 available nights < nights required
        mvc.perform(get("/api/places/" + placeId + "/availability"
                + "?checkIn=2030-06-15&checkOut=2030-06-18"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.availableRooms").isArray())
            .andExpect(jsonPath("$.availableRooms.length()").value(0));
    }

    @Test
    void availability_publicEndpoint_noAuthRequired() throws Exception {
        LocalDate checkIn  = LocalDate.now().plusDays(1);
        LocalDate checkOut = LocalDate.now().plusDays(3);

        mvc.perform(get("/api/places/" + placeId + "/availability"
                + "?checkIn=" + checkIn + "&checkOut=" + checkOut))
            .andExpect(status().isOk()); // no auth header
    }

    @Test
    void availability_ratePlanApplied_showsDiscountedPrice() throws Exception {
        // STD-TWIN room is seeded with "Summer Deal" at 800,000 (priceFrom=900,000)
        LocalDate checkIn  = LocalDate.now().plusDays(1);
        LocalDate checkOut = LocalDate.now().plusDays(4);

        String body = mvc.perform(get("/api/places/" + placeId + "/availability"
                + "?checkIn=" + checkIn + "&checkOut=" + checkOut
                + "&adults=1&children=0"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode rooms = mapper.readTree(body).get("availableRooms");
        boolean found = false;
        for (JsonNode room : rooms) {
            if ("STD-TWIN".equals(room.get("roomCode").asText())) {
                found = true;
                double price    = room.get("pricePerNight").asDouble();
                double original = room.get("originalPricePerNight").asDouble();
                assertTrue(price < original, "Rate plan price must be lower than priceFrom");
                assertEquals(800000.0, price, 0.01);
                assertEquals("Summer Deal", room.get("appliedRatePlan").asText());
                assertEquals(3 * 800000.0, room.get("totalPrice").asDouble(), 0.01);
                break;
            }
        }
        assertTrue(found, "STD-TWIN room must appear in availability results");
    }

    @Test
    void availability_nonHotelPlace_returns404() throws Exception {
        mvc.perform(get("/api/places/99999/availability"
                + "?checkIn=" + LocalDate.now().plusDays(1)
                + "&checkOut=" + LocalDate.now().plusDays(3)))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.status").value(404));
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private String ratePlanPayload(String name, String type, String price,
                                    String startDate, String endDate) {
        return """
            {
              "rateName": "%s",
              "rateType": "%s",
              "pricePerNight": %s,
              "startDate": "%s",
              "endDate": "%s"
            }
            """.formatted(name, type, price, startDate, endDate);
    }
}
