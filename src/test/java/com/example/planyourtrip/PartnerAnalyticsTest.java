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

import java.time.LocalDate;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * PartnerAnalyticsTest — Phase 6.7.
 * Every scenario provisions its own throwaway partner, hotel, hotel-detail, room,
 * guest and booking (never touching shared seed data or other test files' fixtures)
 * so tests stay isolated from each other and from other test classes sharing the
 * same H2 instance.
 */
@SpringBootTest
@AutoConfigureMockMvc
class PartnerAnalyticsTest {

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

    private record PartnerCtx(String token, Long profileId) {}
    private record Scenario(PartnerCtx partner, String guestToken, Long hotelId, Long hotelDetailId,
                             Long roomId, Long bookingId) {}

    // ═══════════════════════════════════════════════════════════════════════════
    // OVERVIEW / OWNERSHIP
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partnerOverview_returnsMetrics() throws Exception {
        Scenario s = setupBookingScenario("Overview", 3, 5);

        String body = mvc.perform(get("/api/partner/analytics/overview")
                .param("from", today.toString())
                .param("to", today.plusDays(10).toString())
                .header("Authorization", "Bearer " + s.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertTrue(res.get("totalBookings").asLong() >= 1);
        assertNotNull(res.get("totalRevenue"));
        assertNotNull(res.get("occupancyRate"));
        assertNotNull(res.get("averageDailyRate"));
    }

    @Test
    void partner_cannotViewAnotherHotelsAnalytics() throws Exception {
        Scenario s = setupBookingScenario("OwnershipEnforced", 3, 5);
        PartnerCtx stranger = createAndApprovePartner();

        mvc.perform(get("/api/partner/analytics/overview")
                .param("hotelId", String.valueOf(s.hotelId()))
                .header("Authorization", "Bearer " + stranger.token()))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // REVENUE / OCCUPANCY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void revenueAnalytics_works() throws Exception {
        Scenario s = setupBookingScenario("Revenue", 3, 5);

        String body = mvc.perform(get("/api/partner/analytics/revenue")
                .param("from", today.toString())
                .param("to", today.plusDays(10).toString())
                .header("Authorization", "Bearer " + s.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertTrue(res.get("revenueByDay").isArray());
        assertTrue(res.get("revenueByDay").size() > 0);
        assertTrue(res.get("revenueByRoom").isArray());
        assertTrue(res.get("revenueByRoom").size() >= 1);
        assertNotNull(res.get("revenueMonthToDate"));
        assertNotNull(res.get("revenueLast30Days"));
    }

    @Test
    void occupancyAnalytics_works() throws Exception {
        Scenario s = setupBookingScenario("Occupancy", 3, 5);

        String body = mvc.perform(get("/api/partner/analytics/occupancy")
                .param("from", today.plusDays(3).toString())
                .param("to", today.plusDays(4).toString())
                .header("Authorization", "Bearer " + s.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertTrue(res.get("occupancyByDay").isArray());
        assertEquals(2, res.get("occupancyByDay").size());
        assertTrue(res.get("totalRoomInventory").asInt() > 0);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // BOOKINGS / ROOMS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void bookingStatusAnalytics_works() throws Exception {
        Scenario s = setupBookingScenario("BookingAnalytics", 3, 5);

        String body = mvc.perform(get("/api/partner/analytics/bookings")
                .param("from", today.toString())
                .param("to", today.plusDays(10).toString())
                .header("Authorization", "Bearer " + s.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertTrue(res.get("arrivals").asLong() >= 1);
        boolean foundConfirmed = false;
        for (JsonNode n : res.get("bookingsByStatus")) {
            if ("CONFIRMED".equals(n.get("label").asText())) foundConfirmed = true;
        }
        assertTrue(foundConfirmed, "bookingsByStatus must include the CONFIRMED bucket");
    }

    @Test
    void roomAnalytics_works() throws Exception {
        Scenario s = setupBookingScenario("RoomAnalytics", 3, 5);

        String body = mvc.perform(get("/api/partner/analytics/rooms")
                .param("from", today.toString())
                .param("to", today.plusDays(10).toString())
                .header("Authorization", "Bearer " + s.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertTrue(res.get("topRoomsByBookings").isArray());
        assertTrue(res.get("topRoomsByBookings").size() >= 1);
        assertTrue(res.get("roomAvailabilitySummary").isArray());
        assertTrue(res.get("roomAvailabilitySummary").size() >= 1);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PROMOTIONS / REVIEWS / MESSAGES
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void promotionAnalytics_works() throws Exception {
        Scenario s = setupBookingScenario("PromoAnalytics", 3, 5);
        createHotelPromotion(s);

        String body = mvc.perform(get("/api/partner/analytics/promotions")
                .header("Authorization", "Bearer " + s.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertTrue(res.get("activePromotions").asLong() >= 1);
        assertTrue(res.get("promotionsByType").isArray());
        assertTrue(res.get("promotionsByType").size() >= 1);
        assertTrue(res.get("promotionCountByStatus").isArray());
        assertTrue(res.get("estimatedDiscountedBookings").isNull());
    }

    @Test
    void reviewAnalytics_works() throws Exception {
        Scenario s = setupBookingScenario("ReviewAnalytics", 3, 5);
        driveToCompleted(s);
        createApprovedReview(s);

        String body = mvc.perform(get("/api/partner/analytics/reviews")
                .header("Authorization", "Bearer " + s.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertTrue(res.get("reviewCount").asLong() >= 1);
        assertTrue(res.get("approvedReviews").asLong() >= 1);
        assertTrue(res.get("averageRating").asDouble() > 0);
        assertTrue(res.get("latestReviews").isArray());
        assertTrue(res.get("latestReviews").size() >= 1);
    }

    @Test
    void messageAnalytics_works() throws Exception {
        Scenario s = setupBookingScenario("MessageAnalytics", 3, 5);
        createConversationWithUnreadMessage(s);

        String body = mvc.perform(get("/api/partner/analytics/messages")
                .header("Authorization", "Bearer " + s.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertTrue(res.get("openConversations").asLong() >= 1);
        assertTrue(res.get("unreadPartnerMessages").asLong() >= 1);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // DATE RANGE / FILTER
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void dateRangeValidation_rejectsFromAfterTo() throws Exception {
        Scenario s = setupBookingScenario("DateValidation", 3, 5);

        mvc.perform(get("/api/partner/analytics/overview")
                .param("from", today.plusDays(5).toString())
                .param("to", today.toString())
                .header("Authorization", "Bearer " + s.partner().token()))
            .andExpect(status().isBadRequest());
    }

    @Test
    void defaultDateRange_works() throws Exception {
        Scenario s = setupBookingScenario("DefaultRange", 2, 4);

        // Business rule forbids creating a booking with a past checkIn, so a fixture
        // that falls inside the default "last 30 days" window is arranged directly
        // via the repository rather than through the create-booking API.
        Booking booking = bookingRepo.findById(s.bookingId()).orElseThrow();
        booking.setCheckInDate(today.minusDays(3));
        booking.setCheckOutDate(today.minusDays(1));
        bookingRepo.save(booking);

        String body = mvc.perform(get("/api/partner/analytics/overview")
                .header("Authorization", "Bearer " + s.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertTrue(mapper.readTree(body).get("totalBookings").asLong() >= 1);
    }

    @Test
    void hotelIdFilter_works() throws Exception {
        PartnerCtx partner = createAndApprovePartner();

        Long hotel1 = createHotelPlace(uniq("HotelFilter1"));
        createHotelDetail(hotel1);
        Long room1 = createRoom(hotel1, "RM-" + uniqSuffix());
        assignOwner(hotel1, partner.profileId());
        bulkCreateInventory(room1, today.minusDays(30), 60);

        Long hotel2 = createHotelPlace(uniq("HotelFilter2"));
        createHotelDetail(hotel2);
        Long room2 = createRoom(hotel2, "RM-" + uniqSuffix());
        assignOwner(hotel2, partner.profileId());
        bulkCreateInventory(room2, today.minusDays(30), 60);

        String guestToken = registerGuest();
        createAndConfirmBooking(guestToken, room1, today.plusDays(3), today.plusDays(5));
        createAndConfirmBooking(guestToken, room2, today.plusDays(3), today.plusDays(5));

        String body = mvc.perform(get("/api/partner/analytics/overview")
                .param("hotelId", String.valueOf(hotel1))
                .param("from", today.toString())
                .param("to", today.plusDays(10).toString())
                .header("Authorization", "Bearer " + partner.token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals(1, mapper.readTree(body).get("totalBookings").asLong());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // AUTH / APPROVAL
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void unauthenticated_rejected() throws Exception {
        mvc.perform(get("/api/partner/analytics/overview"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void nonApprovedPartner_rejected() throws Exception {
        String draftToken = createDraftPartnerToken();

        mvc.perform(get("/api/partner/analytics/overview")
                .header("Authorization", "Bearer " + draftToken))
            .andExpect(status().isForbidden());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private Scenario setupBookingScenario(String prefix, int checkInOffset, int checkOutOffset) throws Exception {
        PartnerCtx partner = createAndApprovePartner();
        Long hotelId = createHotelPlace(uniq(prefix));
        Long hotelDetailId = createHotelDetail(hotelId);
        Long roomId = createRoom(hotelId, "RM-" + uniqSuffix());
        assignOwner(hotelId, partner.profileId());
        bulkCreateInventory(roomId, today.minusDays(30), 60);

        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, roomId,
            today.plusDays(checkInOffset), today.plusDays(checkOutOffset));

        return new Scenario(partner, guestToken, hotelId, hotelDetailId, roomId, bookingId);
    }

    private void driveToCompleted(Scenario s) throws Exception {
        mvc.perform(patch("/api/partner/bookings/" + s.bookingId() + "/check-in")
                .header("Authorization", "Bearer " + s.partner().token()))
            .andExpect(status().isOk());
        mvc.perform(patch("/api/partner/bookings/" + s.bookingId() + "/check-out")
                .header("Authorization", "Bearer " + s.partner().token()))
            .andExpect(status().isOk());
        mvc.perform(patch("/api/partner/bookings/" + s.bookingId() + "/complete")
                .header("Authorization", "Bearer " + s.partner().token()))
            .andExpect(status().isOk());
    }

    private Long createApprovedReview(Scenario s) throws Exception {
        String body = mvc.perform(post("/api/reviews")
                .header("Authorization", "Bearer " + s.guestToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + s.bookingId()
                    + ",\"ratingOverall\":5,\"title\":\"Great stay\",\"content\":\"Loved it\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long reviewId = mapper.readTree(body).get("id").asLong();

        mvc.perform(patch("/api/admin/reviews/" + reviewId + "/moderate")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"APPROVED\"}"))
            .andExpect(status().isOk());
        return reviewId;
    }

    private Long createHotelPromotion(Scenario s) throws Exception {
        String body = mvc.perform(post("/api/partner/promotions")
                .header("Authorization", "Bearer " + s.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"name":"Test Promo","code":"PROMO-%s","promotionType":"GENERAL","discountType":"PERCENTAGE",
                         "discountValue":10,"minimumStay":1,"stackable":false,"priority":1,
                         "startDate":"%s","endDate":"%s","active":true,"targetType":"HOTEL","targetId":%d}
                        """.formatted(uniqSuffix(), today.minusDays(5), today.plusDays(30), s.hotelDetailId())))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private Long createConversationWithUnreadMessage(Scenario s) throws Exception {
        String body = mvc.perform(post("/api/me/conversations")
                .header("Authorization", "Bearer " + s.guestToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + s.bookingId() + ",\"subject\":\"Question\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long conversationId = mapper.readTree(body).get("id").asLong();

        mvc.perform(post("/api/me/conversations/" + conversationId + "/messages")
                .header("Authorization", "Bearer " + s.guestToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"body\":\"Hi, question about check-in\"}"))
            .andExpect(status().isCreated());

        return conversationId;
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
        return registerAndLogin("Guest Tester", "analytics-guest-" + counter.getAndIncrement() + "@test.com");
    }

    private String createDraftPartnerToken() throws Exception {
        String email = "partner-analytics-draft-" + counter.getAndIncrement() + "@test.com";
        String token = registerAndLogin("Partner Tester", email);
        String profileReq = """
                {"businessName":"Draft Hotel Co","businessType":"HOTEL","representativeName":"Partner Tester",
                 "phone":"0901234567","email":"contact@example.com","address":"123 Le Loi, Da Nang"}
                """;
        mvc.perform(post("/api/partner/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(profileReq))
            .andExpect(status().isOk());
        return token;
    }

    private PartnerCtx createAndApprovePartner() throws Exception {
        String email = "partner-analytics-" + counter.getAndIncrement() + "@test.com";
        String token = registerAndLogin("Partner Tester", email);

        String profileReq = """
                {"businessName":"Test Hotel Co %d","businessType":"HOTEL","representativeName":"Partner Tester",
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

        return new PartnerCtx(token, profileId);
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
