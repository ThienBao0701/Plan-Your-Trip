package com.example.planyourtrip;

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

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class BookingTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;
    @Autowired RoomInventoryRepository inventoryRepo;
    @Autowired BookingRepository bookingRepo;

    private String adminToken;
    private String userToken;
    private Long stdTwinRoomId;

    // Inventory covers today to today+89. Tests use offsets below 50 to avoid seed bookings.
    // Each test uses a unique date window to prevent cross-test inventory conflicts.
    private static final LocalDate TODAY = LocalDate.now();

    @BeforeEach
    void setup() throws Exception {
        adminToken = login("admin@planyourtrip.com", "admin123456");
        userToken  = login("demo@planyourtrip.com",  "demo123456");

        Long placeId  = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        stdTwinRoomId = hotelRoomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "STD-TWIN".equals(r.getRoomCode()))
            .findFirst().orElseThrow().getId();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CREATE BOOKING
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void booking_create_success_returns201() throws Exception {
        LocalDate ci = TODAY.plusDays(5);
        LocalDate co = ci.plusDays(2);

        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(bookingPayload(stdTwinRoomId, ci, co, 2, 0, 1, null)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertNotNull(res.get("id"));
        assertNotNull(res.get("bookingCode"));
        assertTrue(res.get("bookingCode").asText().startsWith("PYT-"));
        assertEquals("PENDING",  res.get("status").asText());
        assertEquals("VND",      res.get("currency").asText());
        assertEquals(2,          res.get("nights").asInt());
        assertEquals(2,          res.get("adults").asInt());
        assertEquals("STD-TWIN", res.get("roomCode").asText());
        assertNotNull(res.get("basePrice"));
        assertNotNull(res.get("finalPrice"));
    }

    @Test
    void booking_create_bookingCode_hasCorrectFormat() throws Exception {
        LocalDate ci = TODAY.plusDays(6);
        LocalDate co = ci.plusDays(1);

        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(bookingPayload(stdTwinRoomId, ci, co, 1, 0, 1, null)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        String code = mapper.readTree(body).get("bookingCode").asText();
        assertTrue(code.matches("PYT-\\d{8}-\\d{6}"),
            "bookingCode must match PYT-YYYYMMDD-NNNNNN but was: " + code);
    }

    @Test
    void booking_create_inventoryDecremented() throws Exception {
        LocalDate ci = TODAY.plusDays(7);
        LocalDate co = ci.plusDays(2);

        long beforeAvail = inventoryRepo.countNightsWithSufficientInventory(stdTwinRoomId, ci, co, 1);

        mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(bookingPayload(stdTwinRoomId, ci, co, 2, 0, 1, null)))
            .andExpect(status().isCreated());

        long afterAvail = inventoryRepo.countNightsWithSufficientInventory(stdTwinRoomId, ci, co, 1);
        // After booking 1 room, each night still has 17+ available (18 initial - 1)
        // The countNightsWithSufficientInventory for qty=1 checks >= 1 available
        assertEquals(beforeAvail, afterAvail); // still available for qty=1

        // But for the original qty=18 check, count should be lower
        long beforeFull = inventoryRepo.countNightsWithSufficientInventory(stdTwinRoomId, ci, co, 18);
        assertEquals(0, beforeFull); // now only 17 available, not 18
    }

    @Test
    void booking_create_pricingSnapshotStored() throws Exception {
        LocalDate ci = TODAY.plusDays(8);
        LocalDate co = ci.plusDays(2);

        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(bookingPayload(stdTwinRoomId, ci, co, 2, 0, 1, null)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertFalse(res.get("basePrice").isNull());
        assertFalse(res.get("finalPrice").isNull());
        assertFalse(res.get("discountAmount").isNull());
        // basePrice must be positive
        assertTrue(res.get("basePrice").asDouble() > 0);
        // finalPrice must be positive and <= basePrice
        assertTrue(res.get("finalPrice").asDouble() > 0);
        assertTrue(res.get("finalPrice").asDouble() <= res.get("basePrice").asDouble());
    }

    @Test
    void booking_create_unauthenticated_returns401() throws Exception {
        LocalDate ci = TODAY.plusDays(9);
        LocalDate co = ci.plusDays(1);

        mvc.perform(post("/api/bookings")
                .contentType(MediaType.APPLICATION_JSON)
                .content(bookingPayload(stdTwinRoomId, ci, co, 1, 0, 1, null)))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void booking_create_pastCheckIn_returns400() throws Exception {
        LocalDate ci = TODAY.minusDays(1);
        LocalDate co = TODAY.plusDays(1);

        mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(bookingPayload(stdTwinRoomId, ci, co, 1, 0, 1, null)))
            .andExpect(status().isBadRequest());
    }

    @Test
    void booking_create_sameDate_returns400() throws Exception {
        LocalDate ci = TODAY.plusDays(3);

        mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(bookingPayload(stdTwinRoomId, ci, ci, 1, 0, 1, null)))
            .andExpect(status().isBadRequest());
    }

    @Test
    void booking_create_roomNotFound_returns404() throws Exception {
        LocalDate ci = TODAY.plusDays(10);
        LocalDate co = ci.plusDays(1);

        mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(bookingPayload(99999L, ci, co, 1, 0, 1, null)))
            .andExpect(status().isNotFound());
    }

    @Test
    void booking_create_adultsExceedCapacity_returns400() throws Exception {
        // STD-TWIN maxAdults=2; requesting 3 adults
        LocalDate ci = TODAY.plusDays(11);
        LocalDate co = ci.plusDays(1);

        mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(bookingPayload(stdTwinRoomId, ci, co, 3, 0, 1, null)))
            .andExpect(status().isBadRequest());
    }

    @Test
    void booking_create_noInventory_returns422() throws Exception {
        // today+95 to today+97 is outside the 90-day seed window — no inventory records exist
        LocalDate ci = TODAY.plusDays(95);
        LocalDate co = ci.plusDays(2);

        mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(bookingPayload(stdTwinRoomId, ci, co, 1, 0, 1, null)))
            .andExpect(status().isUnprocessableEntity());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // GET BOOKING BY ID
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void booking_getById_owner_returns200() throws Exception {
        Long id = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(12), TODAY.plusDays(14), 2);

        String body = mvc.perform(get("/api/bookings/" + id)
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals(id, mapper.readTree(body).get("id").asLong());
    }

    @Test
    void booking_getById_admin_returns200() throws Exception {
        Long id = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(15), TODAY.plusDays(17), 1);

        // Admin can view any booking via the user endpoint
        String body = mvc.perform(get("/api/bookings/" + id)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals(id, mapper.readTree(body).get("id").asLong());
    }

    @Test
    void booking_getById_nonexistent_returns404() throws Exception {
        mvc.perform(get("/api/bookings/9999999")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNotFound());
    }

    @Test
    void booking_getById_unauthenticated_returns401() throws Exception {
        mvc.perform(get("/api/bookings/1"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MY BOOKINGS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void booking_myBookings_returns200WithList() throws Exception {
        String body = mvc.perform(get("/api/me/bookings")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());
        // Seeded bookings exist for demo user
        assertTrue(arr.size() >= 2);
    }

    @Test
    void booking_myBookings_unauthenticated_returns401() throws Exception {
        mvc.perform(get("/api/me/bookings"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CANCEL BOOKING
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void booking_cancel_pending_returns200_andRestoresInventory() throws Exception {
        LocalDate ci = TODAY.plusDays(20);
        LocalDate co = ci.plusDays(2);

        // Use qty=18 threshold: seed sets availableInventory=18, booking drops to 17
        long initCount = inventoryRepo.countNightsWithSufficientInventory(stdTwinRoomId, ci, co, 18);

        Long id = createBooking(userToken, stdTwinRoomId, ci, co, 1);

        // After booking: 17 available < 18 threshold, so count drops
        long afterBookCount = inventoryRepo.countNightsWithSufficientInventory(stdTwinRoomId, ci, co, 18);
        assertEquals(0, afterBookCount);

        String body = mvc.perform(patch("/api/bookings/" + id + "/cancel")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals("CANCELLED", mapper.readTree(body).get("status").asText());
        assertFalse(mapper.readTree(body).get("cancelledAt").isNull());

        // After cancel: inventory restored to initial level
        long afterCancelCount = inventoryRepo.countNightsWithSufficientInventory(stdTwinRoomId, ci, co, 18);
        assertEquals(initCount, afterCancelCount);
    }

    @Test
    void booking_cancel_alreadyCancelled_returns422() throws Exception {
        Long id = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(22), TODAY.plusDays(24), 1);

        // First cancel
        mvc.perform(patch("/api/bookings/" + id + "/cancel")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());

        // Second cancel
        mvc.perform(patch("/api/bookings/" + id + "/cancel")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void booking_cancel_checkedOut_returns422() throws Exception {
        Long id = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(25), TODAY.plusDays(27), 1);

        // Admin sets to CHECKED_OUT
        mvc.perform(patch("/api/admin/bookings/" + id + "/status")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"CHECKED_OUT\"}"))
            .andExpect(status().isOk());

        // User tries to cancel
        mvc.perform(patch("/api/bookings/" + id + "/cancel")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void booking_cancel_noShow_returns422() throws Exception {
        Long id = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(28), TODAY.plusDays(30), 1);

        mvc.perform(patch("/api/admin/bookings/" + id + "/status")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"NO_SHOW\"}"))
            .andExpect(status().isOk());

        mvc.perform(patch("/api/bookings/" + id + "/cancel")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void booking_cancel_unauthenticated_returns401() throws Exception {
        mvc.perform(patch("/api/bookings/1/cancel"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ADMIN BOOKING APIS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void admin_getBookings_returns200() throws Exception {
        String body = mvc.perform(get("/api/admin/bookings")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());
        assertTrue(arr.size() >= 2); // at least the 2 seeded bookings
    }

    @Test
    void admin_getBookings_forbiddenForUser_returns403() throws Exception {
        mvc.perform(get("/api/admin/bookings")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isForbidden());
    }

    @Test
    void admin_getBookingById_returns200() throws Exception {
        Long id = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(32), TODAY.plusDays(34), 2);

        String body = mvc.perform(get("/api/admin/bookings/" + id)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals(id, res.get("id").asLong());
        assertEquals("PENDING", res.get("status").asText());
        assertNotNull(res.get("bookingCode"));
        assertNotNull(res.get("userEmail"));
        assertNotNull(res.get("hotelName"));
    }

    @Test
    void admin_updateStatus_confirmed_returns200() throws Exception {
        Long id = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(35), TODAY.plusDays(37), 1);

        String body = mvc.perform(patch("/api/admin/bookings/" + id + "/status")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"CONFIRMED\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("CONFIRMED", res.get("status").asText());
        assertFalse(res.get("confirmedAt").isNull());
    }

    @Test
    void admin_updateStatus_cancelled_restoresInventory() throws Exception {
        LocalDate ci = TODAY.plusDays(38);
        LocalDate co = ci.plusDays(2);

        // Use qty=18 threshold to detect the before/after decrement difference
        long initCount = inventoryRepo.countNightsWithSufficientInventory(stdTwinRoomId, ci, co, 18);

        Long id = createBooking(userToken, stdTwinRoomId, ci, co, 1);

        // After booking: 17 available < 18 threshold
        long afterBookCount = inventoryRepo.countNightsWithSufficientInventory(stdTwinRoomId, ci, co, 18);
        assertEquals(0, afterBookCount);

        mvc.perform(patch("/api/admin/bookings/" + id + "/status")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"CANCELLED\"}"))
            .andExpect(status().isOk());

        // After admin cancel: inventory restored
        long afterCancelCount = inventoryRepo.countNightsWithSufficientInventory(stdTwinRoomId, ci, co, 18);
        assertEquals(initCount, afterCancelCount);
    }

    @Test
    void admin_updateStatus_forbiddenForUser_returns403() throws Exception {
        Long id = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(41), TODAY.plusDays(43), 1);

        mvc.perform(patch("/api/admin/bookings/" + id + "/status")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"CONFIRMED\"}"))
            .andExpect(status().isForbidden());
    }

    @Test
    void admin_getBookingById_notFound_returns404() throws Exception {
        mvc.perform(get("/api/admin/bookings/9999999")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SPECIAL REQUEST
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void booking_create_withSpecialRequest_stores() throws Exception {
        LocalDate ci = TODAY.plusDays(44);
        LocalDate co = ci.plusDays(1);
        String req = String.format(
            "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\",\"adults\":1," +
            "\"children\":0,\"numberOfRooms\":1,\"specialRequest\":\"Late check-in requested\"}",
            stdTwinRoomId, ci, co);

        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        assertEquals("Late check-in requested",
            mapper.readTree(body).get("specialRequest").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private Long createBooking(String token, Long roomId, LocalDate ci, LocalDate co, int adults)
            throws Exception {
        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(bookingPayload(roomId, ci, co, adults, 0, 1, null)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private String bookingPayload(Long roomId, LocalDate ci, LocalDate co,
                                   int adults, int children, int numRooms, String specialReq) {
        String sr = specialReq == null ? "null" : "\"" + specialReq + "\"";
        return String.format(
            "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\"," +
            "\"adults\":%d,\"children\":%d,\"numberOfRooms\":%d,\"specialRequest\":%s}",
            roomId, ci, co, adults, children, numRooms, sr);
    }
}
