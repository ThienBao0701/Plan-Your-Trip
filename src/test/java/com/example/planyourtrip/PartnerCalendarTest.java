package com.example.planyourtrip;

import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.CategoryRepository;
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
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * PartnerCalendarTest — Phase 6.3.
 * Every scenario provisions its own throwaway partner, hotel, hotel-detail and room
 * (never touching the shared seeded Grand Palace Hotel) so tests stay isolated from
 * each other and from other test classes sharing the same H2 instance.
 */
@SpringBootTest
@AutoConfigureMockMvc
class PartnerCalendarTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;

    private String adminToken;
    private static final AtomicInteger counter = new AtomicInteger(1);

    private Long accCategoryId;
    private Long hotelSubcategoryId;
    private Long locationId;

    @BeforeEach
    void setup() {
        accCategoryId      = categoryRepo.findBySlug("accommodation").orElseThrow().getId();
        hotelSubcategoryId = categoryRepo.findBySlug("hotel").orElseThrow().getId();
        locationId         = locationRepo.findByCode("VT").orElseThrow().getId();
    }

    private record PartnerCtx(String token, Long profileId) {}
    private record OwnedRoom(PartnerCtx partner, Long hotelId, Long roomId) {}

    // ═══════════════════════════════════════════════════════════════════════════
    // ROOMS — list / view / ownership
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partner_listsMyRooms() throws Exception {
        OwnedRoom r = setupOwnedRoom("ListRooms");

        String body = mvc.perform(get("/api/partner/rooms")
                .param("hotelId", String.valueOf(r.hotelId()))
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());
        boolean found = false;
        for (JsonNode n : arr) if (n.get("id").asLong() == r.roomId()) found = true;
        assertTrue(found, "Owned room must appear in getMyRooms()");
    }

    @Test
    void partner_cannotListAnotherPartnersRooms() throws Exception {
        OwnedRoom r = setupOwnedRoom("ListOtherRooms");
        PartnerCtx stranger = createAndApprovePartner();

        mvc.perform(get("/api/partner/rooms")
                .param("hotelId", String.valueOf(r.hotelId()))
                .header("Authorization", "Bearer " + stranger.token()))
            .andExpect(status().isNotFound());
    }

    @Test
    void partner_getsRoomDetail() throws Exception {
        OwnedRoom r = setupOwnedRoom("RoomDetail");

        mvc.perform(get("/api/partner/rooms/" + r.roomId())
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(r.roomId()));
    }

    @Test
    void partner_cannotGetAnotherPartnersRoom() throws Exception {
        OwnedRoom r = setupOwnedRoom("GetOtherRoom");
        PartnerCtx stranger = createAndApprovePartner();

        mvc.perform(get("/api/partner/rooms/" + r.roomId())
                .header("Authorization", "Bearer " + stranger.token()))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ROOMS — update / activate / deactivate
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partner_updatesRoomInformation() throws Exception {
        OwnedRoom r = setupOwnedRoom("UpdateRoom");

        String body = mvc.perform(put("/api/partner/rooms/" + r.roomId())
                .header("Authorization", "Bearer " + r.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(roomPayload("Updated Deluxe Room", "RM-" + uniqSuffix())))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals("Updated Deluxe Room", mapper.readTree(body).get("roomName").asText());
    }

    @Test
    void partner_cannotModifyAnotherPartnersRoom() throws Exception {
        OwnedRoom r = setupOwnedRoom("ModifyOtherRoom");
        PartnerCtx stranger = createAndApprovePartner();

        mvc.perform(put("/api/partner/rooms/" + r.roomId())
                .header("Authorization", "Bearer " + stranger.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(roomPayload("Hijacked Room", "RM-" + uniqSuffix())))
            .andExpect(status().isNotFound());
    }

    @Test
    void partner_activatesRoom() throws Exception {
        OwnedRoom r = setupOwnedRoom("ActivateRoom");

        mvc.perform(patch("/api/partner/rooms/" + r.roomId() + "/deactivate")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk());

        String body = mvc.perform(patch("/api/partner/rooms/" + r.roomId() + "/activate")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertTrue(mapper.readTree(body).get("active").asBoolean());
    }

    @Test
    void partner_deactivatesRoom() throws Exception {
        OwnedRoom r = setupOwnedRoom("DeactivateRoom");

        String body = mvc.perform(patch("/api/partner/rooms/" + r.roomId() + "/deactivate")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertFalse(mapper.readTree(body).get("active").asBoolean());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // AUTH / APPROVAL
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void unauthenticated_roomsRejected() throws Exception {
        mvc.perform(get("/api/partner/rooms").param("hotelId", "1"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void unauthenticated_calendarRejected() throws Exception {
        mvc.perform(get("/api/partner/calendar/rooms/1"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void nonApprovedPartner_cannotAccessRooms() throws Exception {
        String draftToken = createDraftPartnerToken();

        mvc.perform(get("/api/partner/rooms")
                .param("hotelId", "1")
                .header("Authorization", "Bearer " + draftToken))
            .andExpect(status().isForbidden());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CALENDAR — view / bulk / single-day
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partner_bulkUpdatesInventory() throws Exception {
        OwnedRoom r = setupOwnedRoom("BulkUpdate");

        String body = mvc.perform(post("/api/partner/calendar/rooms/" + r.roomId() + "/bulk")
                .header("Authorization", "Bearer " + r.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"items":[%s,%s,%s]}
                        """.formatted(
                        inventoryPayload("2030-08-01", 20, 18, 1, 0, 1),
                        inventoryPayload("2030-08-02", 20, 18, 1, 0, 1),
                        inventoryPayload("2030-08-03", 20, 18, 1, 0, 1))))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode results = mapper.readTree(body);
        assertEquals(3, results.size());
    }

    @Test
    void partner_viewsCalendar() throws Exception {
        OwnedRoom r = setupOwnedRoom("ViewCalendar");
        bulkInsert(r, "2030-08-10", 5);

        String body = mvc.perform(get("/api/partner/calendar/rooms/" + r.roomId())
                .param("from", "2030-08-10").param("to", "2030-08-14")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode inv = mapper.readTree(body).get("inventory");
        assertEquals(5, inv.size());
        for (int i = 1; i < inv.size(); i++) {
            LocalDate prev = LocalDate.parse(inv.get(i - 1).get("inventoryDate").asText());
            LocalDate curr = LocalDate.parse(inv.get(i).get("inventoryDate").asText());
            assertTrue(curr.isAfter(prev), "Calendar must be sorted ascending by date");
        }
    }

    @Test
    void partner_updatesSingleDayInventory() throws Exception {
        OwnedRoom r = setupOwnedRoom("SingleDayUpdate");
        bulkInsert(r, "2030-08-20", 1);

        String body = mvc.perform(put("/api/partner/calendar/rooms/" + r.roomId() + "/2030-08-20")
                .header("Authorization", "Bearer " + r.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(inventoryPayload("2030-08-20", 25, 22, 1, 0, 2)))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals(25, mapper.readTree(body).get("totalInventory").asInt());
        assertEquals(22, mapper.readTree(body).get("availableInventory").asInt());
    }

    @Test
    void partner_cannotAccessAnotherPartnersCalendar() throws Exception {
        OwnedRoom r = setupOwnedRoom("CalendarOwnershipView");
        PartnerCtx stranger = createAndApprovePartner();

        mvc.perform(get("/api/partner/calendar/rooms/" + r.roomId())
                .header("Authorization", "Bearer " + stranger.token()))
            .andExpect(status().isNotFound());
    }

    @Test
    void partner_cannotBulkUpdateAnotherPartnersCalendar() throws Exception {
        OwnedRoom r = setupOwnedRoom("CalendarOwnershipBulk");
        PartnerCtx stranger = createAndApprovePartner();

        mvc.perform(post("/api/partner/calendar/rooms/" + r.roomId() + "/bulk")
                .header("Authorization", "Bearer " + stranger.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"items":[%s]}
                        """.formatted(inventoryPayload("2030-08-25", 20, 18, 1, 0, 1))))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // STOP SELL / CTA / CTD
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partner_updatesStopSell() throws Exception {
        OwnedRoom r = setupOwnedRoom("StopSell");
        bulkInsert(r, "2030-09-01", 1);

        String body = mvc.perform(patch("/api/partner/calendar/rooms/" + r.roomId() + "/2030-09-01/stop-sell")
                .header("Authorization", "Bearer " + r.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"value\":true}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertTrue(mapper.readTree(body).get("stopSell").asBoolean());
    }

    @Test
    void partner_updatesClosedArrival() throws Exception {
        OwnedRoom r = setupOwnedRoom("ClosedArrival");
        bulkInsert(r, "2030-09-05", 1);

        String body = mvc.perform(patch("/api/partner/calendar/rooms/" + r.roomId() + "/2030-09-05/closed-arrival")
                .header("Authorization", "Bearer " + r.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"value\":true}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertTrue(mapper.readTree(body).get("closedArrival").asBoolean());
    }

    @Test
    void partner_updatesClosedDeparture() throws Exception {
        OwnedRoom r = setupOwnedRoom("ClosedDeparture");
        bulkInsert(r, "2030-09-10", 1);

        String body = mvc.perform(patch("/api/partner/calendar/rooms/" + r.roomId() + "/2030-09-10/closed-departure")
                .header("Authorization", "Bearer " + r.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"value\":true}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertTrue(mapper.readTree(body).get("closedDeparture").asBoolean());
    }

    @Test
    void stopSell_nonExistentDate_returns404() throws Exception {
        OwnedRoom r = setupOwnedRoom("StopSellMissingDate");

        mvc.perform(patch("/api/partner/calendar/rooms/" + r.roomId() + "/2031-01-01/stop-sell")
                .header("Authorization", "Bearer " + r.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"value\":true}"))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // DAILY PRICE (rate plan reuse)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partner_updatesDailyPriceViaRatePlan() throws Exception {
        OwnedRoom r = setupOwnedRoom("DailyPrice");

        String req = """
                {"rateName":"Peak Season","rateType":"STANDARD","pricePerNight":750000,
                 "startDate":"2030-09-20","endDate":"2030-09-25","active":true}
                """;

        String body = mvc.perform(put("/api/partner/calendar/rooms/" + r.roomId() + "/price")
                .header("Authorization", "Bearer " + r.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals(750000, mapper.readTree(body).get("pricePerNight").asDouble());

        String listBody = mvc.perform(get("/api/partner/calendar/rooms/" + r.roomId() + "/price")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode plans = mapper.readTree(listBody);
        boolean found = false;
        for (JsonNode p : plans) if ("Peak Season".equals(p.get("rateName").asText())) found = true;
        assertTrue(found, "Newly created rate plan must appear in getPrices()");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // TRANSACTION ROLLBACK
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void bulkUpdate_invalidItem_rollsBackEntireBatch() throws Exception {
        OwnedRoom r = setupOwnedRoom("RollbackBulk");

        mvc.perform(post("/api/partner/calendar/rooms/" + r.roomId() + "/bulk")
                .header("Authorization", "Bearer " + r.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"items":[%s,%s]}
                        """.formatted(
                        inventoryPayload("2030-10-01", 20, 18, 1, 0, 1),
                        inventoryPayload("2030-10-02", 20, 30, 1, 0, 1))))
            .andExpect(status().isBadRequest());

        String body = mvc.perform(get("/api/partner/calendar/rooms/" + r.roomId())
                .param("from", "2030-10-01").param("to", "2030-10-02")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode inv = mapper.readTree(body).get("inventory");
        assertEquals(0, inv.size(),
            "The valid item in a failed bulk batch must not be persisted — the whole transaction must roll back");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PERFORMANCE-SENSITIVE RANGE QUERY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void calendarRangeQuery_returnsAllDaysInSingleCall() throws Exception {
        OwnedRoom r = setupOwnedRoom("PerfRange");
        LocalDate start = LocalDate.parse("2030-11-01");
        bulkInsert(r, start.toString(), 30);

        String body = mvc.perform(get("/api/partner/calendar/rooms/" + r.roomId())
                .param("from", start.toString())
                .param("to", start.plusDays(29).toString())
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode inv = mapper.readTree(body).get("inventory");
        assertEquals(30, inv.size(), "Single range query must return all 30 days in one call");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ADMIN UNRESTRICTED ACCESS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void admin_stillHasUnrestrictedRoomAccess() throws Exception {
        OwnedRoom r = setupOwnedRoom("AdminUnrestrictedRoom");

        mvc.perform(get("/api/admin/rooms/" + r.roomId())
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(r.roomId()));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private OwnedRoom setupOwnedRoom(String namePrefix) throws Exception {
        PartnerCtx partner = createAndApprovePartner();
        Long hotelId = createHotelPlace(uniq(namePrefix));
        createHotelDetail(hotelId);
        Long roomId = createRoom(hotelId, "RM-" + uniqSuffix());
        assignOwner(hotelId, partner.profileId());
        return new OwnedRoom(partner, hotelId, roomId);
    }

    private void bulkInsert(OwnedRoom r, String startDate, int days) throws Exception {
        LocalDate start = LocalDate.parse(startDate);
        StringBuilder items = new StringBuilder();
        for (int i = 0; i < days; i++) {
            if (i > 0) items.append(",");
            items.append(inventoryPayload(start.plusDays(i).toString(), 20, 18, 1, 0, 1));
        }
        mvc.perform(post("/api/partner/calendar/rooms/" + r.roomId() + "/bulk")
                .header("Authorization", "Bearer " + r.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"items\":[" + items + "]}"))
            .andExpect(status().isOk());
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

    private String registerAndLogin(String email) throws Exception {
        String body = mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"Partner Tester\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private String createDraftPartnerToken() throws Exception {
        String email = "partner-cal-draft-" + counter.getAndIncrement() + "@test.com";
        String token = registerAndLogin(email);
        String profileReq = """
                {"businessName":"Draft Hotel Co","businessType":"HOTEL","representativeName":"Partner Tester",
                 "phone":"0901234567","email":"contact@example.com","address":"123 Le Loi, Da Nang"}
                """;
        mvc.perform(post("/api/partner/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(profileReq))
            .andExpect(status().isOk());
        return token;
    }

    private PartnerCtx createAndApprovePartner() throws Exception {
        String email = "partner-cal-" + counter.getAndIncrement() + "@test.com";
        String token = registerAndLogin(email);

        String profileReq = """
                {"businessName":"Test Hotel Co %d","businessType":"HOTEL","representativeName":"Partner Tester",
                 "phone":"0901234567","email":"contact@example.com","address":"123 Le Loi, Da Nang"}
                """.formatted(counter.get());
        String profileBody = mvc.perform(post("/api/partner/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(profileReq))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        Long profileId = mapper.readTree(profileBody).get("id").asLong();

        mvc.perform(post("/api/partner/profile/submit")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        mvc.perform(post("/api/admin/partners/" + profileId + "/approve")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk());

        return new PartnerCtx(token, profileId);
    }

    private Long createHotelPlace(String name) throws Exception {
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
        Long id = mapper.readTree(resp).get("id").asLong();

        adminPatchStatus(id, "APPROVED");
        adminPatchStatus(id, "PUBLISHED");
        return id;
    }

    private void adminPatchStatus(Long id, String status) throws Exception {
        mvc.perform(patch("/api/admin/places/" + id + "/status")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"" + status + "\"}"))
            .andExpect(status().isOk());
    }

    private void createHotelDetail(Long placeId) throws Exception {
        String req = """
                {
                  "placeId": %d,
                  "starRating": 4,
                  "checkInTime": "14:00:00",
                  "checkOutTime": "12:00:00",
                  "totalRooms": 10,
                  "availableRooms": 10,
                  "freeCancellation": false,
                  "prepaymentRequired": false,
                  "breakfastIncluded": false,
                  "airportShuttle": false
                }
                """.formatted(placeId);
        mvc.perform(post("/api/admin/hotels")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isCreated());
    }

    private Long createRoom(Long placeId, String roomCode) throws Exception {
        String req = """
                {
                  "placeId": %d,
                  "roomName": "Deluxe Room",
                  "roomCode": "%s",
                  "roomType": "DELUXE",
                  "bedType": "QUEEN",
                  "bedCount": 1,
                  "maxAdults": 2,
                  "maxChildren": 1,
                  "maxGuests": 3,
                  "roomSizeSqm": 25.0,
                  "floorNumber": 2,
                  "smokingAllowed": false,
                  "breakfastIncluded": true,
                  "freeCancellation": true,
                  "instantConfirmation": true,
                  "priceFrom": 500000,
                  "originalPrice": 600000,
                  "quantity": 10,
                  "availableQuantity": 10,
                  "active": true
                }
                """.formatted(placeId, roomCode);
        String resp = mvc.perform(post("/api/admin/rooms")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp).get("id").asLong();
    }

    private void assignOwner(Long hotelId, Long partnerProfileId) throws Exception {
        mvc.perform(post("/api/admin/hotels/" + hotelId + "/assign-owner")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"partnerProfileId\":" + partnerProfileId + "}"))
            .andExpect(status().isOk());
    }

    private String roomPayload(String roomName, String roomCode) {
        return """
                {
                  "roomName": "%s",
                  "roomCode": "%s",
                  "roomType": "DELUXE",
                  "bedType": "QUEEN",
                  "bedCount": 1,
                  "maxAdults": 2,
                  "maxChildren": 1,
                  "maxGuests": 3,
                  "priceFrom": 550000,
                  "originalPrice": 650000,
                  "quantity": 10,
                  "availableQuantity": 10
                }
                """.formatted(roomName, roomCode);
    }

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

    private String uniq(String prefix) {
        return prefix + "-" + UUID.randomUUID().toString().substring(0, 8);
    }

    private String uniqSuffix() {
        return UUID.randomUUID().toString().substring(0, 8);
    }
}
