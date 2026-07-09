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
 * TripBudgetTest — Phase 7.6.
 * Every scenario registers its own throwaway owner and, where needed, throwaway
 * collaborator users, and creates its own trip — budget/expense state is
 * trip-specific and must not leak across tests.
 */
@SpringBootTest
@AutoConfigureMockMvc
class TripBudgetTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;

    private static final AtomicInteger counter = new AtomicInteger(1);

    // ═══════════════════════════════════════════════════════════════════════════
    // BUDGET CRUD
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void ownerCreatesBudget() throws Exception {
        String token = registerAndLogin("budget-create");
        Long tripId = createTrip(token, "Budget Trip", "Tokyo", "2028-02-01", "2028-02-05");

        String body = mvc.perform(put("/api/me/trips/" + tripId + "/budget")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"totalBudget\":20000000,\"currency\":\"VND\",\"notes\":\"Save for flights\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals(20000000, res.get("totalBudget").asDouble());
        assertEquals("VND", res.get("currency").asText());
    }

    @Test
    void ownerUpdatesBudget() throws Exception {
        String token = registerAndLogin("budget-update");
        Long tripId = createTrip(token, "Budget Update Trip", "Seoul", "2028-02-10", "2028-02-15");
        putBudget(token, tripId, "15000000", "VND", "Initial");

        String body = mvc.perform(put("/api/me/trips/" + tripId + "/budget")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"totalBudget\":18000000,\"currency\":\"VND\",\"notes\":\"Revised upward\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals(18000000, res.get("totalBudget").asDouble());
        assertEquals("Revised upward", res.get("notes").asText());
    }

    @Test
    void deleteBudget_succeeds() throws Exception {
        String token = registerAndLogin("budget-delete");
        Long tripId = createTrip(token, "Budget Delete Trip", "Osaka", "2028-02-20", "2028-02-25");
        putBudget(token, tripId, "5000000", "VND", null);

        mvc.perform(delete("/api/me/trips/" + tripId + "/budget")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNoContent());

        mvc.perform(get("/api/me/trips/" + tripId + "/budget")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // EXPENSE PERMISSIONS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void editorCanAddExpense() throws Exception {
        String ownerToken = registerAndLogin("budget-editor-owner");
        String editorToken = registerAndLogin("budget-editor-editor");
        Long tripId = createTrip(ownerToken, "Editor Expense Trip", "Hanoi", "2028-03-01", "2028-03-05");
        invite(ownerToken, tripId, emailOf(editorToken), "EDITOR");

        String body = mvc.perform(post("/api/me/trips/" + tripId + "/expenses")
                .header("Authorization", "Bearer " + editorToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(expensePayload(null, null, "FOOD", "150000", "VND", "Street food", "2028-03-01")))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        assertEquals("Street food", mapper.readTree(body).get("title").asText());
    }

    @Test
    void viewerCannotAddExpense() throws Exception {
        String ownerToken = registerAndLogin("budget-viewer-owner");
        String viewerToken = registerAndLogin("budget-viewer-viewer");
        Long tripId = createTrip(ownerToken, "Viewer Expense Trip", "Hai Phong", "2028-03-10", "2028-03-15");
        invite(ownerToken, tripId, emailOf(viewerToken), "VIEWER");

        mvc.perform(post("/api/me/trips/" + tripId + "/expenses")
                .header("Authorization", "Bearer " + viewerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(expensePayload(null, null, "FOOD", "50000", "VND", "Snacks", "2028-03-10")))
            .andExpect(status().isForbidden());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CROSS-TRIP DAY/ITEM VALIDATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void expenseWithDayFromAnotherTrip_rejected() throws Exception {
        String token = registerAndLogin("budget-crosstrip");
        Long tripA = createTrip(token, "Trip A", "Da Nang", "2028-04-01", "2028-04-05");
        Long tripB = createTrip(token, "Trip B", "Nha Trang", "2028-04-10", "2028-04-15");
        Long dayInTripB = addDay(token, tripB, 1, "2028-04-10");

        mvc.perform(post("/api/me/trips/" + tripA + "/expenses")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(expensePayload(dayInTripB, null, "TRANSPORT", "100000", "VND", "Taxi", "2028-04-01")))
            .andExpect(status().isBadRequest());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // AMOUNT VALIDATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void expenseAmount_validation() throws Exception {
        String token = registerAndLogin("budget-amountval");
        Long tripId = createTrip(token, "Amount Validation Trip", "Can Tho", "2028-04-20", "2028-04-25");

        mvc.perform(post("/api/me/trips/" + tripId + "/expenses")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(expensePayload(null, null, "FOOD", "-50", "VND", "Bad expense", "2028-04-20")))
            .andExpect(status().isBadRequest());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // LIST / SORTING
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void listExpenses_sorted() throws Exception {
        String token = registerAndLogin("budget-listsort");
        Long tripId = createTrip(token, "List Sort Trip", "Vinh", "2028-05-01", "2028-05-10");

        addExpense(token, tripId, expensePayload(null, null, "FOOD", "100000", "VND", "Day1 lunch", "2028-05-01"));
        addExpense(token, tripId, expensePayload(null, null, "TRANSPORT", "200000", "VND", "Day5 taxi", "2028-05-05"));
        addExpense(token, tripId, expensePayload(null, null, "SHOPPING", "300000", "VND", "Day3 souvenirs", "2028-05-03"));

        String body = mvc.perform(get("/api/me/trips/" + tripId + "/expenses")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode list = mapper.readTree(body);
        assertEquals(3, list.size());
        assertEquals("Day5 taxi", list.get(0).get("title").asText());
        assertEquals("Day3 souvenirs", list.get(1).get("title").asText());
        assertEquals("Day1 lunch", list.get(2).get("title").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SUMMARY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void budgetSummary_calculatesSpentRemainingOverBudget() throws Exception {
        String token = registerAndLogin("budget-summary");
        Long tripId = createTrip(token, "Summary Trip", "Quy Nhon", "2028-05-15", "2028-05-20");
        putBudget(token, tripId, "1000000", "VND", null);

        addExpense(token, tripId, expensePayload(null, null, "FOOD", "700000", "VND", "Meals", "2028-05-15"));
        addExpense(token, tripId, expensePayload(null, null, "TRANSPORT", "500000", "VND", "Flights", "2028-05-16"));

        String body = mvc.perform(get("/api/me/trips/" + tripId + "/budget-summary")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals(1000000, res.get("totalBudget").asDouble());
        assertEquals(1200000, res.get("totalSpent").asDouble());
        assertEquals(-200000, res.get("remainingBudget").asDouble());
        assertTrue(res.get("overBudget").asBoolean());
    }

    @Test
    void categoryBreakdown_works() throws Exception {
        String token = registerAndLogin("budget-breakdown");
        Long tripId = createTrip(token, "Breakdown Trip", "Hue", "2028-06-01", "2028-06-05");

        addExpense(token, tripId, expensePayload(null, null, "FOOD", "100000", "VND", "Lunch", "2028-06-01"));
        addExpense(token, tripId, expensePayload(null, null, "FOOD", "50000", "VND", "Coffee", "2028-06-02"));
        addExpense(token, tripId, expensePayload(null, null, "TRANSPORT", "300000", "VND", "Bus", "2028-06-03"));

        String body = mvc.perform(get("/api/me/trips/" + tripId + "/budget-summary")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode breakdown = mapper.readTree(body).get("categoryBreakdown");
        double foodTotal = 0, transportTotal = 0;
        for (JsonNode n : breakdown) {
            if (n.get("category").asText().equals("FOOD")) foodTotal = n.get("totalAmount").asDouble();
            if (n.get("category").asText().equals("TRANSPORT")) transportTotal = n.get("totalAmount").asDouble();
        }
        assertEquals(150000, foodTotal);
        assertEquals(300000, transportTotal);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // DELETE EXPENSE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void deleteExpense_succeeds() throws Exception {
        String token = registerAndLogin("budget-deleteexpense");
        Long tripId = createTrip(token, "Delete Expense Trip", "Phan Thiet", "2028-06-10", "2028-06-15");
        Long expenseId = mapper.readTree(addExpense(token, tripId,
            expensePayload(null, null, "OTHER", "20000", "VND", "Misc", "2028-06-10"))).get("id").asLong();

        mvc.perform(delete("/api/me/trips/expenses/" + expenseId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNoContent());

        mvc.perform(get("/api/me/trips/expenses/" + expenseId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // COLLABORATOR / OWNERSHIP ISOLATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void viewerCollaboratorCanRead() throws Exception {
        String ownerToken = registerAndLogin("budget-viewread-owner");
        String viewerToken = registerAndLogin("budget-viewread-viewer");
        Long tripId = createTrip(ownerToken, "Viewer Read Budget Trip", "Ha Giang", "2028-07-01", "2028-07-05");
        putBudget(ownerToken, tripId, "3000000", "VND", null);
        invite(ownerToken, tripId, emailOf(viewerToken), "VIEWER");

        mvc.perform(get("/api/me/trips/" + tripId + "/budget")
                .header("Authorization", "Bearer " + viewerToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.totalBudget").value(3000000));
    }

    @Test
    void nonCollaboratorCannotReadPrivateTripBudget() throws Exception {
        String ownerToken = registerAndLogin("budget-stranger-owner");
        String strangerToken = registerAndLogin("budget-stranger");
        Long tripId = createTrip(ownerToken, "Private Budget Trip", "Cao Bang", "2028-07-10", "2028-07-15");
        putBudget(ownerToken, tripId, "1000000", "VND", null);

        mvc.perform(get("/api/me/trips/" + tripId + "/budget")
                .header("Authorization", "Bearer " + strangerToken))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // TRIP DELETION CASCADE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void deleteTrip_cascadesBudgetAndExpenses() throws Exception {
        String token = registerAndLogin("budget-cascade");
        Long tripId = createTrip(token, "Cascade Budget Trip", "Lao Cai", "2028-08-01", "2028-08-05");
        putBudget(token, tripId, "2000000", "VND", null);
        Long expenseId = mapper.readTree(addExpense(token, tripId,
            expensePayload(null, null, "FOOD", "50000", "VND", "Snacks", "2028-08-01"))).get("id").asLong();

        mvc.perform(delete("/api/me/trips/" + tripId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNoContent());

        mvc.perform(get("/api/me/trips/" + tripId + "/budget")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNotFound());
        mvc.perform(get("/api/me/trips/expenses/" + expenseId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // AUTH
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void unauthenticated_rejected() throws Exception {
        mvc.perform(get("/api/me/trips/1/budget"))
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

    private void putBudget(String token, Long tripId, String totalBudget, String currency, String notes) throws Exception {
        mvc.perform(put("/api/me/trips/" + tripId + "/budget")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"totalBudget\":" + totalBudget + ",\"currency\":\"" + currency + "\",\"notes\":"
                    + (notes == null ? "null" : "\"" + notes + "\"") + "}"))
            .andExpect(status().isOk());
    }

    private String expensePayload(Long tripDayId, Long tripItemId, String category, String amount,
                                   String currency, String title, String expenseDate) {
        return "{\"tripDayId\":" + tripDayId
            + ",\"tripItemId\":" + tripItemId
            + ",\"category\":\"" + category + "\""
            + ",\"amount\":" + amount
            + ",\"currency\":\"" + currency + "\""
            + ",\"title\":\"" + title + "\""
            + ",\"notes\":null"
            + ",\"expenseDate\":\"" + expenseDate + "\"}";
    }

    private String addExpense(String token, Long tripId, String payload) throws Exception {
        return mvc.perform(post("/api/me/trips/" + tripId + "/expenses")
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
