package com.example.planyourtrip;

import com.example.planyourtrip.model.BookingModification;
import com.example.planyourtrip.repository.*;
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
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Phase 7.36 — Booking Modification Audit &amp; Notification.
 *
 * <p>Exercises the additive behaviour layered onto {@code PATCH /api/bookings/{id}/modify}: every
 * successful modification of a PENDING booking now (a) writes an immutable {@code BookingModification}
 * audit row capturing what changed (old→new dates/occupancy/plan/price + signed price difference),
 * (b) fires a customer-safe "Booking modified" notification, and (c) surfaces a MODIFIED event in
 * the booking timeline. A rolled-back modification writes neither the audit row nor the notification.
 *
 * <p>Isolation: every scenario provisions its OWN published hotel/room + inventory (mirroring
 * {@code BookingModificationTest}), so pricing and inventory are exact and deterministic.
 */
@SpringBootTest
@AutoConfigureMockMvc
class BookingModificationAuditTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired BookingModificationRepository modificationRepo;

    private String adminToken;
    private Long accCategoryId;
    private Long hotelSubcategoryId;
    private Long locationId;
    private static final AtomicInteger counter = new AtomicInteger(1);

    @BeforeEach
    void setup() throws Exception {
        adminToken = login("admin@planyourtrip.com", "admin123456");
        accCategoryId      = categoryRepo.findBySlug("accommodation").orElseThrow().getId();
        hotelSubcategoryId = categoryRepo.findBySlug("hotel").orElseThrow().getId();
        locationId         = locationRepo.findByCode("VT").orElseThrow().getId();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 1. A single modification writes exactly one audit row with correct old→new values
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void modify_writesOneAuditRowWithCorrectOldToNewValues() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Flat", "AUD-1", 1_000_000, 20));

        String token = registerAndLogin("aud-1-" + uniq() + "@test.com");
        JsonNode booking = book(token, roomId, today(3), today(5), 2, 0, planId, 0); // 2 nights
        Long bookingId = booking.get("id").asLong();
        double oldFinal = booking.get("finalPrice").asDouble();

        Map<String, Object> req = new LinkedHashMap<>();
        req.put("checkIn", today(20).toString());
        req.put("checkOut", today(23).toString()); // 3 nights
        req.put("children", 1);
        JsonNode res = modify(token, bookingId, req, status().isOk());
        double newFinal = res.get("finalPrice").asDouble();

        List<BookingModification> rows = modificationRepo.findByBookingIdOrderByCreatedAtAscIdAsc(bookingId);
        assertEquals(1, rows.size(), "exactly one audit row per modification");
        BookingModification m = rows.get(0);
        assertEquals(today(3),  m.getOldCheckInDate());
        assertEquals(today(20), m.getNewCheckInDate());
        assertEquals(today(5),  m.getOldCheckOutDate());
        assertEquals(today(23), m.getNewCheckOutDate());
        assertEquals(2, m.getOldAdults());
        assertEquals(2, m.getNewAdults());
        assertEquals(0, m.getOldChildren());
        assertEquals(1, m.getNewChildren());
        assertEquals(planId.longValue(), m.getOldRatePlanId().longValue());
        assertEquals(planId.longValue(), m.getNewRatePlanId().longValue());
        assertEquals(oldFinal, m.getOldTotalPrice().doubleValue(), 0.01);
        assertEquals(newFinal, m.getNewTotalPrice().doubleValue(), 0.01);
        assertEquals(newFinal - oldFinal, m.getPriceDifference().doubleValue(), 0.01);
        assertNotNull(m.getCreatedAt());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 2. Modifying twice accumulates two ordered audit rows
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void modifyTwice_accumulatesTwoOrderedAuditRows() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Flat", "AUD-2", 1_000_000, 20));

        String token = registerAndLogin("aud-2-" + uniq() + "@test.com");
        Long bookingId = book(token, roomId, today(3), today(5), 2, 0, planId, 0).get("id").asLong();

        // First modification: 2 → 3 nights.
        Map<String, Object> r1 = new LinkedHashMap<>();
        r1.put("checkOut", today(6).toString());
        modify(token, bookingId, r1, status().isOk());

        // Second modification: occupancy change.
        Map<String, Object> r2 = new LinkedHashMap<>();
        r2.put("adults", 3);
        modify(token, bookingId, r2, status().isOk());

        List<BookingModification> rows = modificationRepo.findByBookingIdOrderByCreatedAtAscIdAsc(bookingId);
        assertEquals(2, rows.size(), "history accumulates one row per modification");
        // Ordered oldest-first: first row is the date change, second is the occupancy change.
        assertEquals(today(5), rows.get(0).getOldCheckOutDate());
        assertEquals(today(6), rows.get(0).getNewCheckOutDate());
        assertEquals(2, rows.get(1).getOldAdults());
        assertEquals(3, rows.get(1).getNewAdults());
        // The second row's OLD checkout reflects the first modification's NEW checkout (chained state).
        assertEquals(today(6), rows.get(1).getOldCheckOutDate());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 3. priceDifference is signed: positive for a price increase, negative for a decrease
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void priceDifference_positiveForIncrease_negativeForDecrease() throws Exception {
        Long roomId = provisionBookableRoom();
        Long cheap = createPlanReturnId(roomId, plan("Cheap", "AUD-3C", 1_000_000, 20));
        Long pricey = createPlanReturnId(roomId, plan("Pricey", "AUD-3P", 1_500_000, 5));

        // Increase: switch cheap → pricey plan (same dates).
        String tokenUp = registerAndLogin("aud-3up-" + uniq() + "@test.com");
        Long up = book(tokenUp, roomId, today(3), today(5), 2, 0, cheap, 0).get("id").asLong();
        Map<String, Object> upReq = new LinkedHashMap<>();
        upReq.put("ratePlanId", pricey);
        modify(tokenUp, up, upReq, status().isOk());
        BookingModification upRow = modificationRepo.findByBookingIdOrderByCreatedAtAscIdAsc(up).get(0);
        assertTrue(upRow.getPriceDifference().signum() > 0, "pricier plan → positive difference");
        assertEquals(upRow.getNewTotalPrice().subtract(upRow.getOldTotalPrice()), upRow.getPriceDifference());

        // Decrease: switch pricey → cheap plan (same dates).
        String tokenDown = registerAndLogin("aud-3down-" + uniq() + "@test.com");
        Long down = book(tokenDown, roomId, today(8), today(10), 2, 0, pricey, 0).get("id").asLong();
        Map<String, Object> downReq = new LinkedHashMap<>();
        downReq.put("ratePlanId", cheap);
        modify(tokenDown, down, downReq, status().isOk());
        BookingModification downRow = modificationRepo.findByBookingIdOrderByCreatedAtAscIdAsc(down).get(0);
        assertTrue(downRow.getPriceDifference().signum() < 0, "cheaper plan → negative difference");
        assertEquals(downRow.getNewTotalPrice().subtract(downRow.getOldTotalPrice()), downRow.getPriceDifference());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 4. A "Booking modified" notification is created for the owner (customer-safe message)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void modify_createsBookingModifiedNotificationForOwner() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Flat", "AUD-4", 1_000_000, 20));

        String token = registerAndLogin("aud-4-" + uniq() + "@test.com");
        JsonNode booking = book(token, roomId, today(3), today(5), 2, 0, planId, 0);
        Long bookingId = booking.get("id").asLong();
        String bookingCode = booking.get("bookingCode").asText();

        // Creating a booking fires no notification.
        assertTrue(notifications(token).isEmpty(), "no notification before modify");

        Map<String, Object> req = new LinkedHashMap<>();
        req.put("checkOut", today(6).toString());
        modify(token, bookingId, req, status().isOk());

        JsonNode notes = notifications(token);
        assertEquals(1, notes.size(), "exactly one notification on modify");
        JsonNode n = notes.get(0);
        assertEquals("Booking modified", n.get("title").asText());
        assertEquals("BOOKING", n.get("notificationType").asText());
        String msg = n.get("message").asText();
        assertTrue(msg.contains(bookingCode), "message references the booking code");
        assertTrue(msg.contains(today(6).toString()), "message includes the new check-out date");
        // Customer-safe: no internal / null leakage.
        assertFalse(msg.contains("null"), "no null leakage");
        assertFalse(msg.toLowerCase().contains("basePrice".toLowerCase()));
        assertFalse(msg.contains("HELD"));
        assertFalse(msg.contains("ratePlanAdjustment"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 5. The booking timeline now includes one MODIFIED event per modification
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void timeline_includesModifiedEventPerModification() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Flat", "AUD-5", 1_000_000, 20));

        String token = registerAndLogin("aud-5-" + uniq() + "@test.com");
        Long bookingId = book(token, roomId, today(3), today(5), 2, 0, planId, 0).get("id").asLong();

        // No MODIFIED events before any modification (only CREATED).
        assertEquals(0, countTimelineEvents(token, bookingId, "MODIFIED"));

        Map<String, Object> r1 = new LinkedHashMap<>();
        r1.put("checkOut", today(6).toString());
        modify(token, bookingId, r1, status().isOk());

        Map<String, Object> r2 = new LinkedHashMap<>();
        r2.put("adults", 3);
        modify(token, bookingId, r2, status().isOk());

        JsonNode timeline = timeline(token, bookingId);
        assertEquals(2, countEvents(timeline, "MODIFIED"), "one MODIFIED event per modification");
        // Descriptions reflect what changed.
        boolean hasDates = false, hasOccupancy = false;
        for (JsonNode ev : timeline.get("events")) {
            if (!"MODIFIED".equals(ev.get("event").asText())) continue;
            String d = ev.get("description").asText();
            if (d.contains("dates")) hasDates = true;
            if (d.contains("occupancy")) hasOccupancy = true;
        }
        assertTrue(hasDates, "date-change modification described");
        assertTrue(hasOccupancy, "occupancy-change modification described");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 6. A failed modification (unavailable dates → 422) writes NO audit row and NO notification
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void failedModify_rollsBackAuditRowAndNotification() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("RB", "AUD-6", 1_000_000, 20));
        seedNight(roomId, today(30), 0, 0);
        seedNight(roomId, today(31), 0, 0);

        String token = registerAndLogin("aud-6-" + uniq() + "@test.com");
        Long bookingId = book(token, roomId, today(3), today(5), 2, 0, planId, 0).get("id").asLong();

        Map<String, Object> req = new LinkedHashMap<>();
        req.put("checkIn", today(30).toString());
        req.put("checkOut", today(32).toString());
        modify(token, bookingId, req, status().isUnprocessableEntity());

        assertTrue(modificationRepo.findByBookingIdOrderByCreatedAtAscIdAsc(bookingId).isEmpty(),
            "failed modify writes no audit row (same transaction rolled back)");
        assertTrue(notifications(token).isEmpty(),
            "failed modify fires no notification (same transaction rolled back)");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 7. Audit rows are immutable — a later modification never mutates an earlier row
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void auditRows_immutable_earlierRowUnchangedByLaterModification() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Flat", "AUD-7", 1_000_000, 20));

        String token = registerAndLogin("aud-7-" + uniq() + "@test.com");
        Long bookingId = book(token, roomId, today(3), today(5), 2, 0, planId, 0).get("id").asLong();

        Map<String, Object> r1 = new LinkedHashMap<>();
        r1.put("checkOut", today(6).toString());
        modify(token, bookingId, r1, status().isOk());

        BookingModification first = modificationRepo.findByBookingIdOrderByCreatedAtAscIdAsc(bookingId).get(0);
        Long firstId = first.getId();
        LocalDate firstOldOut = first.getOldCheckOutDate();
        LocalDate firstNewOut = first.getNewCheckOutDate();

        // A second modification.
        Map<String, Object> r2 = new LinkedHashMap<>();
        r2.put("adults", 3);
        modify(token, bookingId, r2, status().isOk());

        // Re-read the first row: its values are untouched (write-once).
        BookingModification firstReloaded = modificationRepo.findById(firstId).orElseThrow();
        assertEquals(firstOldOut, firstReloaded.getOldCheckOutDate());
        assertEquals(firstNewOut, firstReloaded.getNewCheckOutDate());
        assertEquals(2, firstReloaded.getOldAdults());
        assertEquals(2, firstReloaded.getNewAdults(), "first row's newAdults not overwritten by later change to 3");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS (adapted from BookingModificationTest)
    // ═══════════════════════════════════════════════════════════════════════════

    private LocalDate today(int plus) { return LocalDate.now().plusDays(plus); }

    private JsonNode notifications(String token) throws Exception {
        String body = mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode timeline(String token, Long bookingId) throws Exception {
        String body = mvc.perform(get("/api/bookings/" + bookingId + "/timeline")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private int countTimelineEvents(String token, Long bookingId, String event) throws Exception {
        return countEvents(timeline(token, bookingId), event);
    }

    private int countEvents(JsonNode timeline, String event) {
        int n = 0;
        for (JsonNode ev : timeline.get("events"))
            if (event.equals(ev.get("event").asText())) n++;
        return n;
    }

    private Map<String, Object> plan(String name, String code, long price, int priority) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("rateName", name);
        m.put("rateType", "STANDARD");
        m.put("pricePerNight", price);
        m.put("startDate", LocalDate.now().toString());
        m.put("endDate", LocalDate.now().plusDays(365).toString());
        m.put("active", true);
        m.put("priority", priority);
        m.put("code", code);
        return m;
    }

    private Long createPlanReturnId(Long roomId, Object body) throws Exception {
        String resp = mvc.perform(post("/api/admin/rooms/" + roomId + "/rate-plans")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(body)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp).get("id").asLong();
    }

    private JsonNode book(String token, Long roomId, LocalDate ci, LocalDate co,
                          int adults, int children, Long ratePlanId, int extraBeds) throws Exception {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("roomId", roomId);
        m.put("checkIn", ci.toString());
        m.put("checkOut", co.toString());
        m.put("adults", adults);
        m.put("children", children);
        m.put("numberOfRooms", 1);
        if (ratePlanId != null) m.put("ratePlanId", ratePlanId);
        if (extraBeds > 0) m.put("extraBeds", extraBeds);
        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(m)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode modify(String token, Long bookingId, Map<String, Object> req,
                            org.springframework.test.web.servlet.ResultMatcher expected) throws Exception {
        String body = mvc.perform(patch("/api/bookings/" + bookingId + "/modify")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(req)))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
    }

    // ── Provisioning ──────────────────────────────────────────────────────────

    /** A bookable room: published hotel + inventory seeded today+1..today+50 (10 available). */
    private Long provisionBookableRoom() throws Exception {
        Long hotelId = createHotelPlace(uniq());
        createHotelDetail(hotelId);
        Long roomId = createRoom(hotelId, "RM-" + uniq());
        StringBuilder items = new StringBuilder();
        for (int i = 1; i <= 50; i++) {
            if (items.length() > 0) items.append(",");
            items.append(String.format(
                "{\"inventoryDate\":\"%s\",\"totalInventory\":10,\"availableInventory\":10,"
                + "\"blockedInventory\":0,\"soldInventory\":0,\"maintenanceInventory\":0,"
                + "\"stopSell\":false,\"closedArrival\":false,\"closedDeparture\":false}",
                today(i)));
        }
        mvc.perform(post("/api/admin/rooms/" + roomId + "/inventory/bulk")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"items\":[" + items + "]}"))
            .andExpect(status().isOk());
        return roomId;
    }

    private void seedNight(Long roomId, LocalDate date, int total, int available) throws Exception {
        String item = String.format(
            "{\"inventoryDate\":\"%s\",\"totalInventory\":%d,\"availableInventory\":%d,"
            + "\"blockedInventory\":0,\"soldInventory\":0,\"maintenanceInventory\":0,"
            + "\"stopSell\":false,\"closedArrival\":false,\"closedDeparture\":false}",
            date, total, available);
        mvc.perform(post("/api/admin/rooms/" + roomId + "/inventory/bulk")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"items\":[" + item + "]}"))
            .andExpect(status().isOk());
    }

    private String uniq() { return UUID.randomUUID().toString().substring(0, 8); }

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
                .content("{\"fullName\":\"Audit Tester\",\"email\":\"" + email + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private Long createHotelPlace(String name) throws Exception {
        String req = """
            {"name":"%s","categoryId":%d,"subcategoryId":%d,"administrativeUnitId":%d,
             "address":"123 Test Street","priceLevel":2,"featured":false,"verified":false,"status":"DRAFT"}
            """.formatted(name, accCategoryId, hotelSubcategoryId, locationId);
        String resp = mvc.perform(post("/api/admin/places")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long id = mapper.readTree(resp).get("id").asLong();
        patchStatus(id, "APPROVED");
        patchStatus(id, "PUBLISHED");
        return id;
    }

    private void patchStatus(Long id, String status) throws Exception {
        mvc.perform(patch("/api/admin/places/" + id + "/status")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"" + status + "\"}"))
            .andExpect(status().isOk());
    }

    private void createHotelDetail(Long placeId) throws Exception {
        String req = """
            {"placeId":%d,"starRating":4,"checkInTime":"14:00:00","checkOutTime":"12:00:00",
             "totalRooms":10,"availableRooms":10,"freeCancellation":false,"prepaymentRequired":false,
             "breakfastIncluded":false,"airportShuttle":false}
            """.formatted(placeId);
        mvc.perform(post("/api/admin/hotels")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isCreated());
    }

    private Long createRoom(Long placeId, String roomCode) throws Exception {
        String req = """
            {"placeId":%d,"roomName":"Deluxe Room","roomCode":"%s","roomType":"DELUXE","bedType":"QUEEN",
             "bedCount":1,"maxAdults":3,"maxChildren":2,"maxGuests":4,"roomSizeSqm":25.0,"floorNumber":2,
             "smokingAllowed":false,"breakfastIncluded":true,"freeCancellation":true,"instantConfirmation":true,
             "priceFrom":900000,"originalPrice":1000000,"quantity":10,"availableQuantity":10,"active":true}
            """.formatted(placeId, roomCode);
        String resp = mvc.perform(post("/api/admin/rooms")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp).get("id").asLong();
    }
}
