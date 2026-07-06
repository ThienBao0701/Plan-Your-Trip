package com.example.planyourtrip;

import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.repository.RoomInventoryRepository;
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
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class RoomInventoryTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;
    @Autowired RoomInventoryRepository inventoryRepo;

    private String adminToken;
    private Long firstRoomId;

    // Far-future dates safe from seed data (seed covers today + 90 days)
    private static final String FAR_DATE    = "2030-06-15";
    private static final String FAR_DATE_2  = "2030-06-16";
    private static final String FAR_DATE_3  = "2030-06-17";

    @BeforeEach
    void setup() throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"admin@planyourtrip.com\",\"password\":\"admin123456\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        adminToken = mapper.readTree(body).get("token").asText();

        Long placeId = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        firstRoomId = hotelRoomRepo.findAllByHotelDetailId(detailId).get(0).getId();
    }

    // ─── Seed verification ────────────────────────────────────────────────────

    @Test
    void seed_allDemoRooms_haveInventory() throws Exception {
        String body = mvc.perform(get("/api/admin/rooms/" + firstRoomId + "/inventory")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.roomId").value(firstRoomId))
            .andExpect(jsonPath("$.inventory").isArray())
            .andReturn().getResponse().getContentAsString();

        JsonNode inv = mapper.readTree(body).get("inventory");
        assertTrue(inv.size() >= 90, "Seeded room must have at least 90 inventory records, got " + inv.size());
    }

    @Test
    void seed_inventoryHasCorrectValues() throws Exception {
        String today = LocalDate.now().toString();
        String body = mvc.perform(get("/api/admin/rooms/" + firstRoomId + "/inventory"
                + "?from=" + today + "&to=" + today)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode inv = mapper.readTree(body).get("inventory");
        assertEquals(1, inv.size(), "Should have exactly 1 record for today");
        JsonNode rec = inv.get(0);
        assertEquals(20, rec.get("totalInventory").asInt());
        assertEquals(18, rec.get("availableInventory").asInt());
        assertEquals(1,  rec.get("blockedInventory").asInt());
        assertEquals(0,  rec.get("soldInventory").asInt());
        assertEquals(1,  rec.get("maintenanceInventory").asInt());
        assertFalse(rec.get("stopSell").asBoolean());
    }

    // ─── GET / Calendar ordering ──────────────────────────────────────────────

    @Test
    void get_inventory_returnedOrderedByDate() throws Exception {
        String from = LocalDate.now().toString();
        String to   = LocalDate.now().plusDays(6).toString();

        String body = mvc.perform(get("/api/admin/rooms/" + firstRoomId + "/inventory"
                + "?from=" + from + "&to=" + to)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode inv = mapper.readTree(body).get("inventory");
        assertEquals(7, inv.size());
        for (int i = 1; i < inv.size(); i++) {
            LocalDate prev = LocalDate.parse(inv.get(i - 1).get("inventoryDate").asText());
            LocalDate curr = LocalDate.parse(inv.get(i).get("inventoryDate").asText());
            assertTrue(curr.isAfter(prev), "Inventory must be sorted ascending by date");
        }
    }

    @Test
    void get_inventory_byDateRange_returnsCorrectCount() throws Exception {
        String from = LocalDate.now().plusDays(10).toString();
        String to   = LocalDate.now().plusDays(19).toString();

        String body = mvc.perform(get("/api/admin/rooms/" + firstRoomId + "/inventory"
                + "?from=" + from + "&to=" + to)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode inv = mapper.readTree(body).get("inventory");
        assertEquals(10, inv.size(), "Date range of 10 days should return 10 records");
    }

    @Test
    void get_requiresAdminAuth() throws Exception {
        mvc.perform(get("/api/admin/rooms/" + firstRoomId + "/inventory"))
            .andExpect(status().isUnauthorized());
    }

    // ─── CREATE ───────────────────────────────────────────────────────────────

    @Test
    void create_newInventoryDate_returns201() throws Exception {
        String body = mvc.perform(post("/api/admin/rooms/" + firstRoomId + "/inventory")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(inventoryPayload(FAR_DATE, 20, 15, 2, 0, 3)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.id").isNumber())
            .andExpect(jsonPath("$.inventoryDate").value(FAR_DATE))
            .andExpect(jsonPath("$.totalInventory").value(20))
            .andExpect(jsonPath("$.availableInventory").value(15))
            .andReturn().getResponse().getContentAsString();

        assertTrue(mapper.readTree(body).get("id").asLong() > 0);
    }

    @Test
    void create_duplicateDate_returns409() throws Exception {
        // Seed covers today, so creating for today should conflict
        String today = LocalDate.now().toString();
        mvc.perform(post("/api/admin/rooms/" + firstRoomId + "/inventory")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(inventoryPayload(today, 10, 8, 1, 0, 1)))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.status").value(409));
    }

    @Test
    void create_validation_negativeInventory_returns400() throws Exception {
        mvc.perform(post("/api/admin/rooms/" + firstRoomId + "/inventory")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "inventoryDate": "2030-07-01",
                      "totalInventory": -1,
                      "availableInventory": 0,
                      "blockedInventory": 0,
                      "soldInventory": 0,
                      "maintenanceInventory": 0
                    }
                    """))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void create_validation_availableExceedsTotal_returns400() throws Exception {
        mvc.perform(post("/api/admin/rooms/" + firstRoomId + "/inventory")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(inventoryPayload("2030-07-02", 10, 15, 0, 0, 0)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void create_missingDate_returns400() throws Exception {
        mvc.perform(post("/api/admin/rooms/" + firstRoomId + "/inventory")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "totalInventory": 10,
                      "availableInventory": 8,
                      "blockedInventory": 1,
                      "soldInventory": 0,
                      "maintenanceInventory": 1
                    }
                    """))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400));
    }

    // ─── UPDATE ───────────────────────────────────────────────────────────────

    @Test
    void update_existingRecord_returns200() throws Exception {
        String today = LocalDate.now().toString();
        mvc.perform(put("/api/admin/rooms/" + firstRoomId + "/inventory/" + today)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(inventoryPayload(today, 25, 20, 2, 1, 2)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.totalInventory").value(25))
            .andExpect(jsonPath("$.availableInventory").value(20))
            .andExpect(jsonPath("$.soldInventory").value(1));

        // Restore
        mvc.perform(put("/api/admin/rooms/" + firstRoomId + "/inventory/" + today)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(inventoryPayload(today, 20, 18, 1, 0, 1)))
            .andExpect(status().isOk());
    }

    @Test
    void update_nonExistentDate_returns404() throws Exception {
        mvc.perform(put("/api/admin/rooms/" + firstRoomId + "/inventory/2099-12-31")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(inventoryPayload("2099-12-31", 10, 8, 1, 0, 1)))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.status").value(404));
    }

    // ─── BULK ─────────────────────────────────────────────────────────────────

    @Test
    void bulk_upsert_creates_and_updates() throws Exception {
        // Create 3 new records via bulk
        String body = mvc.perform(post("/api/admin/rooms/" + firstRoomId + "/inventory/bulk")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "items": [
                        %s,
                        %s,
                        %s
                      ]
                    }
                    """.formatted(
                        inventoryPayload(FAR_DATE_2, 20, 18, 1, 0, 1),
                        inventoryPayload(FAR_DATE_3, 20, 18, 1, 0, 1),
                        inventoryPayload("2030-06-18", 20, 18, 1, 0, 1)
                    )))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode results = mapper.readTree(body);
        assertTrue(results.isArray());
        assertEquals(3, results.size());

        // Upsert same dates again with different values → should update, not fail
        mvc.perform(post("/api/admin/rooms/" + firstRoomId + "/inventory/bulk")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "items": [
                        %s
                      ]
                    }
                    """.formatted(inventoryPayload(FAR_DATE_2, 25, 20, 2, 1, 2))))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$[0].totalInventory").value(25))
            .andExpect(jsonPath("$[0].soldInventory").value(1));
    }

    @Test
    void get_nonExistentRoom_returns404() throws Exception {
        mvc.perform(get("/api/admin/rooms/99999/inventory")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.status").value(404));
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private String inventoryPayload(String date, int total, int available,
                                    int blocked, int sold, int maintenance) {
        return """
            {
              "inventoryDate": "%s",
              "totalInventory": %d,
              "availableInventory": %d,
              "blockedInventory": %d,
              "soldInventory": %d,
              "maintenanceInventory": %d,
              "stopSell": false,
              "closedArrival": false,
              "closedDeparture": false
            }
            """.formatted(date, total, available, blocked, sold, maintenance);
    }

    private List<Long> allDemoRoomIds() {
        Long placeId = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        return hotelRoomRepo.findAllByHotelDetailId(detailId)
            .stream().map(r -> r.getId()).toList();
    }
}
