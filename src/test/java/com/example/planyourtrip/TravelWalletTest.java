package com.example.planyourtrip;

import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PlaceRepository;
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
 * TravelWalletTest — Phase 7.12 (Travel Wallet Foundation).
 * Aggregates existing TripPlanDocument/Booking/Invoice rows into a per-user
 * wallet without duplicating their file/business data. Every scenario
 * registers its own throwaway user(s) (and, where a booking/invoice is
 * needed, books the seeded SUITE-KNG room like InvoiceTest/BookingTest) so
 * wallet state never leaks across tests.
 */
@SpringBootTest
@AutoConfigureMockMvc
class TravelWalletTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;

    private static final AtomicInteger counter = new AtomicInteger(1);
    private static final LocalDate TODAY = LocalDate.now();
    private static final AtomicInteger dayCursor = new AtomicInteger(10);

    private Long suiteRoomId;

    @BeforeEach
    void setup() {
        Long placeId = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        suiteRoomId = hotelRoomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "SUITE-KNG".equals(r.getRoomCode()))
            .findFirst().orElseThrow().getId();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 1-3: CREATE / LIST / GET
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void createsMetadataOnlyWalletItem() throws Exception {
        String token = registerAndLogin("wallet-create");

        JsonNode res = createItem(token, metadataPayload("My spare cash note", "OTHER", null, null));

        assertNotNull(res.get("id"));
        assertEquals("My spare cash note", res.get("displayTitle").asText());
        assertEquals("OTHER", res.get("walletItemType").asText());
        assertFalse(res.get("favorite").asBoolean());
        assertFalse(res.get("archived").asBoolean());
        assertTrue(res.get("document") == null || res.get("document").isNull());
        assertTrue(res.get("booking") == null || res.get("booking").isNull());
        assertTrue(res.get("invoice") == null || res.get("invoice").isNull());
    }

    @Test
    void listsWalletItems() throws Exception {
        String token = registerAndLogin("wallet-list");
        createItem(token, metadataPayload("List item A", "OTHER", null, null));
        createItem(token, metadataPayload("List item B", "ITINERARY", null, null));

        JsonNode arr = mapper.readTree(mvc.perform(get("/api/me/travel-wallet")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());

        assertEquals(2, arr.size());
    }

    @Test
    void getsOwnWalletItem() throws Exception {
        String token = registerAndLogin("wallet-get");
        Long id = createItem(token, metadataPayload("Gettable item", "OTHER", null, null)).get("id").asLong();

        mvc.perform(get("/api/me/travel-wallet/" + id)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(id))
            .andExpect(jsonPath("$.displayTitle").value("Gettable item"));
    }

    @Test
    void anotherUserGets404() throws Exception {
        String owner = registerAndLogin("wallet-owner-404");
        String stranger = registerAndLogin("wallet-stranger-404");
        Long id = createItem(owner, metadataPayload("Private item", "OTHER", null, null)).get("id").asLong();

        mvc.perform(get("/api/me/travel-wallet/" + id)
                .header("Authorization", "Bearer " + stranger))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 5-8: UPDATE / FAVORITE / ARCHIVE / DELETE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void updatesWalletItem() throws Exception {
        String token = registerAndLogin("wallet-update");
        Long id = createItem(token, metadataPayload("Old title", "OTHER", null, null)).get("id").asLong();

        JsonNode res = mapper.readTree(mvc.perform(put("/api/me/travel-wallet/" + id)
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(metadataPayload("New title", "INSURANCE", null, null)))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());

        assertEquals("New title", res.get("displayTitle").asText());
        assertEquals("INSURANCE", res.get("walletItemType").asText());
    }

    @Test
    void favoritesAndUnfavorites() throws Exception {
        String token = registerAndLogin("wallet-favorite");
        Long id = createItem(token, metadataPayload("Fav item", "OTHER", null, null)).get("id").asLong();

        JsonNode faved = mapper.readTree(mvc.perform(patch("/api/me/travel-wallet/" + id + "/favorite")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertTrue(faved.get("favorite").asBoolean());

        JsonNode unfaved = mapper.readTree(mvc.perform(patch("/api/me/travel-wallet/" + id + "/unfavorite")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertFalse(unfaved.get("favorite").asBoolean());
    }

    @Test
    void archivesAndRestores() throws Exception {
        String token = registerAndLogin("wallet-archive");
        Long id = createItem(token, metadataPayload("Archive item", "OTHER", null, null)).get("id").asLong();

        JsonNode archived = mapper.readTree(mvc.perform(patch("/api/me/travel-wallet/" + id + "/archive")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertTrue(archived.get("archived").asBoolean());
        assertEquals("ARCHIVED", archived.get("effectiveStatus").asText());

        // Soft delete: item must still be gettable directly by id.
        mvc.perform(get("/api/me/travel-wallet/" + id)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        JsonNode restored = mapper.readTree(mvc.perform(patch("/api/me/travel-wallet/" + id + "/restore")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertFalse(restored.get("archived").asBoolean());
    }

    @Test
    void deletesWalletItem() throws Exception {
        String token = registerAndLogin("wallet-delete");
        Long id = createItem(token, metadataPayload("Delete item", "OTHER", null, null)).get("id").asLong();

        mvc.perform(delete("/api/me/travel-wallet/" + id)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNoContent());

        mvc.perform(get("/api/me/travel-wallet/" + id)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 9-10: MASKING / EXPIRY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void referenceNumberStoredMaskedOnly() throws Exception {
        String token = registerAndLogin("wallet-mask");
        String raw = "AB1234567890";

        String payload = String.format("""
                {"tripPlanId":null,"tripPlanDocumentId":null,"bookingId":null,"invoiceId":null,
                 "walletItemType":"PASSPORT","displayTitle":"My passport","issuer":"Immigration",
                 "referenceNumber":"%s","validFrom":null,"validUntil":null,"status":null}
                """, raw);

        JsonNode res = createItem(token, payload);
        String masked = res.get("referenceNumberMasked").asText();

        assertNotEquals(raw, masked, "The raw reference number must never be returned verbatim");
        assertTrue(masked.endsWith("7890"), "Masked value must retain the last 4 characters");
        assertFalse(masked.contains("AB12"), "Masked value must not leak the masked-out prefix");
        assertFalse(res.toString().contains(raw), "Raw reference number must not appear anywhere in the response");

        // Also verify it round-trips masked through a plain GET (i.e. is what got persisted).
        Long id = res.get("id").asLong();
        JsonNode fetched = mapper.readTree(mvc.perform(get("/api/me/travel-wallet/" + id)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertEquals(masked, fetched.get("referenceNumberMasked").asText());
        assertFalse(fetched.toString().contains(raw));
    }

    @Test
    void expiredStatusComputedFromValidUntil_withoutDbWriteChangingStatus() throws Exception {
        String token = registerAndLogin("wallet-expired");

        String payload = """
                {"tripPlanId":null,"tripPlanDocumentId":null,"bookingId":null,"invoiceId":null,
                 "walletItemType":"VISA","displayTitle":"Old visa","issuer":null,
                 "referenceNumber":null,"validFrom":null,"validUntil":"2020-01-01","status":null}
                """;

        JsonNode created = createItem(token, payload);
        assertEquals("ACTIVE", created.get("status").asText(), "Stored status must remain ACTIVE (not overwritten)");
        assertEquals("EXPIRED", created.get("effectiveStatus").asText());
        assertTrue(created.get("expired").asBoolean());

        // Re-fetch: still computed on read, never persisted as EXPIRED.
        Long id = created.get("id").asLong();
        JsonNode fetched = mapper.readTree(mvc.perform(get("/api/me/travel-wallet/" + id)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertEquals("ACTIVE", fetched.get("status").asText());
        assertEquals("EXPIRED", fetched.get("effectiveStatus").asText());
        assertTrue(fetched.get("expired").asBoolean());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 11-12: IMPORT TRIP DOCUMENT + IDEMPOTENCY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void importsTripPlanDocument() throws Exception {
        String token = registerAndLogin("wallet-import-doc");
        Long tripId = createTrip(token, "Wallet Doc Trip", "Lisbon", "2029-01-01", "2029-01-05");
        Long documentId = addDocument(token, tripId, "https://cdn.example.com/passport.pdf",
            "DOCUMENT", "PASSPORT", "Passport scan").get("id").asLong();

        JsonNode res = mapper.readTree(mvc.perform(post("/api/me/travel-wallet/import/trip-document/" + documentId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());

        assertTrue(res.get("created").asBoolean());
        JsonNode item = res.get("item");
        assertEquals("PASSPORT", item.get("walletItemType").asText());
        assertEquals("Passport scan", item.get("displayTitle").asText());
        assertEquals(documentId, item.get("document").get("id").asLong());
    }

    @Test
    void duplicateTripPlanDocumentImportIsIdempotent() throws Exception {
        String token = registerAndLogin("wallet-import-doc-dup");
        Long tripId = createTrip(token, "Wallet Dup Doc Trip", "Porto", "2029-02-01", "2029-02-05");
        Long documentId = addDocument(token, tripId, "https://cdn.example.com/visa.pdf",
            "DOCUMENT", "VISA", "Visa scan").get("id").asLong();

        JsonNode first = mapper.readTree(mvc.perform(post("/api/me/travel-wallet/import/trip-document/" + documentId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertTrue(first.get("created").asBoolean());
        long firstId = first.get("item").get("id").asLong();

        JsonNode second = mapper.readTree(mvc.perform(post("/api/me/travel-wallet/import/trip-document/" + documentId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertFalse(second.get("created").asBoolean());
        assertEquals(firstId, second.get("item").get("id").asLong());

        JsonNode listArr = mapper.readTree(mvc.perform(get("/api/me/travel-wallet")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        long count = 0;
        for (JsonNode n : listArr) if (n.get("id").asLong() == firstId) count++;
        assertEquals(1, count, "Duplicate import must not create a second row");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 13-16: IMPORT BOOKING / INVOICE + OWNERSHIP
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void importsOwnBooking() throws Exception {
        String token = registerAndLogin("wallet-import-booking");
        Long bookingId = createBooking(token);

        JsonNode res = mapper.readTree(mvc.perform(post("/api/me/travel-wallet/import/booking/" + bookingId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());

        assertTrue(res.get("created").asBoolean());
        JsonNode item = res.get("item");
        assertEquals("BOOKING_CONFIRMATION", item.get("walletItemType").asText());
        assertEquals(bookingId, item.get("booking").get("id").asLong());
        assertNotNull(item.get("referenceNumberMasked"));
    }

    @Test
    void rejectsAnotherUsersBookingImport() throws Exception {
        String owner = registerAndLogin("wallet-booking-owner");
        String stranger = registerAndLogin("wallet-booking-stranger");
        Long bookingId = createBooking(owner);

        mvc.perform(post("/api/me/travel-wallet/import/booking/" + bookingId)
                .header("Authorization", "Bearer " + stranger))
            .andExpect(status().isNotFound());
    }

    @Test
    void importsOwnInvoice() throws Exception {
        String token = registerAndLogin("wallet-import-invoice");
        Long bookingId = createBooking(token);
        Long paymentId = createPayment(token, bookingId);
        mockSuccess(token, paymentId);
        Long invoiceId = createInvoice(token, bookingId, paymentId).get("id").asLong();

        JsonNode res = mapper.readTree(mvc.perform(post("/api/me/travel-wallet/import/invoice/" + invoiceId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());

        assertTrue(res.get("created").asBoolean());
        JsonNode item = res.get("item");
        assertEquals("INVOICE", item.get("walletItemType").asText());
        assertEquals(invoiceId, item.get("invoice").get("id").asLong());
    }

    @Test
    void rejectsAnotherUsersInvoiceImport() throws Exception {
        String owner = registerAndLogin("wallet-invoice-owner");
        String stranger = registerAndLogin("wallet-invoice-stranger");
        Long bookingId = createBooking(owner);
        Long paymentId = createPayment(owner, bookingId);
        mockSuccess(owner, paymentId);
        Long invoiceId = createInvoice(owner, bookingId, paymentId).get("id").asLong();

        mvc.perform(post("/api/me/travel-wallet/import/invoice/" + invoiceId)
                .header("Authorization", "Bearer " + stranger))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 17: DOCUMENT/MEDIA MAPPING REUSE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void documentMediaMappingIsReused() throws Exception {
        String token = registerAndLogin("wallet-media-reuse");
        Long tripId = createTrip(token, "Wallet Media Trip", "Faro", "2029-03-01", "2029-03-05");
        JsonNode doc = addDocument(token, tripId, "https://cdn.example.com/insurance.pdf",
            "DOCUMENT", "INSURANCE", "Travel insurance");
        Long documentId = doc.get("id").asLong();
        String mediaUrl = doc.get("mediaAsset").get("url").asText();

        JsonNode res = mapper.readTree(mvc.perform(post("/api/me/travel-wallet/import/trip-document/" + documentId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());

        JsonNode item = res.get("item");
        assertNotNull(item.get("document"), "Response must embed the nested document DTO");
        assertNotNull(item.get("document").get("mediaAsset"), "Nested document DTO must carry its MediaAsset mapping");
        assertEquals(mediaUrl, item.get("document").get("mediaAsset").get("url").asText());
        // The wallet item itself must not duplicate raw media fields at the top level.
        assertNull(item.get("url"));
        assertNull(item.get("thumbnailUrl"));
        assertNull(item.get("mediaAssetId"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 18: SORTING
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void favoritesSortFirst() throws Exception {
        String token = registerAndLogin("wallet-sort-fav");
        createItem(token, metadataPayload("Older non-favorite", "OTHER", null, null));
        Long secondId = createItem(token, metadataPayload("Newer to be favorited", "OTHER", null, null)).get("id").asLong();

        mvc.perform(patch("/api/me/travel-wallet/" + secondId + "/favorite")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        // Add a third, plain item created after the favorite — favorite must still sort first.
        createItem(token, metadataPayload("Newest non-favorite", "OTHER", null, null));

        JsonNode arr = mapper.readTree(mvc.perform(get("/api/me/travel-wallet")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());

        assertEquals(3, arr.size());
        assertEquals(secondId, arr.get(0).get("id").asLong(), "Favorited item must sort first regardless of creation order");
        assertTrue(arr.get(0).get("favorite").asBoolean());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 19-21: ADMIN + SECURITY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void adminReadOnlyViewWorks() throws Exception {
        String token = registerAndLogin("wallet-admin-view");
        JsonNode created = createItem(token, metadataPayload("Admin visible item", "OTHER", null, null));
        Long userId = created.get("userId").asLong();

        JsonNode arr = mapper.readTree(mvc.perform(get("/api/admin/users/" + userId + "/travel-wallet")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());

        boolean found = false;
        for (JsonNode n : arr) if ("Admin visible item".equals(n.get("displayTitle").asText())) found = true;
        assertTrue(found, "Admin must be able to read another user's wallet items");
    }

    @Test
    void nonAdminAdminViewRejected() throws Exception {
        String token = registerAndLogin("wallet-admin-reject");
        Long userId = createItem(token, metadataPayload("Blocked item", "OTHER", null, null)).get("userId").asLong();

        mvc.perform(get("/api/admin/users/" + userId + "/travel-wallet")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
    }

    @Test
    void unauthenticatedRejected() throws Exception {
        mvc.perform(get("/api/me/travel-wallet")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/me/travel-wallet/1")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/me/travel-wallet")
                .contentType(MediaType.APPLICATION_JSON)
                .content(metadataPayload("x", "OTHER", null, null)))
            .andExpect(status().isUnauthorized());
        mvc.perform(get("/api/admin/users/1/travel-wallet")).andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 22: DELETE DOES NOT CASCADE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void deletingWalletItemDoesNotDeleteUnderlyingRecords() throws Exception {
        String token = registerAndLogin("wallet-no-cascade");
        Long tripId = createTrip(token, "No Cascade Trip", "Sintra", "2029-04-01", "2029-04-05");
        Long documentId = addDocument(token, tripId, "https://cdn.example.com/ticket2.pdf",
            "DOCUMENT", "FLIGHT_TICKET", "Flight ticket").get("id").asLong();
        Long bookingId = createBooking(token);
        Long paymentId = createPayment(token, bookingId);
        mockSuccess(token, paymentId);
        Long invoiceId = createInvoice(token, bookingId, paymentId).get("id").asLong();

        Long docItemId = mapper.readTree(mvc.perform(post("/api/me/travel-wallet/import/trip-document/" + documentId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString()).get("item").get("id").asLong();
        Long bookingItemId = mapper.readTree(mvc.perform(post("/api/me/travel-wallet/import/booking/" + bookingId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString()).get("item").get("id").asLong();
        Long invoiceItemId = mapper.readTree(mvc.perform(post("/api/me/travel-wallet/import/invoice/" + invoiceId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString()).get("item").get("id").asLong();

        mvc.perform(delete("/api/me/travel-wallet/" + docItemId).header("Authorization", "Bearer " + token))
            .andExpect(status().isNoContent());
        mvc.perform(delete("/api/me/travel-wallet/" + bookingItemId).header("Authorization", "Bearer " + token))
            .andExpect(status().isNoContent());
        mvc.perform(delete("/api/me/travel-wallet/" + invoiceItemId).header("Authorization", "Bearer " + token))
            .andExpect(status().isNoContent());

        mvc.perform(get("/api/me/trips/documents/" + documentId).header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
        mvc.perform(get("/api/bookings/" + bookingId).header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
        mvc.perform(get("/api/invoices/" + invoiceId).header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 23: FULL REGRESSION SANITY (rest of the suite is verified by the full run)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void existingModulesUnaffected_seedDataStillVisible() throws Exception {
        mvc.perform(get("/api/admin/invoices")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk());
        mvc.perform(get("/api/admin/bookings")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk());
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

    private String metadataPayload(String displayTitle, String walletItemType, String validFrom, String validUntil) {
        return String.format("""
                {"tripPlanId":null,"tripPlanDocumentId":null,"bookingId":null,"invoiceId":null,
                 "walletItemType":"%s","displayTitle":"%s","issuer":null,"referenceNumber":null,
                 "validFrom":%s,"validUntil":%s,"status":null}
                """,
            walletItemType, displayTitle,
            validFrom == null ? "null" : "\"" + validFrom + "\"",
            validUntil == null ? "null" : "\"" + validUntil + "\"");
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

    private JsonNode addDocument(String token, Long tripId, String url, String mediaType, String documentType, String title) throws Exception {
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

    private Long createBooking(String token) throws Exception {
        LocalDate ci = TODAY.plusDays(dayCursor.getAndAdd(3));
        LocalDate co = ci.plusDays(2);

        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format(
                    "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\",\"adults\":2,\"children\":0,\"numberOfRooms\":1}",
                    suiteRoomId, ci, co)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private Long createPayment(String token, Long bookingId) throws Exception {
        String body = mvc.perform(post("/api/payments")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"paymentMethod\":\"MOCK\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private void mockSuccess(String token, Long paymentId) throws Exception {
        mvc.perform(post("/api/payments/" + paymentId + "/mock-success")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
    }

    private JsonNode createInvoice(String token, Long bookingId, Long paymentId) throws Exception {
        String body = mvc.perform(post("/api/invoices")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format("{\"bookingId\":%d,\"paymentId\":%d}", bookingId, paymentId)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }
}
