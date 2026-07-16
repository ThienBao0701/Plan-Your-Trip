package com.example.planyourtrip;

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

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Phase 7.35 — READ-ONLY preview of a PENDING booking modification
 * (POST /api/me/bookings/{bookingId}/modify/preview).
 *
 * <p>Proves the preview computes exactly what {@code PATCH /api/bookings/{id}/modify} (Phase 7.34)
 * WOULD do — new price, old→new totals + difference (additional payment / refundable amount),
 * overlap-adjusted inventory availability, layered coupon/loyalty/travel-credit/gift-card previews —
 * and, critically, that it mutates NOTHING (no booking / inventory / payment / reservation / ledger /
 * notification change; the booking's own fields are untouched). Also proves ownership (403),
 * non-PENDING rejection (422), the room-change-not-supported invariant, and the overlap-adjustment
 * that makes a one-night-shift overlapping stay show AVAILABLE.
 *
 * <p>Isolation: every scenario provisions its OWN published hotel/room + inventory (never mutating
 * the shared seeded hotel), so inventory and pricing are exact and deterministic.
 */
@SpringBootTest
@AutoConfigureMockMvc
class BookingModificationPreviewTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired RoomInventoryRepository inventoryRepo;
    @Autowired InventoryReservationRepository reservationRepo;
    @Autowired BookingRepository bookingRepo;
    @Autowired PaymentRepository paymentRepo;
    @Autowired NotificationRepository notificationRepo;
    @Autowired CustomerCouponRepository customerCouponRepo;
    @Autowired LoyaltyPointsTransactionRepository loyaltyTxnRepo;
    @Autowired LoyaltyPointsRedemptionRepository redemptionRepo;
    @Autowired TravelCreditTransactionRepository creditTxnRepo;
    @Autowired GiftCardTransactionRepository giftTxnRepo;

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
    // 1. Same dates → zero difference, both summaries agree, room unchanged
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void sameDates_zeroDifference_roomUnchanged() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Flat", "PV-FLAT-" + uniq(), 1_000_000, 20));
        String token = registerAndLogin("pv-same-" + uniq() + "@test.com");
        JsonNode booking = book(token, roomId, today(3), today(5), 2, 0, planId);
        Long bookingId = booking.get("id").asLong();

        // Preview with NO changes (empty request → keep current).
        JsonNode res = preview(token, bookingId, new LinkedHashMap<>(), status().isOk());

        assertEqDec(dec(booking.get("finalPrice")), dec(res.get("oldTotal")));
        assertEqDec(dec(booking.get("finalPrice")), dec(res.get("estimatedTotal")));
        assertEqDec(BigDecimal.ZERO, dec(res.get("priceDifference")));
        assertEqDec(BigDecimal.ZERO, dec(res.get("additionalPayment")));
        assertEqDec(BigDecimal.ZERO, dec(res.get("refundableAmount")));
        assertTrue(res.get("inventoryAvailable").asBoolean(), "same dates always available");

        // Room-change-not-supported: old room == new room, ALWAYS.
        assertEquals(res.get("oldRoomId").asLong(), res.get("newRoomId").asLong());
        assertEquals(roomId.longValue(), res.get("newRoomId").asLong());
        // Existing & proposed summaries match on the unchanged booking.
        assertEquals(today(3).toString(), res.get("newCheckIn").asText());
        assertEquals(today(5).toString(), res.get("newCheckOut").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 2. Different (longer) dates → additional payment
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void longerStay_reportsAdditionalPayment() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Flat", "PV-LONG-" + uniq(), 1_000_000, 20));
        String token = registerAndLogin("pv-long-" + uniq() + "@test.com");
        JsonNode booking = book(token, roomId, today(3), today(5), 2, 0, planId); // 2 nights
        Long bookingId = booking.get("id").asLong();
        BigDecimal oldTotal = dec(booking.get("finalPrice"));

        Map<String, Object> req = new LinkedHashMap<>();
        req.put("checkOut", today(8).toString()); // 5 nights
        JsonNode res = preview(token, bookingId, req, status().isOk());

        assertEquals(5, res.get("proposedBooking").get("nights").asInt());
        BigDecimal newTotal = dec(res.get("estimatedTotal"));
        assertTrue(newTotal.compareTo(oldTotal) > 0, "5 nights costs more than 2");
        assertEqDec(newTotal.subtract(oldTotal), dec(res.get("priceDifference")));
        assertEqDec(newTotal.subtract(oldTotal), dec(res.get("additionalPayment")));
        assertEqDec(BigDecimal.ZERO, dec(res.get("refundableAmount")));
        assertTrue(res.get("inventoryAvailable").asBoolean());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 3. Different (shorter) dates → refundable amount
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void shorterStay_reportsRefundableAmount() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Flat", "PV-SHORT-" + uniq(), 1_000_000, 20));
        String token = registerAndLogin("pv-short-" + uniq() + "@test.com");
        JsonNode booking = book(token, roomId, today(3), today(7), 2, 0, planId); // 4 nights
        Long bookingId = booking.get("id").asLong();
        BigDecimal oldTotal = dec(booking.get("finalPrice"));

        Map<String, Object> req = new LinkedHashMap<>();
        req.put("checkOut", today(5).toString()); // 2 nights
        JsonNode res = preview(token, bookingId, req, status().isOk());

        assertEquals(2, res.get("proposedBooking").get("nights").asInt());
        BigDecimal newTotal = dec(res.get("estimatedTotal"));
        assertTrue(newTotal.compareTo(oldTotal) < 0);
        assertEqDec(oldTotal.subtract(newTotal), dec(res.get("refundableAmount")));
        assertEqDec(BigDecimal.ZERO, dec(res.get("additionalPayment")));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 4. One-night shift OVERLAPPING the rest → AVAILABLE despite room's own hold
    //    (the core overlap-adjustment guarantee)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void oneNightShiftOverlapping_showsAvailableEvenWhenRoomFullOnlyBecauseOfOwnHold() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Flat", "PV-OV-" + uniq(), 1_000_000, 20));
        // Exactly ONE room on each night of the window, so this booking's own hold exhausts them.
        seedNight(roomId, today(3), 1, 1);
        seedNight(roomId, today(4), 1, 1);
        seedNight(roomId, today(5), 1, 1);

        String token = registerAndLogin("pv-ov-" + uniq() + "@test.com");
        JsonNode booking = book(token, roomId, today(3), today(5), 1, 0, planId); // holds nights 3,4
        Long bookingId = booking.get("id").asLong();
        // The room now looks FULL on the shared nights because of THIS booking's own hold.
        assertEquals(0, avail(roomId, today(3)));
        assertEquals(0, avail(roomId, today(4)));

        // Shift by one night: today+3..today+5  →  today+4..today+6 (night 4 shared, night 5 new).
        seedNight(roomId, today(6), 1, 1);
        Map<String, Object> req = new LinkedHashMap<>();
        req.put("checkIn", today(4).toString());
        req.put("checkOut", today(6).toString());
        JsonNode res = preview(token, bookingId, req, status().isOk());

        assertTrue(res.get("inventoryAvailable").asBoolean(),
            "one-night-shift overlapping stay must show AVAILABLE — this booking's own hold on the "
            + "shared night is treated as released");
        assertTrue(res.get("eligibilityFailures").isEmpty(), "no inventory failure surfaced");
        // Read-only: the room is STILL 0 on the shared nights afterwards (nothing restored).
        assertEquals(0, avail(roomId, today(3)));
        assertEquals(0, avail(roomId, today(4)));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 5. Truly unavailable NEW dates (disjoint, exhausted) → not available, failure
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void unavailableDisjointDates_reportsUnavailableNotThrown() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Flat", "PV-UN-" + uniq(), 1_000_000, 20));
        seedNight(roomId, today(30), 0, 0);
        seedNight(roomId, today(31), 0, 0);

        String token = registerAndLogin("pv-un-" + uniq() + "@test.com");
        Long bookingId = book(token, roomId, today(3), today(5), 2, 0, planId).get("id").asLong();

        Map<String, Object> req = new LinkedHashMap<>();
        req.put("checkIn", today(30).toString());
        req.put("checkOut", today(32).toString());
        JsonNode res = preview(token, bookingId, req, status().isOk()); // still 200 — informational

        assertFalse(res.get("inventoryAvailable").asBoolean());
        assertTrue(hasFailureContaining(res, "Insufficient inventory"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 6. Change to an explicit eligible rate plan → reflected in proposed pricing
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void changeRatePlan_reflectedInProposedPricing() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planA = createPlanReturnId(roomId, plan("Plan A", "PV-PA-" + uniq(), 1_000_000, 20));
        Long planB = createPlanReturnId(roomId, plan("Plan B", "PV-PB-" + uniq(), 1_500_000, 5));
        String token = registerAndLogin("pv-plan-" + uniq() + "@test.com");
        JsonNode booking = book(token, roomId, today(3), today(5), 2, 0, planA);
        Long bookingId = booking.get("id").asLong();

        Map<String, Object> req = new LinkedHashMap<>();
        req.put("ratePlanId", planB);
        JsonNode res = preview(token, bookingId, req, status().isOk());

        assertEquals(planA.longValue(), res.get("oldRatePlanId").asLong());
        assertEquals(planB.longValue(), res.get("newRatePlanId").asLong());
        assertEquals("Plan B", res.get("newRatePlanName").asText());
        // 2 nights × 1,500,000 subtotal.
        assertEqDec(new BigDecimal("3000000"), dec(res.get("subtotal")));
        // Booking itself unchanged (still Plan A) — read-only.
        assertEquals(planA.longValue(), getBooking(token, bookingId).get("selectedRatePlanId").asLong());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 7. Occupancy change → reflected in nightly breakdown
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void occupancyChange_reflectedInNightlyBreakdown() throws Exception {
        Long roomId = provisionBookableRoom();
        Map<String, Object> p = plan("Occ", "PV-OCC-" + uniq(), 1_000_000, 20);
        p.put("occupancyPricingEnabled", true);
        Long planId = createPlanReturnId(roomId, p);
        addOccupancy(planId, 2, 1, 1_200_000);

        String token = registerAndLogin("pv-occ-" + uniq() + "@test.com");
        JsonNode booking = book(token, roomId, today(3), today(4), 2, 0, planId); // 1 night, (2,0) base
        Long bookingId = booking.get("id").asLong();

        Map<String, Object> req = new LinkedHashMap<>();
        req.put("children", 1);
        JsonNode res = preview(token, bookingId, req, status().isOk());

        assertEquals(0, res.get("oldChildren").asInt());
        assertEquals(1, res.get("newChildren").asInt());
        assertEqDec(new BigDecimal("1200000"),
            dec(res.get("proposedPricing").get("baseQuote").get("finalNightlyRate")));
        // dates unchanged → available; inventory untouched.
        assertTrue(res.get("inventoryAvailable").asBoolean());
        assertEquals(9, avail(roomId, today(3)), "occupancy-only preview must not touch inventory");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 8. Benefit previews layered onto the proposed modification
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void couponPreview_layeredOntoProposedModification() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Cpn", "PV-CPN-" + uniq(), 1_000_000, 20));
        String token = registerAndLogin("pv-cpn-" + uniq() + "@test.com");
        JsonNode booking = book(token, roomId, today(3), today(5), 2, 0, planId);
        Long bookingId = booking.get("id").asLong();

        String code = uniqueCode("CPN");
        createFixedCouponDef(code, "100000");
        Long couponId = claim(token, code).get("id").asLong();

        Map<String, Object> req = new LinkedHashMap<>();
        req.put("checkOut", today(6).toString()); // 3 nights
        req.put("couponId", couponId);
        JsonNode res = preview(token, bookingId, req, status().isOk());

        JsonNode pricing = res.get("proposedPricing");
        assertFalse(pricing.get("couponPreview").isNull(), "coupon preview present");
        assertEqDec(new BigDecimal("100000"), dec(pricing.get("couponDiscount")));
        // Pre-benefit total (used for the modify price difference) excludes the coupon…
        BigDecimal preBenefit = dec(pricing.get("totalBeforeCustomerBenefits"));
        assertEqDec(preBenefit, dec(res.get("estimatedTotal")),
            "estimatedTotal (what modify sets) is the PRE-benefit total");
        // …while the benefit-inclusive estimate is lower by the coupon.
        assertEqDec(preBenefit.subtract(new BigDecimal("100000")), dec(pricing.get("estimatedPayable")));
    }

    @Test
    void loyaltyTravelCreditGiftCardPreviews_layered() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Ben", "PV-BEN-" + uniq(), 1_000_000, 20));
        JsonNode user = registerUser("pv-ben");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        JsonNode booking = book(token, roomId, today(3), today(5), 2, 0, planId);
        Long bookingId = booking.get("id").asLong();

        grantLoyaltyPoints(userId, 3000);
        grantCredits(userId, "500000");
        String giftCode = issueAndActivate(token, new BigDecimal("200000"));

        Map<String, Object> req = new LinkedHashMap<>();
        req.put("requestedPoints", 1000);
        req.put("travelCreditAmountRequested", 50000);
        req.put("giftCardCode", giftCode);
        JsonNode res = preview(token, bookingId, req, status().isOk());

        JsonNode pricing = res.get("proposedPricing");
        assertFalse(pricing.get("loyaltyPreview").isNull(), "loyalty preview present");
        assertFalse(pricing.get("travelCreditPreview").isNull(), "travel-credit preview present");
        assertFalse(pricing.get("giftCardPreview").isNull(), "gift-card preview present");
        assertTrue(dec(pricing.get("loyaltyDiscount")).signum() > 0);
        assertEqDec(new BigDecimal("50000"), dec(pricing.get("travelCreditApplied")));
        assertEqDec(new BigDecimal("200000"), dec(pricing.get("giftCardApplied")));

        // Nothing consumed by the benefit previews.
        assertEquals(3000L, getJson(token, "/api/me/loyalty").get("currentBalance").asLong());
        assertEqDec(new BigDecimal("500000"), dec(getJson(token, "/api/me/travel-credits").get("balance")));
        assertEqDec(new BigDecimal("200000"),
            dec(getJson(token, "/api/me/gift-cards/code/" + giftCode).get("currentBalance")));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 9. Ownership → 403 (matches modify())
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void anotherUsersBooking_returns403() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Own", "PV-OWN-" + uniq(), 1_000_000, 20));
        String owner = registerAndLogin("pv-owner-" + uniq() + "@test.com");
        Long bookingId = book(owner, roomId, today(3), today(5), 2, 0, planId).get("id").asLong();

        String other = registerAndLogin("pv-other-" + uniq() + "@test.com");
        Map<String, Object> req = new LinkedHashMap<>();
        req.put("checkOut", today(6).toString());
        preview(other, bookingId, req, status().isForbidden());
    }

    @Test
    void unauthenticated_returns401() throws Exception {
        mvc.perform(post("/api/me/bookings/1/modify/preview")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"checkOut\":\"" + today(6) + "\"}"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 10. Non-PENDING → 422 (cancelled / completed)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void cancelledBooking_returns422() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Canc", "PV-CN-" + uniq(), 1_000_000, 20));
        String token = registerAndLogin("pv-canc-" + uniq() + "@test.com");
        Long bookingId = book(token, roomId, today(3), today(5), 2, 0, planId).get("id").asLong();
        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        Map<String, Object> req = new LinkedHashMap<>();
        req.put("checkOut", today(6).toString());
        preview(token, bookingId, req, status().isUnprocessableEntity());
    }

    @Test
    void completedBooking_returns422() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Comp", "PV-CO-" + uniq(), 1_000_000, 20));
        String token = registerAndLogin("pv-comp-" + uniq() + "@test.com");
        Long bookingId = book(token, roomId, today(3), today(5), 2, 0, planId).get("id").asLong();
        // Pay → CONFIRMED, then admin force-set to COMPLETED (adminUpdateStatus, no engine gate).
        payAndSucceed(token, bookingId);
        adminSetStatus(bookingId, "COMPLETED");
        assertEquals("COMPLETED", getBooking(token, bookingId).get("status").asText());

        Map<String, Object> req = new LinkedHashMap<>();
        req.put("checkOut", today(6).toString());
        preview(token, bookingId, req, status().isUnprocessableEntity());
    }

    @Test
    void confirmedBooking_returns422() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Conf", "PV-CF-" + uniq(), 1_000_000, 20));
        String token = registerAndLogin("pv-conf-" + uniq() + "@test.com");
        Long bookingId = book(token, roomId, today(3), today(5), 2, 0, planId).get("id").asLong();
        payAndSucceed(token, bookingId); // → CONFIRMED
        assertEquals("CONFIRMED", getBooking(token, bookingId).get("status").asText());

        Map<String, Object> req = new LinkedHashMap<>();
        req.put("checkOut", today(6).toString());
        preview(token, bookingId, req, status().isUnprocessableEntity());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 11. Booking with an applied coupon → 422 (mirrors modify())
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void bookingWithAppliedCoupon_returns422() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("HasCpn", "PV-HC-" + uniq(), 1_000_000, 20));
        String code = uniqueCode("HAS");
        createFixedCouponDef(code, "50000");
        String token = registerAndLogin("pv-hascpn-" + uniq() + "@test.com");
        claim(token, code);
        JsonNode booking = bookWithCoupon(token, roomId, today(3), today(5), planId, code);
        Long bookingId = booking.get("id").asLong();
        assertFalse(booking.get("couponCode").isNull());

        Map<String, Object> req = new LinkedHashMap<>();
        req.put("checkOut", today(6).toString());
        preview(token, bookingId, req, status().isUnprocessableEntity());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 12. Invalid params → 400 (mirrors modify())
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void invalidParams_return400() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Val", "PV-VAL-" + uniq(), 1_000_000, 20));
        String token = registerAndLogin("pv-val-" + uniq() + "@test.com");
        Long bookingId = book(token, roomId, today(3), today(5), 2, 0, planId).get("id").asLong();

        Map<String, Object> a = new LinkedHashMap<>(); // checkOut <= checkIn
        a.put("checkIn", today(5).toString());
        a.put("checkOut", today(5).toString());
        preview(token, bookingId, a, status().isBadRequest());

        Map<String, Object> b = new LinkedHashMap<>(); // past checkIn
        b.put("checkIn", today(-1).toString());
        b.put("checkOut", today(2).toString());
        preview(token, bookingId, b, status().isBadRequest());

        Map<String, Object> c = new LinkedHashMap<>(); // adults < 1 (bean validation @Min(1))
        c.put("adults", 0);
        preview(token, bookingId, c, status().isBadRequest());

        Map<String, Object> d = new LinkedHashMap<>(); // guests exceed capacity (maxGuests = 4)
        d.put("adults", 3);
        d.put("children", 2);
        preview(token, bookingId, d, status().isBadRequest());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 13. READ-ONLY: preview mutates NOTHING across every table + booking fields
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void previewMutatesNothing_acrossBookingInventoryPaymentReservationLedgerNotification() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, plan("Imm", "PV-IMM-" + uniq(), 1_000_000, 20));
        JsonNode user = registerUser("pv-imm");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        JsonNode booking = book(token, roomId, today(3), today(5), 2, 0, planId);
        Long bookingId = booking.get("id").asLong();

        // Set up benefits so the preview exercises every benefit stage too.
        String code = uniqueCode("IMM");
        createFixedCouponDef(code, "100000");
        Long couponId = claim(token, code).get("id").asLong();
        grantLoyaltyPoints(userId, 2000);
        grantCredits(userId, "300000");
        String giftCode = issueAndActivate(token, new BigDecimal("150000"));

        // Snapshot EVERY table + the booking's own fields BEFORE the preview.
        long bookings = bookingRepo.count();
        long payments = paymentRepo.count();
        long reservations = reservationRepo.count();
        long notifications = notificationRepo.count();
        long coupons = customerCouponRepo.count();
        long loyaltyTxns = loyaltyTxnRepo.count();
        long redemptions = redemptionRepo.count();
        long creditTxns = creditTxnRepo.count();
        long giftTxns = giftTxnRepo.count();
        int inv3 = avail(roomId, today(3));
        int inv4 = avail(roomId, today(4));
        String bookingBefore = getBooking(token, bookingId).toString();
        String reservationStatusBefore = reservationRepo.findByBookingId(bookingId).orElseThrow().getStatus().name();

        // Preview a date change WITH all four benefits engaged.
        Map<String, Object> req = new LinkedHashMap<>();
        req.put("checkOut", today(8).toString());
        req.put("couponId", couponId);
        req.put("requestedPoints", 1000);
        req.put("travelCreditAmountRequested", 50000);
        req.put("giftCardCode", giftCode);
        JsonNode res = preview(token, bookingId, req, status().isOk());
        assertFalse(res.get("estimatedTotal").isNull());

        // Nothing changed anywhere.
        assertEquals(bookings, bookingRepo.count(), "no booking created/deleted");
        assertEquals(payments, paymentRepo.count(), "no payment created");
        assertEquals(reservations, reservationRepo.count(), "no reservation created");
        assertEquals(notifications, notificationRepo.count(), "no notification created");
        assertEquals(coupons, customerCouponRepo.count(), "no coupon row change");
        assertEquals(loyaltyTxns, loyaltyTxnRepo.count(), "no loyalty ledger row");
        assertEquals(redemptions, redemptionRepo.count(), "no loyalty redemption reserved");
        assertEquals(creditTxns, creditTxnRepo.count(), "no travel-credit ledger row");
        assertEquals(giftTxns, giftTxnRepo.count(), "no gift-card ledger row");
        assertEquals(inv3, avail(roomId, today(3)), "inventory untouched (old night 1)");
        assertEquals(inv4, avail(roomId, today(4)), "inventory untouched (old night 2)");
        assertEquals(10, avail(roomId, today(7)), "inventory untouched (previewed new night)");

        // The booking's OWN fields are byte-for-byte unchanged.
        assertEquals(bookingBefore, getBooking(token, bookingId).toString(), "booking fields unchanged");
        assertEquals(reservationStatusBefore,
            reservationRepo.findByBookingId(bookingId).orElseThrow().getStatus().name(),
            "reservation status unchanged (still HELD, dates unchanged)");
        assertEquals(today(3), reservationRepo.findByBookingId(bookingId).orElseThrow().getCheckInDate(),
            "reservation dates unchanged");
        // Coupon still spendable afterwards.
        assertEquals("AVAILABLE", getJson(token, "/api/me/coupons/" + couponId).get("status").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private LocalDate today(int plus) { return LocalDate.now().plusDays(plus); }

    private boolean hasFailureContaining(JsonNode res, String fragment) {
        for (JsonNode f : res.get("eligibilityFailures"))
            if (f.asText().contains(fragment)) return true;
        return false;
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

    private void addOccupancy(Long planId, int adults, int children, long price) throws Exception {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("adults", adults);
        m.put("children", children);
        m.put("pricePerNight", price);
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
                          int adults, int children, Long ratePlanId) throws Exception {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("roomId", roomId);
        m.put("checkIn", ci.toString());
        m.put("checkOut", co.toString());
        m.put("adults", adults);
        m.put("children", children);
        m.put("numberOfRooms", 1);
        if (ratePlanId != null) m.put("ratePlanId", ratePlanId);
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

    private JsonNode preview(String token, Long bookingId, Map<String, Object> req,
                             org.springframework.test.web.servlet.ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/me/bookings/" + bookingId + "/modify/preview")
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

    private void adminSetStatus(Long bookingId, String status) throws Exception {
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/status")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"" + status + "\"}"))
            .andExpect(status().isOk());
    }

    // ── Benefit setup ────────────────────────────────────────────────────────

    private JsonNode createFixedCouponDef(String code, String amount) throws Exception {
        String payload = String.format("""
                {"code":"%s","name":"Preview %s","description":"Phase 7.35 test coupon",
                 "discountType":"FIXED_AMOUNT","discountValue":%s,"maxDiscountAmount":null,"minimumSpend":null,
                 "validFrom":"%s","validUntil":"%s","active":true,"totalUsageLimit":null,"usageLimitPerUser":1}
                """,
            code, code, amount, LocalDate.now().minusDays(1), LocalDate.now().plusDays(60));
        String body = mvc.perform(post("/api/admin/coupon-definitions")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode claim(String token, String code) throws Exception {
        String body = mvc.perform(post("/api/me/coupons/claim")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"" + code + "\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private void grantLoyaltyPoints(Long userId, long points) throws Exception {
        mvc.perform(post("/api/admin/users/" + userId + "/loyalty/grant")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format(
                    "{\"points\":%d,\"description\":\"Phase 7.35 test grant\"," +
                    "\"referenceType\":\"ADMIN\",\"referenceId\":null,\"idempotencyKey\":null}", points)))
            .andExpect(status().isCreated());
    }

    private void grantCredits(Long userId, String amount) throws Exception {
        mvc.perform(post("/api/admin/users/" + userId + "/travel-credits/grant")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"amount\":" + amount + ",\"currency\":\"VND\",\"description\":\"Phase 7.35 test grant\"}"))
            .andExpect(status().isCreated());
    }

    private String issueAndActivate(String token, BigDecimal amount) throws Exception {
        String productCode = ("PV-GC-" + counter.getAndIncrement()).toUpperCase();
        String product = String.format("""
            {"productCode":"%s","name":"Preview gift %s","description":"Phase 7.35 test product",
             "currency":"VND","fixedAmount":null,"minimumAmount":1000,"maximumAmount":500000000,
             "customAmountAllowed":true,"validDaysAfterActivation":365,"active":true,
             "validFrom":null,"validUntil":null}
            """, productCode, productCode);
        mvc.perform(post("/api/admin/gift-card-products")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(product))
            .andExpect(status().isCreated());

        String issueBody = String.format("""
            {"productCode":"%s","amount":%s,"recipientUserId":null,"recipientEmail":null,
             "personalMessage":null,"idempotencyKey":null}
            """, productCode, amount.toPlainString());
        String cardResp = mvc.perform(post("/api/me/gift-cards/issue")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(issueBody))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        JsonNode card = mapper.readTree(cardResp);
        mvc.perform(post("/api/me/gift-cards/" + card.get("id").asLong() + "/activate")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
        return card.get("fullCode").asText();
    }

    // ── Provisioning ──────────────────────────────────────────────────────────

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

    private String uniqueCode(String prefix) {
        return ("PV-" + prefix + "-" + counter.getAndIncrement()).toUpperCase();
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
                .content("{\"fullName\":\"Preview Tester\",\"email\":\"" + email + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private JsonNode registerUser(String namePrefix) throws Exception {
        String email = namePrefix + "-" + counter.getAndIncrement() + "@test.com";
        String body = mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"" + namePrefix + " Tester\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
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

    // ── Decimal helpers ───────────────────────────────────────────────────────

    private BigDecimal dec(JsonNode n) { return new BigDecimal(n.asText()); }

    private void assertEqDec(BigDecimal expected, BigDecimal actual) {
        assertEquals(0, expected.compareTo(actual),
            "expected " + expected.toPlainString() + " but was " + actual.toPlainString());
    }

    private void assertEqDec(BigDecimal expected, BigDecimal actual, String msg) {
        assertEquals(0, expected.compareTo(actual),
            msg + " — expected " + expected.toPlainString() + " but was " + actual.toPlainString());
    }

    private JsonNode getJson(String token, String url) throws Exception {
        String body = mvc.perform(get(url).header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }
}
