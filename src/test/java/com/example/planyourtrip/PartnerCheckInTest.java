package com.example.planyourtrip;

import com.example.planyourtrip.model.Booking;
import com.example.planyourtrip.model.BookingStatus;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.BookingCheckInAuditRepository;
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
 * PartnerCheckInTest — Phase 7.40 (Partner Guest Check-in; the first staff-performed booking MUTATION).
 *
 * <p>Exercises {@code POST /api/partner/bookings/check-in}: reuse of the Phase 7.39 verify+resolve+
 * ownership step, the {@code CONFIRMED/CHECK_IN_READY → CHECKED_IN} transition (via
 * {@code BookingStatusEngineService}), the configurable check-in time window, the one-shot customer
 * notification + immutable audit row, strict idempotency on a repeat, and Spring-Security role gating.
 *
 * <p>Each scenario provisions its own throwaway partner, hotel, room and guest (mirroring
 * {@code PartnerVoucherVerifyTest}) so it is isolated on the shared H2 instance.
 */
@SpringBootTest
@AutoConfigureMockMvc
class PartnerCheckInTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired BookingRepository bookingRepo;
    @Autowired NotificationRepository notificationRepo;
    @Autowired BookingCheckInAuditRepository auditRepo;
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
    // SUCCESSFUL CHECK-IN
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void ownedConfirmedBooking_checksIn() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Confirmed");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(4));
        Long customerUserId = bookingRepo.findById(bookingId).orElseThrow().getUser().getId();
        long customerNotifsBefore = notificationRepo.findByRecipientUserIdOrderByCreatedAtDesc(customerUserId).size();
        String payload = fetchVoucherPayload(guestToken, bookingId);

        JsonNode res = mapper.readTree(checkInByPayload(r.partner().token(), payload)
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());

        assertTrue(res.get("success").asBoolean());
        assertEquals("CHECKED_IN", res.get("bookingStatus").asText());
        assertFalse(res.get("checkedInAt").isNull());
        assertEquals("Guest Tester", res.get("guestName").asText());
        assertFalse(res.get("roomName").asText().isBlank());
        assertFalse(res.get("hotelName").asText().isBlank());

        assertEquals(BookingStatus.CHECKED_IN, bookingRepo.findById(bookingId).orElseThrow().getStatus());
        assertNotNull(bookingRepo.findById(bookingId).orElseThrow().getActualCheckInAt());
        assertEquals(1, auditRepo.countByBookingId(bookingId));

        // Dedup: check-in creates EXACTLY ONE customer notification total, and it is the status engine's
        // lifecycle notification — PartnerCheckInService emits none of its own.
        long customerNotifsAfter = notificationRepo.findByRecipientUserIdOrderByCreatedAtDesc(customerUserId).size();
        assertEquals(customerNotifsBefore + 1, customerNotifsAfter, "exactly one new customer notification on check-in");
        assertEquals(1, countLifecycleCheckInNotification(customerUserId), "it is the engine's 'Booking checked in'");
        assertEquals(0, countCheckInCompleted(customerUserId), "no duplicate 'Check-in completed' notification");
    }

    @Test
    void checkInReadyBooking_checksIn() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("CheckInReady");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(3));
        setStatus(bookingId, BookingStatus.CHECK_IN_READY);
        String payload = fetchVoucherPayload(guestToken, bookingId);

        JsonNode res = mapper.readTree(checkInByPayload(r.partner().token(), payload)
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
        assertTrue(res.get("success").asBoolean());
        assertEquals("CHECKED_IN", res.get("bookingStatus").asText());
        assertEquals(BookingStatus.CHECKED_IN, bookingRepo.findById(bookingId).orElseThrow().getStatus());
    }

    @Test
    void checkInByBookingCode_works() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("ByCode");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(3));
        String code = bookingRepo.findById(bookingId).orElseThrow().getBookingCode();

        JsonNode res = mapper.readTree(checkInByCode(r.partner().token(), code)
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
        assertTrue(res.get("success").asBoolean());
        assertEquals("CHECKED_IN", res.get("bookingStatus").asText());
        assertEquals(BookingStatus.CHECKED_IN, bookingRepo.findById(bookingId).orElseThrow().getStatus());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // IDEMPOTENCY — double check-in
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void doubleCheckIn_isIdempotent_noDuplicateSideEffects() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Idempotent");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(4));
        Long customerUserId = bookingRepo.findById(bookingId).orElseThrow().getUser().getId();
        String payload = fetchVoucherPayload(guestToken, bookingId);

        // First check-in — the real transition.
        JsonNode first = mapper.readTree(checkInByPayload(r.partner().token(), payload)
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
        // Truncate to millis: the first response reflects the in-memory nanosecond instant while the
        // idempotent repeat reads the H2-truncated (microsecond) value — same instant, different precision.
        Instant checkedInAt1 = Instant.parse(first.get("checkedInAt").asText()).truncatedTo(ChronoUnit.MILLIS);

        long notificationsAfterFirst = notificationRepo.count();
        long lifecycleNotifAfterFirst = countLifecycleCheckInNotification(customerUserId);
        long dupNotifAfterFirst = countCheckInCompleted(customerUserId);
        long auditAfterFirst = auditRepo.countByBookingId(bookingId);
        long timelineAfterFirst = countCheckedInTimelineEvents(r.partner().token(), bookingId);
        var persistedCheckedInAt = bookingRepo.findById(bookingId).orElseThrow().getActualCheckInAt();

        // Second check-in — must short-circuit deterministically with NO new side effects.
        JsonNode second = mapper.readTree(checkInByPayload(r.partner().token(), payload)
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
        assertTrue(second.get("success").asBoolean());
        assertEquals("CHECKED_IN", second.get("bookingStatus").asText());
        Instant checkedInAt2 = Instant.parse(second.get("checkedInAt").asText()).truncatedTo(ChronoUnit.MILLIS);
        assertEquals(checkedInAt1, checkedInAt2, "checkedInAt must be immutable");

        assertEquals(1, lifecycleNotifAfterFirst,
            "exactly one lifecycle 'Booking checked in' notification (status engine = single source of truth)");
        assertEquals(0, dupNotifAfterFirst,
            "PartnerCheckInService must NOT create its own duplicate 'Check-in completed' notification");
        assertEquals(1, auditAfterFirst, "exactly one audit row");
        assertEquals(1, timelineAfterFirst, "exactly one CHECKED_IN timeline event");

        // Counts unchanged after the 2nd call.
        assertEquals(notificationsAfterFirst, notificationRepo.count(), "no new notification on repeat");
        assertEquals(lifecycleNotifAfterFirst, countLifecycleCheckInNotification(customerUserId),
            "still exactly one lifecycle notification after the repeat");
        assertEquals(0, countCheckInCompleted(customerUserId), "still no duplicate notification after the repeat");
        assertEquals(auditAfterFirst, auditRepo.countByBookingId(bookingId), "no second audit row on repeat");
        assertEquals(timelineAfterFirst, countCheckedInTimelineEvents(r.partner().token(), bookingId),
            "no duplicate CHECKED_IN timeline event on repeat");
        assertEquals(persistedCheckedInAt, bookingRepo.findById(bookingId).orElseThrow().getActualCheckInAt(),
            "persisted actualCheckInAt must be unchanged by the repeat");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // INELIGIBLE STATUS → 422
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void pendingBooking_unprocessable() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Pending");
        String guestToken = registerGuest();
        Long bookingId = createBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(3)); // no payment → PENDING
        String payload = fetchVoucherPayload(guestToken, bookingId);

        checkInByPayload(r.partner().token(), payload).andExpect(status().isUnprocessableEntity());
        assertEquals(BookingStatus.PENDING, bookingRepo.findById(bookingId).orElseThrow().getStatus());
        assertEquals(0, auditRepo.countByBookingId(bookingId));
    }

    @Test
    void cancelledBooking_unprocessable() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Cancelled");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(3));
        String payload = fetchVoucherPayload(guestToken, bookingId);
        setStatus(bookingId, BookingStatus.CANCELLED);

        checkInByPayload(r.partner().token(), payload).andExpect(status().isUnprocessableEntity());
    }

    @Test
    void completedBooking_unprocessable() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Completed");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(3));
        String payload = fetchVoucherPayload(guestToken, bookingId);
        setStatus(bookingId, BookingStatus.COMPLETED);

        checkInByPayload(r.partner().token(), payload).andExpect(status().isUnprocessableEntity());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // TIME WINDOW → 422
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void farFutureBooking_unprocessable() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("FarFuture");
        String guestToken = registerGuest();
        // Well beyond the default 1-day early window → check-in not yet available.
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(15), today.plusDays(17));
        String payload = fetchVoucherPayload(guestToken, bookingId);

        checkInByPayload(r.partner().token(), payload).andExpect(status().isUnprocessableEntity());
        assertEquals(BookingStatus.CONFIRMED, bookingRepo.findById(bookingId).orElseThrow().getStatus());
        assertEquals(0, auditRepo.countByBookingId(bookingId));
    }

    @Test
    void expiredBooking_unprocessable() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Expired");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(3));
        // Rewrite the stay entirely into the past — the stay period has ended.
        setDates(bookingId, today.minusDays(5), today.minusDays(2));
        String payload = fetchVoucherPayload(guestToken, bookingId);

        checkInByPayload(r.partner().token(), payload).andExpect(status().isUnprocessableEntity());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // OWNERSHIP / SIGNATURE → uniform 404
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void anotherPartnersBooking_notFound() throws Exception {
        OwnedHotelRoom owner = setupOwnedHotelRoom("OwnerHotel");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, owner.roomId(), today.plusDays(1), today.plusDays(3));
        String payload = fetchVoucherPayload(guestToken, bookingId);

        OwnedHotelRoom stranger = setupOwnedHotelRoom("StrangerHotel");
        checkInByPayload(stranger.partner().token(), payload).andExpect(status().isNotFound());
        // Not mutated by the failed attempt.
        assertEquals(BookingStatus.CONFIRMED, bookingRepo.findById(bookingId).orElseThrow().getStatus());
    }

    @Test
    void anotherPartnersBookingByCode_notFound() throws Exception {
        OwnedHotelRoom owner = setupOwnedHotelRoom("OwnerByCode");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, owner.roomId(), today.plusDays(1), today.plusDays(3));
        String code = bookingRepo.findById(bookingId).orElseThrow().getBookingCode();

        OwnedHotelRoom stranger = setupOwnedHotelRoom("StrangerByCode");
        checkInByCode(stranger.partner().token(), code).andExpect(status().isNotFound());
    }

    @Test
    void tamperedSignature_notFound() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("TamperSig");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(3));
        String payload = fetchVoucherPayload(guestToken, bookingId);

        char last = payload.charAt(payload.length() - 1);
        String tampered = payload.substring(0, payload.length() - 1) + (last == 'A' ? 'B' : 'A');
        checkInByPayload(r.partner().token(), tampered).andExpect(status().isNotFound());
        assertEquals(BookingStatus.CONFIRMED, bookingRepo.findById(bookingId).orElseThrow().getStatus());
    }

    @Test
    void validlySignedButUnknownBooking_notFound() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("UnknownBooking");
        String signed = voucherSignatureService.sign("PYT-19990101-999999");
        checkInByPayload(r.partner().token(), signed).andExpect(status().isNotFound());
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
        postCheckIn(r.partner().token(), mapper.writeValueAsString(body)).andExpect(status().isBadRequest());
    }

    @Test
    void neitherInput_badRequest() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("NeitherInput");
        postCheckIn(r.partner().token(), "{}").andExpect(status().isBadRequest());
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

        checkInByPayload(guestToken, payload).andExpect(status().isForbidden());
    }

    @Test
    void anonymous_unauthorized() throws Exception {
        mvc.perform(post("/api/partner/bookings/check-in")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"voucherPayload\":\"PYT-V1.X.Y\"}"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private ResultActions checkInByPayload(String token, String payload) throws Exception {
        Map<String, String> body = new HashMap<>();
        body.put("voucherPayload", payload);
        return postCheckIn(token, mapper.writeValueAsString(body));
    }

    private ResultActions checkInByCode(String token, String code) throws Exception {
        Map<String, String> body = new HashMap<>();
        body.put("bookingCode", code);
        return postCheckIn(token, mapper.writeValueAsString(body));
    }

    private ResultActions postCheckIn(String token, String json) throws Exception {
        return mvc.perform(post("/api/partner/bookings/check-in")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json));
    }

    /** The single lifecycle check-in notification — emitted by BookingStatusEngineService (source of truth). */
    private long countLifecycleCheckInNotification(Long customerUserId) {
        return notificationRepo.findByRecipientUserIdOrderByCreatedAtDesc(customerUserId).stream()
            .filter(n -> "Booking checked in".equals(n.getTitle()))
            .count();
    }

    /** The removed Phase 7.40 duplicate — must never be created (dedup: PartnerCheckInService emits none). */
    private long countCheckInCompleted(Long customerUserId) {
        return notificationRepo.findByRecipientUserIdOrderByCreatedAtDesc(customerUserId).stream()
            .filter(n -> "Check-in completed".equals(n.getTitle()))
            .count();
    }

    private long countCheckedInTimelineEvents(String partnerToken, Long bookingId) throws Exception {
        String body = mvc.perform(get("/api/partner/bookings/" + bookingId)
                .header("Authorization", "Bearer " + partnerToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode events = mapper.readTree(body).get("timeline").get("events");
        long count = 0;
        for (JsonNode e : events) {
            if ("CHECKED_IN".equals(e.get("event").asText())) count++;
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
        bulkCreateInventory(roomId, today.minusDays(2), 40);
        return new OwnedHotelRoom(partner, hotelId, roomId);
    }

    /** Create a booking WITHOUT payment — stays PENDING. Returns the booking id. */
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
        return registerAndLogin("guest-ci-" + counter.getAndIncrement() + "@test.com");
    }

    private PartnerCtx createAndApprovePartner() throws Exception {
        String email = "partner-checkin-" + counter.getAndIncrement() + "@test.com";
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
