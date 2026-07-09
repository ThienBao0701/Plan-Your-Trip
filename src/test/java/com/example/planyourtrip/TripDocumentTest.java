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
 * TripDocumentTest — Phase 7.9.
 * Every scenario registers its own throwaway owner and, where needed, throwaway
 * collaborator users, and creates its own trip — document state is trip-specific
 * and must not leak across tests.
 */
@SpringBootTest
@AutoConfigureMockMvc
class TripDocumentTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;

    private static final AtomicInteger counter = new AtomicInteger(1);

    // ═══════════════════════════════════════════════════════════════════════════
    // CREATE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void createDocument_succeeds() throws Exception {
        String token = registerAndLogin("doc-create");
        Long tripId = createTrip(token, "Document Trip", "Rome", "2029-07-01", "2029-07-05");

        String body = mvc.perform(post("/api/me/trips/" + tripId + "/documents")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(newMediaDocPayload(null, null, "https://cdn.example.com/ticket.pdf", "DOCUMENT",
                    "FLIGHT_TICKET", "Outbound flight", null)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("FLIGHT_TICKET", res.get("documentType").asText());
        assertEquals("Outbound flight", res.get("title").asText());
        assertFalse(res.get("pinned").asBoolean());
        assertEquals("https://cdn.example.com/ticket.pdf", res.get("mediaAsset").get("url").asText());
        assertNotNull(res.get("uploadedByUserId"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // UPDATE / DELETE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void updateDocument_succeeds() throws Exception {
        String token = registerAndLogin("doc-update");
        Long tripId = createTrip(token, "Update Doc Trip", "Milan", "2029-07-10", "2029-07-15");
        Long docId = mapper.readTree(addDocument(token, tripId,
            newMediaDocPayload(null, null, "https://cdn.example.com/visa.pdf", "DOCUMENT",
                "VISA", "Old title", null))).get("id").asLong();

        String body = mvc.perform(put("/api/me/trips/documents/" + docId)
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(newMediaDocPayload(null, null, "https://cdn.example.com/visa.pdf", "DOCUMENT",
                    "VISA", "New title", "Updated notes")))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("New title", res.get("title").asText());
        assertEquals("Updated notes", res.get("notes").asText());
    }

    @Test
    void deleteDocument_succeeds() throws Exception {
        String token = registerAndLogin("doc-delete");
        Long tripId = createTrip(token, "Delete Doc Trip", "Venice", "2029-07-20", "2029-07-25");
        Long docId = mapper.readTree(addDocument(token, tripId,
            newMediaDocPayload(null, null, "https://cdn.example.com/insurance.pdf", "DOCUMENT",
                "INSURANCE", null, null))).get("id").asLong();

        mvc.perform(delete("/api/me/trips/documents/" + docId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNoContent());

        mvc.perform(get("/api/me/trips/documents/" + docId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PIN / UNPIN
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void pinDocument_succeeds() throws Exception {
        String token = registerAndLogin("doc-pin");
        Long tripId = createTrip(token, "Pin Doc Trip", "Florence", "2029-08-01", "2029-08-05");
        Long docId = mapper.readTree(addDocument(token, tripId,
            newMediaDocPayload(null, null, "https://cdn.example.com/passport.jpg", "IMAGE",
                "PASSPORT", null, null))).get("id").asLong();

        String body = mvc.perform(patch("/api/me/trips/documents/" + docId + "/pin")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertTrue(mapper.readTree(body).get("pinned").asBoolean());
    }

    @Test
    void unpinDocument_succeeds() throws Exception {
        String token = registerAndLogin("doc-unpin");
        Long tripId = createTrip(token, "Unpin Doc Trip", "Turin", "2029-08-10", "2029-08-15");
        Long docId = mapper.readTree(addDocument(token, tripId,
            newMediaDocPayload(null, null, "https://cdn.example.com/tour.pdf", "DOCUMENT",
                "TOUR", null, null))).get("id").asLong();

        mvc.perform(patch("/api/me/trips/documents/" + docId + "/pin")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        String body = mvc.perform(patch("/api/me/trips/documents/" + docId + "/unpin")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertFalse(mapper.readTree(body).get("pinned").asBoolean());
    }

    @Test
    void pinnedDocumentsSortedFirst() throws Exception {
        String token = registerAndLogin("doc-pinsort");
        Long tripId = createTrip(token, "Pin Sort Doc Trip", "Genoa", "2029-08-20", "2029-08-25");
        addDocument(token, tripId, newMediaDocPayload(null, null, "https://cdn.example.com/a.pdf", "DOCUMENT", "OTHER", "First", null));
        Long secondId = mapper.readTree(addDocument(token, tripId,
            newMediaDocPayload(null, null, "https://cdn.example.com/b.pdf", "DOCUMENT", "OTHER", "Second", null)))
            .get("id").asLong();
        addDocument(token, tripId, newMediaDocPayload(null, null, "https://cdn.example.com/c.pdf", "DOCUMENT", "OTHER", "Third", null));

        mvc.perform(patch("/api/me/trips/documents/" + secondId + "/pin")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        String body = mvc.perform(get("/api/me/trips/" + tripId + "/documents")
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
    void sameTripValidation_rejectsCrossTripDay() throws Exception {
        String token = registerAndLogin("doc-crosstrip");
        Long tripA = createTrip(token, "Trip A", "Naples", "2029-09-01", "2029-09-05");
        Long tripB = createTrip(token, "Trip B", "Palermo", "2029-09-10", "2029-09-15");
        Long dayInTripB = addDay(token, tripB, 1, "2029-09-10");

        mvc.perform(post("/api/me/trips/" + tripA + "/documents")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(newMediaDocPayload(dayInTripB, null, "https://cdn.example.com/x.pdf", "DOCUMENT", "OTHER", null, null)))
            .andExpect(status().isBadRequest());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PERMISSIONS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void viewerCannotModify() throws Exception {
        String ownerToken = registerAndLogin("doc-viewer-owner");
        String viewerToken = registerAndLogin("doc-viewer-viewer");
        Long tripId = createTrip(ownerToken, "Viewer Doc Trip", "Bologna", "2029-09-20", "2029-09-25");
        invite(ownerToken, tripId, emailOf(viewerToken), "VIEWER");

        mvc.perform(post("/api/me/trips/" + tripId + "/documents")
                .header("Authorization", "Bearer " + viewerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(newMediaDocPayload(null, null, "https://cdn.example.com/sneaky.pdf", "DOCUMENT", "OTHER", null, null)))
            .andExpect(status().isForbidden());
    }

    @Test
    void viewerCanList() throws Exception {
        String ownerToken = registerAndLogin("doc-viewerlist-owner");
        String viewerToken = registerAndLogin("doc-viewerlist-viewer");
        Long tripId = createTrip(ownerToken, "Viewer List Doc Trip", "Verona", "2029-10-01", "2029-10-05");
        invite(ownerToken, tripId, emailOf(viewerToken), "VIEWER");
        addDocument(ownerToken, tripId, newMediaDocPayload(null, null, "https://cdn.example.com/hotel.pdf", "DOCUMENT", "HOTEL_BOOKING", null, null));

        String body = mvc.perform(get("/api/me/trips/" + tripId + "/documents")
                .header("Authorization", "Bearer " + viewerToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals(1, mapper.readTree(body).size());
    }

    @Test
    void ownerAndEditorCanUpload() throws Exception {
        String ownerToken = registerAndLogin("doc-editor-owner");
        String editorToken = registerAndLogin("doc-editor-editor");
        Long tripId = createTrip(ownerToken, "Editor Doc Trip", "Pisa", "2029-10-10", "2029-10-15");
        invite(ownerToken, tripId, emailOf(editorToken), "EDITOR");

        mvc.perform(post("/api/me/trips/" + tripId + "/documents")
                .header("Authorization", "Bearer " + ownerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(newMediaDocPayload(null, null, "https://cdn.example.com/owner-doc.pdf", "DOCUMENT", "OTHER", "By owner", null)))
            .andExpect(status().isCreated());

        mvc.perform(post("/api/me/trips/" + tripId + "/documents")
                .header("Authorization", "Bearer " + editorToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(newMediaDocPayload(null, null, "https://cdn.example.com/editor-doc.pdf", "DOCUMENT", "OTHER", "By editor", null)))
            .andExpect(status().isCreated());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MEDIA ASSET REUSE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void mediaAssetIsReused_notDuplicated() throws Exception {
        String token = registerAndLogin("doc-reuse");
        Long tripId = createTrip(token, "Reuse Doc Trip", "Siena", "2029-10-20", "2029-10-25");

        String firstBody = addDocument(token, tripId,
            newMediaDocPayload(null, null, "https://cdn.example.com/shared.pdf", "DOCUMENT", "PASSPORT", "Passport scan", null));
        Long mediaAssetId = mapper.readTree(firstBody).get("mediaAsset").get("id").asLong();

        String secondBody = mvc.perform(post("/api/me/trips/" + tripId + "/documents")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(reuseMediaDocPayload(mediaAssetId, "OTHER", "Same scan, other category")))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        JsonNode second = mapper.readTree(secondBody);
        assertEquals(mediaAssetId, second.get("mediaAsset").get("id").asLong(),
            "Reusing mediaAssetId must not create a duplicate MediaAsset row");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // AUTH
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void unauthenticated_rejected() throws Exception {
        mvc.perform(get("/api/me/trips/1/documents"))
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

    private String newMediaDocPayload(Long tripDayId, Long tripItemId, String url, String mediaType,
                                       String documentType, String title, String notes) {
        return "{\"tripDayId\":" + tripDayId
            + ",\"tripItemId\":" + tripItemId
            + ",\"mediaAssetId\":null"
            + ",\"url\":\"" + url + "\""
            + ",\"thumbnailUrl\":null"
            + ",\"mediaType\":\"" + mediaType + "\""
            + ",\"altText\":null"
            + ",\"documentType\":\"" + documentType + "\""
            + ",\"title\":" + (title == null ? "null" : "\"" + title + "\"")
            + ",\"notes\":" + (notes == null ? "null" : "\"" + notes + "\"")
            + "}";
    }

    private String reuseMediaDocPayload(Long mediaAssetId, String documentType, String title) {
        return "{\"tripDayId\":null,\"tripItemId\":null"
            + ",\"mediaAssetId\":" + mediaAssetId
            + ",\"url\":null,\"thumbnailUrl\":null,\"mediaType\":null,\"altText\":null"
            + ",\"documentType\":\"" + documentType + "\""
            + ",\"title\":\"" + title + "\",\"notes\":null}";
    }

    private String addDocument(String token, Long tripId, String payload) throws Exception {
        return mvc.perform(post("/api/me/trips/" + tripId + "/documents")
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
