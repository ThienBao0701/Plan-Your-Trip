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
 * TripTimelineTest — Phase 7.10.
 * Every scenario registers its own throwaway owner and, where needed, throwaway
 * collaborator users, and creates its own trip — timeline/reminder state is
 * trip-specific and must not leak across tests.
 */
@SpringBootTest
@AutoConfigureMockMvc
class TripTimelineTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;

    private static final AtomicInteger counter = new AtomicInteger(1);

    // ═══════════════════════════════════════════════════════════════════════════
    // TIMELINE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void timelineReturnsItineraryItems() throws Exception {
        String token = registerAndLogin("timeline-items");
        Long tripId = createTrip(token, "Timeline Items Trip", "Lisbon", "2029-11-01", "2029-11-05");
        Long dayId = addDay(token, tripId, 1, "2029-11-01");
        addItem(token, dayId, "{\"customTitle\":\"City walking tour\",\"startTime\":\"09:00:00\"}");

        String body = mvc.perform(get("/api/me/trips/" + tripId + "/timeline")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode items = mapper.readTree(body).get("items");
        boolean hasDay = false, hasItem = false;
        for (JsonNode n : items) {
            if (n.get("type").asText().equals("DAY")) hasDay = true;
            if (n.get("type").asText().equals("ITEM") && n.get("title").asText().equals("City walking tour")) hasItem = true;
        }
        assertTrue(hasDay, "Timeline must include the day");
        assertTrue(hasItem, "Timeline must include the itinerary item");
    }

    @Test
    void timelineIncludesDocuments() throws Exception {
        String token = registerAndLogin("timeline-docs");
        Long tripId = createTrip(token, "Timeline Docs Trip", "Porto", "2029-11-10", "2029-11-15");
        addDocument(token, tripId, "https://cdn.example.com/ticket.pdf", "DOCUMENT", "FLIGHT_TICKET", "Boarding pass");

        String body = mvc.perform(get("/api/me/trips/" + tripId + "/timeline")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode items = mapper.readTree(body).get("items");
        boolean hasDocument = false;
        for (JsonNode n : items) {
            if (n.get("type").asText().equals("DOCUMENT") && n.get("title").asText().equals("Boarding pass")) hasDocument = true;
        }
        assertTrue(hasDocument, "Timeline must include the document");
    }

    @Test
    void timelineIncludesReminders() throws Exception {
        String token = registerAndLogin("timeline-reminders");
        Long tripId = createTrip(token, "Timeline Reminders Trip", "Braga", "2029-11-20", "2029-11-25");
        addReminder(token, tripId, reminderPayload(null, null, null, "CHECK_IN", "Online check-in",
            "Check in 24h before flight", "2029-11-19T10:00:00Z"));

        String body = mvc.perform(get("/api/me/trips/" + tripId + "/timeline")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode items = mapper.readTree(body).get("items");
        boolean hasReminder = false;
        for (JsonNode n : items) {
            if (n.get("type").asText().equals("REMINDER") && n.get("title").asText().equals("Online check-in")) hasReminder = true;
        }
        assertTrue(hasReminder, "Timeline must include the reminder");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // REMINDER CREATE PERMISSIONS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void ownerCreatesReminder() throws Exception {
        String token = registerAndLogin("reminder-owner");
        Long tripId = createTrip(token, "Reminder Owner Trip", "Coimbra", "2029-12-01", "2029-12-05");

        String body = addReminder(token, tripId, reminderPayload(null, null, null, "CUSTOM", "Pack sunscreen",
            null, "2029-11-30T08:00:00Z"));

        JsonNode res = mapper.readTree(body);
        assertEquals("Pack sunscreen", res.get("title").asText());
        assertEquals("PENDING", res.get("status").asText());
        assertNotNull(res.get("userId"));
    }

    @Test
    void editorCreatesReminder() throws Exception {
        String ownerToken = registerAndLogin("reminder-editor-owner");
        String editorToken = registerAndLogin("reminder-editor-editor");
        Long tripId = createTrip(ownerToken, "Reminder Editor Trip", "Faro", "2029-12-10", "2029-12-15");
        invite(ownerToken, tripId, emailOf(editorToken), "EDITOR");

        mvc.perform(post("/api/me/trips/" + tripId + "/reminders")
                .header("Authorization", "Bearer " + editorToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(reminderPayload(null, null, null, "ACTIVITY", "Book kayak tour", null, "2029-12-11T09:00:00Z")))
            .andExpect(status().isCreated());
    }

    @Test
    void viewerCannotCreateReminder() throws Exception {
        String ownerToken = registerAndLogin("reminder-viewer-owner");
        String viewerToken = registerAndLogin("reminder-viewer-viewer");
        Long tripId = createTrip(ownerToken, "Reminder Viewer Trip", "Aveiro", "2029-12-20", "2029-12-25");
        invite(ownerToken, tripId, emailOf(viewerToken), "VIEWER");

        mvc.perform(post("/api/me/trips/" + tripId + "/reminders")
                .header("Authorization", "Bearer " + viewerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(reminderPayload(null, null, null, "CUSTOM", "Sneaky reminder", null, "2029-12-21T09:00:00Z")))
            .andExpect(status().isForbidden());
    }

    @Test
    void viewerCanReadReminders() throws Exception {
        String ownerToken = registerAndLogin("reminder-viewerread-owner");
        String viewerToken = registerAndLogin("reminder-viewerread-viewer");
        Long tripId = createTrip(ownerToken, "Reminder Viewer Read Trip", "Evora", "2030-01-01", "2030-01-05");
        invite(ownerToken, tripId, emailOf(viewerToken), "VIEWER");
        addReminder(ownerToken, tripId, reminderPayload(null, null, null, "OTHER", "Buy travel adapter", null, "2029-12-31T09:00:00Z"));

        String body = mvc.perform(get("/api/me/trips/" + tripId + "/reminders")
                .header("Authorization", "Bearer " + viewerToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals(1, mapper.readTree(body).size());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // UPDATE / COMPLETE / CANCEL / DELETE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void updateReminder_succeeds() throws Exception {
        String token = registerAndLogin("reminder-update");
        Long tripId = createTrip(token, "Reminder Update Trip", "Setubal", "2030-01-10", "2030-01-15");
        Long reminderId = mapper.readTree(addReminder(token, tripId,
            reminderPayload(null, null, null, "CUSTOM", "Old title", null, "2030-01-09T09:00:00Z")))
            .get("id").asLong();

        String body = mvc.perform(put("/api/me/trips/reminders/" + reminderId)
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(reminderPayload(null, null, null, "CUSTOM", "New title", "Updated message", "2030-01-09T12:00:00Z")))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("New title", res.get("title").asText());
        assertEquals("Updated message", res.get("message").asText());
    }

    @Test
    void completeReminder_setsCompletedAt() throws Exception {
        String token = registerAndLogin("reminder-complete");
        Long tripId = createTrip(token, "Reminder Complete Trip", "Sintra", "2030-01-20", "2030-01-25");
        Long reminderId = mapper.readTree(addReminder(token, tripId,
            reminderPayload(null, null, null, "PAYMENT", "Pay hotel deposit", null, "2030-01-19T09:00:00Z")))
            .get("id").asLong();

        String body = mvc.perform(patch("/api/me/trips/reminders/" + reminderId + "/complete")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("COMPLETED", res.get("status").asText());
        assertFalse(res.get("completedAt").isNull());
    }

    @Test
    void cancelReminder_succeeds() throws Exception {
        String token = registerAndLogin("reminder-cancel");
        Long tripId = createTrip(token, "Reminder Cancel Trip", "Cascais", "2030-02-01", "2030-02-05");
        Long reminderId = mapper.readTree(addReminder(token, tripId,
            reminderPayload(null, null, null, "PACKING", "Buy travel pillow", null, "2030-01-31T09:00:00Z")))
            .get("id").asLong();

        String body = mvc.perform(patch("/api/me/trips/reminders/" + reminderId + "/cancel")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals("CANCELLED", mapper.readTree(body).get("status").asText());

        String defaultList = mvc.perform(get("/api/me/trips/" + tripId + "/reminders")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals(0, mapper.readTree(defaultList).size(), "Cancelled reminders must be hidden by default");

        String withCancelled = mvc.perform(get("/api/me/trips/" + tripId + "/reminders?includeCancelled=true")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals(1, mapper.readTree(withCancelled).size(), "includeCancelled=true must return it explicitly");
    }

    @Test
    void deleteReminder_succeeds() throws Exception {
        String token = registerAndLogin("reminder-delete");
        Long tripId = createTrip(token, "Reminder Delete Trip", "Guimaraes", "2030-02-10", "2030-02-15");
        Long reminderId = mapper.readTree(addReminder(token, tripId,
            reminderPayload(null, null, null, "OTHER", "Confirm airport transfer", null, "2030-02-09T09:00:00Z")))
            .get("id").asLong();

        mvc.perform(delete("/api/me/trips/reminders/" + reminderId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNoContent());

        String body = mvc.perform(get("/api/me/trips/" + tripId + "/reminders")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals(0, mapper.readTree(body).size());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CROSS-TRIP VALIDATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void crossTripLink_rejected() throws Exception {
        String token = registerAndLogin("reminder-crosstrip");
        Long tripA = createTrip(token, "Trip A", "Trento", "2030-02-20", "2030-02-25");
        Long tripB = createTrip(token, "Trip B", "Bolzano", "2030-03-01", "2030-03-05");
        Long dayInTripB = addDay(token, tripB, 1, "2030-03-01");

        mvc.perform(post("/api/me/trips/" + tripA + "/reminders")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(reminderPayload(dayInTripB, null, null, "CUSTOM", "Cross-trip reminder", null, "2030-02-19T09:00:00Z")))
            .andExpect(status().isBadRequest());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CASCADE (bonus — verifies the deleteTrip ordering fix)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void deleteTrip_withLinkedReminderDayItemDocument_doesNotFail() throws Exception {
        String token = registerAndLogin("reminder-cascade");
        Long tripId = createTrip(token, "Cascade Trip", "Matera", "2030-03-10", "2030-03-15");
        Long dayId = addDay(token, tripId, 1, "2030-03-10");
        Long itemId = mapper.readTree(addItem(token, dayId, "{\"customTitle\":\"Cave tour\"}")).get("id").asLong();
        Long docId = addDocumentRaw(token, tripId,
            "https://cdn.example.com/cave-ticket.pdf", "DOCUMENT", "TOUR", "Cave tour ticket").get("id").asLong();
        addReminder(token, tripId, reminderPayload(dayId, itemId, docId, "ACTIVITY", "Bring flashlight", null, "2030-03-09T09:00:00Z"));

        mvc.perform(delete("/api/me/trips/" + tripId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNoContent());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // AUTH
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void unauthenticated_rejected() throws Exception {
        mvc.perform(get("/api/me/trips/1/timeline"))
            .andExpect(status().isUnauthorized());
        mvc.perform(get("/api/me/trips/1/reminders"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

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

    private Long addDay(String token, Long tripId, int dayNumber, String date) throws Exception {
        String body = mvc.perform(post("/api/me/trips/" + tripId + "/days")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"dayNumber\":" + dayNumber + ",\"date\":\"" + date + "\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private String addItem(String token, Long dayId, String itemJson) throws Exception {
        return mvc.perform(post("/api/me/trips/days/" + dayId + "/items")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(itemJson))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
    }

    private String collaboratorPayload(String email, String role) {
        return "{\"email\":\"" + email + "\",\"role\":\"" + role + "\"}";
    }

    private void invite(String ownerToken, Long tripId, String email, String role) throws Exception {
        mvc.perform(post("/api/me/trips/" + tripId + "/collaborators")
                .header("Authorization", "Bearer " + ownerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(collaboratorPayload(email, role)))
            .andExpect(status().isCreated());
    }

    private void addDocument(String token, Long tripId, String url, String mediaType, String documentType, String title) throws Exception {
        addDocumentRaw(token, tripId, url, mediaType, documentType, title);
    }

    private JsonNode addDocumentRaw(String token, Long tripId, String url, String mediaType, String documentType, String title) throws Exception {
        String payload = "{\"tripDayId\":null,\"tripItemId\":null,\"mediaAssetId\":null"
            + ",\"url\":\"" + url + "\",\"thumbnailUrl\":null,\"mediaType\":\"" + mediaType + "\",\"altText\":null"
            + ",\"documentType\":\"" + documentType + "\",\"title\":\"" + title + "\",\"notes\":null}";
        String body = mvc.perform(post("/api/me/trips/" + tripId + "/documents")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private String reminderPayload(Long tripDayId, Long tripItemId, Long documentId, String reminderType,
                                    String title, String message, String reminderAt) {
        return "{\"tripDayId\":" + tripDayId
            + ",\"tripItemId\":" + tripItemId
            + ",\"documentId\":" + documentId
            + ",\"reminderType\":\"" + reminderType + "\""
            + ",\"title\":\"" + title + "\""
            + ",\"message\":" + (message == null ? "null" : "\"" + message + "\"")
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

    private String emailOf(String token) throws Exception {
        String body = mvc.perform(get("/api/me")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("email").asText();
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
