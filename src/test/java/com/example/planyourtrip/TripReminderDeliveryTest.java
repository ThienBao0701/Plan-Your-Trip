package com.example.planyourtrip;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * TripReminderDeliveryTest — Phase 7.11 (Reminder Delivery Foundation).
 * Delivers due TripPlanReminders into the existing in-app Notification
 * system. No email/push/WebSocket/scheduler in this phase — delivery is
 * triggered manually via the admin endpoints exercised below.
 *
 * Every scenario registers its own throwaway user and creates its own trip,
 * mirroring TripTimelineTest's convention so reminder/notification state
 * never leaks across tests. The seeded admin@planyourtrip.com account (see
 * AdminPlaceCrudTest / NotificationTest) is reused for admin-trigger checks.
 */
@SpringBootTest
@AutoConfigureMockMvc
class TripReminderDeliveryTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;

    private static final AtomicInteger counter = new AtomicInteger(1);

    // ═══════════════════════════════════════════════════════════════════════════
    // USER-FACING: GET /api/me/trips/reminders/due
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void userListsOwnDueReminders() throws Exception {
        String token = registerAndLogin("due-list");
        Long tripId = createTrip(token, "Due List Trip", "Lisbon", "2020-01-01", "2020-01-05");
        addReminder(token, tripId, reminderPayload("CUSTOM", "Overdue check-in", "2020-01-01T09:00:00Z"));

        String body = mvc.perform(get("/api/me/trips/reminders/due")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertEquals(1, arr.size());
        assertEquals("Overdue check-in", arr.get(0).get("title").asText());
    }

    @Test
    void futureReminderNotDue() throws Exception {
        String token = registerAndLogin("due-future");
        Long tripId = createTrip(token, "Future Trip", "Porto", "2030-01-01", "2030-01-05");
        addReminder(token, tripId, reminderPayload("CUSTOM", "Future reminder", "2099-01-01T09:00:00Z"));

        String body = mvc.perform(get("/api/me/trips/reminders/due")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals(0, mapper.readTree(body).size(), "Future reminder must not be in the due list");
    }

    @Test
    void deliveredReminderNotDue() throws Exception {
        String token = registerAndLogin("due-delivered");
        Long tripId = createTrip(token, "Delivered Trip", "Braga", "2020-01-01", "2020-01-05");
        Long reminderId = addReminderId(token, tripId, reminderPayload("CUSTOM", "Already delivered", "2020-01-01T09:00:00Z"));

        adminDeliverSingle(reminderId);

        String body = mvc.perform(get("/api/me/trips/reminders/due")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals(0, mapper.readTree(body).size(), "Already-delivered reminder must be excluded from the due list");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ADMIN DELIVERY TRIGGERS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void adminDeliverDueCreatesNotification() throws Exception {
        String token = registerAndLogin("deliver-due-notif");
        Long tripId = createTrip(token, "Deliver Due Trip", "Faro", "2020-01-01", "2020-01-05");
        addReminder(token, tripId, reminderPayload("CUSTOM", "Bulk deliver me", "2020-01-01T09:00:00Z"));

        String resultBody = mvc.perform(post("/api/admin/trip-reminders/deliver-due")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode result = mapper.readTree(resultBody);
        assertTrue(result.get("delivered").asInt() >= 1);

        String mine = mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertTrue(containsTitle(mapper.readTree(mine), "Bulk deliver me"));
    }

    @Test
    void adminDeliverSingleCreatesNotification() throws Exception {
        String token = registerAndLogin("deliver-single-notif");
        Long tripId = createTrip(token, "Deliver Single Trip", "Evora", "2020-01-01", "2020-01-05");
        Long reminderId = addReminderId(token, tripId, reminderPayload("CUSTOM", "Deliver me solo", "2020-01-01T09:00:00Z"));

        JsonNode result = adminDeliverSingle(reminderId);
        assertEquals(1, result.get("delivered").asInt());

        String mine = mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertTrue(containsTitle(mapper.readTree(mine), "Deliver me solo"));
    }

    @Test
    void deliverySetsDeliveredAt() throws Exception {
        String token = registerAndLogin("deliver-sets-at");
        Long tripId = createTrip(token, "Delivered At Trip", "Sintra", "2020-01-01", "2020-01-05");
        Long reminderId = addReminderId(token, tripId, reminderPayload("CUSTOM", "Stamp delivered at", "2020-01-01T09:00:00Z"));

        adminDeliverSingle(reminderId);

        // deliveredAt is not exposed on TripPlanReminderResponse; verify indirectly
        // via idempotency — the reminder must now be gone from the due list.
        String body = mvc.perform(get("/api/me/trips/reminders/due")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals(0, mapper.readTree(body).size());
    }

    @Test
    void deliveryIncrementsDeliveryAttempts() throws Exception {
        String token = registerAndLogin("deliver-attempts");
        Long tripId = createTrip(token, "Attempts Trip", "Cascais", "2020-01-01", "2020-01-05");
        Long reminderId = addReminderId(token, tripId, reminderPayload("CUSTOM", "Count my attempts", "2020-01-01T09:00:00Z"));

        JsonNode first = adminDeliverSingle(reminderId);
        assertEquals(1, first.get("totalAttempted").asInt());
        assertEquals(1, first.get("delivered").asInt());

        // Second call is a no-op skip (idempotent) — attempted count reflects the call, not a real attempt.
        JsonNode second = adminDeliverSingle(reminderId);
        assertEquals(0, second.get("delivered").asInt());
        assertEquals(1, second.get("skipped").asInt());
    }

    @Test
    void deliveryIsIdempotent_noDuplicateNotification() throws Exception {
        String token = registerAndLogin("deliver-idempotent");
        Long tripId = createTrip(token, "Idempotent Trip", "Guimaraes", "2020-01-01", "2020-01-05");
        Long reminderId = addReminderId(token, tripId, reminderPayload("CUSTOM", "Only once please", "2020-01-01T09:00:00Z"));

        adminDeliverSingle(reminderId);
        adminDeliverSingle(reminderId);
        adminDeliverSingle(reminderId);

        String mine = mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals(1, countTitle(mapper.readTree(mine), "Only once please"),
            "Repeated delivery of an already-delivered reminder must not duplicate the notification");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SECURITY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void nonAdminCannotTriggerDelivery() throws Exception {
        String token = registerAndLogin("non-admin-trigger");

        mvc.perform(post("/api/admin/trip-reminders/deliver-due")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());

        mvc.perform(post("/api/admin/trip-reminders/1/deliver")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
    }

    @Test
    void unauthenticatedRejected() throws Exception {
        mvc.perform(get("/api/me/trips/reminders/due"))
            .andExpect(status().isUnauthorized());
        mvc.perform(post("/api/admin/trip-reminders/deliver-due"))
            .andExpect(status().isUnauthorized());
        mvc.perform(post("/api/admin/trip-reminders/1/deliver"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private String adminTokenCache;

    private String adminToken() throws Exception {
        if (adminTokenCache == null) {
            String body = mvc.perform(post("/api/auth/login")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("{\"email\":\"admin@planyourtrip.com\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
            adminTokenCache = mapper.readTree(body).get("token").asText();
        }
        return adminTokenCache;
    }

    private JsonNode adminDeliverSingle(Long reminderId) throws Exception {
        String body = mvc.perform(post("/api/admin/trip-reminders/" + reminderId + "/deliver")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private boolean containsTitle(JsonNode arr, String title) {
        for (JsonNode n : arr) {
            if (n.get("title").asText().equals(title)) return true;
        }
        return false;
    }

    private long countTitle(JsonNode arr, String title) {
        long count = 0;
        for (JsonNode n : arr) {
            if (n.get("title").asText().equals(title)) count++;
        }
        return count;
    }

    private String tripPayload(String title, String destination, String startDate, String endDate) {
        return """
                {"title":"%s","description":"A test trip","destination":"%s","coverImage":"https://cdn.example.com/cover.jpg",
                 "startDate":"%s","endDate":"%s","status":"PLANNING","isPublic":false}
                """.formatted(title, destination, startDate, endDate);
    }

    private Long createTrip(String token, String title, String destination, String startDate, String endDate) throws Exception {
        String body = mvc.perform(post("/api/me/trips")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(tripPayload(title, destination, startDate, endDate)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private String reminderPayload(String reminderType, String title, String reminderAt) {
        return "{\"tripDayId\":null,\"tripItemId\":null,\"documentId\":null"
            + ",\"reminderType\":\"" + reminderType + "\""
            + ",\"title\":\"" + title + "\""
            + ",\"message\":null"
            + ",\"reminderAt\":\"" + reminderAt + "\"}";
    }

    private String addReminder(String token, Long tripId, String payload) throws Exception {
        return mvc.perform(post("/api/me/trips/" + tripId + "/reminders")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
    }

    private Long addReminderId(String token, Long tripId, String payload) throws Exception {
        return mapper.readTree(addReminder(token, tripId, payload)).get("id").asLong();
    }

    private String registerAndLogin(String namePrefix) throws Exception {
        String email = namePrefix + "-" + counter.getAndIncrement() + "@test.com";
        String body = mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"" + namePrefix + " Tester\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }
}
