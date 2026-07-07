package com.example.planyourtrip;

import com.example.planyourtrip.model.Booking;
import com.example.planyourtrip.model.BookingStatus;
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
 * PartnerBookingTest — Phase 6.5.
 * Every scenario provisions its own throwaway partner, hotel, hotel-detail, room and
 * guest (never touching the shared seeded Grand Palace Hotel or other test files'
 * rooms) so tests stay isolated from each other and from other test classes sharing
 * the same H2 instance.
 */
@SpringBootTest
@AutoConfigureMockMvc
class PartnerBookingTest {

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
    private record OwnedHotelRoom(PartnerCtx partner, Long hotelId, Long roomId) {}

    // ═══════════════════════════════════════════════════════════════════════════
    // LIST / OWNERSHIP / DETAIL
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partner_listsBookings() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("ListBookings");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(10), today.plusDays(12));

        String body = mvc.perform(get("/api/partner/bookings")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode content = mapper.readTree(body).get("content");
        assertTrue(content.isArray());
        assertTrue(containsId(content, bookingId));
    }

    @Test
    void ownershipEnforced() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("OwnershipEnforced");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(10), today.plusDays(12));
        PartnerCtx stranger = createAndApprovePartner();

        mvc.perform(get("/api/partner/bookings/" + bookingId)
                .header("Authorization", "Bearer " + stranger.token()))
            .andExpect(status().isNotFound());

        mvc.perform(patch("/api/partner/bookings/" + bookingId + "/check-in")
                .header("Authorization", "Bearer " + stranger.token()))
            .andExpect(status().isNotFound());
    }

    @Test
    void bookingDetail() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Detail");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(5), today.plusDays(7));

        String body = mvc.perform(get("/api/partner/bookings/" + bookingId)
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals(bookingId, res.get("booking").get("id").asLong());
        assertEquals(r.roomId(), res.get("booking").get("roomId").asLong());
        assertTrue(res.get("payments").isArray());
        assertTrue(res.get("payments").size() >= 1);
        assertNotNull(res.get("timeline"));
        assertTrue(res.get("timeline").get("events").isArray());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SEARCH
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void search_byBookingCode() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("SearchCode");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(5), today.plusDays(7));
        String bookingCode = fetchBookingCode(r, bookingId);

        String body = mvc.perform(get("/api/partner/bookings")
                .param("bookingCode", bookingCode)
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode content = mapper.readTree(body).get("content");
        assertEquals(1, content.size());
        assertEquals(bookingId, content.get(0).get("id").asLong());
    }

    @Test
    void search_byGuestName() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("SearchGuest");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(5), today.plusDays(7));

        String body = mvc.perform(get("/api/partner/bookings")
                .param("guest", "Guest Tester")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode content = mapper.readTree(body).get("content");
        assertTrue(containsId(content, bookingId));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // DASHBOARD FILTERS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void filter_arrivalsToday() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("ArrivalsToday");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today, today.plusDays(2));

        String body = mvc.perform(get("/api/partner/bookings")
                .param("arrivalToday", "true")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertTrue(containsId(mapper.readTree(body).get("content"), bookingId));
    }

    @Test
    void filter_departuresToday() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("DeparturesToday");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(5), today.plusDays(7));

        // Business rule forbids creating a booking with a past checkIn, so a "departs
        // today" fixture (which requires checkIn strictly before today) is arranged
        // directly via the repository rather than through the create-booking API.
        Booking booking = bookingRepo.findById(bookingId).orElseThrow();
        booking.setCheckOutDate(today);
        bookingRepo.save(booking);

        String body = mvc.perform(get("/api/partner/bookings")
                .param("departureToday", "true")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertTrue(containsId(mapper.readTree(body).get("content"), bookingId));
    }

    @Test
    void filter_upcoming() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Upcoming");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(3), today.plusDays(5));

        String body = mvc.perform(get("/api/partner/bookings")
                .param("upcoming", "true")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertTrue(containsId(mapper.readTree(body).get("content"), bookingId));
    }

    @Test
    void filter_inHouse() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("InHouse");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today, today.plusDays(2));

        mvc.perform(patch("/api/partner/bookings/" + bookingId + "/check-in")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk());

        String body = mvc.perform(get("/api/partner/bookings")
                .param("inHouse", "true")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode content = mapper.readTree(body).get("content");
        assertTrue(containsId(content, bookingId));
        for (JsonNode n : content) if (n.get("id").asLong() == bookingId)
            assertEquals("CHECKED_IN", n.get("status").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // STATUS TRANSITIONS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void checkIn_succeeds() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("CheckIn");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today, today.plusDays(2));

        String body = mvc.perform(patch("/api/partner/bookings/" + bookingId + "/check-in")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals("CHECKED_IN", mapper.readTree(body).get("status").asText());
        assertFalse(mapper.readTree(body).get("actualCheckInAt").isNull());
    }

    @Test
    void checkOut_succeeds() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("CheckOut");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today, today.plusDays(2));

        mvc.perform(patch("/api/partner/bookings/" + bookingId + "/check-in")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk());

        String body = mvc.perform(patch("/api/partner/bookings/" + bookingId + "/check-out")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals("CHECKED_OUT", mapper.readTree(body).get("status").asText());
    }

    @Test
    void noShow_succeeds() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("NoShow");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(5), today.plusDays(7));

        String body = mvc.perform(patch("/api/partner/bookings/" + bookingId + "/no-show")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals("NO_SHOW", mapper.readTree(body).get("status").asText());
    }

    @Test
    void complete_succeeds() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Complete");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today, today.plusDays(2));

        mvc.perform(patch("/api/partner/bookings/" + bookingId + "/check-in")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk());
        mvc.perform(patch("/api/partner/bookings/" + bookingId + "/check-out")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk());

        String body = mvc.perform(patch("/api/partner/bookings/" + bookingId + "/complete")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals("COMPLETED", mapper.readTree(body).get("status").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // NOTIFICATIONS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void notification_checkIn_guestNotified() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("NotifyCheckIn");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today, today.plusDays(2));

        mvc.perform(patch("/api/partner/bookings/" + bookingId + "/check-in")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk());

        String body = mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + guestToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertTrue(containsTitle(mapper.readTree(body), "Booking checked in"));
    }

    @Test
    void notification_checkOut_guestNotified() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("NotifyCheckOut");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today, today.plusDays(2));

        mvc.perform(patch("/api/partner/bookings/" + bookingId + "/check-in")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk());
        mvc.perform(patch("/api/partner/bookings/" + bookingId + "/check-out")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk());

        String body = mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + guestToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertTrue(containsTitle(mapper.readTree(body), "Booking checked out"));
    }

    @Test
    void notification_noShow_adminNotified() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("NotifyNoShow");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(5), today.plusDays(7));

        mvc.perform(patch("/api/partner/bookings/" + bookingId + "/no-show")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk());

        String body = mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertTrue(containsTitle(mapper.readTree(body), "Booking marked as no-show"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // DASHBOARD
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void dashboardSummary() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Dashboard");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today, today.plusDays(2));

        mvc.perform(patch("/api/partner/bookings/" + bookingId + "/check-in")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk());

        String body = mvc.perform(get("/api/partner/dashboard")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertTrue(res.get("todaysArrivals").asLong() >= 1);
        assertTrue(res.get("currentGuests").asLong() >= 1);
        assertNotNull(res.get("occupancyRate"));
        assertNotNull(res.get("revenueToday"));
        assertNotNull(res.get("revenueMonth"));
        assertNotNull(res.get("averageStayNights"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // AUTH / ADMIN COMPATIBILITY / ROLLBACK
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void unauthorized_rejected() throws Exception {
        mvc.perform(get("/api/partner/bookings"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void admin_compatibility_unrestrictedAccess() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("AdminCompat");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(5), today.plusDays(7));

        mvc.perform(get("/api/admin/bookings/" + bookingId)
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(bookingId));

        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/check-in")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk());
    }

    @Test
    void rollbackSafety_illegalTransition_noPartialStateChange() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("RollbackSafety");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(5), today.plusDays(7));

        // Booking is CONFIRMED; check-out without a prior check-in is an illegal transition.
        mvc.perform(patch("/api/partner/bookings/" + bookingId + "/check-out")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isUnprocessableEntity());

        Booking unchanged = bookingRepo.findById(bookingId).orElseThrow();
        assertEquals(BookingStatus.CONFIRMED, unchanged.getStatus());
        assertNull(unchanged.getActualCheckOutAt());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private OwnedHotelRoom setupOwnedHotelRoom(String namePrefix) throws Exception {
        PartnerCtx partner = createAndApprovePartner();
        Long hotelId = createHotelPlace(uniq(namePrefix));
        createHotelDetail(hotelId);
        Long roomId = createRoom(hotelId, "RM-" + uniqSuffix());
        assignOwner(hotelId, partner.profileId());
        bulkCreateInventory(roomId, today.minusDays(2), 40);
        return new OwnedHotelRoom(partner, hotelId, roomId);
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

    private String fetchBookingCode(OwnedHotelRoom r, Long bookingId) throws Exception {
        String body = mvc.perform(get("/api/partner/bookings/" + bookingId)
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("booking").get("bookingCode").asText();
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

    private String registerAndLogin(String email) throws Exception {
        String body = mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"Guest Tester\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private String registerGuest() throws Exception {
        return registerAndLogin("guest-" + counter.getAndIncrement() + "@test.com");
    }

    private String createDraftPartnerEmail() {
        return "partner-booking-" + counter.getAndIncrement() + "@test.com";
    }

    private PartnerCtx createAndApprovePartner() throws Exception {
        String email = createDraftPartnerEmail();
        String token = registerPartnerAndLogin(email);

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

    private String registerPartnerAndLogin(String email) throws Exception {
        String body = mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"Partner Tester\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
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

    private void createHotelDetail(Long placeId) throws Exception {
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
        mvc.perform(post("/api/admin/hotels")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isCreated());
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

    private boolean containsId(JsonNode arr, Long id) {
        for (JsonNode n : arr) if (n.get("id").asLong() == id) return true;
        return false;
    }

    private boolean containsTitle(JsonNode arr, String title) {
        for (JsonNode n : arr) {
            if (title.equals(n.get("title").asText())) return true;
        }
        return false;
    }
}
