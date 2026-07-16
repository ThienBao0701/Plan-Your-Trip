package com.example.planyourtrip;

import com.example.planyourtrip.model.Booking;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.BookingRepository;
import com.example.planyourtrip.repository.CategoryRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * AdminAnalyticsTest — Phase 7.37 (Admin Platform Analytics Overview).
 *
 * <p>The admin overview reports UN-scoped, platform-wide totals, so this suite shares one
 * H2 instance with every other test class (no per-test rollback). Assertions are therefore
 * DELTA-based: each test snapshots the overview, creates its own throwaway fixtures, then
 * asserts the change relative to the snapshot — never an absolute platform total.
 */
@SpringBootTest
@AutoConfigureMockMvc
class AdminAnalyticsTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired BookingRepository bookingRepo;

    private String adminToken;
    private static final AtomicInteger counter = new AtomicInteger(1);

    private Long accCategoryId;
    private Long hotelSubcategoryId;
    private Long locationId;
    private LocalDate today;

    @BeforeEach
    void setup() {
        accCategoryId      = categoryRepo.findBySlug("accommodation").orElseThrow().getId();
        hotelSubcategoryId = categoryRepo.findBySlug("hotel").orElseThrow().getId();
        locationId         = locationRepo.findByCode("VT").orElseThrow().getId();
        today              = LocalDate.now();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // OVERVIEW — TOTALS / STATUS BREAKDOWN / REVENUE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void adminOverview_totalsAndStatusBreakdown() throws Exception {
        JsonNode before = overview(null, null);
        long beforeTotal = before.get("totalBookings").asLong();
        long beforeConfirmed = statusCount(before, "CONFIRMED");

        Fixture f = createPublishedHotelWithRoom("OverviewTotals");
        String guest = registerGuest();
        createAndConfirmBooking(guest, f.roomId, today.plusDays(3), today.plusDays(5));
        createAndConfirmBooking(guest, f.roomId, today.plusDays(6), today.plusDays(8));

        JsonNode after = overview(null, null);
        assertEquals(beforeTotal + 2, after.get("totalBookings").asLong());
        assertEquals(beforeConfirmed + 2, statusCount(after, "CONFIRMED"));

        // Every BookingStatus bucket must be present (0-filled), stable for a dashboard.
        String[] allStatuses = {"PENDING", "CONFIRMED", "CHECK_IN_READY", "CHECKED_IN", "CHECKED_OUT",
            "COMPLETED", "CANCELLED", "REFUNDED", "ARCHIVED", "NO_SHOW"};
        for (String st : allStatuses) {
            assertTrue(hasStatusBucket(after, st), "bookingsByStatus must contain bucket " + st);
        }
    }

    @Test
    void adminOverview_grossRevenueMatchesFinalPriceOfConfirmedBookings() throws Exception {
        JsonNode before = overview(null, null);
        BigDecimal beforeRevenue = new BigDecimal(before.get("grossRevenue").asText());

        Fixture f = createPublishedHotelWithRoom("RevenueDef");
        String guest = registerGuest();
        Long b1 = createAndConfirmBooking(guest, f.roomId, today.plusDays(3), today.plusDays(5));
        Long b2 = createAndConfirmBooking(guest, f.roomId, today.plusDays(6), today.plusDays(9));

        // Revenue is defined as SUM(Booking.finalPrice) over revenue-recognised statuses
        // (CONFIRMED is one of them). Read the persisted finalPrice back so the assertion
        // is exact regardless of what the pricing engine computed.
        BigDecimal expectedDelta = finalPrice(b1).add(finalPrice(b2));

        JsonNode after = overview(null, null);
        BigDecimal afterRevenue = new BigDecimal(after.get("grossRevenue").asText());
        assertEquals(0, expectedDelta.compareTo(afterRevenue.subtract(beforeRevenue)),
            "grossRevenue delta must equal the summed finalPrice of the two confirmed bookings");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // OVERVIEW — DATE RANGE FILTER
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void adminOverview_dateRangeFilter_excludesOutOfRangeBookings() throws Exception {
        LocalDate inStart = today.plusDays(2), inEnd = today.plusDays(4);
        LocalDate outStart = today.plusDays(20), outEnd = today.plusDays(25);

        long beforeIn = overview(inStart, inEnd).get("bookingsInRange").asLong();
        long beforeOut = overview(outStart, outEnd).get("bookingsInRange").asLong();

        Fixture f = createPublishedHotelWithRoom("DateRange");
        String guest = registerGuest();
        // One booking with check-in inside [inStart, inEnd].
        createAndConfirmBooking(guest, f.roomId, today.plusDays(3), today.plusDays(5));

        assertEquals(beforeIn + 1, overview(inStart, inEnd).get("bookingsInRange").asLong(),
            "in-range window must count the new booking");
        assertEquals(beforeOut, overview(outStart, outEnd).get("bookingsInRange").asLong(),
            "a disjoint window must NOT count the new booking");
    }

    @Test
    void adminOverview_rejectsFromAfterTo() throws Exception {
        mvc.perform(get("/api/admin/analytics/overview")
                .param("from", today.plusDays(5).toString())
                .param("to", today.toString())
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isBadRequest());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // OVERVIEW — ACTIVE HOTELS / ROOMS / USERS / PARTNERS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void adminOverview_activeCounts() throws Exception {
        JsonNode before = overview(null, null);
        long beforeHotels = before.get("activeHotels").asLong();
        long beforeRooms = before.get("activeRooms").asLong();
        long beforeUsers = before.get("totalUsers").asLong();
        long beforePartners = before.get("totalPartners").asLong();

        // createPublishedHotelWithRoom provisions a new partner + published hotel + active room,
        // and registerGuest adds one user.
        createPublishedHotelWithRoom("ActiveCounts");
        registerGuest();

        JsonNode after = overview(null, null);
        assertEquals(beforeHotels + 1, after.get("activeHotels").asLong());
        assertEquals(beforeRooms + 1, after.get("activeRooms").asLong());
        assertTrue(after.get("totalUsers").asLong() >= beforeUsers + 2, "partner + guest add at least two users");
        assertEquals(beforePartners + 1, after.get("totalPartners").asLong());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SECURITY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void nonAdmin_forbidden() throws Exception {
        String guestToken = registerGuest();
        mvc.perform(get("/api/admin/analytics/overview")
                .header("Authorization", "Bearer " + guestToken))
            .andExpect(status().isForbidden());
    }

    @Test
    void unauthenticated_unauthorized() throws Exception {
        mvc.perform(get("/api/admin/analytics/overview"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private record Fixture(Long hotelId, Long hotelDetailId, Long roomId, Long partnerProfileId) {}

    private JsonNode overview(LocalDate from, LocalDate to) throws Exception {
        var req = get("/api/admin/analytics/overview").header("Authorization", "Bearer " + adminToken());
        if (from != null) req = req.param("from", from.toString());
        if (to != null) req = req.param("to", to.toString());
        String body = mvc.perform(req).andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private long statusCount(JsonNode overview, String status) {
        for (JsonNode n : overview.get("bookingsByStatus")) {
            if (status.equals(n.get("label").asText())) return n.get("count").asLong();
        }
        return 0L;
    }

    private boolean hasStatusBucket(JsonNode overview, String status) {
        for (JsonNode n : overview.get("bookingsByStatus")) {
            if (status.equals(n.get("label").asText())) return true;
        }
        return false;
    }

    private BigDecimal finalPrice(Long bookingId) {
        return bookingRepo.findById(bookingId).orElseThrow().getFinalPrice();
    }

    private Fixture createPublishedHotelWithRoom(String prefix) throws Exception {
        Long profileId = createAndApprovePartner();
        Long hotelId = createHotelPlace(uniq(prefix));
        Long hotelDetailId = createHotelDetail(hotelId);
        Long roomId = createRoom(hotelId, "RM-" + uniqSuffix());
        assignOwner(hotelId, profileId);
        bulkCreateInventory(roomId, today.minusDays(30), 60);
        return new Fixture(hotelId, hotelDetailId, roomId, profileId);
    }

    private Long createAndConfirmBooking(String guestToken, Long roomId, LocalDate ci, LocalDate co) throws Exception {
        String bookingBody = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + guestToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format(
                    "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\",\"adults\":2,\"children\":0,\"numberOfRooms\":1}",
                    roomId, ci, co)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long bookingId = mapper.readTree(bookingBody).get("id").asLong();

        String paymentBody = mvc.perform(post("/api/payments")
                .header("Authorization", "Bearer " + guestToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"paymentMethod\":\"CASH\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long paymentId = mapper.readTree(paymentBody).get("id").asLong();

        mvc.perform(post("/api/payments/" + paymentId + "/mock-success")
                .header("Authorization", "Bearer " + guestToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}"))
            .andExpect(status().isOk());

        return bookingId;
    }

    private String adminToken() throws Exception {
        if (adminToken == null) adminToken = login("admin@planyourtrip.com", "admin123456");
        return adminToken;
    }

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private String registerAndLogin(String fullName, String email) throws Exception {
        String body = mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"" + fullName + "\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private String registerGuest() throws Exception {
        return registerAndLogin("Guest Tester", "admin-analytics-guest-" + counter.getAndIncrement() + "@test.com");
    }

    private Long createAndApprovePartner() throws Exception {
        String email = "admin-analytics-partner-" + counter.getAndIncrement() + "@test.com";
        String token = registerAndLogin("Partner Tester", email);

        String profileReq = """
                {"businessName":"Admin Analytics Hotel Co %d","businessType":"HOTEL","representativeName":"Partner Tester",
                 "phone":"0901234567","email":"contact@example.com","address":"123 Le Loi, Da Nang"}
                """.formatted(counter.get());
        String profileBody = mvc.perform(post("/api/partner/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(profileReq))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        Long profileId = mapper.readTree(profileBody).get("id").asLong();

        mvc.perform(post("/api/partner/profile/submit")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        mvc.perform(post("/api/admin/partners/" + profileId + "/approve")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk());

        return profileId;
    }

    private Long createHotelPlace(String name) throws Exception {
        String req = """
                {
                  "name": "%s",
                  "categoryId": %d,
                  "subcategoryId": %d,
                  "administrativeUnitId": %d,
                  "address": "123 Test Street, Test City",
                  "priceLevel": 2,
                  "featured": false,
                  "verified": false,
                  "status": "DRAFT"
                }
                """.formatted(name, accCategoryId, hotelSubcategoryId, locationId);

        String resp = mvc.perform(post("/api/admin/places")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long id = mapper.readTree(resp).get("id").asLong();

        adminPatchStatus(id, "APPROVED");
        adminPatchStatus(id, "PUBLISHED");
        return id;
    }

    private void adminPatchStatus(Long id, String status) throws Exception {
        mvc.perform(patch("/api/admin/places/" + id + "/status")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"" + status + "\"}"))
            .andExpect(status().isOk());
    }

    private Long createHotelDetail(Long placeId) throws Exception {
        String req = """
                {
                  "placeId": %d,
                  "starRating": 4,
                  "checkInTime": "14:00:00",
                  "checkOutTime": "12:00:00",
                  "totalRooms": 10,
                  "availableRooms": 10,
                  "freeCancellation": false,
                  "prepaymentRequired": false,
                  "breakfastIncluded": false,
                  "airportShuttle": false
                }
                """.formatted(placeId);
        String resp = mvc.perform(post("/api/admin/hotels")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp).get("id").asLong();
    }

    private Long createRoom(Long placeId, String roomCode) throws Exception {
        String req = """
                {
                  "placeId": %d,
                  "roomName": "Deluxe Room",
                  "roomCode": "%s",
                  "roomType": "DELUXE",
                  "bedType": "QUEEN",
                  "bedCount": 1,
                  "maxAdults": 2,
                  "maxChildren": 1,
                  "maxGuests": 3,
                  "roomSizeSqm": 25.0,
                  "floorNumber": 2,
                  "smokingAllowed": false,
                  "breakfastIncluded": true,
                  "freeCancellation": true,
                  "instantConfirmation": true,
                  "priceFrom": 500000,
                  "originalPrice": 600000,
                  "quantity": 10,
                  "availableQuantity": 10,
                  "active": true
                }
                """.formatted(placeId, roomCode);
        String resp = mvc.perform(post("/api/admin/rooms")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp).get("id").asLong();
    }

    private void assignOwner(Long hotelId, Long partnerProfileId) throws Exception {
        mvc.perform(post("/api/admin/hotels/" + hotelId + "/assign-owner")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"partnerProfileId\":" + partnerProfileId + "}"))
            .andExpect(status().isOk());
    }

    private void bulkCreateInventory(Long roomId, LocalDate start, int days) throws Exception {
        StringBuilder items = new StringBuilder();
        for (int i = 0; i < days; i++) {
            if (i > 0) items.append(",");
            LocalDate d = start.plusDays(i);
            items.append(String.format(
                "{\"inventoryDate\":\"%s\",\"totalInventory\":10,\"availableInventory\":10," +
                "\"blockedInventory\":0,\"soldInventory\":0,\"maintenanceInventory\":0," +
                "\"stopSell\":false,\"closedArrival\":false,\"closedDeparture\":false}", d));
        }
        mvc.perform(post("/api/admin/rooms/" + roomId + "/inventory/bulk")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"items\":[" + items + "]}"))
            .andExpect(status().isOk());
    }

    private String uniq(String prefix) {
        return prefix + "-" + UUID.randomUUID().toString().substring(0, 8);
    }

    private String uniqSuffix() {
        return UUID.randomUUID().toString().substring(0, 8);
    }
}
