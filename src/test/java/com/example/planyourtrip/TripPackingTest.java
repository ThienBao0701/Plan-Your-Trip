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
 * TripPackingTest — Phase 7.7.
 * Every scenario registers its own throwaway owner and, where needed, throwaway
 * collaborator users, and creates its own trip — packing list state is
 * trip-specific and must not leak across tests.
 */
@SpringBootTest
@AutoConfigureMockMvc
class TripPackingTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;

    private static final AtomicInteger counter = new AtomicInteger(1);

    // ═══════════════════════════════════════════════════════════════════════════
    // CREATE PERMISSIONS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void ownerCreatesPackingItem() throws Exception {
        String token = registerAndLogin("packing-owner");
        Long tripId = createTrip(token, "Packing Owner Trip", "Bangkok", "2028-09-01", "2028-09-05");

        String body = mvc.perform(post("/api/me/trips/" + tripId + "/packing")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(itemPayload("Passport", "DOCUMENTS", 1, null, null)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("Passport", res.get("label").asText());
        assertEquals("DOCUMENTS", res.get("category").asText());
        assertFalse(res.get("checked").asBoolean());
        assertEquals(0, res.get("sortOrder").asInt());
    }

    @Test
    void editorCreatesPackingItem() throws Exception {
        String ownerToken = registerAndLogin("packing-editor-owner");
        String editorToken = registerAndLogin("packing-editor-editor");
        Long tripId = createTrip(ownerToken, "Packing Editor Trip", "Singapore", "2028-09-10", "2028-09-15");
        invite(ownerToken, tripId, emailOf(editorToken), "EDITOR");

        mvc.perform(post("/api/me/trips/" + tripId + "/packing")
                .header("Authorization", "Bearer " + editorToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(itemPayload("Sunscreen", "TOILETRIES", 1, null, null)))
            .andExpect(status().isCreated());
    }

    @Test
    void viewerCannotCreate() throws Exception {
        String ownerToken = registerAndLogin("packing-viewer-owner");
        String viewerToken = registerAndLogin("packing-viewer-viewer");
        Long tripId = createTrip(ownerToken, "Packing Viewer Trip", "Kuala Lumpur", "2028-09-20", "2028-09-25");
        invite(ownerToken, tripId, emailOf(viewerToken), "VIEWER");

        mvc.perform(post("/api/me/trips/" + tripId + "/packing")
                .header("Authorization", "Bearer " + viewerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(itemPayload("Camera", "ELECTRONICS", 1, null, null)))
            .andExpect(status().isForbidden());
    }

    @Test
    void viewerCanList() throws Exception {
        String ownerToken = registerAndLogin("packing-viewerlist-owner");
        String viewerToken = registerAndLogin("packing-viewerlist-viewer");
        Long tripId = createTrip(ownerToken, "Packing Viewer List Trip", "Manila", "2028-10-01", "2028-10-05");
        invite(ownerToken, tripId, emailOf(viewerToken), "VIEWER");
        addItem(ownerToken, tripId, itemPayload("Charger", "ELECTRONICS", 1, null, null));

        String body = mvc.perform(get("/api/me/trips/" + tripId + "/packing")
                .header("Authorization", "Bearer " + viewerToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals(1, mapper.readTree(body).size());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CHECK / UNCHECK
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void checkSetsCheckedAt() throws Exception {
        String token = registerAndLogin("packing-check");
        Long tripId = createTrip(token, "Check Trip", "Jakarta", "2028-10-10", "2028-10-15");
        Long itemId = mapper.readTree(addItem(token, tripId, itemPayload("Toothbrush", "TOILETRIES", 1, null, null)))
            .get("id").asLong();

        String body = mvc.perform(patch("/api/me/trips/packing/" + itemId + "/check")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertTrue(res.get("checked").asBoolean());
        assertFalse(res.get("checkedAt").isNull());
    }

    @Test
    void uncheckClearsCheckedAt() throws Exception {
        String token = registerAndLogin("packing-uncheck");
        Long tripId = createTrip(token, "Uncheck Trip", "Yangon", "2028-10-20", "2028-10-25");
        Long itemId = mapper.readTree(addItem(token, tripId, itemPayload("Umbrella", "OTHER", 1, null, null)))
            .get("id").asLong();

        mvc.perform(patch("/api/me/trips/packing/" + itemId + "/check")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        String body = mvc.perform(patch("/api/me/trips/packing/" + itemId + "/uncheck")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertFalse(res.get("checked").asBoolean());
        assertTrue(res.get("checkedAt").isNull());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // UPDATE / DELETE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void updateItem_succeeds() throws Exception {
        String token = registerAndLogin("packing-update");
        Long tripId = createTrip(token, "Update Item Trip", "Phnom Penh", "2028-11-01", "2028-11-05");
        Long itemId = mapper.readTree(addItem(token, tripId, itemPayload("Socks", "CLOTHES", 2, null, null)))
            .get("id").asLong();

        String body = mvc.perform(put("/api/me/trips/packing/" + itemId)
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(itemPayload("Wool socks", "CLOTHES", 3, null, "Warm ones"))
                )
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("Wool socks", res.get("label").asText());
        assertEquals(3, res.get("quantity").asInt());
        assertEquals("Warm ones", res.get("notes").asText());
    }

    @Test
    void deleteItem_reordersRemaining() throws Exception {
        String token = registerAndLogin("packing-delete");
        Long tripId = createTrip(token, "Delete Item Trip", "Vientiane", "2028-11-10", "2028-11-15");
        Long itemA = mapper.readTree(addItem(token, tripId, itemPayload("A", "OTHER", 1, null, null))).get("id").asLong();
        Long itemB = mapper.readTree(addItem(token, tripId, itemPayload("B", "OTHER", 1, null, null))).get("id").asLong();
        Long itemC = mapper.readTree(addItem(token, tripId, itemPayload("C", "OTHER", 1, null, null))).get("id").asLong();

        mvc.perform(delete("/api/me/trips/packing/" + itemB)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNoContent());

        String body = mvc.perform(get("/api/me/trips/" + tripId + "/packing")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode list = mapper.readTree(body);
        assertEquals(2, list.size());
        assertEquals(itemA, list.get(0).get("id").asLong());
        assertEquals(0, list.get(0).get("sortOrder").asInt());
        assertEquals(itemC, list.get(1).get("id").asLong());
        assertEquals(1, list.get(1).get("sortOrder").asInt(), "Remaining items must be resequenced contiguously");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // REORDER
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void reorder_works() throws Exception {
        String token = registerAndLogin("packing-reorder");
        Long tripId = createTrip(token, "Reorder Trip", "Vientiane", "2028-11-20", "2028-11-25");
        Long itemA = mapper.readTree(addItem(token, tripId, itemPayload("A", "OTHER", 1, null, null))).get("id").asLong();
        Long itemB = mapper.readTree(addItem(token, tripId, itemPayload("B", "OTHER", 1, null, null))).get("id").asLong();
        Long itemC = mapper.readTree(addItem(token, tripId, itemPayload("C", "OTHER", 1, null, null))).get("id").asLong();

        String body = mvc.perform(patch("/api/me/trips/" + tripId + "/packing/reorder")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"orderedItemIds\":[" + itemC + "," + itemA + "," + itemB + "]}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode list = mapper.readTree(body);
        assertEquals("C", list.get(0).get("label").asText());
        assertEquals("A", list.get(1).get("label").asText());
        assertEquals("B", list.get(2).get("label").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ASSIGNED USER VALIDATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void assignedUserMustBeOwnerOrCollaborator() throws Exception {
        String ownerToken = registerAndLogin("packing-assign-owner");
        String strangerToken = registerAndLogin("packing-assign-stranger");
        Long strangerId = idOf(strangerToken);
        Long tripId = createTrip(ownerToken, "Assign Trip", "Hanoi", "2028-12-01", "2028-12-05");

        mvc.perform(post("/api/me/trips/" + tripId + "/packing")
                .header("Authorization", "Bearer " + ownerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(itemPayload("Tent", "OTHER", 1, strangerId, null)))
            .andExpect(status().isBadRequest());
    }

    @Test
    void assignedUser_collaboratorAllowed() throws Exception {
        String ownerToken = registerAndLogin("packing-assign2-owner");
        String editorToken = registerAndLogin("packing-assign2-editor");
        Long editorId = idOf(editorToken);
        Long tripId = createTrip(ownerToken, "Assign Collab Trip", "Hanoi", "2028-12-10", "2028-12-15");
        invite(ownerToken, tripId, emailOf(editorToken), "EDITOR");

        String body = mvc.perform(post("/api/me/trips/" + tripId + "/packing")
                .header("Authorization", "Bearer " + ownerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(itemPayload("Backpack", "OTHER", 1, editorId, null)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        assertEquals(editorId, mapper.readTree(body).get("assignedToUserId").asLong());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // VALIDATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void quantity_validation() throws Exception {
        String token = registerAndLogin("packing-qtyval");
        Long tripId = createTrip(token, "Quantity Validation Trip", "Hue", "2028-12-20", "2028-12-25");

        mvc.perform(post("/api/me/trips/" + tripId + "/packing")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(itemPayload("Bad Item", "OTHER", 0, null, null)))
            .andExpect(status().isBadRequest());
    }

    @Test
    void label_required() throws Exception {
        String token = registerAndLogin("packing-labelreq");
        Long tripId = createTrip(token, "Label Required Trip", "Hai Phong", "2029-01-01", "2029-01-05");

        mvc.perform(post("/api/me/trips/" + tripId + "/packing")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(itemPayload("", "OTHER", 1, null, null)))
            .andExpect(status().isBadRequest());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ISOLATION / AUTH
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void nonCollaborator_blocked() throws Exception {
        String ownerToken = registerAndLogin("packing-stranger-owner");
        String strangerToken = registerAndLogin("packing-stranger");
        Long tripId = createTrip(ownerToken, "Private Packing Trip", "Da Lat", "2029-01-10", "2029-01-15");

        mvc.perform(get("/api/me/trips/" + tripId + "/packing")
                .header("Authorization", "Bearer " + strangerToken))
            .andExpect(status().isNotFound());
    }

    @Test
    void unauthenticated_rejected() throws Exception {
        mvc.perform(get("/api/me/trips/1/packing"))
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

    private String itemPayload(String label, String category, int quantity, Long assignedToUserId, String notes) {
        return "{\"label\":\"" + label + "\""
            + ",\"category\":\"" + category + "\""
            + ",\"quantity\":" + quantity
            + ",\"assignedToUserId\":" + assignedToUserId
            + ",\"notes\":" + (notes == null ? "null" : "\"" + notes + "\"")
            + "}";
    }

    private String addItem(String token, Long tripId, String payload) throws Exception {
        return mvc.perform(post("/api/me/trips/" + tripId + "/packing")
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

    private Long idOf(String token) throws Exception {
        String body = mvc.perform(get("/api/me")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
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
