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
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * NotificationTest — Phase 5.4.
 * Uses the SUITE-KNG room, which no other test class books, so day windows
 * here don't need to be coordinated with BookingTest/PaymentTest/ReservationTest.
 */
@SpringBootTest
@AutoConfigureMockMvc
class NotificationTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;

    private String adminToken;
    private String userToken;
    private String partnerToken;
    private Long suiteRoomId;

    private static final LocalDate TODAY = LocalDate.now();
    private static final AtomicInteger dayCursor = new AtomicInteger(1);

    @BeforeEach
    void setup() throws Exception {
        adminToken   = login("admin@planyourtrip.com",   "admin123456");
        userToken    = login("demo@planyourtrip.com",    "demo123456");
        partnerToken = login("partner@planyourtrip.com", "partner123456");

        Long placeId  = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        suiteRoomId = hotelRoomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "SUITE-KNG".equals(r.getRoomCode()))
            .findFirst().orElseThrow().getId();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // BOOKING INTEGRATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void notification_bookingCancel_createsNotification() throws Exception {
        Long bookingId = createBooking();

        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());

        JsonNode arr = getMine(userToken);
        assertTrue(containsTitle(arr, "Booking cancelled"), "Cancelling a booking must create a notification");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PAYMENT INTEGRATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void notification_paymentSuccess_createsPaymentAndBookingNotifications() throws Exception {
        Long bookingId = createBooking();
        Long paymentId = createPayment(bookingId);

        mvc.perform(post("/api/payments/" + paymentId + "/mock-success")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());

        JsonNode arr = getMine(userToken);
        assertTrue(containsTitle(arr, "Payment successful"), "Successful payment must notify");
        assertTrue(containsTitle(arr, "Booking confirmed"), "Confirming a booking must notify");
    }

    @Test
    void notification_paymentFail_createsNotification() throws Exception {
        Long bookingId = createBooking();
        Long paymentId = createPayment(bookingId);

        mvc.perform(post("/api/payments/" + paymentId + "/mock-fail")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());

        JsonNode arr = getMine(userToken);
        assertTrue(containsTitle(arr, "Payment failed"), "Failed payment must notify");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // UNREAD LIST / COUNT
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void notification_unreadList_containsNewNotification() throws Exception {
        Long bookingId = createBooking();
        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());

        String body = mvc.perform(get("/api/me/notifications/unread")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());
        assertTrue(containsTitle(arr, "Booking cancelled"));
        for (JsonNode n : arr) {
            assertFalse(n.get("read").asBoolean(), "Unread list must only contain unread notifications");
        }
    }

    @Test
    void notification_unreadCount_reflectsNewNotification() throws Exception {
        long before = getUnreadCount(userToken);

        Long bookingId = createBooking();
        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());

        long after = getUnreadCount(userToken);
        assertEquals(before + 1, after, "Unread count must increment by exactly one new notification");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MARK READ / MARK ALL READ / DELETE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void notification_markRead_flipsFlag_andLeavesUnreadList() throws Exception {
        Long bookingId = createBooking();
        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());

        Long notifId = findByTitle(getMine(userToken), "Booking cancelled");

        String body = mvc.perform(patch("/api/me/notifications/" + notifId + "/read")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertTrue(res.get("read").asBoolean());
        assertFalse(res.get("readAt").isNull());

        JsonNode unread = mapper.readTree(mvc.perform(get("/api/me/notifications/unread")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertFalse(containsId(unread, notifId), "Read notification must not appear in unread list");
    }

    @Test
    void notification_markAllRead_zeroesUnreadCount() throws Exception {
        Long bookingId = createBooking();
        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());

        assertTrue(getUnreadCount(userToken) > 0);

        mvc.perform(patch("/api/me/notifications/read-all")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());

        assertEquals(0, getUnreadCount(userToken));
    }

    @Test
    void notification_delete_removesFromGetMine() throws Exception {
        Long bookingId = createBooking();
        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());

        Long notifId = findByTitle(getMine(userToken), "Booking cancelled");

        mvc.perform(delete("/api/me/notifications/" + notifId)
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isNoContent());

        assertFalse(containsId(getMine(userToken), notifId), "Deleted notification must not appear in getMine");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // OWNER SECURITY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void notification_markRead_otherUser_returns403() throws Exception {
        Long bookingId = createBooking();
        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());

        Long notifId = findByTitle(getMine(userToken), "Booking cancelled");

        mvc.perform(patch("/api/me/notifications/" + notifId + "/read")
                .header("Authorization", "Bearer " + partnerToken))
            .andExpect(status().isForbidden());
    }

    @Test
    void notification_delete_otherUser_returns403() throws Exception {
        Long bookingId = createBooking();
        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());

        Long notifId = findByTitle(getMine(userToken), "Booking cancelled");

        mvc.perform(delete("/api/me/notifications/" + notifId)
                .header("Authorization", "Bearer " + partnerToken))
            .andExpect(status().isForbidden());
    }

    @Test
    void notification_getMine_unauthenticated_returns401() throws Exception {
        mvc.perform(get("/api/me/notifications"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ADMIN BROADCAST / LIST
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void admin_broadcast_createsNotificationForEveryEnabledUser() throws Exception {
        String body = mvc.perform(post("/api/admin/notifications/broadcast")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"title\":\"Platform maintenance\",\"message\":\"Scheduled maintenance tonight.\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        int recipientCount = Integer.parseInt(body);
        assertTrue(recipientCount >= 3, "Broadcast must reach all enabled demo users");

        assertTrue(containsTitle(getMine(userToken), "Platform maintenance"),
            "Broadcast notification must appear for the demo user");
    }

    @Test
    void admin_broadcast_forbiddenForUser_returns403() throws Exception {
        mvc.perform(post("/api/admin/notifications/broadcast")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"title\":\"Hi\",\"message\":\"Hi there\"}"))
            .andExpect(status().isForbidden());
    }

    @Test
    void admin_listNotifications_returns200() throws Exception {
        Long bookingId = createBooking();
        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());

        String body = mvc.perform(get("/api/admin/notifications")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());
        assertTrue(arr.size() >= 1);
    }

    @Test
    void admin_listNotifications_forbiddenForUser_returns403() throws Exception {
        mvc.perform(get("/api/admin/notifications")
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

    private Long createBooking() throws Exception {
        LocalDate ci = TODAY.plusDays(dayCursor.getAndAdd(3));
        LocalDate co = ci.plusDays(2);

        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format(
                    "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\",\"adults\":2,\"children\":0,\"numberOfRooms\":1}",
                    suiteRoomId, ci, co)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
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

    private JsonNode getMine(String token) throws Exception {
        String body = mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private long getUnreadCount(String token) throws Exception {
        String body = mvc.perform(get("/api/me/notifications/unread-count")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return Long.parseLong(body);
    }

    private boolean containsTitle(JsonNode arr, String title) {
        for (JsonNode n : arr) {
            if (title.equals(n.get("title").asText())) return true;
        }
        return false;
    }

    private boolean containsId(JsonNode arr, Long id) {
        for (JsonNode n : arr) {
            if (n.get("id").asLong() == id) return true;
        }
        return false;
    }

    private Long findByTitle(JsonNode arr, String title) {
        for (JsonNode n : arr) {
            if (title.equals(n.get("title").asText())) return n.get("id").asLong();
        }
        throw new AssertionError("No notification found with title: " + title);
    }
}
