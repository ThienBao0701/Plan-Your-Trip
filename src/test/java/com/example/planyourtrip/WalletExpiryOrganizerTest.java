package com.example.planyourtrip;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
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
 * WalletExpiryOrganizerTest — Phase 7.13 (Wallet Expiry Alerts &amp; Smart Organizer).
 * Covers the read-only Smart Organizer views (summary/organized/expiring-soon/
 * expired/upcoming/unlinked + the enhanced list filters) and the manual
 * expiry-reminder generation triggers on top of the Phase 7.12 Travel Wallet
 * and Phase 7.10/7.11 reminder foundations. Every scenario registers its own
 * throwaway user(s) (and trip(s), where needed) so wallet/reminder state
 * never leaks across tests — mirrors TravelWalletTest's / TripReminderDeliveryTest's
 * conventions.
 */
@SpringBootTest
@AutoConfigureMockMvc
class WalletExpiryOrganizerTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;

    private static final AtomicInteger counter = new AtomicInteger(1);
    private static final LocalDate TODAY = LocalDate.now();

    // ═══════════════════════════════════════════════════════════════════════════
    // 1: SUMMARY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void walletSummaryReturnsCorrectCounts() throws Exception {
        String token = registerAndLogin("summary");
        Long tripId = createTrip(token, "Summary Trip", "Da Nang", "2029-05-01", "2029-05-10");

        createItem(token, walletPayload(null, "OTHER", "Active plain", null, null));
        createItem(token, walletPayload(null, "OTHER", "Upcoming pass", TODAY.plusDays(10).toString(), null));
        createItem(token, walletPayload(null, "VISA", "Expiring soon visa", null, TODAY.plusDays(5).toString()));
        createItem(token, walletPayload(null, "VISA", "Expired old visa", null, TODAY.minusDays(5).toString()));
        Long toArchiveId = createItem(token, walletPayload(null, "OTHER", "To be archived", null, null)).get("id").asLong();
        Long toFavoriteId = createItem(token, walletPayload(null, "OTHER", "To be favorited", null, null)).get("id").asLong();
        createItem(token, walletPayload(tripId, "OTHER", "Trip linked item", null, null));

        archiveItem(token, toArchiveId);
        favoriteItem(token, toFavoriteId);

        JsonNode s = getJson(token, "/api/me/travel-wallet/summary");

        assertEquals(7, s.get("totalItems").asLong());
        assertEquals(4, s.get("activeItems").asLong(), "active/no-dates/favorited/trip-linked/expiring-soon items, minus the archived one");
        assertEquals(1, s.get("upcomingItems").asLong());
        assertEquals(1, s.get("expiringSoonItems").asLong());
        assertEquals(1, s.get("expiredItems").asLong());
        assertEquals(1, s.get("archivedItems").asLong());
        assertEquals(1, s.get("favoriteItems").asLong());
        assertEquals(6, s.get("unlinkedItems").asLong(), "everything except the trip-linked item");
        assertEquals(5, s.get("countsByType").get("OTHER").asLong());
        assertEquals(2, s.get("countsByType").get("VISA").asLong());
        assertEquals(1, s.get("countsByTrip").get(tripId.toString()).asLong());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 2: ORGANIZED / FAVORITES
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void organizedResponseGroupsFavoritesFirst() throws Exception {
        String token = registerAndLogin("organized-fav");
        createItem(token, walletPayload(null, "OTHER", "Not favorited", null, null));
        Long favId = createItem(token, walletPayload(null, "OTHER", "Favorited item", null, null)).get("id").asLong();
        favoriteItem(token, favId);

        JsonNode org = getJson(token, "/api/me/travel-wallet/organized");

        JsonNode favorites = org.get("favorites");
        assertEquals(1, favorites.size());
        assertEquals(favId, favorites.get(0).get("id").asLong());
        assertTrue(favorites.get(0).get("favorite").asBoolean());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 3-6: DEDICATED GROUP ENDPOINTS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void expiringSoonEndpointReturnsItemsWithin30Days() throws Exception {
        String token = registerAndLogin("group-expiring");
        createItem(token, walletPayload(null, "VISA", "Within window", null, TODAY.plusDays(10).toString()));
        createItem(token, walletPayload(null, "VISA", "Outside window", null, TODAY.plusDays(40).toString()));
        createItem(token, walletPayload(null, "VISA", "Already expired", null, TODAY.minusDays(3).toString()));

        JsonNode group = getJson(token, "/api/me/travel-wallet/expiring-soon");

        assertEquals(1, group.get("count").asLong());
        assertEquals("Within window", group.get("items").get(0).get("displayTitle").asText());
    }

    @Test
    void expiredEndpointReturnsExpiredItems() throws Exception {
        String token = registerAndLogin("group-expired");
        createItem(token, walletPayload(null, "VISA", "Long expired", null, TODAY.minusDays(20).toString()));
        createItem(token, walletPayload(null, "OTHER", "Still active", null, null));

        JsonNode group = getJson(token, "/api/me/travel-wallet/expired");

        assertEquals(1, group.get("count").asLong());
        assertEquals("Long expired", group.get("items").get(0).get("displayTitle").asText());
    }

    @Test
    void upcomingEndpointReturnsFutureValidItems() throws Exception {
        String token = registerAndLogin("group-upcoming");
        createItem(token, walletPayload(null, "FLIGHT_TICKET", "Future ticket", TODAY.plusDays(15).toString(), null));
        createItem(token, walletPayload(null, "OTHER", "Already valid", null, null));

        JsonNode group = getJson(token, "/api/me/travel-wallet/upcoming");

        assertEquals(1, group.get("count").asLong());
        assertEquals("Future ticket", group.get("items").get(0).get("displayTitle").asText());
    }

    @Test
    void unlinkedEndpointReturnsMetadataOnlyItems() throws Exception {
        String token = registerAndLogin("group-unlinked");
        Long tripId = createTrip(token, "Unlinked Check Trip", "Hue", "2029-06-01", "2029-06-05");
        createItem(token, walletPayload(null, "OTHER", "Metadata only", null, null));
        createItem(token, walletPayload(tripId, "OTHER", "Trip linked", null, null));

        JsonNode group = getJson(token, "/api/me/travel-wallet/unlinked");

        assertEquals(1, group.get("count").asLong());
        assertEquals("Metadata only", group.get("items").get(0).get("displayTitle").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 7-10: LIST FILTERS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void listFilterByType() throws Exception {
        String token = registerAndLogin("filter-type");
        createItem(token, walletPayload(null, "OTHER", "Other item", null, null));
        createItem(token, walletPayload(null, "VISA", "Visa item", null, null));

        JsonNode arr = getJson(token, "/api/me/travel-wallet?type=VISA");

        assertEquals(1, arr.size());
        assertEquals("VISA", arr.get(0).get("walletItemType").asText());
    }

    @Test
    void listFilterByStatus() throws Exception {
        String token = registerAndLogin("filter-status");
        createItem(token, walletPayload(null, "VISA", "Expired filter item", null, TODAY.minusDays(3).toString()));
        createItem(token, walletPayload(null, "OTHER", "Active filter item", null, null));

        JsonNode arr = getJson(token, "/api/me/travel-wallet?status=EXPIRED");

        assertEquals(1, arr.size());
        assertEquals("Expired filter item", arr.get(0).get("displayTitle").asText());
        assertEquals("EXPIRED", arr.get(0).get("effectiveStatus").asText());
    }

    @Test
    void listFilterByTripId() throws Exception {
        String token = registerAndLogin("filter-trip");
        Long tripA = createTrip(token, "Trip A Filter", "Nha Trang", "2029-07-01", "2029-07-05");
        Long tripB = createTrip(token, "Trip B Filter", "Phu Quoc", "2029-08-01", "2029-08-05");
        createItem(token, walletPayload(tripA, "OTHER", "In trip A", null, null));
        createItem(token, walletPayload(tripB, "OTHER", "In trip B", null, null));

        JsonNode arr = getJson(token, "/api/me/travel-wallet?tripId=" + tripA);

        assertEquals(1, arr.size());
        assertEquals("In trip A", arr.get(0).get("displayTitle").asText());
    }

    @Test
    void listFilterByFavorite() throws Exception {
        String token = registerAndLogin("filter-fav");
        createItem(token, walletPayload(null, "OTHER", "Plain item", null, null));
        Long favId = createItem(token, walletPayload(null, "OTHER", "Fav filter item", null, null)).get("id").asLong();
        favoriteItem(token, favId);

        JsonNode arr = getJson(token, "/api/me/travel-wallet?favorite=true");

        assertEquals(1, arr.size());
        assertEquals(favId, arr.get(0).get("id").asLong());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 11: ARCHIVED EXCLUSION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void archivedItemsExcludedFromActiveGroupsByDefault() throws Exception {
        String token = registerAndLogin("archived-exclusion");
        Long activeId = createItem(token, walletPayload(null, "OTHER", "Stays active", null, null)).get("id").asLong();
        Long archivedId = createItem(token, walletPayload(null, "OTHER", "Gets archived", null, null)).get("id").asLong();
        archiveItem(token, archivedId);

        JsonNode org = getJson(token, "/api/me/travel-wallet/organized");

        assertTrue(containsId(org.get("active"), activeId));
        assertFalse(containsId(org.get("active"), archivedId), "Archived item must not appear in the active group by default");
        assertTrue(containsId(org.get("archived"), archivedId));
        assertFalse(containsId(org.get("archived"), activeId));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 12-16: REMINDER GENERATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void generatesThirtyDayReminder() throws Exception {
        String token = registerAndLogin("gen-30");
        Long tripId = createTrip(token, "Gen30 Trip", "Hanoi", "2029-01-01", "2029-01-10");
        createItem(token, walletPayload(tripId, "VISA", "30-day visa", null, TODAY.plusDays(31).toString()));

        JsonNode result = generateForUser(token);
        assertTrue(result.get("remindersCreated").asInt() >= 1);

        JsonNode reminders = tripReminders(token, tripId);
        assertTrue(hasTitle(reminders, "Travel document expires in 30 days"));
    }

    @Test
    void generatesSevenDayReminder() throws Exception {
        String token = registerAndLogin("gen-7");
        Long tripId = createTrip(token, "Gen7 Trip", "Hanoi", "2029-01-01", "2029-01-10");
        createItem(token, walletPayload(tripId, "VISA", "7-day visa", null, TODAY.plusDays(31).toString()));

        generateForUser(token);

        JsonNode reminders = tripReminders(token, tripId);
        assertTrue(hasTitle(reminders, "Travel document expires in 7 days"));
    }

    @Test
    void generatesOneDayReminder() throws Exception {
        String token = registerAndLogin("gen-1");
        Long tripId = createTrip(token, "Gen1 Trip", "Hanoi", "2029-01-01", "2029-01-10");
        createItem(token, walletPayload(tripId, "VISA", "1-day visa", null, TODAY.plusDays(31).toString()));

        generateForUser(token);

        JsonNode reminders = tripReminders(token, tripId);
        assertTrue(hasTitle(reminders, "Travel document expires tomorrow"));
    }

    @Test
    void pastReminderAtNotCreated() throws Exception {
        String token = registerAndLogin("gen-past");
        // validUntil so close that the 30-day-before reminderAt (validUntil - 30d) is already
        // in the past, while the 7-day and 1-day windows are still in the future.
        Long tripId = createTrip(token, "GenPast Trip", "Hanoi", "2029-01-01", "2029-01-10");
        createItem(token, walletPayload(tripId, "VISA", "Soon-expiring visa", null, TODAY.plusDays(29).toString()));

        JsonNode result = generateForUser(token);
        assertTrue(result.get("remindersSkipped").asInt() >= 1);

        JsonNode reminders = tripReminders(token, tripId);
        assertFalse(hasTitle(reminders, "Travel document expires in 30 days"),
            "The 30-day window's reminderAt is already in the past and must be skipped, not created");
        assertTrue(hasTitle(reminders, "Travel document expires in 7 days"), "The 7-day window is still in the future and must be created");
    }

    @Test
    void generationIsIdempotent() throws Exception {
        String token = registerAndLogin("gen-idempotent");
        Long tripId = createTrip(token, "GenIdempotent Trip", "Hanoi", "2029-01-01", "2029-01-10");
        createItem(token, walletPayload(tripId, "VISA", "Idempotent visa", null, TODAY.plusDays(31).toString()));

        JsonNode first = generateForUser(token);
        assertEquals(3, first.get("remindersCreated").asInt());

        int countAfterFirst = tripReminders(token, tripId).size();

        JsonNode second = generateForUser(token);
        assertEquals(0, second.get("remindersCreated").asInt(), "Repeated generation must not create duplicate reminders");

        int countAfterSecond = tripReminders(token, tripId).size();
        assertEquals(countAfterFirst, countAfterSecond, "Reminder count must stay the same across repeated generation runs");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 17-20: OWNERSHIP / ADMIN / SECURITY ON GENERATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void singleItemGenerationEnforcesOwnership() throws Exception {
        String owner = registerAndLogin("gen-owner");
        String stranger = registerAndLogin("gen-stranger");
        Long itemId = createItem(owner, walletPayload(null, "VISA", "Owner-only visa", null, TODAY.plusDays(31).toString())).get("id").asLong();

        mvc.perform(post("/api/me/travel-wallet/" + itemId + "/generate-expiry-reminders")
                .header("Authorization", "Bearer " + stranger))
            .andExpect(status().isNotFound());
    }

    @Test
    void userTriggerCreatesOnlyOwnReminders() throws Exception {
        String userA = registerAndLogin("gen-scope-a");
        String userB = registerAndLogin("gen-scope-b");
        Long tripA = createTrip(userA, "Scope A Trip", "Hanoi", "2029-01-01", "2029-01-10");
        Long tripB = createTrip(userB, "Scope B Trip", "Hanoi", "2029-01-01", "2029-01-10");
        createItem(userA, walletPayload(tripA, "VISA", "A's visa", null, TODAY.plusDays(31).toString()));
        createItem(userB, walletPayload(tripB, "VISA", "B's visa", null, TODAY.plusDays(31).toString()));

        generateForUser(userA);

        JsonNode remindersA = tripReminders(userA, tripA);
        assertTrue(hasTitle(remindersA, "Travel document expires in 30 days"));

        JsonNode remindersB = tripReminders(userB, tripB);
        assertEquals(0, remindersB.size(), "User A's generation trigger must not create reminders for user B's items");
    }

    @Test
    void adminTriggerProcessesMultipleUsers() throws Exception {
        String user1 = registerAndLogin("gen-admin-1");
        String user2 = registerAndLogin("gen-admin-2");
        Long trip1 = createTrip(user1, "Admin Gen Trip 1", "Hanoi", "2029-01-01", "2029-01-10");
        Long trip2 = createTrip(user2, "Admin Gen Trip 2", "Hanoi", "2029-01-01", "2029-01-10");
        createItem(user1, walletPayload(trip1, "VISA", "User1 visa", null, TODAY.plusDays(31).toString()));
        createItem(user2, walletPayload(trip2, "VISA", "User2 visa", null, TODAY.plusDays(31).toString()));

        String resultBody = mvc.perform(post("/api/admin/travel-wallet/generate-expiry-reminders")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode result = mapper.readTree(resultBody);
        assertTrue(result.get("usersProcessed").asInt() >= 2);
        assertTrue(result.get("remindersCreated").asInt() >= 2);

        assertTrue(hasTitle(tripReminders(user1, trip1), "Travel document expires in 30 days"));
        assertTrue(hasTitle(tripReminders(user2, trip2), "Travel document expires in 30 days"));
    }

    @Test
    void nonAdminAdminTriggerRejected() throws Exception {
        String token = registerAndLogin("gen-non-admin");

        mvc.perform(post("/api/admin/travel-wallet/generate-expiry-reminders")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 21: SENSITIVE DATA MUST NOT LEAK
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void sensitiveReferenceNeverLeaksIntoReminderMessage() throws Exception {
        String token = registerAndLogin("gen-mask");
        Long tripId = createTrip(token, "Mask Trip", "Hanoi", "2029-01-01", "2029-01-10");
        String raw = "AB1234567890";

        JsonNode created = createItem(token, walletPayload(tripId, "PASSPORT", "Masked passport",
            null, TODAY.plusDays(31).toString(), raw, null));
        String masked = created.get("referenceNumberMasked").asText();
        assertNotEquals(raw, masked);

        generateForUser(token);

        JsonNode reminders = tripReminders(token, tripId);
        boolean checkedAny = false;
        for (JsonNode r : reminders) {
            checkedAny = true;
            String title = r.get("title").asText();
            String message = r.get("message") == null || r.get("message").isNull() ? "" : r.get("message").asText();
            assertFalse(title.contains(raw), "Title must never contain the raw reference value");
            assertFalse(message.contains(raw), "Message must never contain the raw reference value");
            assertFalse(title.contains(masked), "Title must never contain the masked reference value either");
            assertFalse(message.contains(masked), "Message must never contain the masked reference value either");
            assertTrue(message.contains("PASSPORT"), "Message must still include the walletItemType");
            assertTrue(message.contains("Masked passport"), "Message must still include the displayTitle");
        }
        assertTrue(checkedAny, "At least one reminder must have been generated to check");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 22: expiryReminderEnabled=false
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void expiryReminderDisabledPreventsGeneration() throws Exception {
        String token = registerAndLogin("gen-disabled");
        Long tripId = createTrip(token, "Disabled Trip", "Hanoi", "2029-01-01", "2029-01-10");
        createItem(token, walletPayload(tripId, "VISA", "Opted-out visa", null, TODAY.plusDays(31).toString(), null, false));

        JsonNode result = generateForUser(token);
        assertEquals(0, result.get("remindersCreated").asInt());

        JsonNode reminders = tripReminders(token, tripId);
        assertEquals(0, reminders.size());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 23: UNAUTHENTICATED
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void unauthenticatedRejected() throws Exception {
        mvc.perform(get("/api/me/travel-wallet/summary")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/me/travel-wallet/organized")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/me/travel-wallet/expiring-soon")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/me/travel-wallet/expired")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/me/travel-wallet/upcoming")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/me/travel-wallet/unlinked")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/me/travel-wallet/generate-expiry-reminders")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/me/travel-wallet/1/generate-expiry-reminders")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/admin/travel-wallet/generate-expiry-reminders")).andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 24: FULL REGRESSION SANITY (rest of the suite is verified by the full run)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void existingModulesUnaffected_fullRegressionSanity() throws Exception {
        mvc.perform(get("/api/admin/invoices")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk());
        mvc.perform(get("/api/admin/bookings")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk());

        // Phase 7.10/7.11 trip reminders (unrelated tripPlan-scoped reminder, not wallet-generated)
        // must still round-trip exactly as before — confirms the nullable-tripPlan schema change
        // and the new sourceType/sourceId/sourceKey columns didn't disturb ordinary CRUD.
        String token = registerAndLogin("regression-sanity");
        Long tripId = createTrip(token, "Regression Trip", "Hanoi", "2029-01-01", "2029-01-10");
        String reminderPayload = "{\"tripDayId\":null,\"tripItemId\":null,\"documentId\":null"
            + ",\"reminderType\":\"CUSTOM\",\"title\":\"Plain reminder\",\"message\":null"
            + ",\"reminderAt\":\"2099-01-01T09:00:00Z\"}";
        JsonNode created = mapper.readTree(mvc.perform(post("/api/me/trips/" + tripId + "/reminders")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(reminderPayload))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString());
        assertEquals(tripId, created.get("tripPlanId").asLong());
        assertEquals("Plain reminder", created.get("title").asText());
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

    private String walletPayload(Long tripPlanId, String walletItemType, String displayTitle,
                                  String validFrom, String validUntil) {
        return walletPayload(tripPlanId, walletItemType, displayTitle, validFrom, validUntil, null, null);
    }

    private String walletPayload(Long tripPlanId, String walletItemType, String displayTitle,
                                  String validFrom, String validUntil, String referenceNumber, Boolean expiryReminderEnabled) {
        return String.format("""
                {"tripPlanId":%s,"tripPlanDocumentId":null,"bookingId":null,"invoiceId":null,
                 "walletItemType":"%s","displayTitle":"%s","issuer":null,"referenceNumber":%s,
                 "validFrom":%s,"validUntil":%s,"status":null,"expiryReminderEnabled":%s}
                """,
            tripPlanId == null ? "null" : tripPlanId,
            walletItemType, displayTitle,
            referenceNumber == null ? "null" : "\"" + referenceNumber + "\"",
            validFrom == null ? "null" : "\"" + validFrom + "\"",
            validUntil == null ? "null" : "\"" + validUntil + "\"",
            expiryReminderEnabled == null ? "null" : expiryReminderEnabled);
    }

    private JsonNode createItem(String token, String payload) throws Exception {
        String body = mvc.perform(post("/api/me/travel-wallet")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private void favoriteItem(String token, Long id) throws Exception {
        mvc.perform(patch("/api/me/travel-wallet/" + id + "/favorite")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
    }

    private void archiveItem(String token, Long id) throws Exception {
        mvc.perform(patch("/api/me/travel-wallet/" + id + "/archive")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
    }

    private JsonNode getJson(String token, String url) throws Exception {
        String body = mvc.perform(get(url).header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode generateForUser(String token) throws Exception {
        String body = mvc.perform(post("/api/me/travel-wallet/generate-expiry-reminders")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode tripReminders(String token, Long tripId) throws Exception {
        String body = mvc.perform(get("/api/me/trips/" + tripId + "/reminders")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private boolean hasTitle(JsonNode arr, String title) {
        for (JsonNode n : arr) if (title.equals(n.get("title").asText())) return true;
        return false;
    }

    private boolean containsId(JsonNode arr, Long id) {
        for (JsonNode n : arr) if (n.get("id").asLong() == id) return true;
        return false;
    }
}
