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

/**
 * ReservationTest — Phase 5.3.
 * Uses DLX-KING room (days 1–57 in 3-day windows) to avoid inventory
 * conflicts with BookingTest (STD-TWIN, days 3–44) and
 * PaymentTest (STD-TWIN, days 45–88).
 */
@SpringBootTest
@AutoConfigureMockMvc
class ReservationTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;

    private String adminToken;
    private String userToken;
    private Long dlxKingRoomId;

    private static final LocalDate TODAY = LocalDate.now();

    @BeforeEach
    void setup() throws Exception {
        adminToken = login("admin@planyourtrip.com", "admin123456");
        userToken  = login("demo@planyourtrip.com",  "demo123456");

        Long placeId  = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        dlxKingRoomId = hotelRoomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "DLX-KING".equals(r.getRoomCode()))
            .findFirst().orElseThrow().getId();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HAPPY-PATH STATUS TRANSITIONS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void reservation_adminCheckIn_confirmedBooking_setsCheckedIn() throws Exception {
        Long bookingId = createAndConfirm(TODAY.plusDays(1), TODAY.plusDays(3));

        String body = mvc.perform(patch("/api/admin/bookings/" + bookingId + "/check-in")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("CHECKED_IN", res.get("status").asText());
        assertFalse(res.get("actualCheckInAt").isNull());
        assertFalse(res.get("lastStatusChangedAt").isNull());
    }

    @Test
    void reservation_adminCheckOut_checkedInBooking_setsCheckedOut() throws Exception {
        Long bookingId = createAndConfirm(TODAY.plusDays(4), TODAY.plusDays(6));

        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/check-in")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());

        String body = mvc.perform(patch("/api/admin/bookings/" + bookingId + "/check-out")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("CHECKED_OUT", res.get("status").asText());
        assertFalse(res.get("actualCheckOutAt").isNull());
    }

    @Test
    void reservation_adminComplete_checkedOutBooking_setsCompleted() throws Exception {
        Long bookingId = createAndConfirm(TODAY.plusDays(7), TODAY.plusDays(9));
        adminCheckIn(bookingId);
        adminCheckOut(bookingId);

        String body = mvc.perform(patch("/api/admin/bookings/" + bookingId + "/complete")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("COMPLETED", res.get("status").asText());
        assertFalse(res.get("completedAt").isNull());
    }

    @Test
    void reservation_adminArchive_completedBooking_setsArchived() throws Exception {
        Long bookingId = createAndConfirm(TODAY.plusDays(10), TODAY.plusDays(12));
        adminCheckIn(bookingId);
        adminCheckOut(bookingId);
        adminComplete(bookingId);

        String body = mvc.perform(patch("/api/admin/bookings/" + bookingId + "/archive")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("ARCHIVED", res.get("status").asText());
        assertFalse(res.get("archivedAt").isNull());
    }

    @Test
    void reservation_checkInReady_toCheckedIn() throws Exception {
        Long bookingId = createAndConfirm(TODAY.plusDays(13), TODAY.plusDays(15));

        // CONFIRMED → CHECK_IN_READY (via force-set since engine doesn't expose this dedicated endpoint)
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/status")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"CHECK_IN_READY\"}"))
            .andExpect(status().isOk());

        String body = mvc.perform(patch("/api/admin/bookings/" + bookingId + "/check-in")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals("CHECKED_IN", mapper.readTree(body).get("status").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ILLEGAL TRANSITIONS — engine enforcement
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void reservation_checkIn_pendingBooking_returns422() throws Exception {
        Long bookingId = createBooking(TODAY.plusDays(16), TODAY.plusDays(18));

        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/check-in")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void reservation_checkIn_checkedOutBooking_returns422() throws Exception {
        Long bookingId = createAndConfirm(TODAY.plusDays(19), TODAY.plusDays(21));
        adminCheckIn(bookingId);
        adminCheckOut(bookingId);

        // CHECKED_OUT → CHECKED_IN is illegal
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/check-in")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void reservation_checkOut_pendingBooking_returns422() throws Exception {
        Long bookingId = createBooking(TODAY.plusDays(22), TODAY.plusDays(24));

        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/check-out")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void reservation_complete_checkedInBooking_returns422() throws Exception {
        Long bookingId = createAndConfirm(TODAY.plusDays(25), TODAY.plusDays(27));
        adminCheckIn(bookingId);

        // CHECKED_IN → COMPLETED is illegal (must go through CHECKED_OUT first)
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/complete")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void reservation_archive_pendingBooking_returns422() throws Exception {
        Long bookingId = createBooking(TODAY.plusDays(28), TODAY.plusDays(30));

        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/archive")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void reservation_archive_checkedOutBooking_returns422() throws Exception {
        Long bookingId = createAndConfirm(TODAY.plusDays(31), TODAY.plusDays(33));
        adminCheckIn(bookingId);
        adminCheckOut(bookingId);

        // CHECKED_OUT → ARCHIVED requires going through COMPLETED first
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/archive")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isUnprocessableEntity());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CANCEL WITH REASON
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void reservation_cancel_withReason_storesReason() throws Exception {
        Long bookingId = createBooking(TODAY.plusDays(34), TODAY.plusDays(36));

        String body = mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"cancelReason\":\"Change of plans\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("CANCELLED",       res.get("status").asText());
        assertEquals("Change of plans", res.get("cancelReason").asText());
    }

    @Test
    void reservation_cancel_checkInReady_returns422() throws Exception {
        Long bookingId = createAndConfirm(TODAY.plusDays(37), TODAY.plusDays(39));

        // Force CHECK_IN_READY
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/status")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"CHECK_IN_READY\"}"))
            .andExpect(status().isOk());

        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isUnprocessableEntity());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // USER VIEWS: upcoming / history / active
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void reservation_upcoming_returnsPendingBookings() throws Exception {
        Long bookingId = createBooking(TODAY.plusDays(40), TODAY.plusDays(42));

        String body = mvc.perform(get("/api/me/bookings/upcoming")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());
        boolean found = false;
        for (JsonNode n : arr) {
            if (n.get("id").asLong() == bookingId) { found = true; break; }
        }
        assertTrue(found, "New PENDING booking must appear in upcoming");
    }

    @Test
    void reservation_upcoming_confirmedBooking_appearsInUpcoming() throws Exception {
        Long bookingId = createAndConfirm(TODAY.plusDays(43), TODAY.plusDays(45));

        String body = mvc.perform(get("/api/me/bookings/upcoming")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        boolean found = false;
        for (JsonNode n : arr) {
            if (n.get("id").asLong() == bookingId) { found = true; break; }
        }
        assertTrue(found, "CONFIRMED booking must appear in upcoming");
    }

    @Test
    void reservation_history_cancelledBooking_appearsInHistory() throws Exception {
        Long bookingId = createBooking(TODAY.plusDays(46), TODAY.plusDays(48));

        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());

        String body = mvc.perform(get("/api/me/bookings/history")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());
        boolean found = false;
        for (JsonNode n : arr) {
            if (n.get("id").asLong() == bookingId) { found = true; break; }
        }
        assertTrue(found, "Cancelled booking must appear in history");
    }

    @Test
    void reservation_active_checkedInBooking_appearsInActive() throws Exception {
        Long bookingId = createAndConfirm(TODAY.plusDays(53), TODAY.plusDays(55));
        adminCheckIn(bookingId);

        String body = mvc.perform(get("/api/me/bookings/active")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());
        boolean found = false;
        for (JsonNode n : arr) {
            if (n.get("id").asLong() == bookingId) { found = true; break; }
        }
        assertTrue(found, "CHECKED_IN booking must appear in active");
    }

    @Test
    void reservation_upcoming_unauthenticated_returns401() throws Exception {
        mvc.perform(get("/api/me/bookings/upcoming"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // TIMELINE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void reservation_timeline_createdEvent_present() throws Exception {
        Long bookingId = createBooking(TODAY.plusDays(56), TODAY.plusDays(58));

        String body = mvc.perform(get("/api/bookings/" + bookingId + "/timeline")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals(bookingId, res.get("bookingId").asLong());
        assertNotNull(res.get("bookingCode"));
        JsonNode events = res.get("events");
        assertTrue(events.isArray());
        assertTrue(events.size() >= 1);
        assertEquals("CREATED", events.get(0).get("event").asText());
    }

    @Test
    void reservation_timeline_paid_confirmedEvents_present() throws Exception {
        Long bookingId = createAndConfirm(TODAY.plusDays(58), TODAY.plusDays(60));

        String body = mvc.perform(get("/api/bookings/" + bookingId + "/timeline")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode events = mapper.readTree(body).get("events");
        boolean hasPaid = false, hasConfirmed = false;
        for (JsonNode e : events) {
            if ("PAID".equals(e.get("event").asText()))      hasPaid = true;
            if ("CONFIRMED".equals(e.get("event").asText())) hasConfirmed = true;
        }
        assertTrue(hasPaid,      "Timeline must contain PAID event after mock-success");
        assertTrue(hasConfirmed, "Timeline must contain CONFIRMED event");
    }

    @Test
    void reservation_adminTimeline_accessible() throws Exception {
        Long bookingId = createBooking(TODAY.plusDays(60), TODAY.plusDays(62));

        mvc.perform(get("/api/admin/bookings/" + bookingId + "/timeline")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());
    }

    @Test
    void reservation_timeline_otherUser_returns403() throws Exception {
        Long bookingId = createBooking(TODAY.plusDays(62), TODAY.plusDays(64));

        // partner cannot view user's timeline
        String partnerToken = login("partner@planyourtrip.com", "partner123456");
        mvc.perform(get("/api/bookings/" + bookingId + "/timeline")
                .header("Authorization", "Bearer " + partnerToken))
            .andExpect(status().isForbidden());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ADMIN SEARCH
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void reservation_adminSearch_byStatus_returnsList() throws Exception {
        String body = mvc.perform(get("/api/admin/bookings?status=CONFIRMED")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());
        for (JsonNode n : arr) {
            assertEquals("CONFIRMED", n.get("status").asText(),
                "All results must have CONFIRMED status");
        }
    }

    @Test
    void reservation_adminSearch_byGuest_returnsMatchingBookings() throws Exception {
        String body = mvc.perform(get("/api/admin/bookings?guest=demo")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());
        assertTrue(arr.size() >= 1, "Should find bookings for guest 'demo'");
    }

    @Test
    void reservation_adminSearch_noParams_returnsAll() throws Exception {
        // No filter params — falls through to adminGetAll()
        String body = mvc.perform(get("/api/admin/bookings")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());
        assertTrue(arr.size() >= 2);
    }

    @Test
    void reservation_adminSearch_forbiddenForUser_returns403() throws Exception {
        mvc.perform(get("/api/admin/bookings?status=PENDING")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isForbidden());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // NEW RESPONSE FIELDS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void reservation_bookingResponse_hasNewFields() throws Exception {
        Long bookingId = createAndConfirm(TODAY.plusDays(64), TODAY.plusDays(66));
        adminCheckIn(bookingId);

        String body = mvc.perform(get("/api/bookings/" + bookingId)
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertTrue(res.has("actualCheckInAt"),    "Response must have actualCheckInAt");
        assertTrue(res.has("actualCheckOutAt"),   "Response must have actualCheckOutAt");
        assertTrue(res.has("completedAt"),        "Response must have completedAt");
        assertTrue(res.has("archivedAt"),         "Response must have archivedAt");
        assertTrue(res.has("lastStatusChangedAt"),"Response must have lastStatusChangedAt");
        assertTrue(res.has("cancelReason"),       "Response must have cancelReason");

        assertFalse(res.get("actualCheckInAt").isNull(),    "actualCheckInAt must be set after check-in");
        assertFalse(res.get("lastStatusChangedAt").isNull(),"lastStatusChangedAt must be set");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SECURITY — admin-only check
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void reservation_checkIn_forbiddenForUser_returns403() throws Exception {
        Long bookingId = createAndConfirm(TODAY.plusDays(66), TODAY.plusDays(68));

        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/check-in")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isForbidden());
    }

    @Test
    void reservation_checkOut_forbiddenForUser_returns403() throws Exception {
        Long bookingId = createAndConfirm(TODAY.plusDays(68), TODAY.plusDays(70));
        adminCheckIn(bookingId);

        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/check-out")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isForbidden());
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

    /** Create a PENDING booking (no payment). */
    private Long createBooking(LocalDate ci, LocalDate co) throws Exception {
        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format(
                    "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\",\"adults\":2,\"children\":0,\"numberOfRooms\":1}",
                    dlxKingRoomId, ci, co)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    /** Create a booking, then pay and confirm it → CONFIRMED. */
    private Long createAndConfirm(LocalDate ci, LocalDate co) throws Exception {
        Long bookingId = createBooking(ci, co);
        Long paymentId = createPayment(bookingId);
        mockSuccess(paymentId);
        return bookingId;
    }

    private Long createPayment(Long bookingId) throws Exception {
        String body = mvc.perform(post("/api/payments")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"paymentMethod\":\"MOCK\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private void mockSuccess(Long paymentId) throws Exception {
        mvc.perform(post("/api/payments/" + paymentId + "/mock-success")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());
    }

    private void adminCheckIn(Long bookingId) throws Exception {
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/check-in")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());
    }

    private void adminCheckOut(Long bookingId) throws Exception {
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/check-out")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());
    }

    private void adminComplete(Long bookingId) throws Exception {
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/complete")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());
    }
}
