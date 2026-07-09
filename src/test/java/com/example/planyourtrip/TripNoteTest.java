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
 * TripNoteTest — Phase 7.8.
 * Every scenario registers its own throwaway owner and, where needed, throwaway
 * collaborator users, and creates its own trip — note state is trip-specific and
 * must not leak across tests.
 */
@SpringBootTest
@AutoConfigureMockMvc
class TripNoteTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;

    private static final AtomicInteger counter = new AtomicInteger(1);

    // ═══════════════════════════════════════════════════════════════════════════
    // CREATE PERMISSIONS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void ownerCreatesNote() throws Exception {
        String token = registerAndLogin("note-owner");
        Long tripId = createTrip(token, "Note Owner Trip", "Bali", "2029-02-01", "2029-02-05");

        String body = mvc.perform(post("/api/me/trips/" + tripId + "/notes")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(notePayload(null, null, "NOTE", "Packing reminder", "Don't forget the charger", "NEUTRAL", null)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("NOTE", res.get("noteType").asText());
        assertEquals("Don't forget the charger", res.get("content").asText());
        assertFalse(res.get("pinned").asBoolean());
        assertNotNull(res.get("authorUserId"));
    }

    @Test
    void editorCreatesJournalEntry() throws Exception {
        String ownerToken = registerAndLogin("note-editor-owner");
        String editorToken = registerAndLogin("note-editor-editor");
        Long tripId = createTrip(ownerToken, "Journal Editor Trip", "Kyoto", "2029-02-10", "2029-02-15");
        invite(ownerToken, tripId, emailOf(editorToken), "EDITOR");

        String body = mvc.perform(post("/api/me/trips/" + tripId + "/notes")
                .header("Authorization", "Bearer " + editorToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(notePayload(null, null, "JOURNAL", "Day one", "What an amazing first day!", "EXCITED", null)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        assertEquals("JOURNAL", mapper.readTree(body).get("noteType").asText());
    }

    @Test
    void viewerCannotCreate() throws Exception {
        String ownerToken = registerAndLogin("note-viewer-owner");
        String viewerToken = registerAndLogin("note-viewer-viewer");
        Long tripId = createTrip(ownerToken, "Note Viewer Trip", "Osaka", "2029-02-20", "2029-02-25");
        invite(ownerToken, tripId, emailOf(viewerToken), "VIEWER");

        mvc.perform(post("/api/me/trips/" + tripId + "/notes")
                .header("Authorization", "Bearer " + viewerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(notePayload(null, null, "NOTE", null, "Sneaky note", null, null)))
            .andExpect(status().isForbidden());
    }

    @Test
    void viewerCanList() throws Exception {
        String ownerToken = registerAndLogin("note-viewerlist-owner");
        String viewerToken = registerAndLogin("note-viewerlist-viewer");
        Long tripId = createTrip(ownerToken, "Note Viewer List Trip", "Nagoya", "2029-03-01", "2029-03-05");
        invite(ownerToken, tripId, emailOf(viewerToken), "VIEWER");
        addNote(ownerToken, tripId, notePayload(null, null, "IDEA", null, "Try the ramen place", null, null));

        String body = mvc.perform(get("/api/me/trips/" + tripId + "/notes")
                .header("Authorization", "Bearer " + viewerToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals(1, mapper.readTree(body).size());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // GET / UPDATE / DELETE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void getNote_succeeds() throws Exception {
        String token = registerAndLogin("note-get");
        Long tripId = createTrip(token, "Get Note Trip", "Fukuoka", "2029-03-10", "2029-03-15");
        Long noteId = mapper.readTree(addNote(token, tripId,
            notePayload(null, null, "MEMORY", "Sunset", "Beautiful sunset at the beach", "HAPPY", null)))
            .get("id").asLong();

        mvc.perform(get("/api/me/trips/notes/" + noteId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.title").value("Sunset"));
    }

    @Test
    void updateNote_succeeds() throws Exception {
        String token = registerAndLogin("note-update");
        Long tripId = createTrip(token, "Update Note Trip", "Sapporo", "2029-03-20", "2029-03-25");
        Long noteId = mapper.readTree(addNote(token, tripId,
            notePayload(null, null, "NOTE", "Old title", "Old content", null, null)))
            .get("id").asLong();

        String body = mvc.perform(put("/api/me/trips/notes/" + noteId)
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(notePayload(null, null, "NOTE", "New title", "New content", "CALM", null)))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("New title", res.get("title").asText());
        assertEquals("New content", res.get("content").asText());
        assertEquals("CALM", res.get("mood").asText());
    }

    @Test
    void deleteNote_succeeds() throws Exception {
        String token = registerAndLogin("note-delete");
        Long tripId = createTrip(token, "Delete Note Trip", "Naha", "2029-04-01", "2029-04-05");
        Long noteId = mapper.readTree(addNote(token, tripId,
            notePayload(null, null, "REMINDER", null, "Buy travel insurance", null, null)))
            .get("id").asLong();

        mvc.perform(delete("/api/me/trips/notes/" + noteId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNoContent());

        mvc.perform(get("/api/me/trips/notes/" + noteId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PIN / UNPIN
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void pinNote_succeeds() throws Exception {
        String token = registerAndLogin("note-pin");
        Long tripId = createTrip(token, "Pin Note Trip", "Nara", "2029-04-10", "2029-04-15");
        Long noteId = mapper.readTree(addNote(token, tripId,
            notePayload(null, null, "NOTE", null, "Important reminder", null, null)))
            .get("id").asLong();

        String body = mvc.perform(patch("/api/me/trips/notes/" + noteId + "/pin")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertTrue(mapper.readTree(body).get("pinned").asBoolean());
    }

    @Test
    void unpinNote_succeeds() throws Exception {
        String token = registerAndLogin("note-unpin");
        Long tripId = createTrip(token, "Unpin Note Trip", "Kobe", "2029-04-20", "2029-04-25");
        Long noteId = mapper.readTree(addNote(token, tripId,
            notePayload(null, null, "NOTE", null, "Temporary pin", null, null)))
            .get("id").asLong();

        mvc.perform(patch("/api/me/trips/notes/" + noteId + "/pin")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        String body = mvc.perform(patch("/api/me/trips/notes/" + noteId + "/unpin")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertFalse(mapper.readTree(body).get("pinned").asBoolean());
    }

    @Test
    void pinnedNotesSortedFirst() throws Exception {
        String token = registerAndLogin("note-pinsort");
        Long tripId = createTrip(token, "Pin Sort Trip", "Sendai", "2029-05-01", "2029-05-05");
        addNote(token, tripId, notePayload(null, null, "NOTE", "First", "First note", null, null));
        Long secondId = mapper.readTree(addNote(token, tripId,
            notePayload(null, null, "NOTE", "Second", "Second note", null, null))).get("id").asLong();
        addNote(token, tripId, notePayload(null, null, "NOTE", "Third", "Third note", null, null));

        mvc.perform(patch("/api/me/trips/notes/" + secondId + "/pin")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        String body = mvc.perform(get("/api/me/trips/" + tripId + "/notes")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode list = mapper.readTree(body);
        assertEquals(3, list.size());
        assertEquals("Second", list.get(0).get("title").asText());
        assertTrue(list.get(0).get("pinned").asBoolean());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CROSS-TRIP VALIDATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void linkedDayFromAnotherTrip_rejected() throws Exception {
        String token = registerAndLogin("note-crosstrip");
        Long tripA = createTrip(token, "Trip A", "Chiang Mai", "2029-05-10", "2029-05-15");
        Long tripB = createTrip(token, "Trip B", "Phuket", "2029-05-20", "2029-05-25");
        Long dayInTripB = addDay(token, tripB, 1, "2029-05-20");

        mvc.perform(post("/api/me/trips/" + tripA + "/notes")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(notePayload(dayInTripB, null, "NOTE", null, "Cross-trip note", null, null)))
            .andExpect(status().isBadRequest());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // VALIDATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void content_required() throws Exception {
        String token = registerAndLogin("note-contentreq");
        Long tripId = createTrip(token, "Content Required Trip", "Krabi", "2029-06-01", "2029-06-05");

        mvc.perform(post("/api/me/trips/" + tripId + "/notes")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(notePayload(null, null, "NOTE", "Title only", "", null, null)))
            .andExpect(status().isBadRequest());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ISOLATION / AUTH
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void nonCollaborator_blocked() throws Exception {
        String ownerToken = registerAndLogin("note-stranger-owner");
        String strangerToken = registerAndLogin("note-stranger");
        Long tripId = createTrip(ownerToken, "Private Notes Trip", "Pattaya", "2029-06-10", "2029-06-15");

        mvc.perform(get("/api/me/trips/" + tripId + "/notes")
                .header("Authorization", "Bearer " + strangerToken))
            .andExpect(status().isNotFound());
    }

    @Test
    void unauthenticated_rejected() throws Exception {
        mvc.perform(get("/api/me/trips/1/notes"))
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

    private String notePayload(Long tripDayId, Long tripItemId, String noteType, String title,
                                String content, String mood, String photoUrl) {
        return "{\"tripDayId\":" + tripDayId
            + ",\"tripItemId\":" + tripItemId
            + ",\"noteType\":\"" + noteType + "\""
            + ",\"title\":" + (title == null ? "null" : "\"" + title + "\"")
            + ",\"content\":\"" + content + "\""
            + ",\"mood\":" + (mood == null ? "null" : "\"" + mood + "\"")
            + ",\"photoUrl\":" + (photoUrl == null ? "null" : "\"" + photoUrl + "\"")
            + "}";
    }

    private String addNote(String token, Long tripId, String payload) throws Exception {
        return mvc.perform(post("/api/me/trips/" + tripId + "/notes")
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
