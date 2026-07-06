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

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class HotelRoomTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;

    private String adminToken;
    private Long hotelPlaceId;
    private Long seedRoomId;

    @BeforeEach
    void setup() throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"admin@planyourtrip.com\",\"password\":\"admin123456\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        adminToken = mapper.readTree(body).get("token").asText();

        hotelPlaceId = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long hotelDetailId = hotelDetailRepo.findByPlaceId(hotelPlaceId).orElseThrow().getId();
        seedRoomId = hotelRoomRepo.findAllByHotelDetailId(hotelDetailId)
            .stream().findFirst().orElseThrow().getId();
    }

    // ─── Seed verification ────────────────────────────────────────────────────

    @Test
    void seed_grandPalaceHotel_hasFourRooms() throws Exception {
        String body = mvc.perform(get("/api/admin/hotels/" + hotelPlaceId + "/rooms")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode rooms = mapper.readTree(body);
        assertTrue(rooms.isArray());
        List<String> codes = new ArrayList<>();
        for (JsonNode r : rooms) codes.add(r.get("roomCode").asText());
        assertTrue(codes.containsAll(List.of("STD-TWIN", "DLX-KING", "FAM-DBL", "SUITE-KNG")),
            "All 4 seeded room codes must be present, got: " + codes);
    }

    @Test
    void seed_standardTwin_hasExpectedFields() throws Exception {
        String body = mvc.perform(get("/api/admin/hotels/" + hotelPlaceId + "/rooms")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode rooms = mapper.readTree(body);
        JsonNode stdTwin = null;
        for (JsonNode r : rooms) {
            if ("STD-TWIN".equals(r.get("roomCode").asText())) {
                stdTwin = r;
                break;
            }
        }
        assertNotNull(stdTwin, "STD-TWIN room not found in seed");
        assertEquals("STANDARD", stdTwin.get("roomType").asText());
        assertEquals("TWIN", stdTwin.get("bedType").asText());
        assertEquals(900000, stdTwin.get("priceFrom").decimalValue().intValue());
        assertTrue(stdTwin.get("breakfastIncluded").asBoolean());
    }

    // ─── GET ──────────────────────────────────────────────────────────────────

    @Test
    void get_roomById_returns200() throws Exception {
        mvc.perform(get("/api/admin/rooms/" + seedRoomId)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(seedRoomId))
            .andExpect(jsonPath("$.roomName").isString());
    }

    @Test
    void get_nonExistentRoom_returns404() throws Exception {
        mvc.perform(get("/api/admin/rooms/99999")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.status").value(404));
    }

    @Test
    void list_rooms_requiresAdminAuth() throws Exception {
        mvc.perform(get("/api/admin/hotels/" + hotelPlaceId + "/rooms"))
            .andExpect(status().isUnauthorized());
    }

    // ─── CREATE ───────────────────────────────────────────────────────────────

    @Test
    void create_newRoom_returns201() throws Exception {
        String code = "TEST-" + uid();
        String body = mvc.perform(post("/api/admin/rooms")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(roomPayload(hotelPlaceId, code)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.id").isNumber())
            .andExpect(jsonPath("$.roomCode").value(code))
            .andExpect(jsonPath("$.roomType").value("STANDARD"))
            .andReturn().getResponse().getContentAsString();

        assertTrue(mapper.readTree(body).get("id").asLong() > 0);
    }

    @Test
    void create_duplicateRoomCode_returns409() throws Exception {
        mvc.perform(post("/api/admin/rooms")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(roomPayload(hotelPlaceId, "STD-TWIN")))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.status").value(409));
    }

    @Test
    void create_invalidAvailableQty_returns400() throws Exception {
        String code = "QTY-" + uid();
        mvc.perform(post("/api/admin/rooms")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "placeId": %d,
                      "roomName": "Test Room",
                      "roomCode": "%s",
                      "roomType": "STANDARD",
                      "maxAdults": 2,
                      "maxGuests": 2,
                      "quantity": 5,
                      "availableQuantity": 10
                    }
                    """.formatted(hotelPlaceId, code)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void create_missingRoomType_returns400() throws Exception {
        mvc.perform(post("/api/admin/rooms")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "placeId": %d,
                      "roomName": "Test Room",
                      "roomCode": "NO-TYPE-%s"
                    }
                    """.formatted(hotelPlaceId, uid())))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void create_requiresAdminAuth() throws Exception {
        mvc.perform(post("/api/admin/rooms")
                .contentType(MediaType.APPLICATION_JSON)
                .content(roomPayload(hotelPlaceId, "AUTH-" + uid())))
            .andExpect(status().isUnauthorized());
    }

    // ─── UPDATE ───────────────────────────────────────────────────────────────

    @Test
    void update_existingRoom_returns200() throws Exception {
        mvc.perform(put("/api/admin/rooms/" + seedRoomId)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "roomName": "Updated Room",
                      "roomCode": "STD-TWIN",
                      "roomType": "STANDARD",
                      "maxAdults": 2,
                      "maxGuests": 2,
                      "priceFrom": 950000.00,
                      "quantity": 10,
                      "availableQuantity": 5,
                      "breakfastIncluded": true,
                      "freeCancellation": false,
                      "instantConfirmation": true,
                      "smokingAllowed": false
                    }
                    """))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.roomName").value("Updated Room"))
            .andExpect(jsonPath("$.priceFrom").value(950000.00));

        // Restore
        mvc.perform(put("/api/admin/rooms/" + seedRoomId)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "roomName": "Standard Twin Room",
                      "roomCode": "STD-TWIN",
                      "roomType": "STANDARD",
                      "bedType": "TWIN",
                      "bedCount": 2,
                      "maxAdults": 2,
                      "maxGuests": 2,
                      "priceFrom": 900000.00,
                      "quantity": 10,
                      "availableQuantity": 4,
                      "breakfastIncluded": true,
                      "freeCancellation": false,
                      "instantConfirmation": true,
                      "smokingAllowed": false
                    }
                    """))
            .andExpect(status().isOk());
    }

    @Test
    void update_nonExistentRoom_returns404() throws Exception {
        mvc.perform(put("/api/admin/rooms/99999")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "roomName": "Ghost Room",
                      "roomCode": "GHOST-01",
                      "roomType": "STANDARD",
                      "maxAdults": 2,
                      "maxGuests": 2
                    }
                    """))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.status").value(404));
    }

    // ─── DEACTIVATE ───────────────────────────────────────────────────────────

    @Test
    void deactivate_room_returns204() throws Exception {
        // Create a fresh room to deactivate
        String code = "DEACT-" + uid();
        String body = mvc.perform(post("/api/admin/rooms")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(roomPayload(hotelPlaceId, code)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long newRoomId = mapper.readTree(body).get("id").asLong();

        mvc.perform(patch("/api/admin/rooms/" + newRoomId + "/deactivate")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNoContent());

        // Verify inactive
        mvc.perform(get("/api/admin/rooms/" + newRoomId)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.active").value(false));
    }

    @Test
    void deactivate_nonExistentRoom_returns404() throws Exception {
        mvc.perform(patch("/api/admin/rooms/99999/deactivate")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.status").value(404));
    }

    // ─── PlaceDetail integration ──────────────────────────────────────────────

    @Test
    void placeDetail_hotel_includesActiveRoomsOnly() throws Exception {
        String body = mvc.perform(get("/api/places/" + hotelPlaceId))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.hotelDetail").exists())
            .andExpect(jsonPath("$.hotelDetail.rooms").isArray())
            .andReturn().getResponse().getContentAsString();

        JsonNode rooms = mapper.readTree(body).get("hotelDetail").get("rooms");
        assertTrue(rooms.size() > 0, "Active rooms should be present");
        for (JsonNode room : rooms) {
            assertTrue(room.get("active").asBoolean(), "All public rooms must be active");
        }
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private String roomPayload(Long placeId, String code) {
        return """
            {
              "placeId": %d,
              "roomName": "Test Room %s",
              "roomCode": "%s",
              "roomType": "STANDARD",
              "bedType": "TWIN",
              "bedCount": 2,
              "maxAdults": 2,
              "maxChildren": 0,
              "maxGuests": 2,
              "roomSizeSqm": 25.0,
              "breakfastIncluded": true,
              "freeCancellation": false,
              "instantConfirmation": true,
              "smokingAllowed": false,
              "priceFrom": 800000.00,
              "quantity": 5,
              "availableQuantity": 3
            }
            """.formatted(placeId, code, code);
    }

    private String uid() {
        return UUID.randomUUID().toString().substring(0, 8);
    }
}
