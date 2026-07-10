package com.example.planyourtrip;

import com.example.planyourtrip.model.CustomerCouponStatus;
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

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * CheckoutCouponCreditTest — Phase 7.15 (Coupon &amp; Travel Credit Checkout
 * Integration). Covers applying a claimed coupon at booking creation (discount
 * computation, USED transition, eligibility rejections), redeeming promotional
 * travel credits against the booking total (REDEMPTION ledger row under the
 * account lock), coupon+credit stacking (promotion → coupon → credits),
 * atomicity (a failed booking never burns a coupon or credits), cancellation
 * reversal (idempotent REVERSAL, conditional coupon release) and the untouched
 * legacy flow. Prices are never hard-coded: each scenario first creates a
 * baseline booking on the same dates with a throwaway user and derives every
 * expected amount from that observed promotion-discounted total, so seeded
 * rate plans/promotions can change freely without breaking these tests.
 */
@SpringBootTest
@AutoConfigureMockMvc
class CheckoutCouponCreditTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;
    @Autowired CustomerCouponRepository customerCouponRepo;

    private static final AtomicInteger counter = new AtomicInteger(1);
    private static final LocalDate TODAY = LocalDate.now();

    private Long stdTwinRoomId;

    @BeforeEach
    void setup() throws Exception {
        Long placeId  = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        stdTwinRoomId = hotelRoomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "STD-TWIN".equals(r.getRoomCode()))
            .findFirst().orElseThrow().getId();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 1. APPLY COUPON AT CHECKOUT
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void bookingWithValidCouponAppliesDiscountAndMarksCouponUsed() throws Exception {
        LocalDate ci = TODAY.plusDays(46), co = ci.plusDays(2);
        BigDecimal base = baselinePrice(ci, co);

        String code = uniqueCode("apply");
        createCouponDef(code, "PERCENTAGE", "10", null, null);
        JsonNode user = registerUser("chk-apply");
        String token = user.get("token").asText();
        Long couponId = claim(token, code).get("id").asLong();

        // Apply with a differently-cased code — matching must stay case-insensitive.
        JsonNode res = book(token, bookingPayload(stdTwinRoomId, ci, co, code.toLowerCase(), null),
            status().isCreated());

        BigDecimal expectedDiscount = pct(base, "10");
        assertEquals(code, res.get("couponCode").asText(), "response carries the normalized code");
        assertDecimal(expectedDiscount, res.get("couponDiscountAmount"));
        assertDecimal(base.subtract(expectedDiscount), res.get("finalPrice"));
        assertTrue(res.get("creditAmountUsed").isNull());

        JsonNode coupon = getJson(token, "/api/me/coupons/" + couponId);
        assertEquals("USED", coupon.get("status").asText());
        assertEquals("USED", coupon.get("effectiveStatus").asText());
        assertFalse(coupon.get("usedAt").isNull());
        assertEquals(res.get("id").asLong(), coupon.get("bookingId").asLong());
    }

    @Test
    void couponBelowMinimumSpendRejected() throws Exception {
        LocalDate ci = TODAY.plusDays(48), co = ci.plusDays(1);
        BigDecimal base = baselinePrice(ci, co);

        String code = uniqueCode("minspend");
        createCouponDef(code, "PERCENTAGE", "10", null, base.add(new BigDecimal("1000000")).toPlainString());
        JsonNode user = registerUser("chk-minspend");
        String token = user.get("token").asText();
        Long couponId = claim(token, code).get("id").asLong();

        book(token, bookingPayload(stdTwinRoomId, ci, co, code, null), status().isBadRequest());

        // Rejection must not burn the coupon.
        assertEquals("AVAILABLE", getJson(token, "/api/me/coupons/" + couponId).get("status").asText());
    }

    @Test
    void expiredInactiveOrUsedCouponRejected() throws Exception {
        LocalDate ci = TODAY.plusDays(50), co = ci.plusDays(1);
        baselinePrice(ci, co); // warm the window; amounts not needed here

        // (a) expired claim (per-claim expiresAt in the past) → 409
        String expiredCode = uniqueCode("expired");
        createCouponDef(expiredCode, "PERCENTAGE", "10", null, null);
        JsonNode userA = registerUser("chk-expired");
        String tokenA = userA.get("token").asText();
        Long expiredId = claim(tokenA, expiredCode).get("id").asLong();
        var claimRow = customerCouponRepo.findById(expiredId).orElseThrow();
        claimRow.setExpiresAt(TODAY.minusDays(1));
        customerCouponRepo.save(claimRow);
        book(tokenA, bookingPayload(stdTwinRoomId, ci, co, expiredCode, null), status().isConflict());

        // (b) definition deactivated after claim → 400
        String inactiveCode = uniqueCode("inactive");
        Long defId = createCouponDef(inactiveCode, "PERCENTAGE", "10", null, null).get("id").asLong();
        JsonNode userB = registerUser("chk-inactive");
        String tokenB = userB.get("token").asText();
        claim(tokenB, inactiveCode);
        mvc.perform(patch("/api/admin/coupon-definitions/" + defId + "/deactivate")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk());
        book(tokenB, bookingPayload(stdTwinRoomId, ci, co, inactiveCode, null), status().isBadRequest());

        // (c) already USED on a previous booking → 409
        String usedCode = uniqueCode("used");
        createCouponDef(usedCode, "PERCENTAGE", "10", null, null);
        JsonNode userC = registerUser("chk-used");
        String tokenC = userC.get("token").asText();
        claim(tokenC, usedCode);
        book(tokenC, bookingPayload(stdTwinRoomId, ci, co, usedCode, null), status().isCreated());
        book(tokenC, bookingPayload(stdTwinRoomId, ci.plusDays(1), co.plusDays(1), usedCode, null),
            status().isConflict());
    }

    @Test
    void unclaimedOrAnotherUsersCouponCodeRejected404() throws Exception {
        LocalDate ci = TODAY.plusDays(53), co = ci.plusDays(1);

        String code = uniqueCode("foreign");
        createCouponDef(code, "PERCENTAGE", "10", null, null);
        String owner = registerUser("chk-owner").get("token").asText();
        String stranger = registerUser("chk-stranger").get("token").asText();
        claim(owner, code); // only the owner claimed it

        // Someone else's claimed code — 404, existence never leaks.
        book(stranger, bookingPayload(stdTwinRoomId, ci, co, code, null), status().isNotFound());
        // Entirely unknown code — also 404.
        book(stranger, bookingPayload(stdTwinRoomId, ci, co, "NO-SUCH-CODE-XYZ", null), status().isNotFound());
    }

    @Test
    void percentageAndFixedDiscountsComputeCorrectlyWithCap() throws Exception {
        LocalDate ci = TODAY.plusDays(55), co = ci.plusDays(2);
        BigDecimal base = baselinePrice(ci, co);

        // Percentage 50% capped at base/10 — the cap must win.
        BigDecimal cap = base.divide(BigDecimal.TEN, 2, RoundingMode.HALF_UP);
        String cappedCode = uniqueCode("cap");
        createCouponDef(cappedCode, "PERCENTAGE", "50", cap.toPlainString(), null);
        String tokenA = registerUser("chk-cap").get("token").asText();
        claim(tokenA, cappedCode);
        JsonNode capped = book(tokenA, bookingPayload(stdTwinRoomId, ci, co, cappedCode, null),
            status().isCreated());
        assertDecimal(cap, capped.get("couponDiscountAmount"));
        assertDecimal(base.subtract(cap), capped.get("finalPrice"));

        // Fixed amount base/4 — applied verbatim.
        BigDecimal fixed = base.divide(BigDecimal.valueOf(4), 2, RoundingMode.HALF_UP);
        String fixedCode = uniqueCode("fixed");
        createCouponDef(fixedCode, "FIXED_AMOUNT", fixed.toPlainString(), null, null);
        String tokenB = registerUser("chk-fixed").get("token").asText();
        claim(tokenB, fixedCode);
        JsonNode fixedRes = book(tokenB, bookingPayload(stdTwinRoomId, ci, co, fixedCode, null),
            status().isCreated());
        assertDecimal(fixed, fixedRes.get("couponDiscountAmount"));
        assertDecimal(base.subtract(fixed), fixedRes.get("finalPrice"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 2. REDEEM TRAVEL CREDITS AT CHECKOUT
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void creditsReduceFinalPriceAndCreateRedemptionLedgerRow() throws Exception {
        LocalDate ci = TODAY.plusDays(58), co = ci.plusDays(2);
        BigDecimal base = baselinePrice(ci, co);
        BigDecimal grantAmt = base;
        BigDecimal useAmt = base.divide(BigDecimal.valueOf(5), 2, RoundingMode.HALF_UP);

        JsonNode user = registerUser("chk-credit");
        String token = user.get("token").asText();
        grantCredits(user.get("user").get("id").asLong(), grantAmt.toPlainString());

        JsonNode res = book(token, bookingPayload(stdTwinRoomId, ci, co, null, useAmt.toPlainString()),
            status().isCreated());
        Long bookingId = res.get("id").asLong();

        assertDecimal(useAmt, res.get("creditAmountUsed"));
        assertDecimal(base.subtract(useAmt), res.get("finalPrice"));
        assertTrue(res.get("couponCode").isNull());

        // Balance reduced, exactly one REDEMPTION ledger row pointing at the booking.
        assertDecimal(grantAmt.subtract(useAmt), getJson(token, "/api/me/travel-credits").get("balance"));
        JsonNode redemptions = getJson(token, "/api/me/travel-credits/transactions?type=REDEMPTION")
            .get("content");
        assertEquals(1, redemptions.size());
        JsonNode tx = redemptions.get(0);
        assertEquals("REDEMPTION", tx.get("transactionType").asText());
        assertEquals("BOOKING", tx.get("referenceType").asText());
        assertEquals(bookingId, tx.get("referenceId").asLong());
        assertEquals("booking-" + bookingId + "-redemption", tx.get("idempotencyKey").asText());
        assertDecimal(grantAmt, tx.get("balanceBefore"));
        assertDecimal(grantAmt.subtract(useAmt), tx.get("balanceAfter"));
    }

    @Test
    void creditsExceedingBalanceRejectedAndBalanceNeverNegative() throws Exception {
        LocalDate ci = TODAY.plusDays(61), co = ci.plusDays(1);
        BigDecimal base = baselinePrice(ci, co);
        BigDecimal grantAmt = base.divide(BigDecimal.TEN, 2, RoundingMode.HALF_UP);
        BigDecimal askAmt = base.divide(BigDecimal.valueOf(5), 2, RoundingMode.HALF_UP); // > balance, < total

        JsonNode user = registerUser("chk-overdraw");
        String token = user.get("token").asText();
        grantCredits(user.get("user").get("id").asLong(), grantAmt.toPlainString());

        book(token, bookingPayload(stdTwinRoomId, ci, co, null, askAmt.toPlainString()),
            status().isConflict());

        // Balance untouched (and certainly not negative); no ledger row was left behind.
        assertDecimal(grantAmt, getJson(token, "/api/me/travel-credits").get("balance"));
        assertEquals(0, getJson(token, "/api/me/travel-credits/transactions?type=REDEMPTION")
            .get("content").size());
    }

    @Test
    void creditsExceedingRemainingTotalAfterDiscountsRejected() throws Exception {
        LocalDate ci = TODAY.plusDays(63), co = ci.plusDays(1);
        BigDecimal base = baselinePrice(ci, co);

        JsonNode user = registerUser("chk-overpay");
        String token = user.get("token").asText();
        // Balance is plentiful — the rejection must come from the payable cap, not the balance.
        grantCredits(user.get("user").get("id").asLong(),
            base.multiply(BigDecimal.valueOf(2)).setScale(2, RoundingMode.HALF_UP).toPlainString());

        book(token, bookingPayload(stdTwinRoomId, ci, co, null,
                base.add(BigDecimal.ONE).toPlainString()),
            status().isBadRequest());
    }

    @Test
    void couponAndCreditsCombineCouponFirstThenCredits() throws Exception {
        LocalDate ci = TODAY.plusDays(65), co = ci.plusDays(2);
        BigDecimal base = baselinePrice(ci, co);
        BigDecimal fixed = base.divide(BigDecimal.valueOf(4), 2, RoundingMode.HALF_UP);
        BigDecimal useAmt = base.divide(BigDecimal.valueOf(5), 2, RoundingMode.HALF_UP);

        String code = uniqueCode("combo");
        createCouponDef(code, "FIXED_AMOUNT", fixed.toPlainString(), null, null);
        JsonNode user = registerUser("chk-combo");
        String token = user.get("token").asText();
        claim(token, code);
        grantCredits(user.get("user").get("id").asLong(), base.toPlainString());

        JsonNode res = book(token, bookingPayload(stdTwinRoomId, ci, co, code, useAmt.toPlainString()),
            status().isCreated());

        assertEquals(code, res.get("couponCode").asText());
        assertDecimal(fixed, res.get("couponDiscountAmount"));
        assertDecimal(useAmt, res.get("creditAmountUsed"));
        // promotion-discounted total → minus coupon → minus credits
        assertDecimal(base.subtract(fixed).subtract(useAmt), res.get("finalPrice"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 3. ATOMICITY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void failedBookingBurnsNeitherCouponNorCredits() throws Exception {
        LocalDate ci = TODAY.plusDays(68), co = ci.plusDays(1);
        BigDecimal base = baselinePrice(ci, co);
        BigDecimal tinyGrant = base.divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
        BigDecimal askAmt = base.divide(BigDecimal.valueOf(50), 2, RoundingMode.HALF_UP); // > balance

        String code = uniqueCode("atomic");
        createCouponDef(code, "PERCENTAGE", "10", null, null);
        JsonNode user = registerUser("chk-atomic");
        String token = user.get("token").asText();
        Long couponId = claim(token, code).get("id").asLong();
        grantCredits(user.get("user").get("id").asLong(), tinyGrant.toPlainString());

        // (a) invalid room with a valid coupon → 404, coupon untouched
        book(token, bookingPayload(99999L, ci, co, code, null), status().isNotFound());
        assertEquals("AVAILABLE", getJson(token, "/api/me/coupons/" + couponId).get("status").asText());

        // (b) valid coupon + credits over balance → 409 rolls the WHOLE booking back:
        // coupon still AVAILABLE, no REDEMPTION ledger row, balance untouched.
        book(token, bookingPayload(stdTwinRoomId, ci, co, code, askAmt.toPlainString()),
            status().isConflict());
        JsonNode coupon = getJson(token, "/api/me/coupons/" + couponId);
        assertEquals("AVAILABLE", coupon.get("status").asText());
        assertTrue(coupon.get("usedAt").isNull());
        assertTrue(coupon.get("bookingId").isNull());
        assertDecimal(tinyGrant, getJson(token, "/api/me/travel-credits").get("balance"));
        assertEquals(0, getJson(token, "/api/me/travel-credits/transactions?type=REDEMPTION")
            .get("content").size());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 4. CANCELLATION / REVERSAL
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void cancellationRestoresCreditsViaIdempotentReversal() throws Exception {
        LocalDate ci = TODAY.plusDays(70), co = ci.plusDays(2);
        BigDecimal base = baselinePrice(ci, co);
        BigDecimal grantAmt = base.divide(BigDecimal.valueOf(2), 2, RoundingMode.HALF_UP);
        BigDecimal useAmt = base.divide(BigDecimal.valueOf(5), 2, RoundingMode.HALF_UP);

        JsonNode user = registerUser("chk-reversal");
        String token = user.get("token").asText();
        grantCredits(user.get("user").get("id").asLong(), grantAmt.toPlainString());

        Long bookingId = book(token,
            bookingPayload(stdTwinRoomId, ci, co, null, useAmt.toPlainString()),
            status().isCreated()).get("id").asLong();
        assertDecimal(grantAmt.subtract(useAmt), getJson(token, "/api/me/travel-credits").get("balance"));

        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        // Credits fully restored via a REVERSAL row referencing the booking.
        assertDecimal(grantAmt, getJson(token, "/api/me/travel-credits").get("balance"));
        JsonNode reversals = getJson(token, "/api/me/travel-credits/transactions?type=REVERSAL")
            .get("content");
        assertEquals(1, reversals.size());
        assertEquals("BOOKING", reversals.get(0).get("referenceType").asText());
        assertEquals(bookingId, reversals.get(0).get("referenceId").asLong());
        assertEquals("booking-" + bookingId + "-reversal", reversals.get(0).get("idempotencyKey").asText());

        // A user double-cancel is blocked outright.
        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isUnprocessableEntity());

        // Even forcing the status away and back to CANCELLED (admin force-set path,
        // which also runs the reversal hook) cannot double-restore — the
        // deterministic idempotencyKey returns the original ledger row.
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/status")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"PENDING\"}"))
            .andExpect(status().isOk());
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/status")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"CANCELLED\"}"))
            .andExpect(status().isOk());

        assertDecimal(grantAmt, getJson(token, "/api/me/travel-credits").get("balance"));
        assertEquals(1, getJson(token, "/api/me/travel-credits/transactions?type=REVERSAL")
            .get("content").size());
    }

    @Test
    void cancellationReleasesCouponWhileStillValidOtherwiseKeepsItUsed() throws Exception {
        LocalDate ci = TODAY.plusDays(73), co = ci.plusDays(1);
        baselinePrice(ci, co);

        // (a) coupon still within its validity window → released back to AVAILABLE
        String code = uniqueCode("release");
        createCouponDef(code, "PERCENTAGE", "10", null, null);
        String token = registerUser("chk-release").get("token").asText();
        Long couponId = claim(token, code).get("id").asLong();
        Long bookingId = book(token, bookingPayload(stdTwinRoomId, ci, co, code, null),
            status().isCreated()).get("id").asLong();
        assertEquals("USED", getJson(token, "/api/me/coupons/" + couponId).get("status").asText());

        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        JsonNode released = getJson(token, "/api/me/coupons/" + couponId);
        assertEquals("AVAILABLE", released.get("status").asText());
        assertTrue(released.get("usedAt").isNull());
        assertTrue(released.get("bookingId").isNull());

        // (b) coupon that expired between use and cancellation → stays USED
        String staleCode = uniqueCode("stale");
        createCouponDef(staleCode, "PERCENTAGE", "10", null, null);
        String token2 = registerUser("chk-stale").get("token").asText();
        Long staleCouponId = claim(token2, staleCode).get("id").asLong();
        Long staleBookingId = book(token2,
            bookingPayload(stdTwinRoomId, ci.plusDays(1), co.plusDays(1), staleCode, null),
            status().isCreated()).get("id").asLong();

        var staleRow = customerCouponRepo.findById(staleCouponId).orElseThrow();
        staleRow.setExpiresAt(TODAY.minusDays(1)); // expired after being used
        customerCouponRepo.save(staleRow);

        mvc.perform(patch("/api/bookings/" + staleBookingId + "/cancel")
                .header("Authorization", "Bearer " + token2))
            .andExpect(status().isOk());

        assertEquals(CustomerCouponStatus.USED,
            customerCouponRepo.findById(staleCouponId).orElseThrow().getStatus(),
            "a coupon that could no longer be redeemed anyway is not resurrected");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 5. SURFACING / REGRESSION / SECURITY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void bookingWithoutCouponOrCreditsBehavesExactlyAsBefore() throws Exception {
        LocalDate ci = TODAY.plusDays(76), co = ci.plusDays(2);
        BigDecimal base = baselinePrice(ci, co);

        String token = registerUser("chk-legacy").get("token").asText();
        // Pre-7.15 payload shape — no couponCode / creditAmount keys at all.
        String legacyPayload = String.format(
            "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\"," +
            "\"adults\":2,\"children\":0,\"numberOfRooms\":1,\"specialRequest\":null}",
            stdTwinRoomId, ci, co);
        JsonNode res = book(token, legacyPayload, status().isCreated());

        assertDecimal(base, res.get("finalPrice"));
        assertEquals("PENDING", res.get("status").asText());
        assertTrue(res.get("couponCode").isNull());
        assertTrue(res.get("couponDiscountAmount").isNull());
        assertTrue(res.get("creditAmountUsed").isNull());
    }

    @Test
    void bookingResponseSurfacesCouponAndCreditFields() throws Exception {
        LocalDate ci = TODAY.plusDays(79), co = ci.plusDays(1);
        BigDecimal base = baselinePrice(ci, co);
        BigDecimal fixed = base.divide(BigDecimal.valueOf(4), 2, RoundingMode.HALF_UP);
        BigDecimal useAmt = base.divide(BigDecimal.TEN, 2, RoundingMode.HALF_UP);

        String code = uniqueCode("surface");
        createCouponDef(code, "FIXED_AMOUNT", fixed.toPlainString(), null, null);
        JsonNode user = registerUser("chk-surface");
        String token = user.get("token").asText();
        claim(token, code);
        grantCredits(user.get("user").get("id").asLong(), base.toPlainString());

        JsonNode res = book(token, bookingPayload(stdTwinRoomId, ci, co, code, useAmt.toPlainString()),
            status().isCreated());
        Long bookingId = res.get("id").asLong();

        // Creation response and subsequent GET both surface the new fields.
        JsonNode fetched = getJson(token, "/api/bookings/" + bookingId);
        for (JsonNode node : new JsonNode[]{res, fetched}) {
            assertEquals(code, node.get("couponCode").asText());
            assertDecimal(fixed, node.get("couponDiscountAmount"));
            assertDecimal(useAmt, node.get("creditAmountUsed"));
            assertDecimal(base.subtract(fixed).subtract(useAmt), node.get("finalPrice"));
            // pre-existing fields still present and untouched
            assertNotNull(node.get("discountAmount"));
            assertNotNull(node.get("basePrice"));
        }
    }

    @Test
    void discountedTotalFlowsIntoPaymentAmount() throws Exception {
        LocalDate ci = TODAY.plusDays(81), co = ci.plusDays(1);
        BigDecimal base = baselinePrice(ci, co);
        BigDecimal fixed = base.divide(BigDecimal.valueOf(4), 2, RoundingMode.HALF_UP);
        BigDecimal useAmt = base.divide(BigDecimal.TEN, 2, RoundingMode.HALF_UP);

        String code = uniqueCode("payflow");
        createCouponDef(code, "FIXED_AMOUNT", fixed.toPlainString(), null, null);
        JsonNode user = registerUser("chk-payflow");
        String token = user.get("token").asText();
        claim(token, code);
        grantCredits(user.get("user").get("id").asLong(), base.toPlainString());

        Long bookingId = book(token, bookingPayload(stdTwinRoomId, ci, co, code, useAmt.toPlainString()),
            status().isCreated()).get("id").asLong();

        String payBody = mvc.perform(post("/api/payments")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"paymentMethod\":\"MOCK\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        assertDecimal(base.subtract(fixed).subtract(useAmt),
            mapper.readTree(payBody).get("amount"),
            "payment amount must be the coupon+credit discounted payable total");
    }

    @Test
    void unauthenticatedCheckoutWithCouponOrCreditsRejected() throws Exception {
        LocalDate ci = TODAY.plusDays(83), co = ci.plusDays(1);
        mvc.perform(post("/api/bookings")
                .contentType(MediaType.APPLICATION_JSON)
                .content(bookingPayload(stdTwinRoomId, ci, co, "WELCOME10", "100000")))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private String adminTokenCache;

    private String adminToken() throws Exception {
        if (adminTokenCache == null) {
            String body = mvc.perform(post("/api/auth/login")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("{\"email\":\"admin@planyourtrip.com\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
            adminTokenCache = mapper.readTree(body).get("token").asText();
        }
        return adminTokenCache;
    }

    /** Returns the full auth response — token at "token", user id at "user.id". */
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

    /**
     * The observed promotion-discounted total for these dates: a throwaway user
     * books the same room/date window and we take its finalPrice. Pricing depends
     * only on room + dates (never on the user or remaining inventory), so this is
     * exactly the pre-coupon "order amount" the checkout integration discounts.
     */
    private BigDecimal baselinePrice(LocalDate ci, LocalDate co) throws Exception {
        String token = registerUser("chk-baseline").get("token").asText();
        JsonNode res = book(token, bookingPayload(stdTwinRoomId, ci, co, null, null),
            status().isCreated());
        BigDecimal price = new BigDecimal(res.get("finalPrice").asText());
        assertTrue(price.signum() > 0, "baseline price must be positive");
        return price;
    }

    private String bookingPayload(Long roomId, LocalDate ci, LocalDate co,
                                   String couponCode, String creditAmount) {
        return String.format(
            "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\"," +
            "\"adults\":2,\"children\":0,\"numberOfRooms\":1,\"specialRequest\":null," +
            "\"couponCode\":%s,\"creditAmount\":%s}",
            roomId, ci, co,
            couponCode == null ? "null" : "\"" + couponCode + "\"",
            creditAmount == null ? "null" : creditAmount);
    }

    private JsonNode book(String token, String payload, ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
    }

    private JsonNode createCouponDef(String code, String discountType, String discountValue,
                                      String maxDiscountAmount, String minimumSpend) throws Exception {
        String payload = String.format("""
                {"code":"%s","name":"Checkout %s","description":"Phase 7.15 test coupon",
                 "discountType":"%s","discountValue":%s,"maxDiscountAmount":%s,"minimumSpend":%s,
                 "validFrom":"%s","validUntil":"%s","active":true,"totalUsageLimit":null,"usageLimitPerUser":1}
                """,
            code, code, discountType, discountValue,
            maxDiscountAmount == null ? "null" : maxDiscountAmount,
            minimumSpend == null ? "null" : minimumSpend,
            TODAY.minusDays(1), TODAY.plusDays(60));
        String body = mvc.perform(post("/api/admin/coupon-definitions")
                .header("Authorization", "Bearer " + adminToken())
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

    private void grantCredits(Long userId, String amount) throws Exception {
        mvc.perform(post("/api/admin/users/" + userId + "/travel-credits/grant")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"amount\":" + amount + ",\"currency\":\"VND\"," +
                         "\"description\":\"Phase 7.15 test grant\"}"))
            .andExpect(status().isCreated());
    }

    private JsonNode getJson(String token, String url) throws Exception {
        String body = mvc.perform(get(url)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private String uniqueCode(String prefix) {
        return ("CHK-" + prefix + "-" + counter.getAndIncrement()).toUpperCase();
    }

    /** Mirrors the service's percentage formula: amount × pct / 100 at scale 2 HALF_UP. */
    private BigDecimal pct(BigDecimal amount, String percentage) {
        return amount.multiply(new BigDecimal(percentage))
            .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
    }

    private void assertDecimal(BigDecimal expected, JsonNode actual) {
        assertDecimal(expected, actual, null);
    }

    private void assertDecimal(BigDecimal expected, JsonNode actual, String message) {
        assertNotNull(actual, message);
        assertFalse(actual.isNull(), (message != null ? message + " — " : "") + "expected a value but was null");
        assertEquals(0, expected.compareTo(new BigDecimal(actual.asText())),
            (message != null ? message + " — " : "")
                + "expected " + expected.toPlainString() + " but was " + actual.asText());
    }
}
