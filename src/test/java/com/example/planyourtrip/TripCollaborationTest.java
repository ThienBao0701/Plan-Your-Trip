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
 * TripCollaborationTest — Phase 7.5.
 * Every scenario registers its own throwaway owner and, where needed, throwaway
 * collaborator users, and creates its own trip — no shared fixtures, since
 * collaboration state (invites, public/private) is trip-specific and must not leak
 * across tests.
 */
@SpringBootTest
@AutoConfigureMockMvc
class TripCollaborationTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;

    private static final AtomicInteger counter = new AtomicInteger(1);

    // ═══════════════════════════════════════════════════════════════════════════
    // INVITE / DUPLICATE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void ownerInvitesCollaborator_succeeds() throws Exception {
        String ownerToken = registerAndLogin("collab-owner");
        String collabEmail = registerEmail("collab-viewer");
        Long tripId = createTrip(ownerToken, "Team Trip", "Bali", "2027-06-01", "2027-06-05");

        String body = invite(ownerToken, tripId, collabEmail, "VIEWER");
        JsonNode res = mapper.readTree(body);
        assertEquals(collabEmail, res.get("userEmail").asText());
        assertEquals("VIEWER", res.get("role").asText());
        assertTrue(res.get("active").asBoolean());
    }

    @Test
    void duplicateCollaborator_rejected() throws Exception {
        String ownerToken = registerAndLogin("collab-dup-owner");
        String collabEmail = registerEmail("collab-dup-viewer");
        Long tripId = createTrip(ownerToken, "Dup Collab Trip", "Bali", "2027-06-10", "2027-06-15");

        invite(ownerToken, tripId, collabEmail, "VIEWER");

        mvc.perform(post("/api/me/trips/" + tripId + "/collaborators")
                .header("Authorization", "Bearer " + ownerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(collaboratorPayload(collabEmail, "EDITOR")))
            .andExpect(status().isConflict());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // VIEWER / EDITOR ACCESS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void viewerCanReadSharedTrip() throws Exception {
        String ownerToken = registerAndLogin("collab-viewread-owner");
        String viewerToken = registerAndLogin("collab-viewread-viewer");
        Long tripId = createTrip(ownerToken, "Viewer Read Trip", "Hoi An", "2027-07-01", "2027-07-05");
        invite(ownerToken, tripId, emailOf(viewerToken), "VIEWER");

        mvc.perform(get("/api/me/trips/" + tripId)
                .header("Authorization", "Bearer " + viewerToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.title").value("Viewer Read Trip"));
    }

    @Test
    void viewerCannotEdit() throws Exception {
        String ownerToken = registerAndLogin("collab-viewedit-owner");
        String viewerToken = registerAndLogin("collab-viewedit-viewer");
        Long tripId = createTrip(ownerToken, "Viewer Edit Trip", "Hue", "2027-07-10", "2027-07-15");
        invite(ownerToken, tripId, emailOf(viewerToken), "VIEWER");

        mvc.perform(post("/api/me/trips/" + tripId + "/days")
                .header("Authorization", "Bearer " + viewerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"dayNumber\":1,\"date\":\"2027-07-10\"}"))
            .andExpect(status().isForbidden());
    }

    @Test
    void editorCanAddDayAndItem() throws Exception {
        String ownerToken = registerAndLogin("collab-editor-owner");
        String editorToken = registerAndLogin("collab-editor-editor");
        Long tripId = createTrip(ownerToken, "Editor Trip", "Sapa", "2027-08-01", "2027-08-05");
        invite(ownerToken, tripId, emailOf(editorToken), "EDITOR");

        String dayBody = mvc.perform(post("/api/me/trips/" + tripId + "/days")
                .header("Authorization", "Bearer " + editorToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"dayNumber\":1,\"date\":\"2027-08-01\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long dayId = mapper.readTree(dayBody).get("id").asLong();

        mvc.perform(post("/api/me/trips/days/" + dayId + "/items")
                .header("Authorization", "Bearer " + editorToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"customTitle\":\"Trek to Fansipan\"}"))
            .andExpect(status().isCreated());
    }

    @Test
    void nonCollaboratorCannotReadPrivateTrip() throws Exception {
        String ownerToken = registerAndLogin("collab-stranger-owner");
        String strangerToken = registerAndLogin("collab-stranger");
        Long tripId = createTrip(ownerToken, "Private Trip", "Da Lat", "2027-08-10", "2027-08-15");

        mvc.perform(get("/api/me/trips/" + tripId)
                .header("Authorization", "Bearer " + strangerToken))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PUBLIC SHARING
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void publicTrip_canBeViewedAnonymously() throws Exception {
        String ownerToken = registerAndLogin("collab-public-owner");
        Long tripId = createTrip(ownerToken, "Public Trip", "Phu Quoc", "2027-09-01", "2027-09-05");

        mvc.perform(patch("/api/me/trips/" + tripId + "/public")
                .header("Authorization", "Bearer " + ownerToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.isPublic").value(true));

        mvc.perform(get("/api/trips/public/" + tripId))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.title").value("Public Trip"));
    }

    @Test
    void privateTrip_cannotBeViewedPublicly() throws Exception {
        String ownerToken = registerAndLogin("collab-notpublic-owner");
        Long tripId = createTrip(ownerToken, "Still Private Trip", "Con Dao", "2027-09-10", "2027-09-15");

        mvc.perform(get("/api/trips/public/" + tripId))
            .andExpect(status().isNotFound());
    }

    @Test
    void ownerCanMakeTripPublic() throws Exception {
        String ownerToken = registerAndLogin("collab-makepublic-owner");
        Long tripId = createTrip(ownerToken, "Make Public Trip", "Quy Nhon", "2027-10-01", "2027-10-05");

        String body = mvc.perform(patch("/api/me/trips/" + tripId + "/public")
                .header("Authorization", "Bearer " + ownerToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertTrue(mapper.readTree(body).get("isPublic").asBoolean());
    }

    @Test
    void ownerCanMakeTripPrivate() throws Exception {
        String ownerToken = registerAndLogin("collab-makeprivate-owner");
        Long tripId = createTrip(ownerToken, "Make Private Trip", "Quy Nhon", "2027-10-10", "2027-10-15");
        mvc.perform(patch("/api/me/trips/" + tripId + "/public")
                .header("Authorization", "Bearer " + ownerToken))
            .andExpect(status().isOk());

        String body = mvc.perform(patch("/api/me/trips/" + tripId + "/private")
                .header("Authorization", "Bearer " + ownerToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertFalse(mapper.readTree(body).get("isPublic").asBoolean());

        mvc.perform(get("/api/trips/public/" + tripId))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // COLLABORATOR MANAGEMENT
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void ownerCanUpdateCollaboratorRole() throws Exception {
        String ownerToken = registerAndLogin("collab-rolechange-owner");
        String collabToken = registerAndLogin("collab-rolechange-collab");
        Long tripId = createTrip(ownerToken, "Role Change Trip", "Vinh", "2027-11-01", "2027-11-05");
        Long collaboratorId = mapper.readTree(invite(ownerToken, tripId, emailOf(collabToken), "VIEWER"))
            .get("id").asLong();

        String body = mvc.perform(patch("/api/me/trips/" + tripId + "/collaborators/" + collaboratorId)
                .header("Authorization", "Bearer " + ownerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(collaboratorPayload(emailOf(collabToken), "EDITOR")))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals("EDITOR", mapper.readTree(body).get("role").asText());

        // The role change must take effect immediately for the collaborator's own permissions.
        mvc.perform(post("/api/me/trips/" + tripId + "/days")
                .header("Authorization", "Bearer " + collabToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"dayNumber\":1,\"date\":\"2027-11-01\"}"))
            .andExpect(status().isCreated());
    }

    @Test
    void ownerCanRemoveCollaborator() throws Exception {
        String ownerToken = registerAndLogin("collab-remove-owner");
        String collabToken = registerAndLogin("collab-remove-collab");
        Long tripId = createTrip(ownerToken, "Remove Collab Trip", "Can Tho", "2027-11-10", "2027-11-15");
        Long collaboratorId = mapper.readTree(invite(ownerToken, tripId, emailOf(collabToken), "VIEWER"))
            .get("id").asLong();

        mvc.perform(delete("/api/me/trips/" + tripId + "/collaborators/" + collaboratorId)
                .header("Authorization", "Bearer " + ownerToken))
            .andExpect(status().isNoContent());

        mvc.perform(get("/api/me/trips/" + tripId)
                .header("Authorization", "Bearer " + collabToken))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // NOTIFICATIONS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void collaboratorInvite_createsNotification() throws Exception {
        String ownerToken = registerAndLogin("collab-notify-owner");
        String collabToken = registerAndLogin("collab-notify-collab");
        Long tripId = createTrip(ownerToken, "Notify Trip", "Ninh Binh", "2027-12-01", "2027-12-05");

        invite(ownerToken, tripId, emailOf(collabToken), "VIEWER");

        String body = mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + collabToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode notifications = mapper.readTree(body);
        boolean hasInvite = false;
        for (JsonNode n : notifications) {
            if (n.get("title").asText().equals("You were invited to collaborate on a trip")) hasInvite = true;
        }
        assertTrue(hasInvite, "Invited collaborator must receive a notification");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SHARED TRIPS LIST
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void sharedTripsList_works() throws Exception {
        String ownerToken = registerAndLogin("collab-sharedlist-owner");
        String collabToken = registerAndLogin("collab-sharedlist-collab");
        Long tripId = createTrip(ownerToken, "Shared List Trip", "Ha Long", "2027-12-10", "2027-12-15");
        invite(ownerToken, tripId, emailOf(collabToken), "EDITOR");

        String body = mvc.perform(get("/api/me/trips/shared")
                .header("Authorization", "Bearer " + collabToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode list = mapper.readTree(body);
        assertEquals(1, list.size());
        assertEquals("Shared List Trip", list.get(0).get("title").asText());
        assertEquals("EDITOR", list.get(0).get("role").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // OWNER-ONLY PROTECTION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void ownerOnlyDelete_stillProtected() throws Exception {
        String ownerToken = registerAndLogin("collab-delete-owner");
        String editorToken = registerAndLogin("collab-delete-editor");
        Long tripId = createTrip(ownerToken, "Editor Cannot Delete Trip", "Mui Ne", "2028-01-01", "2028-01-05");
        invite(ownerToken, tripId, emailOf(editorToken), "EDITOR");

        mvc.perform(delete("/api/me/trips/" + tripId)
                .header("Authorization", "Bearer " + editorToken))
            .andExpect(status().isForbidden());

        // Owner can still delete.
        mvc.perform(delete("/api/me/trips/" + tripId)
                .header("Authorization", "Bearer " + ownerToken))
            .andExpect(status().isNoContent());
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

    private String collaboratorPayload(String email, String role) {
        return "{\"email\":\"" + email + "\",\"role\":\"" + role + "\"}";
    }

    private String invite(String ownerToken, Long tripId, String email, String role) throws Exception {
        return mvc.perform(post("/api/me/trips/" + tripId + "/collaborators")
                .header("Authorization", "Bearer " + ownerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(collaboratorPayload(email, role)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
    }

    /** Every registered test user's email is deterministic from its own token payload via /api/me. */
    private String emailOf(String token) throws Exception {
        String body = mvc.perform(get("/api/me")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("email").asText();
    }

    private String registerEmail(String namePrefix) throws Exception {
        String token = registerAndLogin(namePrefix);
        return emailOf(token);
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
