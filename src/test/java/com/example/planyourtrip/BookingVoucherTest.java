package com.example.planyourtrip;

import com.example.planyourtrip.model.BookingStatus;
import com.example.planyourtrip.model.InventoryReservation;
import com.example.planyourtrip.repository.*;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultMatcher;

import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Phase 7.38 — Customer Booking Digital Voucher (read-only foundation).
 *
 * <p>Exercises {@code GET /api/me/bookings/{bookingId}/voucher}: an authenticated, owner-scoped,
 * strictly READ-ONLY endpoint returning a safe voucher DERIVED from persisted booking/payment/
 * modification snapshots. Verifies the voucherStatus eligibility mapping, stable derived codes, a
 * non-sensitive QR payload, 404-for-non-owner, modification consistency, and — critically — that a
 * voucher read mutates NOTHING (booking / payment / inventory / reservation / notification / audit).
 *
 * <p>Isolation: every scenario provisions its OWN published hotel/room + inventory (mirroring
 * {@code BookingModificationAuditTest}), so pricing and inventory are exact and deterministic.
 */
@SpringBootTest
@AutoConfigureMockMvc
class BookingVoucherTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired BookingRepository bookingRepo;
    @Autowired PaymentRepository paymentRepo;
    @Autowired BookingModificationRepository modificationRepo;
    @Autowired NotificationRepository notificationRepo;
    @Autowired InventoryReservationRepository reservationRepo;
    @Autowired RoomInventoryRepository inventoryRepo;

    private String adminToken;
    private Long accCategoryId;
    private Long hotelSubcategoryId;
    private Long locationId;

    @BeforeEach
    void setup() throws Exception {
        adminToken = login("admin@planyourtrip.com", "admin123456");
        accCategoryId      = categoryRepo.findBySlug("accommodation").orElseThrow().getId();
        hotelSubcategoryId = categoryRepo.findBySlug("hotel").orElseThrow().getId();
        locationId         = locationRepo.findByCode("VT").orElseThrow().getId();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 1. confirmed + paid → VALID, all persisted fields present and matching
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void confirmedPaidBooking_voucherIsValid_withMatchingPersistedFields() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Flex", "VCH-1", 1_000_000, 20));

        String token = registerAndLogin("vch-1-" + uniq() + "@test.com");
        JsonNode booking = book(token, roomId, today(3), today(5), 2, 1, planId, 0); // 2 nights
        Long bookingId = booking.get("id").asLong();
        String bookingCode = booking.get("bookingCode").asText();
        pay(token, bookingId); // mock-success → CONFIRMED + PAID

        JsonNode v = voucher(token, bookingId, status().isOk());

        assertEquals("VALID", v.get("voucherStatus").asText());
        assertEquals("CONFIRMED", v.get("bookingStatus").asText());
        assertEquals("PAID", v.get("paymentStatus").asText());
        assertEquals(bookingId, v.get("bookingId").asLong());
        assertEquals(bookingCode, v.get("bookingReference").asText());
        assertEquals(bookingCode, v.get("confirmationCode").asText());
        assertEquals("VCH-" + bookingCode, v.get("voucherCode").asText());
        // qrPayload is now a versioned HMAC-signed payload (Phase 7.38 hardening), no longer the raw
        // "PYT-VCHR:"+bookingCode. Shape: PYT-V1.<bookingCode>.<base64urlSig> (three dot segments).
        String qr = v.get("qrPayload").asText();
        assertTrue(qr.matches("^PYT-V1\\..+\\..+$"), "qrPayload is the versioned signed form: " + qr);
        assertTrue(qr.startsWith("PYT-V1." + bookingCode + "."), "bookingCode is the middle segment");
        assertNotEquals("PYT-VCHR:" + bookingCode, qr, "no longer the raw bookingCode-only payload");
        assertEquals(3, qr.split("\\.", -1).length, "exactly three dot-separated segments");
        assertEquals(2, v.get("numberOfNights").asInt());
        assertEquals(2, v.get("adults").asInt());
        assertEquals(1, v.get("children").asInt());
        assertEquals(today(3).toString(), v.get("checkIn").asText());
        assertEquals(today(5).toString(), v.get("checkOut").asText());
        assertEquals("VCH-1", v.get("selectedRatePlanCode").asText());
        assertEquals("Flex", v.get("selectedRatePlanName").asText());
        assertEquals(booking.get("finalPrice").asDouble(), v.get("finalPrice").asDouble(), 0.01);
        assertEquals("VND", v.get("currency").asText());
        assertNotNull(v.get("guestName").asText());
        assertNotNull(v.get("hotelName").asText());
        assertNotNull(v.get("hotelAddress").asText());
        assertNotNull(v.get("roomName").asText());
        assertTrue(v.get("latestModificationAt").isNull(), "never modified → null");
        assertTrue(v.get("warnings").isArray());
        assertEquals(0, v.get("warnings").size(), "VALID voucher carries no warnings for a refundable plan");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 2. pending / unpaid → NOT_READY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void pendingUnpaidBooking_voucherIsNotReady() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Flex", "VCH-2", 1_000_000, 20));

        String token = registerAndLogin("vch-2-" + uniq() + "@test.com");
        Long bookingId = book(token, roomId, today(3), today(5), 2, 0, planId, 0).get("id").asLong();

        JsonNode v = voucher(token, bookingId, status().isOk());
        assertEquals("NOT_READY", v.get("voucherStatus").asText());
        assertEquals("PENDING", v.get("bookingStatus").asText());
        assertTrue(v.get("paymentStatus").isNull(), "no payment yet → null paymentStatus");
        assertTrue(v.get("warnings").size() >= 1, "NOT_READY carries an advisory");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 3. failed payment → INVALID
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void failedPaymentBooking_voucherIsInvalid() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Flex", "VCH-3", 1_000_000, 20));

        String token = registerAndLogin("vch-3-" + uniq() + "@test.com");
        Long bookingId = book(token, roomId, today(3), today(5), 2, 0, planId, 0).get("id").asLong();
        Long payId = createPayment(token, bookingId);
        mvc.perform(post("/api/payments/" + payId + "/mock-fail")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"failureReason\":\"Insufficient funds\"}"))
            .andExpect(status().isOk());

        JsonNode v = voucher(token, bookingId, status().isOk());
        assertEquals("INVALID", v.get("voucherStatus").asText());
        assertEquals("PENDING", v.get("bookingStatus").asText());
        assertEquals("FAILED", v.get("paymentStatus").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 4. cancelled → CANCELLED (200, not an error)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void cancelledBooking_voucherIsCancelled_with200() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Flex", "VCH-4", 1_000_000, 20));

        String token = registerAndLogin("vch-4-" + uniq() + "@test.com");
        Long bookingId = book(token, roomId, today(3), today(5), 2, 0, planId, 0).get("id").asLong();
        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        JsonNode v = voucher(token, bookingId, status().isOk());
        assertEquals("CANCELLED", v.get("voucherStatus").asText());
        assertEquals("CANCELLED", v.get("bookingStatus").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 5. completed → HISTORICAL
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void completedBooking_voucherIsHistorical() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Flex", "VCH-5", 1_000_000, 20));

        String token = registerAndLogin("vch-5-" + uniq() + "@test.com");
        Long bookingId = book(token, roomId, today(3), today(5), 2, 0, planId, 0).get("id").asLong();
        pay(token, bookingId);
        adminSetStatus(bookingId, "COMPLETED");

        JsonNode v = voucher(token, bookingId, status().isOk());
        assertEquals("HISTORICAL", v.get("voucherStatus").asText());
        assertEquals("COMPLETED", v.get("bookingStatus").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 6 & 7. owner → 200; unrelated customer → 404 (don't leak existence)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void owner200_unrelatedCustomer404() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Flex", "VCH-6", 1_000_000, 20));

        String owner = registerAndLogin("vch-6-owner-" + uniq() + "@test.com");
        String stranger = registerAndLogin("vch-6-stranger-" + uniq() + "@test.com");
        Long bookingId = book(owner, roomId, today(3), today(5), 2, 0, planId, 0).get("id").asLong();

        voucher(owner, bookingId, status().isOk());
        // Deliberate 404 (not 403) for a booking the caller does not own.
        voucher(stranger, bookingId, status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 8. unauthenticated → 401
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void unauthenticated_returns401() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Flex", "VCH-7", 1_000_000, 20));
        String token = registerAndLogin("vch-7-" + uniq() + "@test.com");
        Long bookingId = book(token, roomId, today(3), today(5), 2, 0, planId, 0).get("id").asLong();

        mvc.perform(get("/api/me/bookings/" + bookingId + "/voucher"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 9. repeated reads → identical voucherCode + bookingReference (stability)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void repeatedReads_produceIdenticalStableCodes() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Flex", "VCH-8", 1_000_000, 20));
        String token = registerAndLogin("vch-8-" + uniq() + "@test.com");
        Long bookingId = book(token, roomId, today(3), today(5), 2, 0, planId, 0).get("id").asLong();

        JsonNode a = voucher(token, bookingId, status().isOk());
        JsonNode b = voucher(token, bookingId, status().isOk());
        assertEquals(a.get("voucherCode").asText(), b.get("voucherCode").asText());
        assertEquals(a.get("bookingReference").asText(), b.get("bookingReference").asText());
        assertEquals(a.get("confirmationCode").asText(), b.get("confirmationCode").asText());
        assertEquals(a.get("qrPayload").asText(), b.get("qrPayload").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 10 & 11. QR payload / response carry NO JWT and NO payment / benefit secret
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void qrPayloadAndResponse_containNoTokenOrProviderSecret() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Flex", "VCH-9", 1_000_000, 20));
        String token = registerAndLogin("vch-9-" + uniq() + "@test.com");
        Long bookingId = book(token, roomId, today(3), today(5), 2, 0, planId, 0).get("id").asLong();
        Long payId = createPayment(token, bookingId);
        // Mark paid with a known provider transaction id — it must NEVER appear in the voucher.
        String txnId = "TXN-SECRET-" + uniq();
        mvc.perform(post("/api/payments/" + payId + "/mock-success")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"providerTransactionId\":\"" + txnId + "\"}"))
            .andExpect(status().isOk());

        String raw = mvc.perform(get("/api/me/bookings/" + bookingId + "/voucher")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode v = mapper.readTree(raw);

        String qr = v.get("qrPayload").asText();
        // Versioned signed form: PYT-V1.<bookingCode>.<sig>. It is NOT a JWT — the whole access token
        // is a 3-segment dotted JWT; the voucher payload must not embed it.
        assertTrue(qr.matches("^PYT-V1\\..+\\..+$"), "QR payload is the versioned signed form");
        assertFalse(qr.contains(token), "QR payload does not contain the access token (no embedded JWT)");
        assertFalse(qr.contains(txnId), "QR payload does not contain the provider transaction id");
        assertTrue(qr.startsWith("PYT-V1."), "QR payload uses the versioned signed prefix");

        // Full response body: no JWT, no provider secret, and no sensitive provider/internal fields.
        assertFalse(raw.contains(token), "response body does not leak the JWT");
        assertFalse(raw.contains(txnId), "response body does not leak the provider transaction id");
        assertFalse(raw.contains("providerTransactionId"), "no provider transaction id field exposed");
        assertFalse(raw.contains("partnerNote"), "no internal partner note exposed");
        assertFalse(raw.contains("checkoutUrl"), "no payment checkout url exposed");
        assertFalse(raw.contains("giftCardReference"), "no gift-card reference field exposed");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 12 & 13. A pending-booking modification is reflected; codes stay stable
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void modification_reflectedInVoucher_butCodesUnchanged() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Flex", "VCH-10", 1_000_000, 20));
        String token = registerAndLogin("vch-10-" + uniq() + "@test.com");
        JsonNode booking = book(token, roomId, today(3), today(5), 2, 0, planId, 0); // 2 nights
        Long bookingId = booking.get("id").asLong();

        JsonNode before = voucher(token, bookingId, status().isOk());
        String voucherCodeBefore = before.get("voucherCode").asText();
        String refBefore = before.get("bookingReference").asText();
        String qrBefore = before.get("qrPayload").asText();
        assertTrue(before.get("latestModificationAt").isNull());

        // Change dates (3 nights) + occupancy.
        Map<String, Object> req = new LinkedHashMap<>();
        req.put("checkIn", today(10).toString());
        req.put("checkOut", today(13).toString());
        req.put("adults", 3);
        req.put("children", 1);
        modify(token, bookingId, req, status().isOk());

        JsonNode after = voucher(token, bookingId, status().isOk());
        // New persisted values are reflected.
        assertEquals(today(10).toString(), after.get("checkIn").asText());
        assertEquals(today(13).toString(), after.get("checkOut").asText());
        assertEquals(3, after.get("numberOfNights").asInt());
        assertEquals(3, after.get("adults").asInt());
        assertEquals(1, after.get("children").asInt());
        assertFalse(after.get("latestModificationAt").isNull(), "modification timestamp now populated");
        // Stable codes survive the modification unchanged.
        assertEquals(voucherCodeBefore, after.get("voucherCode").asText());
        assertEquals(refBefore, after.get("bookingReference").asText());
        // The signed QR payload also does NOT rotate: only the immutable bookingCode is signed, so a
        // dates/occupancy change must produce the identical payload.
        assertEquals(qrBefore, after.get("qrPayload").asText(),
            "signed qrPayload is stable across a Phase 7.34 modification (only immutable bookingCode signed)");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 14. voucher read mutates neither Booking nor Payment
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void voucherRead_mutatesNoBookingOrPayment() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Flex", "VCH-11", 1_000_000, 20));
        String token = registerAndLogin("vch-11-" + uniq() + "@test.com");
        Long bookingId = book(token, roomId, today(3), today(5), 2, 0, planId, 0).get("id").asLong();
        pay(token, bookingId);

        long paymentsBefore = paymentRepo.count();
        BookingStatus statusBefore = bookingRepo.findById(bookingId).orElseThrow().getStatus();

        voucher(token, bookingId, status().isOk());
        voucher(token, bookingId, status().isOk());

        assertEquals(paymentsBefore, paymentRepo.count(), "no payment row created/removed by a voucher read");
        assertEquals(statusBefore, bookingRepo.findById(bookingId).orElseThrow().getStatus(),
            "booking status unchanged by a voucher read");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 15. voucher read mutates no inventory (RoomInventory + InventoryReservation)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void voucherRead_mutatesNoInventory() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Flex", "VCH-12", 1_000_000, 20));
        String token = registerAndLogin("vch-12-" + uniq() + "@test.com");
        Long bookingId = book(token, roomId, today(3), today(5), 2, 0, planId, 0).get("id").asLong();

        long inventoryRowsBefore = inventoryRepo.count();
        long reservationsBefore = reservationRepo.count();
        InventoryReservation resBefore = reservationRepo.findByBookingId(bookingId).orElseThrow();
        var resStatusBefore = resBefore.getStatus();

        voucher(token, bookingId, status().isOk());
        voucher(token, bookingId, status().isOk());

        assertEquals(inventoryRowsBefore, inventoryRepo.count(), "no RoomInventory rows changed by a voucher read");
        assertEquals(reservationsBefore, reservationRepo.count(), "no InventoryReservation rows changed");
        assertEquals(resStatusBefore, reservationRepo.findByBookingId(bookingId).orElseThrow().getStatus(),
            "the booking's reservation status is unchanged (still HELD)");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 16. voucher read creates no ledger / notification / audit rows
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void voucherRead_createsNoNotificationOrAuditRows() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Flex", "VCH-13", 1_000_000, 20));
        String token = registerAndLogin("vch-13-" + uniq() + "@test.com");
        Long bookingId = book(token, roomId, today(3), today(5), 2, 0, planId, 0).get("id").asLong();
        pay(token, bookingId);

        long notificationsBefore = notificationRepo.count();
        long auditBefore = modificationRepo.count();

        voucher(token, bookingId, status().isOk());
        voucher(token, bookingId, status().isOk());

        assertEquals(notificationsBefore, notificationRepo.count(), "no notification created by a voucher read");
        assertEquals(auditBefore, modificationRepo.count(), "no BookingModification audit row created");
        // And the booking's own audit history stays empty (it was never modified).
        assertTrue(modificationRepo.findByBookingIdOrderByCreatedAtAscIdAsc(bookingId).isEmpty());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS (adapted from BookingModificationAuditTest / PaymentTest)
    // ═══════════════════════════════════════════════════════════════════════════

    private LocalDate today(int plus) { return LocalDate.now().plusDays(plus); }

    private JsonNode voucher(String token, Long bookingId, ResultMatcher expected) throws Exception {
        String body = mvc.perform(get("/api/me/bookings/" + bookingId + "/voucher")
                .header("Authorization", "Bearer " + token))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
    }

    private void pay(String token, Long bookingId) throws Exception {
        Long payId = createPayment(token, bookingId);
        mvc.perform(post("/api/payments/" + payId + "/mock-success")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
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

    private void adminSetStatus(Long bookingId, String status) throws Exception {
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/status")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"" + status + "\"}"))
            .andExpect(status().isOk());
    }

    private Map<String, Object> plan(String name, String code, long price, int priority) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("rateName", name);
        m.put("rateType", "STANDARD");
        m.put("pricePerNight", price);
        m.put("startDate", LocalDate.now().toString());
        m.put("endDate", LocalDate.now().plusDays(365).toString());
        m.put("active", true);
        m.put("priority", priority);
        m.put("code", code);
        return m;
    }

    private Long createPlanReturnId(Long roomId, Object body) throws Exception {
        String resp = mvc.perform(post("/api/admin/rooms/" + roomId + "/rate-plans")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(body)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp).get("id").asLong();
    }

    private JsonNode book(String token, Long roomId, LocalDate ci, LocalDate co,
                          int adults, int children, Long ratePlanId, int extraBeds) throws Exception {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("roomId", roomId);
        m.put("checkIn", ci.toString());
        m.put("checkOut", co.toString());
        m.put("adults", adults);
        m.put("children", children);
        m.put("numberOfRooms", 1);
        if (ratePlanId != null) m.put("ratePlanId", ratePlanId);
        if (extraBeds > 0) m.put("extraBeds", extraBeds);
        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(m)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode modify(String token, Long bookingId, Map<String, Object> req,
                            ResultMatcher expected) throws Exception {
        String body = mvc.perform(patch("/api/bookings/" + bookingId + "/modify")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(req)))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
    }

    // ── Provisioning ──────────────────────────────────────────────────────────

    /** A bookable room: published hotel + inventory seeded today+1..today+50 (10 available). */
    private Long provisionBookableRoom() throws Exception {
        Long hotelId = createHotelPlace(uniq());
        createHotelDetail(hotelId);
        Long roomId = createRoom(hotelId, "RM-" + uniq());
        StringBuilder items = new StringBuilder();
        for (int i = 1; i <= 50; i++) {
            if (items.length() > 0) items.append(",");
            items.append(String.format(
                "{\"inventoryDate\":\"%s\",\"totalInventory\":10,\"availableInventory\":10,"
                + "\"blockedInventory\":0,\"soldInventory\":0,\"maintenanceInventory\":0,"
                + "\"stopSell\":false,\"closedArrival\":false,\"closedDeparture\":false}",
                today(i)));
        }
        mvc.perform(post("/api/admin/rooms/" + roomId + "/inventory/bulk")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"items\":[" + items + "]}"))
            .andExpect(status().isOk());
        return roomId;
    }

    private String uniq() { return UUID.randomUUID().toString().substring(0, 8); }

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
                .content("{\"fullName\":\"Voucher Tester\",\"email\":\"" + email + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private Long createHotelPlace(String name) throws Exception {
        String req = """
            {"name":"%s","categoryId":%d,"subcategoryId":%d,"administrativeUnitId":%d,
             "address":"123 Test Street","priceLevel":2,"featured":false,"verified":false,"status":"DRAFT"}
            """.formatted(name, accCategoryId, hotelSubcategoryId, locationId);
        String resp = mvc.perform(post("/api/admin/places")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long id = mapper.readTree(resp).get("id").asLong();
        patchStatus(id, "APPROVED");
        patchStatus(id, "PUBLISHED");
        return id;
    }

    private void patchStatus(Long id, String status) throws Exception {
        mvc.perform(patch("/api/admin/places/" + id + "/status")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"" + status + "\"}"))
            .andExpect(status().isOk());
    }

    private void createHotelDetail(Long placeId) throws Exception {
        String req = """
            {"placeId":%d,"starRating":4,"checkInTime":"14:00:00","checkOutTime":"12:00:00",
             "totalRooms":10,"availableRooms":10,"freeCancellation":false,"prepaymentRequired":false,
             "breakfastIncluded":false,"airportShuttle":false}
            """.formatted(placeId);
        mvc.perform(post("/api/admin/hotels")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isCreated());
    }

    private Long createRoom(Long placeId, String roomCode) throws Exception {
        String req = """
            {"placeId":%d,"roomName":"Deluxe Room","roomCode":"%s","roomType":"DELUXE","bedType":"QUEEN",
             "bedCount":1,"maxAdults":3,"maxChildren":2,"maxGuests":4,"roomSizeSqm":25.0,"floorNumber":2,
             "smokingAllowed":false,"breakfastIncluded":true,"freeCancellation":true,"instantConfirmation":true,
             "priceFrom":900000,"originalPrice":1000000,"quantity":10,"availableQuantity":10,"active":true}
            """.formatted(placeId, roomCode);
        String resp = mvc.perform(post("/api/admin/rooms")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp).get("id").asLong();
    }
}
