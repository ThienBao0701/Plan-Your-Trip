package com.example.planyourtrip;

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

import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Phase 7.34 — Customer modification of a PENDING (not-yet-paid) booking.
 *
 * <p>Exercises {@code PATCH /api/bookings/{id}/modify}: changing dates / occupancy / rate plan on a
 * PENDING booking, which re-checks inventory (reusing the Phase 7.28 lock), re-prices and
 * re-snapshots the rate plan (reusing the Phase 7.29/7.30 pipeline) — with full rollback on
 * failure, the PENDING-only boundary, the benefit-rejection rule, and the ownership convention.
 *
 * <p>Isolation: every scenario provisions its OWN published hotel/room + inventory (never mutating
 * the shared seeded Grand Palace Hotel), so inventory and pricing are exact and deterministic.
 */
@SpringBootTest
@AutoConfigureMockMvc
class BookingModificationTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired RoomInventoryRepository inventoryRepo;
    @Autowired InventoryReservationRepository reservationRepo;

    private String adminToken;
    private Long accCategoryId;
    private Long hotelSubcategoryId;
    private Long locationId;
    private static final AtomicInteger counter = new AtomicInteger(1);

    @BeforeEach
    void setup() throws Exception {
        adminToken = login("admin@planyourtrip.com", "admin123456");
        accCategoryId      = categoryRepo.findBySlug("accommodation").orElseThrow().getId();
        hotelSubcategoryId = categoryRepo.findBySlug("hotel").orElseThrow().getId();
        locationId         = locationRepo.findByCode("VT").orElseThrow().getId();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 1. Modify dates → old restored, new decremented, re-priced, reservation moved
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void modifyDates_restoresOldDecrementsNewRepricesAndMovesReservation() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Flat", "FLAT-1", 1_000_000, 20));

        String token = registerAndLogin("mod-dates-" + uniq() + "@test.com");
        JsonNode booking = book(token, roomId, today(3), today(5), 2, 0, planId, 0); // 2 nights
        Long bookingId = booking.get("id").asLong();
        assertEquals(2_000_000.0, booking.get("ratePlanPrice").asDouble(), 0.01);
        assertFinalConsistent(booking);
        assertEquals(9, avail(roomId, today(3)));
        assertEquals(9, avail(roomId, today(4)));

        // Shift to a disjoint 3-night window.
        Map<String, Object> req = new LinkedHashMap<>();
        req.put("checkIn", today(20).toString());
        req.put("checkOut", today(23).toString());
        JsonNode res = modify(token, bookingId, req, status().isOk());

        assertEquals(today(20).toString(), res.get("checkIn").asText());
        assertEquals(today(23).toString(), res.get("checkOut").asText());
        assertEquals(3, res.get("nights").asInt());
        assertEquals(3_000_000.0, res.get("ratePlanPrice").asDouble(), 0.01, "re-priced for 3 nights");
        assertFinalConsistent(res);

        // Old nights fully restored; new nights decremented.
        assertEquals(10, avail(roomId, today(3)), "old night restored");
        assertEquals(10, avail(roomId, today(4)), "old night restored");
        assertEquals(9, avail(roomId, today(20)));
        assertEquals(9, avail(roomId, today(21)));
        assertEquals(9, avail(roomId, today(22)));

        // Reservation row moved to the new window, still HELD.
        InventoryReservation r = reservationRepo.findByBookingId(bookingId).orElseThrow();
        assertEquals("HELD", r.getStatus().name());
        assertEquals(today(20), r.getCheckInDate());
        assertEquals(today(23), r.getCheckOutDate());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 2. Modify occupancy → price reflects occupancy supplement (dates unchanged)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void modifyOccupancy_repricesViaPipeline_inventoryUntouched() throws Exception {
        Long roomId = provisionBookableRoom();
        Map<String, Object> p = plan("Occ", "OCC-1", 1_000_000, 20);
        p.put("occupancyPricingEnabled", true);
        Long planId = createPlanReturnId(roomId, p);
        addOccupancy(planId, 2, 1, 1_200_000, null, null); // (2 adults, 1 child) → 1,200,000/night

        String token = registerAndLogin("mod-occ-" + uniq() + "@test.com");
        JsonNode booking = book(token, roomId, today(6), today(7), 2, 0, planId, 0); // (2,0) → fallback base
        Long bookingId = booking.get("id").asLong();
        assertEquals(1_000_000.0, booking.get("nightlyRateSnapshot").asDouble(), 0.01);
        assertEquals(9, avail(roomId, today(6)));

        Map<String, Object> req = new LinkedHashMap<>();
        req.put("children", 1);
        JsonNode res = modify(token, bookingId, req, status().isOk());

        assertEquals(1, res.get("children").asInt());
        assertEquals(1_200_000.0, res.get("nightlyRateSnapshot").asDouble(), 0.01, "occupancy row applied");
        assertEquals(1_200_000.0, res.get("ratePlanPrice").asDouble(), 0.01, "1 night at the occupancy rate");
        assertFinalConsistent(res);
        // Dates unchanged → inventory untouched.
        assertEquals(9, avail(roomId, today(6)), "occupancy-only change must not touch inventory");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 3. Modify to an explicit eligible rate plan → snapshotted + priced
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void modifyToExplicitRatePlan_snapshotsAndPricesNewPlan() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planA = createPlanReturnId(roomId, plan("Plan A", "PA-1", 1_000_000, 20));
        Long planB = createPlanReturnId(roomId, plan("Plan B", "PB-1", 1_500_000, 5));

        String token = registerAndLogin("mod-plan-" + uniq() + "@test.com");
        JsonNode booking = book(token, roomId, today(8), today(10), 2, 0, planA, 0);
        Long bookingId = booking.get("id").asLong();
        assertEquals(planA.longValue(), booking.get("selectedRatePlanId").asLong());
        assertEquals(2_000_000.0, booking.get("ratePlanPrice").asDouble(), 0.01);

        Map<String, Object> req = new LinkedHashMap<>();
        req.put("ratePlanId", planB);
        JsonNode res = modify(token, bookingId, req, status().isOk());

        assertEquals(planB.longValue(), res.get("selectedRatePlanId").asLong());
        assertEquals("Plan B", res.get("selectedRatePlanName").asText());
        assertEquals(1_500_000.0, res.get("nightlyRateSnapshot").asDouble(), 0.01);
        assertEquals(3_000_000.0, res.get("ratePlanPrice").asDouble(), 0.01, "2 nights × 1,500,000");
        assertFinalConsistent(res);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 4. Modify to an ineligible rate plan → 422, booking unchanged
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void modifyToIneligibleRatePlan_rejected422_bookingUnchanged() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planA = createPlanReturnId(roomId, plan("Eligible", "EL-1", 1_000_000, 20));
        Map<String, Object> longStay = plan("LongStay", "LS-1", 1_000_000, 20);
        longStay.put("minStayNights", 5);
        Long planC = createPlanReturnId(roomId, longStay);

        String token = registerAndLogin("mod-inelig-" + uniq() + "@test.com");
        JsonNode booking = book(token, roomId, today(11), today(13), 2, 0, planA, 0); // 2 nights
        Long bookingId = booking.get("id").asLong();

        Map<String, Object> req = new LinkedHashMap<>();
        req.put("ratePlanId", planC); // 2-night stay violates min-stay 5
        modify(token, bookingId, req, status().isUnprocessableEntity());

        // Booking unchanged.
        JsonNode after = getBooking(token, bookingId);
        assertEquals(planA.longValue(), after.get("selectedRatePlanId").asLong());
        assertEquals(today(11).toString(), after.get("checkIn").asText());
        assertEquals(today(13).toString(), after.get("checkOut").asText());
        assertEquals(2_000_000.0, after.get("ratePlanPrice").asDouble(), 0.01);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 5. Non-PENDING booking → 422, unchanged
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void modifyConfirmedBooking_rejected422() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Conf", "CF-1", 1_000_000, 20));
        String token = registerAndLogin("mod-conf-" + uniq() + "@test.com");
        Long bookingId = book(token, roomId, today(14), today(16), 2, 0, planId, 0).get("id").asLong();

        // Pay to success → booking becomes CONFIRMED.
        payAndSucceed(token, bookingId);
        assertEquals("CONFIRMED", getBooking(token, bookingId).get("status").asText());

        Map<String, Object> req = new LinkedHashMap<>();
        req.put("checkOut", today(17).toString());
        modify(token, bookingId, req, status().isUnprocessableEntity());
    }

    @Test
    void modifyCancelledBooking_rejected422() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Canc", "CN-1", 1_000_000, 20));
        String token = registerAndLogin("mod-canc-" + uniq() + "@test.com");
        Long bookingId = book(token, roomId, today(14), today(16), 2, 0, planId, 0).get("id").asLong();

        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        Map<String, Object> req = new LinkedHashMap<>();
        req.put("checkOut", today(17).toString());
        modify(token, bookingId, req, status().isUnprocessableEntity());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 6. Another user's booking → 403 (matches cancel())
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void modifyAnotherUsersBooking_returns403() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Own", "OWN-1", 1_000_000, 20));
        String owner = registerAndLogin("mod-owner-" + uniq() + "@test.com");
        Long bookingId = book(owner, roomId, today(17), today(19), 2, 0, planId, 0).get("id").asLong();

        String other = registerAndLogin("mod-other-" + uniq() + "@test.com");
        Map<String, Object> req = new LinkedHashMap<>();
        req.put("checkOut", today(20).toString());
        modify(other, bookingId, req, status().isForbidden());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 7. New dates unavailable → 422 AND full rollback (old still held)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void modifyToUnavailableDates_rejected422_fullRollback() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("RB", "RB-1", 1_000_000, 20));
        // Exhaust a disjoint target window (available = 0).
        seedNight(roomId, today(30), 0, 0);
        seedNight(roomId, today(31), 0, 0);

        String token = registerAndLogin("mod-rb-" + uniq() + "@test.com");
        JsonNode booking = book(token, roomId, today(3), today(5), 2, 0, planId, 0); // 2 nights
        Long bookingId = booking.get("id").asLong();
        assertEquals(9, avail(roomId, today(3)));
        assertEquals(9, avail(roomId, today(4)));

        Map<String, Object> req = new LinkedHashMap<>();
        req.put("checkIn", today(30).toString());
        req.put("checkOut", today(32).toString());
        modify(token, bookingId, req, status().isUnprocessableEntity());

        // FULL rollback: old nights still held, target window still 0, booking intact.
        assertEquals(9, avail(roomId, today(3)), "old night still held after rolled-back modify");
        assertEquals(9, avail(roomId, today(4)), "old night still held after rolled-back modify");
        assertEquals(0, avail(roomId, today(30)), "target window unchanged (never negative)");
        assertEquals(0, avail(roomId, today(31)), "target window unchanged (never negative)");

        JsonNode after = getBooking(token, bookingId);
        assertEquals(today(3).toString(), after.get("checkIn").asText());
        assertEquals(today(5).toString(), after.get("checkOut").asText());
        assertEquals(2_000_000.0, after.get("ratePlanPrice").asDouble(), 0.01);
        InventoryReservation r = reservationRepo.findByBookingId(bookingId).orElseThrow();
        assertEquals("HELD", r.getStatus().name());
        assertEquals(today(3), r.getCheckInDate());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 8. Modification does not oversell under the pessimistic lock
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void modifyIntoFullyBookedNight_cannotOversell() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("OS", "OS-1", 1_000_000, 20));
        seedNight(roomId, today(40), 1, 1); // exactly ONE room on this night

        // A different customer takes the single room on today+40.
        String holder = registerAndLogin("mod-holder-" + uniq() + "@test.com");
        book(holder, roomId, today(40), today(41), 1, 0, planId, 0);
        assertEquals(0, avail(roomId, today(40)));

        // Our customer has a booking elsewhere and tries to modify INTO the exhausted night.
        String token = registerAndLogin("mod-os-" + uniq() + "@test.com");
        Long bookingId = book(token, roomId, today(3), today(5), 1, 0, planId, 0).get("id").asLong();

        Map<String, Object> req = new LinkedHashMap<>();
        req.put("checkIn", today(40).toString());
        req.put("checkOut", today(41).toString());
        modify(token, bookingId, req, status().isUnprocessableEntity());

        assertEquals(0, avail(roomId, today(40)), "availability lands at exactly zero, never negative");
        // Our booking is untouched and still holds its original nights.
        assertEquals(9, avail(roomId, today(3)));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 9. Benefit already applied → modification rejected (documented rule)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void modifyBookingWithAppliedCoupon_rejected422() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Cpn", "CPN-1", 1_000_000, 20));

        String code = ("MOD-CPN-" + counter.getAndIncrement()).toUpperCase();
        createCouponDef(code, "PERCENTAGE", "10");
        String token = registerAndLogin("mod-cpn-" + uniq() + "@test.com");
        claim(token, code);

        JsonNode booking = bookWithCoupon(token, roomId, today(11), today(13), planId, code);
        Long bookingId = booking.get("id").asLong();
        assertFalse(booking.get("couponDiscountAmount").isNull(), "coupon applied at creation");

        Map<String, Object> req = new LinkedHashMap<>();
        req.put("checkOut", today(14).toString());
        modify(token, bookingId, req, status().isUnprocessableEntity());

        // Booking unchanged — coupon still attached, dates intact.
        JsonNode after = getBooking(token, bookingId);
        assertEquals(code, after.get("couponCode").asText());
        assertEquals(today(13).toString(), after.get("checkOut").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 10. Unauthenticated → 401
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void modifyUnauthenticated_returns401() throws Exception {
        mvc.perform(patch("/api/bookings/1/modify")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"checkOut\":\"" + today(5) + "\"}"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 11. Invalid modification → 400 (validation reused from create)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void modifyInvalidParams_rejected() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Val", "VAL-1", 1_000_000, 20));
        String token = registerAndLogin("mod-val-" + uniq() + "@test.com");
        Long bookingId = book(token, roomId, today(3), today(5), 2, 0, planId, 0).get("id").asLong();

        // checkOut <= checkIn
        Map<String, Object> a = new LinkedHashMap<>();
        a.put("checkIn", today(5).toString());
        a.put("checkOut", today(5).toString());
        modify(token, bookingId, a, status().isBadRequest());

        // past checkIn
        Map<String, Object> b = new LinkedHashMap<>();
        b.put("checkIn", today(-1).toString());
        b.put("checkOut", today(2).toString());
        modify(token, bookingId, b, status().isBadRequest());

        // adults < 1 (bean validation @Min(1))
        Map<String, Object> c = new LinkedHashMap<>();
        c.put("adults", 0);
        modify(token, bookingId, c, status().isBadRequest());

        // guests exceed capacity (room maxGuests = 4)
        Map<String, Object> d = new LinkedHashMap<>();
        d.put("adults", 3);
        d.put("children", 2);
        modify(token, bookingId, d, status().isBadRequest());

        // Booking is unchanged after all the rejected attempts.
        JsonNode after = getBooking(token, bookingId);
        assertEquals(today(3).toString(), after.get("checkIn").asText());
        assertEquals(today(5).toString(), after.get("checkOut").asText());
        assertEquals(2, after.get("adults").asInt());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private LocalDate today(int plus) { return LocalDate.now().plusDays(plus); }

    /**
     * With no checkout benefit attached, finalPrice must equal the resolved rate-plan price minus
     * the promotion discount (a seeded target-ALL promotion applies to provisioned rooms, so this
     * is asserted relatively rather than against a hard-coded total).
     */
    private void assertFinalConsistent(JsonNode booking) {
        double rpp = booking.get("ratePlanPrice").asDouble();
        double disc = booking.get("discountAmount").asDouble();
        double finalPrice = booking.get("finalPrice").asDouble();
        assertEquals(rpp - disc, finalPrice, 0.01,
            "finalPrice must equal ratePlanPrice minus promotion discount");
        assertTrue(booking.get("couponCode").isNull(), "no coupon should be attached");
        assertTrue(booking.get("creditAmountUsed").isNull(), "no credit should be attached");
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

    private void addOccupancy(Long planId, int adults, int children, long price, Long childSupp, Long extraBedSupp) throws Exception {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("adults", adults);
        m.put("children", children);
        m.put("pricePerNight", price);
        if (childSupp != null) m.put("childSupplement", childSupp);
        if (extraBedSupp != null) m.put("extraBedSupplement", extraBedSupp);
        mvc.perform(post("/api/admin/rate-plans/" + planId + "/occupancy-prices")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(m)))
            .andExpect(status().isCreated());
    }

    private int avail(Long roomId, LocalDate date) {
        return inventoryRepo.findByHotelRoomIdAndInventoryDate(roomId, date).orElseThrow()
            .getAvailableInventory();
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

    private JsonNode bookWithCoupon(String token, Long roomId, LocalDate ci, LocalDate co,
                                    Long ratePlanId, String couponCode) throws Exception {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("roomId", roomId);
        m.put("checkIn", ci.toString());
        m.put("checkOut", co.toString());
        m.put("adults", 2);
        m.put("children", 0);
        m.put("numberOfRooms", 1);
        m.put("ratePlanId", ratePlanId);
        m.put("couponCode", couponCode);
        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(m)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode modify(String token, Long bookingId, Map<String, Object> req,
                            org.springframework.test.web.servlet.ResultMatcher expected) throws Exception {
        String body = mvc.perform(patch("/api/bookings/" + bookingId + "/modify")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(req)))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
    }

    private JsonNode getBooking(String token, Long bookingId) throws Exception {
        String body = mvc.perform(get("/api/bookings/" + bookingId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private void payAndSucceed(String token, Long bookingId) throws Exception {
        String body = mvc.perform(post("/api/payments")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"paymentMethod\":\"MOCK\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long paymentId = mapper.readTree(body).get("id").asLong();
        mvc.perform(post("/api/payments/" + paymentId + "/mock-success")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
    }

    private void createCouponDef(String code, String discountType, String discountValue) throws Exception {
        String payload = String.format("""
                {"code":"%s","name":"Modify %s","description":"Phase 7.34 test coupon",
                 "discountType":"%s","discountValue":%s,"maxDiscountAmount":null,"minimumSpend":null,
                 "validFrom":"%s","validUntil":"%s","active":true,"totalUsageLimit":null,"usageLimitPerUser":1}
                """,
            code, code, discountType, discountValue,
            LocalDate.now().minusDays(1), LocalDate.now().plusDays(60));
        mvc.perform(post("/api/admin/coupon-definitions")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isCreated());
    }

    private void claim(String token, String code) throws Exception {
        mvc.perform(post("/api/me/coupons/claim")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"" + code + "\"}"))
            .andExpect(status().isCreated());
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

    private void seedNight(Long roomId, LocalDate date, int total, int available) throws Exception {
        String item = String.format(
            "{\"inventoryDate\":\"%s\",\"totalInventory\":%d,\"availableInventory\":%d,"
            + "\"blockedInventory\":0,\"soldInventory\":0,\"maintenanceInventory\":0,"
            + "\"stopSell\":false,\"closedArrival\":false,\"closedDeparture\":false}",
            date, total, available);
        mvc.perform(post("/api/admin/rooms/" + roomId + "/inventory/bulk")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"items\":[" + item + "]}"))
            .andExpect(status().isOk());
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
                .content("{\"fullName\":\"Mod Tester\",\"email\":\"" + email + "\",\"password\":\"password123\"}"))
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
