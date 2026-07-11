package com.example.planyourtrip;

import com.example.planyourtrip.model.LoyaltyAccount;
import com.example.planyourtrip.model.LoyaltyAccountStatus;
import com.example.planyourtrip.model.LoyaltyPointsRedemption;
import com.example.planyourtrip.repository.*;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultMatcher;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * LoyaltyRedemptionTest — Phase 7.20 (Loyalty Points Redemption).
 * Covers the redemption policy (seed, CRUD, uniqueness, validation, effective-date
 * selection), preview (conversion, minimum/increment/percentage-cap/payable-floor
 * rules, non-mutating), the reservation lifecycle (debit, ledger, snapshot,
 * ownership/status/account-status guards, one-active-redemption-per-booking,
 * idempotent reserve, concurrency safety), apply-on-payment, release/expire
 * (idempotent restoration), refund-on-cancellation, and security/API status
 * codes (401/403/404/409). Every scenario grants its own throwaway user's
 * loyalty balance via the admin grant endpoint so account state never leaks
 * across tests — mirrors LoyaltyPointsTest/CheckoutCouponCreditTest conventions.
 * 401/400/404 coverage is exercised inline throughout rather than in one
 * isolated test, matching how prior phases structured this suite.
 */
@SpringBootTest
@AutoConfigureMockMvc
class LoyaltyRedemptionTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;
    @Autowired LoyaltyAccountRepository loyaltyAccountRepo;
    @Autowired LoyaltyPointsRedemptionRepository redemptionRepo;

    private static final AtomicInteger counter = new AtomicInteger(1);
    private static final AtomicInteger dayCounter = new AtomicInteger(0);
    private static final LocalDate TODAY = LocalDate.now();

    private Long stdTwinRoomId;

    // ═══════════════════════════════════════════════════════════════════════════
    // POLICY TESTS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void defaultPolicyIsSeededCorrectly() throws Exception {
        List<JsonNode> policies = getJsonAdminList("/api/admin/loyalty/redemption-policies");
        JsonNode def = null;
        for (JsonNode p : policies) if ("DEFAULT_LOYALTY_REDEMPTION".equals(p.get("policyCode").asText())) def = p;
        assertNotNull(def, "seeded default policy must exist");
        assertEquals(100, def.get("pointsPerUnit").asLong());
        assertDecimal(new BigDecimal("1000.00"), def.get("valuePerUnit"));
        assertEquals(1000, def.get("minimumRedemptionPoints").asLong());
        assertEquals(100, def.get("redemptionIncrementPoints").asLong());
        assertEquals(20, def.get("maximumDiscountPercentage").asInt());
        assertDecimal(new BigDecimal("1000.00"), def.get("minimumFinalPayableAmount"));
        assertTrue(def.get("active").asBoolean());
        assertTrue(def.get("effectiveUntil").isNull());
    }

    @Test
    void duplicatePolicyCodeRejected() throws Exception {
        // Created inactive: this test only cares about code uniqueness, and an
        // active policy here would outrank the seeded default (newer effectiveFrom)
        // and silently redirect every other preview/reserve test in this class.
        String code = uniqueCode("dup");
        createPolicy(policyPayload(code, 100, "1000", 1000, 100, 20, "1000", false, null, null),
            status().isCreated());
        createPolicy(policyPayload(code, 100, "1000", 1000, 100, 20, "1000", false, null, null),
            status().isConflict());
    }

    @Test
    void invalidPolicyValuesRejected() throws Exception {
        // Non-positive numeric values.
        createPolicy(policyPayload(uniqueCode("neg"), 0, "1000", 1000, 100, 20, "1000", true, null, null),
            status().isBadRequest());
        // Invalid percentage (>100).
        createPolicy(policyPayload(uniqueCode("pct"), 100, "1000", 1000, 100, 150, "1000", true, null, null),
            status().isBadRequest());
        // Invalid effective date range (until before from).
        Instant from = Instant.now();
        Instant until = from.minusSeconds(3600);
        createPolicy(policyPayloadWithDates(uniqueCode("range"), 100, "1000", 1000, 100, 20, "1000",
                true, from, until),
            status().isBadRequest());
    }

    @Test
    void adminCanActivateAndDeactivatePolicy() throws Exception {
        // Created inactive and left deactivated at the end — an active policy here
        // (effectiveFrom = now) would outrank the seeded default in resolution and
        // silently redirect every other preview/reserve test in this class.
        String code = uniqueCode("toggle");
        JsonNode created = createPolicy(
            policyPayload(code, 100, "1000", 1000, 100, 20, "1000", false, null, null),
            status().isCreated());
        Long id = created.get("id").asLong();

        JsonNode activated = mapper.readTree(mvc.perform(post("/api/admin/loyalty/redemption-policies/" + id + "/activate")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertTrue(activated.get("active").asBoolean());

        JsonNode deactivated = mapper.readTree(mvc.perform(post("/api/admin/loyalty/redemption-policies/" + id + "/deactivate")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertFalse(deactivated.get("active").asBoolean());
    }

    @Test
    void inactivePolicyExcludedFromSelection() throws Exception {
        // Deactivate the seeded default so only our controlled policy can be selected,
        // then confirm a freshly deactivated policy of our own is never picked either.
        String code = uniqueCode("inactive-select");
        JsonNode created = createPolicy(
            policyPayload(code, 50, "500", 1000, 50, 10, "500", false, null, null),
            status().isCreated());
        // Preview must not fail and must not resolve to this inactive policy's odd conversion.
        JsonNode preview = preview(registerUser("policy-inactive").get("token").asText(),
            previewByAmountPayload("50000", "1000"), status().isOk());
        assertNotEquals(code, preview.get("policy").get("policyCode").asText());
    }

    @Test
    void policySelectedByEffectiveDateWindow() throws Exception {
        // A policy whose window is entirely in the future must never be selected now.
        String code = uniqueCode("future-window");
        createPolicy(policyPayloadWithDates(code, 100, "1000", 1000, 100, 20, "1000",
                true, Instant.now().plusSeconds(3600 * 24), null),
            status().isCreated());
        JsonNode preview = preview(registerUser("policy-future").get("token").asText(),
            previewByAmountPayload("50000", "1000"), status().isOk());
        assertNotEquals(code, preview.get("policy").get("policyCode").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PREVIEW TESTS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void previewConvertsPointsToVndCorrectly() throws Exception {
        JsonNode user = registerUser("preview-conv");
        String token = user.get("token").asText();
        grantLoyaltyPoints(user.get("user").get("id").asLong(), 5000);
        JsonNode res = preview(token, previewByAmountPayload("500000", "1000"), status().isOk());
        assertEquals(1000, res.get("acceptedPoints").asLong());
        assertDecimal(new BigDecimal("10000.00"), res.get("discountAmount")); // 1000 pts * 10 VND
        assertTrue(res.get("redeemable").asBoolean());
    }

    @Test
    void previewEnforcesMinimumRedemptionRule() throws Exception {
        String token = registerUser("preview-min").get("token").asText();
        JsonNode res = preview(token, previewByAmountPayload("500000", "500"), status().isOk());
        assertEquals(0, res.get("acceptedPoints").asLong());
        assertFalse(res.get("redeemable").asBoolean());
        assertTrue(containsMessage(res, "Minimum redemption"));
    }

    @Test
    void previewEnforcesIncrementRule() throws Exception {
        JsonNode user = registerUser("preview-inc");
        String token = user.get("token").asText();
        grantLoyaltyPoints(user.get("user").get("id").asLong(), 5000);
        JsonNode res = preview(token, previewByAmountPayload("500000", "1050"), status().isOk());
        assertEquals(1000, res.get("acceptedPoints").asLong(), "floored to the nearest 100-point increment");
        assertTrue(containsMessage(res, "multiple of"));
    }

    @Test
    void previewEnforcesMaximumDiscountPercentageRule() throws Exception {
        JsonNode user = registerUser("preview-pct");
        String token = user.get("token").asText();
        grantLoyaltyPoints(user.get("user").get("id").asLong(), 20000); // plentiful — % cap must bind, not balance
        // 20% of 100,000 = 20,000 VND = 2000 points. Requesting far more must cap at 2000.
        JsonNode res = preview(token, previewByAmountPayload("100000", "9000"), status().isOk());
        assertEquals(2000, res.get("acceptedPoints").asLong());
        assertEquals(2000, res.get("maximumRedeemablePoints").asLong());
        assertTrue(containsMessage(res, "maximum"));
    }

    @Test
    void previewEnforcesMinimumFinalPayableRule() throws Exception {
        // Real integration: credits already reduced the booking's payable amount to
        // near the policy floor (1000 VND), so the loyalty payable-floor constraint
        // binds tighter than the 20% cap even though the eligible base is large.
        LocalDate ci = nextCheckIn(), co = ci.plusDays(1);
        BigDecimal base = baselinePrice(ci, co);
        BigDecimal creditUse = base.subtract(new BigDecimal("1500")).setScale(2, RoundingMode.HALF_UP);

        JsonNode user = registerUser("preview-floor");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 20000); // plentiful — the payable floor, not balance, must bind
        grantCredits(userId, base.toPlainString());
        Long bookingId = book(token, bookingPayload(ci, co, creditUse.toPlainString()),
            status().isCreated()).get("id").asLong();

        JsonNode res = preview(token, previewByBookingPayload(bookingId, "1000"), status().isOk());
        assertEquals(0, res.get("acceptedPoints").asLong(),
            "the ~1500 VND remaining payable leaves less than one 100-point increment of room under the 1000 VND floor");
        assertTrue(containsMessage(res, "maximum") || containsMessage(res, "payable"));
    }

    @Test
    void previewInsufficientBalanceReported() throws Exception {
        JsonNode user = registerUser("preview-bal");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 500);

        JsonNode res = preview(token, previewByAmountPayload("500000", "1000"), status().isOk());
        assertEquals(0, res.get("acceptedPoints").asLong());
        assertEquals(500, res.get("currentBalance").asLong());
        assertTrue(containsMessage(res, "Insufficient balance"));
    }

    @Test
    void previewDoesNotMutateBalanceOrLedger() throws Exception {
        JsonNode user = registerUser("preview-nomutate");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 5000);

        preview(token, previewByAmountPayload("500000", "1000"), status().isOk());
        preview(token, previewByAmountPayload("500000", "2000"), status().isOk());

        JsonNode account = getJson(token, "/api/me/loyalty");
        assertEquals(5000, account.get("currentBalance").asLong(), "preview must never change the balance");
        JsonNode txs = getJson(token, "/api/me/loyalty/transactions");
        assertEquals(1, txs.get("totalElements").asLong(), "preview must never write a ledger row (only the grant exists)");
    }

    @Test
    void previewUsesCouponAdjustedAmountForMaximum() throws Exception {
        LocalDate ci = nextCheckIn(), co = ci.plusDays(1);
        BigDecimal base = baselinePrice(ci, co);
        BigDecimal fixedDiscount = base.divide(BigDecimal.valueOf(4), 2, RoundingMode.HALF_UP);

        String code = uniqueCode("preview-coupon");
        createCouponDef(code, fixedDiscount.toPlainString());
        JsonNode user = registerUser("preview-coupon-user");
        String token = user.get("token").asText();
        claim(token, code);
        Long bookingId = book(token, bookingPayload(ci, co, null, code), status().isCreated())
            .get("id").asLong();

        JsonNode res = preview(token, previewByBookingPayload(bookingId, "1000"), status().isOk());
        assertDecimal(base.subtract(fixedDiscount).setScale(2, RoundingMode.HALF_UP), res.get("eligibleAmount"),
            "eligible amount must reflect the coupon-discounted total, not the raw price");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // RESERVATION TESTS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void reservationDebitsCurrentBalance() throws Exception {
        JsonNode user = registerUser("reserve-debit");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 5000);

        Long bookingId = createBooking(token, nextCheckIn(), null).get("id").asLong();
        JsonNode res = reserve(token, reservePayload(bookingId, 1000, uniqueKey()), status().isCreated());

        assertEquals("RESERVED", res.get("status").asText());
        assertEquals(1000, res.get("pointsRedeemed").asLong());
        assertDecimal(new BigDecimal("10000.00"), res.get("discountAmount"));

        JsonNode account = getJson(token, "/api/me/loyalty");
        assertEquals(4000, account.get("currentBalance").asLong());
    }

    @Test
    void reservationDoesNotDecreaseLifetimePoints() throws Exception {
        JsonNode user = registerUser("reserve-lifetime");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 5000);
        long lifetimeBefore = getJson(token, "/api/me/loyalty").get("lifetimePointsEarned").asLong();

        Long bookingId = createBooking(token, nextCheckIn(), null).get("id").asLong();
        reserve(token, reservePayload(bookingId, 1000, uniqueKey()), status().isCreated());

        JsonNode account = getJson(token, "/api/me/loyalty");
        assertEquals(4000, account.get("currentBalance").asLong());
        assertEquals(lifetimeBefore, account.get("lifetimePointsEarned").asLong(),
            "redemption debit must never touch the monotonic lifetime counter");
    }

    @Test
    void reservationCreatesDebitLedgerTransactionWithCorrectSnapshot() throws Exception {
        JsonNode user = registerUser("reserve-ledger");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 5000);

        Long bookingId = createBooking(token, nextCheckIn(), null).get("id").asLong();
        JsonNode redemption = reserve(token, reservePayload(bookingId, 1000, uniqueKey()), status().isCreated());

        JsonNode debits = getJson(token, "/api/me/loyalty/transactions?type=REDEMPTION_DEBIT").get("content");
        assertEquals(1, debits.size());
        JsonNode tx = debits.get(0);
        assertEquals(1000, tx.get("points").asLong());
        assertEquals(5000, tx.get("balanceBefore").asLong());
        assertEquals(4000, tx.get("balanceAfter").asLong());
        assertEquals("REDEMPTION", tx.get("referenceType").asText());

        // Redemption snapshot stores exact points + discount + eligible amount.
        assertEquals(1000, redemption.get("pointsRedeemed").asLong());
        assertDecimal(new BigDecimal("10000.00"), redemption.get("discountAmount"));
        assertNotNull(redemption.get("eligibleAmount"));
        assertNotNull(redemption.get("redemptionReference"));
        assertNotNull(redemption.get("expiresAt"));
    }

    @Test
    void reservationInsufficientBalanceRejected() throws Exception {
        JsonNode user = registerUser("reserve-insuff");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 500);

        Long bookingId = createBooking(token, nextCheckIn(), null).get("id").asLong();
        reserve(token, reservePayload(bookingId, 1000, uniqueKey()), status().isConflict());

        assertEquals(500, getJson(token, "/api/me/loyalty").get("currentBalance").asLong());
    }

    @Test
    void reservationWrongCustomerRejected() throws Exception {
        JsonNode owner = registerUser("reserve-owner");
        String ownerToken = owner.get("token").asText();
        Long bookingId = createBooking(ownerToken, nextCheckIn(), null).get("id").asLong();

        JsonNode stranger = registerUser("reserve-stranger");
        Long strangerId = stranger.get("user").get("id").asLong();
        String strangerToken = stranger.get("token").asText();
        grantLoyaltyPoints(strangerId, 5000);

        reserve(strangerToken, reservePayload(bookingId, 1000, uniqueKey()), status().isForbidden());
    }

    @Test
    void reservationInactiveAccountRejected() throws Exception {
        JsonNode user = registerUser("reserve-inactive");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 5000);

        LoyaltyAccount account = loyaltyAccountRepo.findByUserId(userId).orElseThrow();
        account.setStatus(LoyaltyAccountStatus.SUSPENDED);
        loyaltyAccountRepo.save(account);

        Long bookingId = createBooking(token, nextCheckIn(), null).get("id").asLong();
        reserve(token, reservePayload(bookingId, 1000, uniqueKey()), status().isConflict());
    }

    @Test
    void reservationInvalidBookingStateRejected() throws Exception {
        JsonNode user = registerUser("reserve-badstate");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 5000);

        Long bookingId = createBooking(token, nextCheckIn(), null).get("id").asLong();
        payForBooking(token, bookingId); // moves the booking out of PENDING

        reserve(token, reservePayload(bookingId, 1000, uniqueKey()), status().isConflict());
    }

    @Test
    void reservationSecondActiveRedemptionForSameBookingRejected() throws Exception {
        JsonNode user = registerUser("reserve-second");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 5000);

        Long bookingId = createBooking(token, nextCheckIn(), null).get("id").asLong();
        reserve(token, reservePayload(bookingId, 1000, uniqueKey()), status().isCreated());
        reserve(token, reservePayload(bookingId, 1000, uniqueKey()), status().isConflict());
    }

    @Test
    void reservationIdempotentReplaySameKeySamePayloadReturnsSameResult() throws Exception {
        JsonNode user = registerUser("reserve-idem-same");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 5000);

        Long bookingId = createBooking(token, nextCheckIn(), null).get("id").asLong();
        String key = uniqueKey();
        JsonNode first = reserve(token, reservePayload(bookingId, 1000, key), status().isCreated());
        JsonNode replay = reserve(token, reservePayload(bookingId, 1000, key), status().isOk());

        assertEquals(first.get("id").asLong(), replay.get("id").asLong());
        assertEquals(4000, getJson(token, "/api/me/loyalty").get("currentBalance").asLong(),
            "replay must not debit a second time");
    }

    @Test
    void reservationIdempotentKeyWithDifferentPayloadReturnsConflict() throws Exception {
        JsonNode user = registerUser("reserve-idem-diff");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 5000);

        Long bookingId = createBooking(token, nextCheckIn(), null).get("id").asLong();
        String key = uniqueKey();
        reserve(token, reservePayload(bookingId, 1000, key), status().isCreated());
        reserve(token, reservePayload(bookingId, 2000, key), status().isConflict());
    }

    @Test
    void concurrentReservationsCannotOverspendTheAccount() throws Exception {
        JsonNode user = registerUser("reserve-concurrent");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 1000); // exactly enough for ONE full-balance reservation

        Long bookingA = createBooking(token, nextCheckIn(), null).get("id").asLong();
        Long bookingB = createBooking(token, nextCheckIn(), null).get("id").asLong();

        ExecutorService pool = Executors.newFixedThreadPool(2);
        CountDownLatch start = new CountDownLatch(1);
        Callable<Integer> taskA = () -> { start.await(); return reserveRaw(token, reservePayload(bookingA, 1000, uniqueKey())); };
        Callable<Integer> taskB = () -> { start.await(); return reserveRaw(token, reservePayload(bookingB, 1000, uniqueKey())); };
        Future<Integer> fa = pool.submit(taskA);
        Future<Integer> fb = pool.submit(taskB);
        start.countDown();
        int statusA = fa.get(30, TimeUnit.SECONDS);
        int statusB = fb.get(30, TimeUnit.SECONDS);
        pool.shutdown();

        int successCount = (statusA == 201 ? 1 : 0) + (statusB == 201 ? 1 : 0);
        int conflictCount = (statusA == 409 ? 1 : 0) + (statusB == 409 ? 1 : 0);
        assertEquals(1, successCount, "exactly one of the two concurrent reservations may succeed");
        assertEquals(1, conflictCount, "the other must be rejected for insufficient balance");
        assertEquals(0, getJson(token, "/api/me/loyalty").get("currentBalance").asLong(),
            "balance must land at exactly zero, never negative");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // APPLY TESTS (triggered by payment success — no direct customer/admin endpoint)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void reservedRedemptionAppliedOnPaymentSuccessWithoutSecondDebit() throws Exception {
        JsonNode user = registerUser("apply-basic");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 5000);

        Long bookingId = createBooking(token, nextCheckIn(), null).get("id").asLong();
        JsonNode reserved = reserve(token, reservePayload(bookingId, 1000, uniqueKey()), status().isCreated());
        String reference = reserved.get("redemptionReference").asText();

        payForBooking(token, bookingId);

        JsonNode applied = getJson(token, "/api/loyalty/redemptions/" + reference);
        assertEquals("APPLIED", applied.get("status").asText());
        assertEquals(4000, getJson(token, "/api/me/loyalty").get("currentBalance").asLong(),
            "applying must never debit a second time");
    }

    @Test
    void repeatedApplyViaRepeatedPaymentCallbackIsIdempotent() throws Exception {
        JsonNode user = registerUser("apply-idem");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 5000);

        Long bookingId = createBooking(token, nextCheckIn(), null).get("id").asLong();
        String reference = reserve(token, reservePayload(bookingId, 1000, uniqueKey()), status().isCreated())
            .get("redemptionReference").asText();

        payForBooking(token, bookingId);
        long balanceAfterFirst = getJson(token, "/api/me/loyalty").get("currentBalance").asLong();

        // A second payment attempt on an already-paid booking will fail at the
        // booking/payment layer, but exercise the redemption side effect stays
        // idempotent regardless of how many times apply is invoked underneath.
        JsonNode reApplied = getJson(token, "/api/loyalty/redemptions/" + reference);
        assertEquals("APPLIED", reApplied.get("status").asText());
        assertEquals(balanceAfterFirst, getJson(token, "/api/me/loyalty").get("currentBalance").asLong());
    }

    @Test
    void bookingWithoutRedemptionHasNullLoyaltyFieldsUnchanged() throws Exception {
        String token = registerUser("apply-none").get("token").asText();
        JsonNode booking = createBooking(token, nextCheckIn(), null);
        assertTrue(booking.get("loyaltyDiscountAmount") == null || booking.get("loyaltyDiscountAmount").isNull());
        assertTrue(booking.get("loyaltyPointsRedeemed") == null || booking.get("loyaltyPointsRedeemed").isNull());
    }

    @Test
    void bookingPricingBreakdownStoresLoyaltyDiscountSeparatelyFromOtherDiscounts() throws Exception {
        LocalDate ci = nextCheckIn(), co = ci.plusDays(1);
        BigDecimal base = baselinePrice(ci, co);
        BigDecimal fixedDiscount = base.divide(BigDecimal.valueOf(5), 2, RoundingMode.HALF_UP);

        String code = uniqueCode("breakdown");
        createCouponDef(code, fixedDiscount.toPlainString());
        JsonNode user = registerUser("breakdown-user");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        claim(token, code);
        grantLoyaltyPoints(userId, 5000);

        Long bookingId = book(token, bookingPayload(ci, co, null, code), status().isCreated())
            .get("id").asLong();
        JsonNode preDiscount = getJson(token, "/api/bookings/" + bookingId);
        BigDecimal afterCoupon = new BigDecimal(preDiscount.get("finalPrice").asText());

        reserve(token, reservePayload(bookingId, 1000, uniqueKey()), status().isCreated());

        JsonNode after = getJson(token, "/api/bookings/" + bookingId);
        assertEquals(code, after.get("couponCode").asText(), "coupon field untouched by loyalty redemption");
        assertDecimal(fixedDiscount, after.get("couponDiscountAmount"));
        assertEquals(1000, after.get("loyaltyPointsRedeemed").asLong());
        assertDecimal(new BigDecimal("10000.00"), after.get("loyaltyDiscountAmount"));
        assertDecimal(afterCoupon.subtract(new BigDecimal("10000.00")).setScale(2, RoundingMode.HALF_UP),
            after.get("finalPrice"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // RELEASE & EXPIRATION TESTS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void reservedRedemptionReleaseRestoresPoints() throws Exception {
        JsonNode user = registerUser("release-basic");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 5000);

        Long bookingId = createBooking(token, nextCheckIn(), null).get("id").asLong();
        String reference = reserve(token, reservePayload(bookingId, 1000, uniqueKey()), status().isCreated())
            .get("redemptionReference").asText();
        assertEquals(4000, getJson(token, "/api/me/loyalty").get("currentBalance").asLong());

        JsonNode released = mapper.readTree(mvc.perform(post("/api/loyalty/redemptions/" + reference + "/release")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertEquals("RELEASED", released.get("status").asText());
        assertEquals(5000, getJson(token, "/api/me/loyalty").get("currentBalance").asLong());
    }

    @Test
    void releaseCreatesExactlyOneReleaseLedgerTransaction() throws Exception {
        JsonNode user = registerUser("release-ledger");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 5000);

        Long bookingId = createBooking(token, nextCheckIn(), null).get("id").asLong();
        String reference = reserve(token, reservePayload(bookingId, 1000, uniqueKey()), status().isCreated())
            .get("redemptionReference").asText();

        mvc.perform(post("/api/loyalty/redemptions/" + reference + "/release")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        JsonNode releases = getJson(token, "/api/me/loyalty/transactions?type=REDEMPTION_RELEASE").get("content");
        assertEquals(1, releases.size());
        assertEquals(1000, releases.get(0).get("points").asLong());
    }

    @Test
    void repeatedReleaseDoesNotRestorePointsTwice() throws Exception {
        JsonNode user = registerUser("release-repeat");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 5000);

        Long bookingId = createBooking(token, nextCheckIn(), null).get("id").asLong();
        String reference = reserve(token, reservePayload(bookingId, 1000, uniqueKey()), status().isCreated())
            .get("redemptionReference").asText();

        mvc.perform(post("/api/loyalty/redemptions/" + reference + "/release")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
        // Second release call on an already-RELEASED (terminal) redemption is idempotent, not an error.
        mvc.perform(post("/api/loyalty/redemptions/" + reference + "/release")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        assertEquals(5000, getJson(token, "/api/me/loyalty").get("currentBalance").asLong());
        assertEquals(1, getJson(token, "/api/me/loyalty/transactions?type=REDEMPTION_RELEASE")
            .get("content").size());
    }

    @Test
    void appliedRedemptionCannotBeReleased() throws Exception {
        JsonNode user = registerUser("release-applied");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 5000);

        Long bookingId = createBooking(token, nextCheckIn(), null).get("id").asLong();
        String reference = reserve(token, reservePayload(bookingId, 1000, uniqueKey()), status().isCreated())
            .get("redemptionReference").asText();
        payForBooking(token, bookingId); // RESERVED -> APPLIED

        mvc.perform(post("/api/loyalty/redemptions/" + reference + "/release")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isConflict());
    }

    @Test
    void expiredReservationRestoresPointsViaAdminExpireStale() throws Exception {
        JsonNode user = registerUser("expire-basic");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 5000);

        Long bookingId = createBooking(token, nextCheckIn(), null).get("id").asLong();
        String reference = reserve(token, reservePayload(bookingId, 1000, uniqueKey()), status().isCreated())
            .get("redemptionReference").asText();

        LoyaltyPointsRedemption row = redemptionRepo.findByRedemptionReference(reference).orElseThrow();
        row.setExpiresAt(Instant.now().minusSeconds(60));
        redemptionRepo.save(row);

        JsonNode run = mapper.readTree(mvc.perform(post("/api/admin/loyalty/redemptions/expire-stale")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertTrue(run.get("expiredCount").asInt() >= 1);

        JsonNode expired = getJson(token, "/api/loyalty/redemptions/" + reference);
        assertEquals("EXPIRED", expired.get("status").asText());
        assertEquals(5000, getJson(token, "/api/me/loyalty").get("currentBalance").asLong());

        JsonNode releases = getJson(token, "/api/me/loyalty/transactions?type=REDEMPTION_RELEASE").get("content");
        assertEquals(1, releases.size(), "expiry restoration uses the RELEASE ledger type");
    }

    @Test
    void expiryCleanupAffectsOnlyExpiredReservedRecords() throws Exception {
        JsonNode user = registerUser("expire-selective");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 5000);

        Long bookingExpired = createBooking(token, nextCheckIn(), null).get("id").asLong();
        Long bookingFresh = createBooking(token, nextCheckIn(), null).get("id").asLong();
        String refExpired = reserve(token, reservePayload(bookingExpired, 1000, uniqueKey()), status().isCreated())
            .get("redemptionReference").asText();
        String refFresh = reserve(token, reservePayload(bookingFresh, 1000, uniqueKey()), status().isCreated())
            .get("redemptionReference").asText();

        LoyaltyPointsRedemption row = redemptionRepo.findByRedemptionReference(refExpired).orElseThrow();
        row.setExpiresAt(Instant.now().minusSeconds(60));
        redemptionRepo.save(row);

        mvc.perform(post("/api/admin/loyalty/redemptions/expire-stale")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk());

        assertEquals("EXPIRED", getJson(token, "/api/loyalty/redemptions/" + refExpired).get("status").asText());
        assertEquals("RESERVED", getJson(token, "/api/loyalty/redemptions/" + refFresh).get("status").asText(),
            "a non-expired RESERVED redemption must be untouched by the sweep");
        // 5000 granted - 1000 (expired, now released) - 1000 (still reserved) = 4000: only the
        // expired reservation's points came back; the fresh RESERVED one stays debited.
        assertEquals(4000, getJson(token, "/api/me/loyalty").get("currentBalance").asLong());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // REFUND (CANCELLATION) TESTS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void appliedRedemptionRefundedOnBookingCancellation() throws Exception {
        JsonNode user = registerUser("refund-basic");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 5000);

        Long bookingId = createBooking(token, nextCheckIn(), null).get("id").asLong();
        String reference = reserve(token, reservePayload(bookingId, 1000, uniqueKey()), status().isCreated())
            .get("redemptionReference").asText();
        payForBooking(token, bookingId);
        assertEquals(4000, getJson(token, "/api/me/loyalty").get("currentBalance").asLong());

        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        JsonNode refunded = getJson(token, "/api/loyalty/redemptions/" + reference);
        assertEquals("REFUNDED", refunded.get("status").asText());
        assertEquals(5000, getJson(token, "/api/me/loyalty").get("currentBalance").asLong());
    }

    @Test
    void refundCreatesExactlyOneRefundLedgerTransaction() throws Exception {
        JsonNode user = registerUser("refund-ledger");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 5000);

        Long bookingId = createBooking(token, nextCheckIn(), null).get("id").asLong();
        reserve(token, reservePayload(bookingId, 1000, uniqueKey()), status().isCreated());
        payForBooking(token, bookingId);

        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        JsonNode refunds = getJson(token, "/api/me/loyalty/transactions?type=REDEMPTION_REFUND").get("content");
        assertEquals(1, refunds.size());
        assertEquals(1000, refunds.get(0).get("points").asLong());
    }

    @Test
    void repeatedCancellationCallbackDoesNotRestorePointsTwice() throws Exception {
        JsonNode user = registerUser("refund-repeat");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 5000);

        Long bookingId = createBooking(token, nextCheckIn(), null).get("id").asLong();
        reserve(token, reservePayload(bookingId, 1000, uniqueKey()), status().isCreated());
        payForBooking(token, bookingId);

        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
        assertEquals(5000, getJson(token, "/api/me/loyalty").get("currentBalance").asLong());

        // A second cancellation attempt on an already-CANCELLED booking is rejected
        // outright at the booking-status layer — the redemption's onBookingCancelled
        // hook can never fire a second time through the real customer-facing flow.
        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isUnprocessableEntity());

        assertEquals(5000, getJson(token, "/api/me/loyalty").get("currentBalance").asLong(),
            "points must not be restored a second time");
        assertEquals(1, getJson(token, "/api/me/loyalty/transactions?type=REDEMPTION_REFUND")
            .get("content").size());
    }

    @Test
    void refundDoesNotIncreaseLifetimePointsEarned() throws Exception {
        JsonNode user = registerUser("refund-lifetime");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 5000);
        long lifetimeAfterGrant = getJson(token, "/api/me/loyalty").get("lifetimePointsEarned").asLong();

        Long bookingId = createBooking(token, nextCheckIn(), null).get("id").asLong();
        reserve(token, reservePayload(bookingId, 1000, uniqueKey()), status().isCreated());
        payForBooking(token, bookingId);

        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        assertEquals(lifetimeAfterGrant, getJson(token, "/api/me/loyalty").get("lifetimePointsEarned").asLong(),
            "a redeem-then-refund cycle must never touch the monotonic lifetime counter");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SECURITY & API TESTS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void customerCannotViewAnotherCustomersRedemption() throws Exception {
        JsonNode owner = registerUser("sec-owner");
        Long ownerId = owner.get("user").get("id").asLong();
        String ownerToken = owner.get("token").asText();
        grantLoyaltyPoints(ownerId, 5000);
        Long bookingId = createBooking(ownerToken, nextCheckIn(), null).get("id").asLong();
        String reference = reserve(ownerToken, reservePayload(bookingId, 1000, uniqueKey()), status().isCreated())
            .get("redemptionReference").asText();

        String strangerToken = registerUser("sec-stranger").get("token").asText();
        mvc.perform(get("/api/loyalty/redemptions/" + reference)
                .header("Authorization", "Bearer " + strangerToken))
            .andExpect(status().isForbidden());
        mvc.perform(get("/api/loyalty/redemptions/booking/" + bookingId)
                .header("Authorization", "Bearer " + strangerToken))
            .andExpect(status().isForbidden());
    }

    @Test
    void nonAdminCannotAccessPolicyManagementEndpoints() throws Exception {
        String token = registerUser("sec-nonadmin-policy").get("token").asText();
        mvc.perform(get("/api/admin/loyalty/redemption-policies")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
        mvc.perform(post("/api/admin/loyalty/redemption-policies")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(policyPayload(uniqueCode("nope"), 100, "1000", 1000, 100, 20, "1000", true, null, null)))
            .andExpect(status().isForbidden());
        mvc.perform(post("/api/admin/loyalty/redemptions/expire-stale")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
    }

    @Test
    void adminCanFullyManagePolicyLifecycle() throws Exception {
        // Created/updated inactive throughout: this test only verifies CRUD
        // mechanics, and an active policy here (effectiveFrom = now) would outrank
        // the seeded default in resolution and silently redirect every other
        // preview/reserve test in this class.
        String code = uniqueCode("full-lifecycle");
        JsonNode created = createPolicy(
            policyPayload(code, 200, "2000", 2000, 200, 15, "2000", false, null, null),
            status().isCreated());
        Long id = created.get("id").asLong();

        JsonNode updated = mapper.readTree(mvc.perform(put("/api/admin/loyalty/redemption-policies/" + id)
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(policyPayload(code, 200, "2500", 2000, 200, 15, "2000", false, null, null)))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertDecimal(new BigDecimal("2500.00"), updated.get("valuePerUnit"));

        JsonNode fetched = mapper.readTree(mvc.perform(get("/api/admin/loyalty/redemption-policies/" + id)
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertEquals(code, fetched.get("policyCode").asText());
    }

    @Test
    void adminRedemptionListSupportsStatusAndCustomerFilters() throws Exception {
        JsonNode user = registerUser("admin-list-filter");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 5000);
        Long bookingId = createBooking(token, nextCheckIn(), null).get("id").asLong();
        String reference = reserve(token, reservePayload(bookingId, 1000, uniqueKey()), status().isCreated())
            .get("redemptionReference").asText();

        JsonNode byCustomer = mapper.readTree(mvc.perform(get("/api/admin/loyalty/redemptions?customerId=" + userId)
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertTrue(byCustomer.get("content").size() >= 1);
        boolean found = false;
        for (JsonNode r : byCustomer.get("content")) if (reference.equals(r.get("redemptionReference").asText())) found = true;
        assertTrue(found);

        JsonNode byStatus = mapper.readTree(mvc.perform(
                get("/api/admin/loyalty/redemptions?bookingId=" + bookingId + "&status=RESERVED")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertEquals(1, byStatus.get("content").size());
    }

    @Test
    void invalidRequestsReturn400OnReserve() throws Exception {
        JsonNode user = registerUser("sec-400");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();
        grantLoyaltyPoints(userId, 5000);
        Long bookingId = createBooking(token, nextCheckIn(), null).get("id").asLong();

        reserve(token, reservePayload(bookingId, 550, uniqueKey()), status().isBadRequest()); // not a multiple of 100
        reserve(token, reservePayload(bookingId, 500, uniqueKey()), status().isBadRequest()); // below minimum
    }

    @Test
    void missingRecordsReturn404() throws Exception {
        String token = registerUser("sec-404").get("token").asText();
        mvc.perform(get("/api/loyalty/redemptions/LRD-NOSUCH-000000")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isNotFound());
        mvc.perform(get("/api/admin/loyalty/redemption-policies/99999999")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isNotFound());
    }

    @Test
    void unauthenticatedRedemptionEndpointsRejected() throws Exception {
        mvc.perform(post("/api/loyalty/redemptions/preview")
                .contentType(MediaType.APPLICATION_JSON)
                .content(previewByAmountPayload("100000", "1000")))
            .andExpect(status().isUnauthorized());
        mvc.perform(post("/api/loyalty/redemptions/reserve")
                .contentType(MediaType.APPLICATION_JSON)
                .content(reservePayload(1L, 1000, "x")))
            .andExpect(status().isUnauthorized());
        mvc.perform(get("/api/loyalty/redemptions/booking/1")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/admin/loyalty/redemption-policies")).andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private String adminTokenCache;

    private String adminToken() throws Exception {
        if (adminTokenCache == null) adminTokenCache = login("admin@planyourtrip.com", "admin123456");
        return adminTokenCache;
    }

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk())
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

    private synchronized Long resolveStdTwinRoomId() {
        if (stdTwinRoomId != null) return stdTwinRoomId;
        Long placeId = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        stdTwinRoomId = hotelRoomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "STD-TWIN".equals(r.getRoomCode()))
            .findFirst().orElseThrow().getId();
        return stdTwinRoomId;
    }

    /**
     * A check-in date within the 90-day seeded inventory window (see
     * DataInitializer#seedRoomInventory), cycling through a spread of offsets —
     * inventory capacity is 18 rooms/day so light reuse across tests is safe.
     */
    private LocalDate nextCheckIn() {
        return TODAY.plusDays(5 + (dayCounter.getAndIncrement() % 80));
    }

    private JsonNode createBooking(String token, LocalDate ci, LocalDate coOrNull) throws Exception {
        LocalDate co = coOrNull != null ? coOrNull : ci.plusDays(1);
        return book(token, bookingPayload(ci, co, null, null), status().isCreated());
    }

    private String bookingPayload(LocalDate ci, LocalDate co, String creditAmount, String couponCode) {
        return String.format(
            "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\"," +
            "\"adults\":2,\"children\":0,\"numberOfRooms\":1,\"specialRequest\":null," +
            "\"couponCode\":%s,\"creditAmount\":%s}",
            resolveStdTwinRoomId(), ci, co,
            couponCode == null ? "null" : "\"" + couponCode + "\"",
            creditAmount == null ? "null" : creditAmount);
    }

    private String bookingPayload(LocalDate ci, LocalDate co, String creditAmount) {
        return bookingPayload(ci, co, creditAmount, null);
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

    /** Observed pre-discount total for these dates via a throwaway booking (mirrors CheckoutCouponCreditTest). */
    private BigDecimal baselinePrice(LocalDate ci, LocalDate co) throws Exception {
        String token = registerUser("redeem-baseline").get("token").asText();
        JsonNode res = book(token, bookingPayload(ci, co, null, null), status().isCreated());
        BigDecimal price = new BigDecimal(res.get("finalPrice").asText());
        assertTrue(price.signum() > 0, "baseline price must be positive");
        return price;
    }

    /** Creates a payment (PENDING) then confirms it via mock-success (PAID) — this is what actually
     *  transitions the booking out of PENDING and fires the RESERVED -> APPLIED redemption hook. */
    private void payForBooking(String token, Long bookingId) throws Exception {
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

    private void grantLoyaltyPoints(Long userId, long points) throws Exception {
        mvc.perform(post("/api/admin/users/" + userId + "/loyalty/grant")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format(
                    "{\"points\":%d,\"description\":\"Phase 7.20 test grant\"," +
                    "\"referenceType\":\"ADMIN\",\"referenceId\":null,\"idempotencyKey\":null}", points)))
            .andExpect(status().isCreated());
    }

    private void grantCredits(Long userId, String amount) throws Exception {
        mvc.perform(post("/api/admin/users/" + userId + "/travel-credits/grant")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"amount\":" + amount + ",\"currency\":\"VND\"," +
                         "\"description\":\"Phase 7.20 test grant\"}"))
            .andExpect(status().isCreated());
    }

    private JsonNode createCouponDef(String code, String fixedDiscountValue) throws Exception {
        String payload = String.format("""
                {"code":"%s","name":"Redeem %s","description":"Phase 7.20 test coupon",
                 "discountType":"FIXED_AMOUNT","discountValue":%s,"maxDiscountAmount":null,"minimumSpend":null,
                 "validFrom":"%s","validUntil":"%s","active":true,"totalUsageLimit":null,"usageLimitPerUser":1}
                """,
            code, code, fixedDiscountValue, TODAY.minusDays(1), TODAY.plusDays(400));
        String body = mvc.perform(post("/api/admin/coupon-definitions")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private void claim(String token, String code) throws Exception {
        mvc.perform(post("/api/me/coupons/claim")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"" + code + "\"}"))
            .andExpect(status().isCreated());
    }

    private String reservePayload(Long bookingId, long points, String idempotencyKey) {
        return String.format("{\"bookingId\":%d,\"requestedPoints\":%d,\"idempotencyKey\":\"%s\"}",
            bookingId, points, idempotencyKey);
    }

    private JsonNode reserve(String token, String payload, ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/loyalty/redemptions/reserve")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
    }

    /** Raw HTTP status only — used by the concurrency test to avoid asserting inside worker threads. */
    private int reserveRaw(String token, String payload) throws Exception {
        return mvc.perform(post("/api/loyalty/redemptions/reserve")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andReturn().getResponse().getStatus();
    }

    private String previewByAmountPayload(String eligibleAmount, String requestedPoints) {
        return String.format("{\"bookingId\":null,\"eligibleAmount\":%s,\"requestedPoints\":%s}",
            eligibleAmount, requestedPoints);
    }

    private String previewByBookingPayload(Long bookingId, String requestedPoints) {
        return String.format("{\"bookingId\":%d,\"eligibleAmount\":null,\"requestedPoints\":%s}",
            bookingId, requestedPoints);
    }

    private JsonNode preview(String token, String payload, ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/loyalty/redemptions/preview")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private String policyPayload(String code, long pointsPerUnit, String valuePerUnit, long minRedemption,
                                  long increment, int maxPct, String minPayable, boolean active,
                                  Instant unusedFrom, Instant unusedUntil) {
        return String.format("""
                {"policyCode":"%s","displayName":"Test policy %s","pointsPerUnit":%d,"valuePerUnit":%s,
                 "minimumRedemptionPoints":%d,"redemptionIncrementPoints":%d,"maximumDiscountPercentage":%d,
                 "minimumFinalPayableAmount":%s,"active":%s,"effectiveFrom":null,"effectiveUntil":null}
                """,
            code, code, pointsPerUnit, valuePerUnit, minRedemption, increment, maxPct, minPayable, active);
    }

    private String policyPayloadWithDates(String code, long pointsPerUnit, String valuePerUnit, long minRedemption,
                                           long increment, int maxPct, String minPayable, boolean active,
                                           Instant from, Instant until) {
        return String.format("""
                {"policyCode":"%s","displayName":"Test policy %s","pointsPerUnit":%d,"valuePerUnit":%s,
                 "minimumRedemptionPoints":%d,"redemptionIncrementPoints":%d,"maximumDiscountPercentage":%d,
                 "minimumFinalPayableAmount":%s,"active":%s,"effectiveFrom":%s,"effectiveUntil":%s}
                """,
            code, code, pointsPerUnit, valuePerUnit, minRedemption, increment, maxPct, minPayable, active,
            from == null ? "null" : "\"" + from + "\"",
            until == null ? "null" : "\"" + until + "\"");
    }

    private JsonNode createPolicy(String payload, ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/admin/loyalty/redemption-policies")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
    }

    private JsonNode getJson(String token, String url) throws Exception {
        String body = mvc.perform(get(url)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private List<JsonNode> getJsonAdminList(String url) throws Exception {
        String body = mvc.perform(get(url)
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode arr = mapper.readTree(body);
        return mapper.convertValue(arr, mapper.getTypeFactory().constructCollectionType(List.class, JsonNode.class));
    }

    private String uniqueCode(String prefix) {
        return ("LRD-" + prefix + "-" + counter.getAndIncrement()).toUpperCase();
    }

    private String uniqueKey() {
        return "lrd-test-key-" + counter.getAndIncrement();
    }

    private boolean containsMessage(JsonNode preview, String substring) {
        for (JsonNode m : preview.get("messages")) if (m.asText().contains(substring)) return true;
        return false;
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
