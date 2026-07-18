package com.example.planyourtrip;

import com.example.planyourtrip.model.Booking;
import com.example.planyourtrip.model.BookingStatus;
import com.example.planyourtrip.model.CheckMethod;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.BookingCheckOutAuditRepository;
import com.example.planyourtrip.repository.BookingRepository;
import com.example.planyourtrip.repository.CategoryRepository;
import com.example.planyourtrip.repository.NotificationRepository;
import com.example.planyourtrip.security.VoucherSignatureService;
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
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * PartnerCheckOutTest — Phase 7.41 (Partner Guest Check-out; a near-mirror of the 7.40 check-in MUTATION).
 *
 * <p>Exercises {@code POST /api/partner/bookings/check-out}: reuse of the Phase 7.39/7.40 verify+resolve+
 * ownership step, the {@code CHECKED_IN → CHECKED_OUT} transition (via {@code BookingStatusEngineService}),
 * the eligibility + time-window checks, the derived audit method (QR_SCAN / MANUAL), the one-shot customer
 * notification + immutable audit row, strict idempotency on a repeat, and Spring-Security role gating.
 *
 * <p>Each scenario provisions its own throwaway partner, hotel, room and guest (mirroring
 * {@code PartnerCheckInTest}) so it is isolated on the shared H2 instance. A booking is driven to
 * CHECKED_IN via the real Phase 7.40 check-in endpoint before check-out is tested.
 */
@SpringBootTest
@AutoConfigureMockMvc
class PartnerCheckOutTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired BookingRepository bookingRepo;
    @Autowired NotificationRepository notificationRepo;
    @Autowired BookingCheckOutAuditRepository auditRepo;
    @Autowired VoucherSignatureService voucherSignatureService;

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
    // SUCCESSFUL CHECK-OUT
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void ownedCheckedInBooking_checksOut() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("CheckedIn");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(4));
        driveToCheckedIn(r.partner().token(), guestToken, bookingId);
        Long customerUserId = bookingRepo.findById(bookingId).orElseThrow().getUser().getId();
        long checkoutNotifsBefore = countLifecycleCheckOutNotification(customerUserId);
        String payload = fetchVoucherPayload(guestToken, bookingId);

        JsonNode res = mapper.readTree(checkOutByPayload(r.partner().token(), payload)
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());

        assertTrue(res.get("success").asBoolean());
        assertEquals("CHECKED_OUT", res.get("bookingStatus").asText());
        assertFalse(res.get("checkedOutAt").isNull());
        assertEquals("Guest Tester", res.get("guestName").asText());
        assertFalse(res.get("roomName").asText().isBlank());
        assertFalse(res.get("hotelName").asText().isBlank());

        assertEquals(BookingStatus.CHECKED_OUT, bookingRepo.findById(bookingId).orElseThrow().getStatus());
        assertNotNull(bookingRepo.findById(bookingId).orElseThrow().getActualCheckOutAt());
        assertEquals(1, auditRepo.countByBookingId(bookingId));
        assertEquals(CheckMethod.QR_SCAN, auditRepo.findByBookingId(bookingId).get(0).getMethod());

        // Dedup: check-out creates EXACTLY ONE customer notification, the status engine's lifecycle one.
        assertEquals(checkoutNotifsBefore + 1, countLifecycleCheckOutNotification(customerUserId),
            "exactly one new 'Booking checked out' notification (engine = single source of truth)");
    }

    @Test
    void checkOutByBookingCode_recordsManualMethod() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("ByCode");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(3));
        driveToCheckedIn(r.partner().token(), guestToken, bookingId);
        String code = bookingRepo.findById(bookingId).orElseThrow().getBookingCode();

        JsonNode res = mapper.readTree(checkOutByCode(r.partner().token(), code)
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
        assertTrue(res.get("success").asBoolean());
        assertEquals("CHECKED_OUT", res.get("bookingStatus").asText());
        assertEquals(BookingStatus.CHECKED_OUT, bookingRepo.findById(bookingId).orElseThrow().getStatus());
        assertEquals(1, auditRepo.countByBookingId(bookingId));
        assertEquals(CheckMethod.MANUAL, auditRepo.findByBookingId(bookingId).get(0).getMethod(),
            "raw booking code input ⇒ MANUAL method");
    }

    @Test
    void checkOutByPayload_recordsQrScanMethod() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("ByPayload");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(3));
        driveToCheckedIn(r.partner().token(), guestToken, bookingId);
        String payload = fetchVoucherPayload(guestToken, bookingId);

        checkOutByPayload(r.partner().token(), payload).andExpect(status().isOk());
        assertEquals(1, auditRepo.countByBookingId(bookingId));
        assertEquals(CheckMethod.QR_SCAN, auditRepo.findByBookingId(bookingId).get(0).getMethod(),
            "scanned voucher payload input ⇒ QR_SCAN method");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // IDEMPOTENCY — double check-out
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void doubleCheckOut_isIdempotent_noDuplicateSideEffects() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Idempotent");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(4));
        driveToCheckedIn(r.partner().token(), guestToken, bookingId);
        Long customerUserId = bookingRepo.findById(bookingId).orElseThrow().getUser().getId();
        String payload = fetchVoucherPayload(guestToken, bookingId);

        // First check-out — the real transition.
        JsonNode first = mapper.readTree(checkOutByPayload(r.partner().token(), payload)
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
        // Truncate to millis: the first response reflects the in-memory nanosecond instant while the
        // idempotent repeat reads the H2-truncated value — same instant, different precision.
        Instant checkedOutAt1 = Instant.parse(first.get("checkedOutAt").asText()).truncatedTo(ChronoUnit.MILLIS);

        long notificationsAfterFirst = notificationRepo.count();
        long lifecycleNotifAfterFirst = countLifecycleCheckOutNotification(customerUserId);
        long auditAfterFirst = auditRepo.countByBookingId(bookingId);
        long timelineAfterFirst = countCheckedOutTimelineEvents(r.partner().token(), bookingId);
        var persistedCheckedOutAt = bookingRepo.findById(bookingId).orElseThrow().getActualCheckOutAt();

        // Second check-out — must short-circuit deterministically with NO new side effects.
        JsonNode second = mapper.readTree(checkOutByPayload(r.partner().token(), payload)
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
        assertTrue(second.get("success").asBoolean());
        assertEquals("CHECKED_OUT", second.get("bookingStatus").asText());
        Instant checkedOutAt2 = Instant.parse(second.get("checkedOutAt").asText()).truncatedTo(ChronoUnit.MILLIS);
        assertEquals(checkedOutAt1, checkedOutAt2, "checkedOutAt must be immutable");

        assertEquals(1, lifecycleNotifAfterFirst,
            "exactly one lifecycle 'Booking checked out' notification (status engine = single source of truth)");
        assertEquals(1, auditAfterFirst, "exactly one audit row");
        assertEquals(1, timelineAfterFirst, "exactly one CHECKED_OUT timeline event");

        // Counts unchanged after the 2nd call.
        assertEquals(notificationsAfterFirst, notificationRepo.count(), "no new notification on repeat");
        assertEquals(lifecycleNotifAfterFirst, countLifecycleCheckOutNotification(customerUserId),
            "still exactly one lifecycle notification after the repeat");
        assertEquals(auditAfterFirst, auditRepo.countByBookingId(bookingId), "no second audit row on repeat");
        assertEquals(timelineAfterFirst, countCheckedOutTimelineEvents(r.partner().token(), bookingId),
            "no duplicate CHECKED_OUT timeline event on repeat");
        assertEquals(persistedCheckedOutAt, bookingRepo.findById(bookingId).orElseThrow().getActualCheckOutAt(),
            "persisted actualCheckOutAt must be unchanged by the repeat");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // INELIGIBLE STATUS → 422
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void confirmedNotYetCheckedIn_unprocessable() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Confirmed");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(3));
        String payload = fetchVoucherPayload(guestToken, bookingId);

        checkOutByPayload(r.partner().token(), payload).andExpect(status().isUnprocessableEntity());
        assertEquals(BookingStatus.CONFIRMED, bookingRepo.findById(bookingId).orElseThrow().getStatus());
        assertEquals(0, auditRepo.countByBookingId(bookingId));
    }

    @Test
    void cancelledBooking_unprocessable() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Cancelled");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(3));
        String payload = fetchVoucherPayload(guestToken, bookingId);
        setStatus(bookingId, BookingStatus.CANCELLED);

        checkOutByPayload(r.partner().token(), payload).andExpect(status().isUnprocessableEntity());
        assertEquals(0, auditRepo.countByBookingId(bookingId));
    }

    @Test
    void completedBooking_unprocessable() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Completed");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(3));
        String payload = fetchVoucherPayload(guestToken, bookingId);
        setStatus(bookingId, BookingStatus.COMPLETED);

        checkOutByPayload(r.partner().token(), payload).andExpect(status().isUnprocessableEntity());
        assertEquals(0, auditRepo.countByBookingId(bookingId));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // TIME WINDOW → 422
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void lateWindowPassed_unprocessable() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("LateWindow");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(4));
        driveToCheckedIn(r.partner().token(), guestToken, bookingId);
        // Rewrite the stay entirely into the past — beyond checkOutDate + lateWindowDays.
        setDates(bookingId, today.minusDays(10), today.minusDays(5));
        String payload = fetchVoucherPayload(guestToken, bookingId);

        checkOutByPayload(r.partner().token(), payload).andExpect(status().isUnprocessableEntity());
        assertEquals(BookingStatus.CHECKED_IN, bookingRepo.findById(bookingId).orElseThrow().getStatus());
        assertEquals(0, auditRepo.countByBookingId(bookingId));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // OWNERSHIP / SIGNATURE → uniform 404
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void anotherPartnersBooking_notFound() throws Exception {
        OwnedHotelRoom owner = setupOwnedHotelRoom("OwnerHotel");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, owner.roomId(), today.plusDays(1), today.plusDays(3));
        driveToCheckedIn(owner.partner().token(), guestToken, bookingId);
        String payload = fetchVoucherPayload(guestToken, bookingId);

        OwnedHotelRoom stranger = setupOwnedHotelRoom("StrangerHotel");
        checkOutByPayload(stranger.partner().token(), payload).andExpect(status().isNotFound());
        // Not mutated by the failed attempt.
        assertEquals(BookingStatus.CHECKED_IN, bookingRepo.findById(bookingId).orElseThrow().getStatus());
    }

    @Test
    void tamperedSignature_notFound() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("TamperSig");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(3));
        driveToCheckedIn(r.partner().token(), guestToken, bookingId);
        String payload = fetchVoucherPayload(guestToken, bookingId);

        char last = payload.charAt(payload.length() - 1);
        String tampered = payload.substring(0, payload.length() - 1) + (last == 'A' ? 'B' : 'A');
        checkOutByPayload(r.partner().token(), tampered).andExpect(status().isNotFound());
        assertEquals(BookingStatus.CHECKED_IN, bookingRepo.findById(bookingId).orElseThrow().getStatus());
    }

    @Test
    void validlySignedButUnknownBooking_notFound() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("UnknownBooking");
        String signed = voucherSignatureService.sign("PYT-19990101-999999");
        checkOutByPayload(r.partner().token(), signed).andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // REQUEST VALIDATION — exactly one of voucherPayload / bookingCode → 400
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void bothInputs_badRequest() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("BothInputs");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(3));
        String payload = fetchVoucherPayload(guestToken, bookingId);
        String code = bookingRepo.findById(bookingId).orElseThrow().getBookingCode();

        Map<String, String> body = new HashMap<>();
        body.put("voucherPayload", payload);
        body.put("bookingCode", code);
        postCheckOut(r.partner().token(), mapper.writeValueAsString(body)).andExpect(status().isBadRequest());
    }

    @Test
    void neitherInput_badRequest() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("NeitherInput");
        postCheckOut(r.partner().token(), "{}").andExpect(status().isBadRequest());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SPRING SECURITY — role gating (before service code)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void customerToken_forbidden() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("CustomerForbidden");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(3));
        String payload = fetchVoucherPayload(guestToken, bookingId);

        checkOutByPayload(guestToken, payload).andExpect(status().isForbidden());
    }

    @Test
    void anonymous_unauthorized() throws Exception {
        mvc.perform(post("/api/partner/bookings/check-out")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"voucherPayload\":\"PYT-V1.X.Y\"}"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private ResultActions checkOutByPayload(String token, String payload) throws Exception {
        Map<String, String> body = new HashMap<>();
        body.put("voucherPayload", payload);
        return postCheckOut(token, mapper.writeValueAsString(body));
    }

    private ResultActions checkOutByCode(String token, String code) throws Exception {
        Map<String, String> body = new HashMap<>();
        body.put("bookingCode", code);
        return postCheckOut(token, mapper.writeValueAsString(body));
    }

    private ResultActions postCheckOut(String token, String json) throws Exception {
        return mvc.perform(post("/api/partner/bookings/check-out")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json));
    }

    /** Drive a CONFIRMED booking to CHECKED_IN via the real Phase 7.40 check-in endpoint. */
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

    /** The single lifecycle check-out notification — emitted by BookingStatusEngineService (source of truth). */
    private long countLifecycleCheckOutNotification(Long customerUserId) {
        return notificationRepo.findByRecipientUserIdOrderByCreatedAtDesc(customerUserId).stream()
            .filter(n -> "Booking checked out".equals(n.getTitle()))
            .count();
    }

    private long countCheckedOutTimelineEvents(String partnerToken, Long bookingId) throws Exception {
        String body = mvc.perform(get("/api/partner/bookings/" + bookingId)
                .header("Authorization", "Bearer " + partnerToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode events = mapper.readTree(body).get("timeline").get("events");
        long count = 0;
        for (JsonNode e : events) {
            if ("CHECKED_OUT".equals(e.get("event").asText())) count++;
        }
        return count;
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
        return registerAndLogin("guest-co-" + counter.getAndIncrement() + "@test.com");
    }

    private PartnerCtx createAndApprovePartner() throws Exception {
        String email = "partner-checkout-" + counter.getAndIncrement() + "@test.com";
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
