package com.example.planyourtrip;

import com.example.planyourtrip.model.Booking;
import com.example.planyourtrip.model.BookingStatus;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.BookingCheckInAuditRepository;
import com.example.planyourtrip.repository.BookingCheckOutAuditRepository;
import com.example.planyourtrip.repository.BookingModificationRepository;
import com.example.planyourtrip.repository.BookingRepository;
import com.example.planyourtrip.repository.CategoryRepository;
import com.example.planyourtrip.repository.NotificationRepository;
import com.example.planyourtrip.repository.PaymentRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

import java.time.Instant;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * PartnerGuestStayTest — Phase 7.42 (Consolidated READ-ONLY Partner Guest Stay Detail).
 *
 * <p>Exercises {@code GET /api/partner/stays/{bookingId}}: ownership-scoped uniform-404 security, the
 * derived currentStayState / night calculations / operational warnings, the reused lifecycle timeline,
 * modification history, check-in / check-out audits, sensitive-field exclusion, and the strict
 * read-only (no-mutation) guarantee. Provisions its own throwaway partner/hotel/room/guest per scenario
 * (mirroring PartnerCheckOutTest) so it is isolated on the shared H2 instance.
 */
@SpringBootTest
@AutoConfigureMockMvc
class PartnerGuestStayTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired BookingRepository bookingRepo;
    @Autowired PaymentRepository paymentRepo;
    @Autowired NotificationRepository notificationRepo;
    @Autowired BookingModificationRepository modificationRepo;
    @Autowired BookingCheckInAuditRepository checkInAuditRepo;
    @Autowired BookingCheckOutAuditRepository checkOutAuditRepo;

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
    // HAPPY PATH — full consolidated projection
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void ownStay_returnsAllSections() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("OwnStay");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(4));

        JsonNode res = parse(bodyOf(getStay(r.partner().token(), bookingId).andExpect(status().isOk())));

        assertEquals(bookingId, res.get("bookingId").asLong());
        assertFalse(res.get("bookingCode").asText().isBlank());
        assertEquals("CONFIRMED", res.get("bookingStatus").asText());
        assertFalse(res.get("createdAt").isNull());
        assertEquals("Guest Tester", res.get("guestName").asText());
        assertEquals(2, res.get("occupancy").get("adults").asInt());
        assertEquals(0, res.get("occupancy").get("children").asInt());
        assertEquals(r.hotelId(), res.get("hotelId").asLong());
        assertEquals(r.roomId(), res.get("roomId").asLong());
        assertFalse(res.get("roomName").asText().isBlank());
        assertFalse(res.get("roomCode").asText().isBlank());
        // schedule
        JsonNode sch = res.get("schedule");
        assertEquals(3, sch.get("totalNights").asLong());
        assertTrue(sch.get("actualCheckInAt").isNull());
        assertTrue(sch.get("actualCheckOutAt").isNull());
        assertEquals("UPCOMING", sch.get("currentStayState").asText());
        assertEquals(0, sch.get("currentNightNumber").asLong());
        assertEquals(3, sch.get("remainingNights").asLong());
        // voucher (CONFIRMED + PAID ⇒ VALID)
        assertEquals("VALID", res.get("voucher").get("voucherStatus").asText());
        assertTrue(res.get("voucher").get("voucherAvailable").asBoolean());
        // timeline present with lifecycle events
        assertTrue(res.get("timeline").get("events").isArray());
        assertTrue(res.get("timeline").get("events").size() >= 1);
        // empty collections
        assertEquals(0, res.get("modifications").size());
        assertTrue(res.get("checkInAudit").isNull());
        assertTrue(res.get("checkOutAudit").isNull());
        // future booking warning
        assertTrue(warningsContain(res, "FUTURE_BOOKING"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SECURITY — uniform 404 / 403 / 401
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void anotherPartnersStay_notFound() throws Exception {
        OwnedHotelRoom owner = setupOwnedHotelRoom("Owner");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, owner.roomId(), today.plusDays(1), today.plusDays(3));

        OwnedHotelRoom stranger = setupOwnedHotelRoom("Stranger");
        getStay(stranger.partner().token(), bookingId).andExpect(status().isNotFound());
    }

    @Test
    void unknownBooking_notFound() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Unknown");
        getStay(r.partner().token(), 99_999_999L).andExpect(status().isNotFound());
    }

    @Test
    void customerToken_forbidden() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("CustForbidden");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(3));

        getStay(guestToken, bookingId).andExpect(status().isForbidden());
    }

    @Test
    void anonymous_unauthorized() throws Exception {
        mvc.perform(get("/api/partner/stays/1")).andExpect(status().isUnauthorized());
    }

    @Test
    void adminToken_canReadAnyStay() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("AdminRead");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(3));

        // ADMIN passes the /api/partner/** role gate, but has no approved partner profile ⇒ service 404.
        getStay(adminToken(), bookingId).andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // STATE DERIVATIONS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void readyForCheckIn_whenTodayInWindow() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Ready");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today, today.plusDays(2));

        JsonNode res = parse(bodyOf(getStay(r.partner().token(), bookingId).andExpect(status().isOk())));
        assertEquals("READY_FOR_CHECK_IN", res.get("schedule").get("currentStayState").asText());
        assertEquals(0, res.get("schedule").get("currentNightNumber").asLong());
        assertEquals(2, res.get("schedule").get("remainingNights").asLong());
    }

    @Test
    void inHouse_whenCheckedIn_currentNightComputed() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("InHouse");
        String guestToken = registerGuest();
        // Stay started 2 days ago (checked in), 4-night stay ⇒ arrival day = night 1, so today = night 3.
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(5));
        setDates(bookingId, today.minusDays(2), today.plusDays(2));
        setStatus(bookingId, BookingStatus.CHECKED_IN);

        JsonNode res = parse(bodyOf(getStay(r.partner().token(), bookingId).andExpect(status().isOk())));
        assertEquals("IN_HOUSE", res.get("schedule").get("currentStayState").asText());
        assertEquals(4, res.get("schedule").get("totalNights").asLong());
        assertEquals(3, res.get("schedule").get("currentNightNumber").asLong());
        assertEquals(1, res.get("schedule").get("remainingNights").asLong());
        assertTrue(warningsContain(res, "CURRENTLY_STAYING"));
    }

    @Test
    void checkedOut_stateAndNights() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("CheckedOut");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(4));
        setDates(bookingId, today.minusDays(5), today.minusDays(2));
        setStatus(bookingId, BookingStatus.CHECKED_OUT);

        JsonNode res = parse(bodyOf(getStay(r.partner().token(), bookingId).andExpect(status().isOk())));
        assertEquals("CHECKED_OUT", res.get("schedule").get("currentStayState").asText());
        assertEquals(3, res.get("schedule").get("totalNights").asLong());
        assertEquals(3, res.get("schedule").get("currentNightNumber").asLong());
        assertEquals(0, res.get("schedule").get("remainingNights").asLong(), "remaining never negative");
        assertTrue(warningsContain(res, "COMPLETED_STAY"));
    }

    @Test
    void cancelled_stateAndWarning() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Cancelled");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(3));
        setStatus(bookingId, BookingStatus.CANCELLED);

        JsonNode res = parse(bodyOf(getStay(r.partner().token(), bookingId).andExpect(status().isOk())));
        assertEquals("CANCELLED", res.get("schedule").get("currentStayState").asText());
        assertEquals(0, res.get("schedule").get("currentNightNumber").asLong());
        // remainingNights is purely formula-driven (totalNights - currentNightNumber); a cancelled
        // future stay keeps its scheduled nights (currentNightNumber == 0). Never negative.
        assertEquals(2, res.get("schedule").get("remainingNights").asLong());
        assertTrue(warningsContain(res, "CANCELLED_STAY"));
    }

    @Test
    void futureBooking_currentNightNumberZero() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Future");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(5), today.plusDays(8));

        JsonNode res = parse(bodyOf(getStay(r.partner().token(), bookingId).andExpect(status().isOk())));
        assertEquals("UPCOMING", res.get("schedule").get("currentStayState").asText());
        assertEquals(0, res.get("schedule").get("currentNightNumber").asLong());
        assertEquals(3, res.get("schedule").get("totalNights").asLong());
        assertEquals(3, res.get("schedule").get("remainingNights").asLong());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MODIFICATION HISTORY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void modificationHistory_returnedWithOldNewValues() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Modify");
        String guestToken = registerGuest();
        // PENDING (unpaid) booking — Phase 7.34 modify only allows PENDING.
        Long bookingId = createBooking(guestToken, r.roomId(), today.plusDays(2), today.plusDays(5));

        Map<String, Object> req = new HashMap<>();
        req.put("adults", 1);
        req.put("children", 1);
        mvc.perform(patch("/api/bookings/" + bookingId + "/modify")
                .header("Authorization", "Bearer " + guestToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(req)))
            .andExpect(status().isOk());

        JsonNode res = parse(bodyOf(getStay(r.partner().token(), bookingId).andExpect(status().isOk())));
        JsonNode mods = res.get("modifications");
        assertEquals(1, mods.size());
        JsonNode m = mods.get(0);
        assertEquals(2, m.get("previousAdults").asInt());
        assertEquals(1, m.get("newAdults").asInt());
        assertEquals(0, m.get("previousChildren").asInt());
        assertEquals(1, m.get("newChildren").asInt());
        assertFalse(m.get("modifiedAt").isNull());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CHECK-IN / CHECK-OUT AUDITS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void checkInAudit_returnedAfterRealCheckIn() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("CIAudit");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(3));
        driveToCheckedIn(r.partner().token(), guestToken, bookingId);

        JsonNode res = parse(bodyOf(getStay(r.partner().token(), bookingId).andExpect(status().isOk())));
        JsonNode ci = res.get("checkInAudit");
        assertFalse(ci.isNull());
        assertEquals("CHECK_IN", ci.get("operation").asText());
        assertTrue(ci.get("method").isNull(), "check-in has no method");
        assertFalse(ci.get("timestamp").isNull());
        assertEquals(r.partner().profileId(), ci.get("partnerProfileId").asLong());
    }

    @Test
    void checkOutAudit_returnedWithMethod() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("COAudit");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(3));
        driveToCheckedIn(r.partner().token(), guestToken, bookingId);
        driveToCheckedOut(r.partner().token(), guestToken, bookingId);

        JsonNode res = parse(bodyOf(getStay(r.partner().token(), bookingId).andExpect(status().isOk())));
        JsonNode co = res.get("checkOutAudit");
        assertFalse(co.isNull());
        assertEquals("CHECK_OUT", co.get("operation").asText());
        assertEquals("QR_SCAN", co.get("method").asText());
        assertFalse(co.get("timestamp").isNull());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SENSITIVE-FIELD EXCLUSION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void response_hasNoSensitiveFields() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("NoSecrets");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(3));

        String body = bodyOf(getStay(r.partner().token(), bookingId).andExpect(status().isOk()));
        String lower = body.toLowerCase();
        assertFalse(lower.contains("signing"), "no signing secret");
        assertFalse(lower.contains("qrpayload"), "no signed QR payload");
        assertFalse(lower.contains("transactionid"), "no payment transaction id");
        assertFalse(lower.contains("giftcard"), "no gift-card code");
        assertFalse(lower.contains("coupon"), "no coupon secret");
        assertFalse(lower.contains("loyalty"), "no loyalty ledger");
        assertFalse(lower.contains("guestemail"), "no guest email");
        assertFalse(lower.contains("\"token\""), "no JWT");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // READ-ONLY — no mutation, deterministic repeats
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void readMutatesNothing_andIsDeterministic() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("ReadOnly");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(3));

        Booking before = bookingRepo.findById(bookingId).orElseThrow();
        BookingStatus statusBefore = before.getStatus();
        Instant updatedAtBefore = before.getUpdatedAt();
        long paymentsBefore = paymentRepo.count();
        long notifsBefore = notificationRepo.count();
        long modsBefore = modificationRepo.count();
        long ciAuditBefore = checkInAuditRepo.count();
        long coAuditBefore = checkOutAuditRepo.count();

        String first = bodyOf(getStay(r.partner().token(), bookingId).andExpect(status().isOk()));
        String second = bodyOf(getStay(r.partner().token(), bookingId).andExpect(status().isOk()));
        assertEquals(first, second, "repeated reads are byte-for-byte deterministic");

        Booking after = bookingRepo.findById(bookingId).orElseThrow();
        assertEquals(statusBefore, after.getStatus(), "status unchanged");
        assertEquals(updatedAtBefore, after.getUpdatedAt(), "updatedAt unchanged (no write)");
        assertEquals(paymentsBefore, paymentRepo.count(), "no payment rows created");
        assertEquals(notifsBefore, notificationRepo.count(), "no notifications created");
        assertEquals(modsBefore, modificationRepo.count(), "no modification rows created");
        assertEquals(ciAuditBefore, checkInAuditRepo.count(), "no check-in audit created");
        assertEquals(coAuditBefore, checkOutAuditRepo.count(), "no check-out audit created");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private ResultActions getStay(String token, Long bookingId) throws Exception {
        return mvc.perform(get("/api/partner/stays/" + bookingId)
            .header("Authorization", "Bearer " + token));
    }

    private String bodyOf(ResultActions ra) throws Exception {
        return ra.andReturn().getResponse().getContentAsString();
    }

    private JsonNode parse(String body) {
        try {
            return mapper.readTree(body);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    private boolean warningsContain(JsonNode res, String token) {
        for (JsonNode w : res.get("operationalWarnings")) {
            if (token.equals(w.asText())) return true;
        }
        return false;
    }

    private void driveToCheckedIn(String partnerToken, String guestToken, Long bookingId) throws Exception {
        String payload = fetchVoucherPayload(guestToken, bookingId);
        Map<String, String> body = new HashMap<>();
        body.put("voucherPayload", payload);
        mvc.perform(post("/api/partner/bookings/check-in")
                .header("Authorization", "Bearer " + partnerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(body)))
            .andExpect(status().isOk());
    }

    private void driveToCheckedOut(String partnerToken, String guestToken, Long bookingId) throws Exception {
        String payload = fetchVoucherPayload(guestToken, bookingId);
        Map<String, String> body = new HashMap<>();
        body.put("voucherPayload", payload);
        mvc.perform(post("/api/partner/bookings/check-out")
                .header("Authorization", "Bearer " + partnerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(body)))
            .andExpect(status().isOk());
    }

    private String fetchVoucherPayload(String guestToken, Long bookingId) throws Exception {
        String body = mvc.perform(get("/api/me/bookings/" + bookingId + "/voucher")
                .header("Authorization", "Bearer " + guestToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("qrPayload").asText();
    }

    private void setStatus(Long bookingId, BookingStatus status) {
        Booking b = bookingRepo.findById(bookingId).orElseThrow();
        b.setStatus(status);
        bookingRepo.save(b);
    }

    /** Rewrite the persisted stay window directly (bookings can't be created with past dates). */
    private void setDates(Long bookingId, LocalDate ci, LocalDate co) {
        Booking b = bookingRepo.findById(bookingId).orElseThrow();
        b.setCheckInDate(ci);
        b.setCheckOutDate(co);
        bookingRepo.save(b);
    }

    private OwnedHotelRoom setupOwnedHotelRoom(String namePrefix) throws Exception {
        PartnerCtx partner = createAndApprovePartner();
        Long hotelId = createHotelPlace(uniq(namePrefix));
        createHotelDetail(hotelId);
        Long roomId = createRoom(hotelId, "RM-" + uniqSuffix());
        assignOwner(hotelId, partner.profileId());
        bulkCreateInventory(roomId, today.minusDays(15), 40);
        return new OwnedHotelRoom(partner, hotelId, roomId);
    }

    private Long createBooking(String guestToken, Long roomId, LocalDate ci, LocalDate co) throws Exception {
        String bookingBody = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + guestToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format(
                    "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\",\"adults\":2,\"children\":0,\"numberOfRooms\":1}",
                    roomId, ci, co)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(bookingBody).get("id").asLong();
    }

    private Long createAndConfirmBooking(String guestToken, Long roomId, LocalDate ci, LocalDate co) throws Exception {
        Long bookingId = createBooking(guestToken, roomId, ci, co);

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
        return registerAndLogin("guest-stay-" + counter.getAndIncrement() + "@test.com");
    }

    private PartnerCtx createAndApprovePartner() throws Exception {
        String email = "partner-stay-" + counter.getAndIncrement() + "@test.com";
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
}
