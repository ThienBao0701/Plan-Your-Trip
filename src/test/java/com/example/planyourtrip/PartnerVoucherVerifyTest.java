package com.example.planyourtrip;

import com.example.planyourtrip.model.Booking;
import com.example.planyourtrip.model.BookingStatus;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.BookingModificationRepository;
import com.example.planyourtrip.repository.BookingRepository;
import com.example.planyourtrip.repository.CategoryRepository;
import com.example.planyourtrip.repository.InventoryReservationRepository;
import com.example.planyourtrip.repository.NotificationRepository;
import com.example.planyourtrip.repository.PaymentRepository;
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

import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * PartnerVoucherVerifyTest — Phase 7.39 (Partner Voucher Verification, read-only; NO check-in).
 *
 * <p>Exercises {@code POST /api/partner/bookings/voucher/verify}: signature verification (reusing the
 * Phase 7.38 {@code VoucherSignatureService}), booking resolution by code, partner ownership,
 * eligibility reporting, uniform 404 for every invalid/not-owned case, Spring-Security role gating,
 * absence of sensitive fields, and a strict no-mutation (read-only) guarantee.
 *
 * <p>Every scenario provisions its own throwaway partner, hotel, room and guest (mirroring
 * {@code PartnerBookingTest}) so it is isolated from other tests sharing the same H2 instance.
 */
@SpringBootTest
@AutoConfigureMockMvc
class PartnerVoucherVerifyTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired BookingRepository bookingRepo;
    @Autowired PaymentRepository paymentRepo;
    @Autowired NotificationRepository notificationRepo;
    @Autowired BookingModificationRepository bookingModificationRepo;
    @Autowired InventoryReservationRepository inventoryReservationRepo;
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
    // VALID / ELIGIBLE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void ownedConfirmedBooking_verifiedAndEligible() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Confirmed");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(3), today.plusDays(6));
        String payload = fetchVoucherPayload(guestToken, bookingId);

        String body = verify(r.partner().token(), payload)
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        JsonNode res = mapper.readTree(body);

        assertTrue(res.get("verified").asBoolean());
        assertTrue(res.get("eligible").asBoolean());
        assertTrue(res.get("reason").isNull());
        assertEquals("CONFIRMED", res.get("bookingStatus").asText());
        assertEquals(r.hotelId(), res.get("hotelId").asLong());
        assertEquals(r.roomId(), res.get("roomId").asLong());
        assertEquals("Guest Tester", res.get("guestName").asText());
        assertEquals(3, res.get("nights").asInt());
        assertEquals(2, res.get("occupancy").get("adults").asInt());
        assertEquals(0, res.get("occupancy").get("children").asInt());
        assertFalse(res.get("bookingCode").asText().isBlank());
    }

    @Test
    void ownedCheckInReadyBooking_eligible() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("CheckInReady");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(1), today.plusDays(2));
        String payload = fetchVoucherPayload(guestToken, bookingId);
        setStatus(bookingId, BookingStatus.CHECK_IN_READY);

        String body = verify(r.partner().token(), payload)
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        JsonNode res = mapper.readTree(body);
        assertTrue(res.get("verified").asBoolean());
        assertTrue(res.get("eligible").asBoolean());
        assertEquals("CHECK_IN_READY", res.get("bookingStatus").asText());
        assertTrue(res.get("reason").isNull());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // VERIFIED BUT INELIGIBLE (200, verified=true, eligible=false + reason)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void ownedPendingBooking_verifiedButNotEligible() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Pending");
        String guestToken = registerGuest();
        // A booking with no completed payment stays PENDING.
        Long bookingId = createBooking(guestToken, r.roomId(), today.plusDays(4), today.plusDays(5));
        String payload = fetchVoucherPayload(guestToken, bookingId);

        String body = verify(r.partner().token(), payload)
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        JsonNode res = mapper.readTree(body);
        assertTrue(res.get("verified").asBoolean());
        assertFalse(res.get("eligible").asBoolean());
        assertEquals("PENDING", res.get("bookingStatus").asText());
        assertFalse(res.get("reason").isNull());
        assertTrue(res.get("reason").asText().contains("PENDING"));
    }

    @Test
    void ownedCancelledBooking_verifiedButNotEligible() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Cancelled");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(3), today.plusDays(5));
        String payload = fetchVoucherPayload(guestToken, bookingId);
        setStatus(bookingId, BookingStatus.CANCELLED);

        String body = verify(r.partner().token(), payload)
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        JsonNode res = mapper.readTree(body);
        assertTrue(res.get("verified").asBoolean());
        assertFalse(res.get("eligible").asBoolean());
        assertEquals("CANCELLED", res.get("bookingStatus").asText());
        assertTrue(res.get("reason").asText().contains("CANCELLED"));
    }

    @Test
    void ownedCompletedBooking_verifiedButNotEligible() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Completed");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(3), today.plusDays(5));
        String payload = fetchVoucherPayload(guestToken, bookingId);
        setStatus(bookingId, BookingStatus.COMPLETED);

        String body = verify(r.partner().token(), payload)
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        JsonNode res = mapper.readTree(body);
        assertTrue(res.get("verified").asBoolean());
        assertFalse(res.get("eligible").asBoolean());
        assertEquals("COMPLETED", res.get("bookingStatus").asText());
        assertTrue(res.get("reason").asText().contains("COMPLETED"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // UNIFORM 404 — invalid signature / tampering / unknown / not-owned
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void tamperedSignature_notFound() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("TamperSig");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(3), today.plusDays(5));
        String payload = fetchVoucherPayload(guestToken, bookingId);

        // Flip the last character of the signature segment.
        char last = payload.charAt(payload.length() - 1);
        char replacement = last == 'A' ? 'B' : 'A';
        String tampered = payload.substring(0, payload.length() - 1) + replacement;

        verify(r.partner().token(), tampered).andExpect(status().isNotFound());
    }

    @Test
    void tamperedBookingCodeSegment_notFound() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("TamperCode");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(3), today.plusDays(5));
        String payload = fetchVoucherPayload(guestToken, bookingId); // PYT-V1.<code>.<sig>

        String[] parts = payload.split("\\.");
        // Alter one char of the booking-code segment; the original signature no longer matches.
        char c = parts[1].charAt(parts[1].length() - 1);
        String mutatedCode = parts[1].substring(0, parts[1].length() - 1) + (c == '9' ? '8' : '9');
        String tampered = parts[0] + "." + mutatedCode + "." + parts[2];

        verify(r.partner().token(), tampered).andExpect(status().isNotFound());
    }

    @Test
    void unsupportedVersion_notFound() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("BadVersion");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(3), today.plusDays(5));
        String payload = fetchVoucherPayload(guestToken, bookingId);

        String v2 = payload.replaceFirst("^PYT-V1\\.", "PYT-V2.");
        verify(r.partner().token(), v2).andExpect(status().isNotFound());
    }

    @Test
    void wellFormedButUnsignedPayload_notFound() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Unsigned");
        // Correct structure, arbitrary (unsigned) signature bytes → HMAC mismatch → 404.
        verify(r.partner().token(), "PYT-V1.PYT-20260101-000001.AAAA").andExpect(status().isNotFound());
    }

    @Test
    void validlySignedButUnknownBooking_notFound() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("UnknownBooking");
        // A genuinely valid signature over a booking code that does not exist in the DB.
        String signed = voucherSignatureService.sign("PYT-19990101-999999");
        verify(r.partner().token(), signed).andExpect(status().isNotFound());
    }

    @Test
    void anotherPartnersBooking_notFoundNoLeak() throws Exception {
        OwnedHotelRoom owner = setupOwnedHotelRoom("OwnerHotel");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, owner.roomId(), today.plusDays(3), today.plusDays(5));
        String payload = fetchVoucherPayload(guestToken, bookingId);

        // A different approved partner (owns a different hotel) must not resolve this booking.
        OwnedHotelRoom stranger = setupOwnedHotelRoom("StrangerHotel");
        verify(stranger.partner().token(), payload).andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SPRING SECURITY — role gating (before service code)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void customerToken_forbidden() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("CustomerForbidden");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(3), today.plusDays(5));
        String payload = fetchVoucherPayload(guestToken, bookingId);

        // A plain USER (customer) is rejected by /api/partner/** role rule (403) before any code runs.
        verify(guestToken, payload).andExpect(status().isForbidden());
    }

    @Test
    void anonymous_unauthorized() throws Exception {
        mvc.perform(post("/api/partner/bookings/voucher/verify")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"voucherPayload\":\"PYT-V1.X.Y\"}"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // NO SENSITIVE FIELD LEAKAGE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void response_excludesSensitiveFields() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("NoLeak");
        String guestEmail = "guest-leak-" + counter.getAndIncrement() + "@test.com";
        String guestToken = registerAndLogin(guestEmail);
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(3), today.plusDays(5));
        String payload = fetchVoucherPayload(guestToken, bookingId);

        String body = verify(r.partner().token(), payload)
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        JsonNode res = mapper.readTree(body);

        // No payment / money / benefit / token / PII fields present.
        for (String forbidden : new String[]{
                "paymentStatus", "transactionId", "paymentId", "finalPrice", "price", "basePrice",
                "currency", "giftCard", "giftCardReference", "coupon", "couponCode", "loyalty",
                "loyaltyDiscountAmount", "credit", "creditAmountUsed", "travelCredit", "email",
                "guestEmail", "token", "jwt", "partnerNote", "specialRequest"}) {
            assertFalse(res.has(forbidden), "response must not expose field: " + forbidden);
        }
        // The guest's email must not appear anywhere in the serialized body.
        assertFalse(body.contains(guestEmail), "response body must not contain the guest email");
        assertFalse(body.contains("@test.com"), "response body must not contain any email address");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // READ-ONLY GUARANTEE + DETERMINISM
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void verify_isReadOnly_noMutation() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("ReadOnly");
        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, r.roomId(), today.plusDays(3), today.plusDays(6));
        String payload = fetchVoucherPayload(guestToken, bookingId);

        Booking before = bookingRepo.findById(bookingId).orElseThrow();
        BookingStatus statusBefore = before.getStatus();
        var updatedBefore = before.getUpdatedAt();
        long payments = paymentRepo.count();
        long notifications = notificationRepo.count();
        long modifications = bookingModificationRepo.count();
        long reservations = inventoryReservationRepo.count();

        // Two identical calls: same output, and still no mutation (deterministic + read-only).
        String first = verify(r.partner().token(), payload)
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        String second = verify(r.partner().token(), payload)
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        assertEquals(first, second, "verification must be deterministic for identical input");

        Booking after = bookingRepo.findById(bookingId).orElseThrow();
        assertEquals(statusBefore, after.getStatus(), "booking status must be unchanged");
        assertEquals(updatedBefore, after.getUpdatedAt(), "booking row must not be re-persisted");
        assertEquals(payments, paymentRepo.count(), "no payment row may be written");
        assertEquals(notifications, notificationRepo.count(), "no notification row may be written");
        assertEquals(modifications, bookingModificationRepo.count(), "no modification row may be written");
        assertEquals(reservations, inventoryReservationRepo.count(), "no inventory reservation may change");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS (adapted from PartnerBookingTest)
    // ═══════════════════════════════════════════════════════════════════════════

    private ResultActions verify(String token, String payload) throws Exception {
        String json = mapper.writeValueAsString(Map.of("voucherPayload", payload));
        return mvc.perform(post("/api/partner/bookings/voucher/verify")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json));
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
        return registerAndLogin("guest-v-" + counter.getAndIncrement() + "@test.com");
    }

    private PartnerCtx createAndApprovePartner() throws Exception {
        String email = "partner-voucher-" + counter.getAndIncrement() + "@test.com";
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
