package com.example.planyourtrip;

import com.example.planyourtrip.repository.BookingRepository;
import com.example.planyourtrip.repository.CategoryRepository;
import com.example.planyourtrip.repository.CustomerCouponRepository;
import com.example.planyourtrip.repository.GiftCardRepository;
import com.example.planyourtrip.repository.GiftCardTransactionRepository;
import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.InventoryReservationRepository;
import com.example.planyourtrip.repository.LoyaltyPointsRedemptionRepository;
import com.example.planyourtrip.repository.LoyaltyPointsTransactionRepository;
import com.example.planyourtrip.repository.NotificationRepository;
import com.example.planyourtrip.repository.PaymentRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.repository.RoomInventoryRepository;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.TravelCreditAccountRepository;
import com.example.planyourtrip.repository.TravelCreditTransactionRepository;
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
 * Phase 7.33 — Authenticated customer benefit pricing quote
 * (POST /api/me/rooms/{roomId}/pricing/quote).
 *
 * <p>Proves the authenticated quote layers the calling customer's OWN coupon /
 * loyalty / travel-credit / gift-card previews on top of the Phase 7.32
 * rate-plan + promotion base, in the exact checkout stacking order, to estimate
 * the payable — and, critically, that it mutates NOTHING: no booking, payment,
 * inventory decrement, inventory reservation, coupon claim/consumption, loyalty
 * reservation/ledger row, travel-credit ledger row or account, gift-card
 * redemption/ledger row, or notification. Also proves ownership (a foreign
 * coupon id 404s), soft-degrade of ineligible benefits, and that the estimate
 * matches a real checkout's charged total.
 */
@SpringBootTest
@AutoConfigureMockMvc
class AuthenticatedPricingQuoteTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository roomRepo;
    @Autowired RoomInventoryRepository inventoryRepo;
    @Autowired InventoryReservationRepository reservationRepo;
    @Autowired CustomerCouponRepository customerCouponRepo;
    @Autowired LoyaltyPointsTransactionRepository loyaltyTxnRepo;
    @Autowired LoyaltyPointsRedemptionRepository redemptionRepo;
    @Autowired TravelCreditTransactionRepository creditTxnRepo;
    @Autowired TravelCreditAccountRepository creditAccountRepo;
    @Autowired GiftCardTransactionRepository giftTxnRepo;
    @Autowired GiftCardRepository giftCardRepo;
    @Autowired BookingRepository bookingRepo;
    @Autowired PaymentRepository paymentRepo;
    @Autowired NotificationRepository notificationRepo;

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
    // 1. HAPPY PATH — all four benefit stages
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void quoteLayersAllFourBenefitPreviewsInStackingOrder() throws Exception {
        Long roomId = provisionBookableRoom();
        createPlanReturnId(roomId, priced("All", "A33-ALL", 1000000));

        JsonNode user = registerUser("q33-all");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();

        // Discover the base pre-benefit total from a benefit-free quote first.
        JsonNode baseOnly = quoteOk(token, roomId, req(today(3), today(5), 2, 0, 0, null, null, null, null, null));
        BigDecimal base = dec(baseOnly.get("totalBeforeCustomerBenefits"));

        // Set up all four benefits, sized to stay within limits.
        BigDecimal fixed = base.divide(BigDecimal.valueOf(10), 2, RoundingMode.HALF_UP);   // coupon
        String code = uniqueCode("all");
        createFixedCouponDef(code, fixed.toPlainString());
        Long couponId = claim(token, code).get("id").asLong();

        grantLoyaltyPoints(userId, 2000);                                                  // loyalty
        BigDecimal creditGrant = base.divide(BigDecimal.valueOf(4), 2, RoundingMode.HALF_UP);
        grantCredits(userId, creditGrant.toPlainString());                                 // travel credit
        BigDecimal creditAsk = base.divide(BigDecimal.valueOf(20), 2, RoundingMode.HALF_UP);
        BigDecimal giftAmt = base.divide(BigDecimal.valueOf(8), 2, RoundingMode.HALF_UP);
        String giftCode = issueAndActivate(token, giftAmt);                                // gift card

        JsonNode q = quoteOk(token, roomId,
            req(today(3), today(5), 2, 0, 0, null, couponId, 1000L, creditAsk, giftCode));

        // All four nested previews present.
        assertFalse(q.get("couponPreview").isNull());
        assertFalse(q.get("loyaltyPreview").isNull());
        assertFalse(q.get("travelCreditPreview").isNull());
        assertFalse(q.get("giftCardPreview").isNull());

        // Stacking arithmetic is internally consistent at every stage.
        BigDecimal couponDiscount = dec(q.get("couponDiscount"));
        BigDecimal afterCoupon = dec(q.get("afterCoupon"));
        BigDecimal loyaltyDiscount = dec(q.get("loyaltyDiscount"));
        BigDecimal afterLoyalty = dec(q.get("afterLoyalty"));
        BigDecimal creditApplied = dec(q.get("travelCreditApplied"));
        BigDecimal afterCredit = dec(q.get("afterTravelCredit"));
        BigDecimal giftApplied = dec(q.get("giftCardApplied"));
        BigDecimal payable = dec(q.get("estimatedPayable"));

        assertEqDec(base, dec(q.get("totalBeforeCustomerBenefits")));
        assertEqDec(fixed, couponDiscount);
        assertEqDec(base.subtract(couponDiscount), afterCoupon);
        assertEqDec(afterCoupon.subtract(loyaltyDiscount), afterLoyalty);
        assertEqDec(creditAsk, creditApplied);                       // fully covered by grant + payable
        assertEqDec(afterLoyalty.subtract(creditApplied), afterCredit);
        assertEqDec(giftAmt, giftApplied);                            // gift < remaining, fully applied
        assertEqDec(afterCredit.subtract(giftApplied), payable);
        assertTrue(loyaltyDiscount.signum() > 0, "1000 points must yield a positive discount");
        assertTrue(q.get("eligibilityFailures").isEmpty(), "no failures when every benefit is eligible");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 2. IDENTICAL CHECKOUT ESTIMATE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void estimatedPayableMatchesRealCheckoutTotal() throws Exception {
        // Coupon + credit + gift card are all applied by BookingService.create; comparing the quote's
        // estimatedPayable to the booking's charged finalPrice proves the estimate equals checkout.
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, priced("Match", "A33-MATCH", 1000000));

        JsonNode user = registerUser("q33-match");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();

        JsonNode baseOnly = quoteOk(token, roomId, req(today(3), today(5), 2, 0, 0, planId, null, null, null, null));
        BigDecimal base = dec(baseOnly.get("totalBeforeCustomerBenefits"));

        BigDecimal fixed = base.divide(BigDecimal.valueOf(10), 2, RoundingMode.HALF_UP);
        String code = uniqueCode("match");
        createFixedCouponDef(code, fixed.toPlainString());
        Long couponId = claim(token, code).get("id").asLong();

        BigDecimal creditAsk = base.divide(BigDecimal.valueOf(20), 2, RoundingMode.HALF_UP);
        grantCredits(userId, creditAsk.multiply(BigDecimal.TEN).setScale(2, RoundingMode.HALF_UP).toPlainString());
        BigDecimal giftAmt = base.divide(BigDecimal.valueOf(8), 2, RoundingMode.HALF_UP);
        String giftCode = issueAndActivate(token, giftAmt);

        JsonNode q = quoteOk(token, roomId,
            req(today(3), today(5), 2, 0, 0, planId, couponId, null, creditAsk, giftCode));
        BigDecimal estimatedPayable = dec(q.get("estimatedPayable"));

        // Now actually book with the SAME benefits (coupon by code, credit amount, gift code).
        JsonNode booking = book(token, roomId, today(3), today(5), planId, code, creditAsk, giftCode);
        assertEqDec(estimatedPayable, dec(booking.get("finalPrice")),
            "quote estimatedPayable must equal the real checkout finalPrice");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 3. LOYALTY STAGE cross-checks the standalone loyalty preview
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void loyaltyDiscountMatchesStandaloneLoyaltyPreview() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, priced("Loy", "A33-LOY", 1000000));

        JsonNode user = registerUser("q33-loy");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        grantLoyaltyPoints(userId, 3000);

        JsonNode q = quoteOk(token, roomId, req(today(3), today(5), 2, 0, 0, planId, null, 2000L, null, null));
        BigDecimal afterCoupon = dec(q.get("afterCoupon"));
        BigDecimal loyaltyDiscount = dec(q.get("loyaltyDiscount"));
        assertTrue(loyaltyDiscount.signum() > 0);
        assertEqDec(afterCoupon.subtract(loyaltyDiscount), dec(q.get("afterLoyalty")));
        assertEqDec(loyaltyDiscount, dec(q.get("estimatedPayable")).negate().add(afterCoupon)); // payable == afterCoupon - discount

        // The nested loyaltyPreview equals what the standalone endpoint returns for the same eligibleAmount.
        JsonNode standalone = loyaltyPreview(token, afterCoupon.toPlainString(), "2000");
        assertEqDec(dec(standalone.get("discountAmount")), loyaltyDiscount);
        assertEqDec(dec(standalone.get("discountAmount")), dec(q.get("loyaltyPreview").get("discountAmount")));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 4. OMITTED BENEFITS ARE SKIPPED
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void omittedBenefitsLeaveTotalUnchanged() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, priced("None", "A33-NONE", 1000000));
        String token = registerUser("q33-none").get("token").asText();

        JsonNode q = quoteOk(token, roomId, req(today(3), today(5), 2, 0, 0, planId, null, null, null, null));
        assertTrue(q.get("couponPreview").isNull());
        assertTrue(q.get("loyaltyPreview").isNull());
        assertTrue(q.get("travelCreditPreview").isNull());
        assertTrue(q.get("giftCardPreview").isNull());
        assertEqDec(dec(q.get("totalBeforeCustomerBenefits")), dec(q.get("estimatedPayable")));
        assertEqDec(BigDecimal.ZERO, dec(q.get("couponDiscount")));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 5. INELIGIBLE (but OWNED) benefit is soft-degraded, not thrown
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void ineligibleOwnedCouponSurfacedNotThrown() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, priced("MinSpend", "A33-MS", 1000000));
        JsonNode user = registerUser("q33-ms");
        String token = user.get("token").asText();

        JsonNode baseOnly = quoteOk(token, roomId, req(today(3), today(5), 2, 0, 0, planId, null, null, null, null));
        BigDecimal base = dec(baseOnly.get("totalBeforeCustomerBenefits"));

        // Coupon requires a minimum spend well above the order total → owned but ineligible.
        String code = uniqueCode("ms");
        createCouponDef(code, "PERCENTAGE", "10", null, base.add(new BigDecimal("1000000")).toPlainString());
        Long couponId = claim(token, code).get("id").asLong();

        JsonNode q = quoteOk(token, roomId, req(today(3), today(5), 2, 0, 0, planId, couponId, null, null, null));
        assertFalse(q.get("couponPreview").get("eligible").asBoolean());
        assertEqDec(BigDecimal.ZERO, dec(q.get("couponDiscount")));
        assertEqDec(base, dec(q.get("estimatedPayable")), "an ineligible coupon applies no discount");
        assertFalse(q.get("eligibilityFailures").isEmpty(), "the ineligibility must be surfaced");
    }

    @Test
    void insufficientTravelCreditAppliesPartialAndReportsIt() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, priced("Partial", "A33-PART", 1000000));
        JsonNode user = registerUser("q33-part");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();

        JsonNode baseOnly = quoteOk(token, roomId, req(today(3), today(5), 2, 0, 0, planId, null, null, null, null));
        BigDecimal base = dec(baseOnly.get("totalBeforeCustomerBenefits"));
        BigDecimal grant = base.divide(BigDecimal.valueOf(10), 2, RoundingMode.HALF_UP);
        grantCredits(userId, grant.toPlainString());
        BigDecimal ask = grant.multiply(BigDecimal.valueOf(3)).setScale(2, RoundingMode.HALF_UP); // > balance

        JsonNode q = quoteOk(token, roomId, req(today(3), today(5), 2, 0, 0, planId, null, null, ask, null));
        assertEqDec(grant, dec(q.get("travelCreditApplied")), "only the available balance is applied");
        assertEqDec(base.subtract(grant), dec(q.get("estimatedPayable")));
        assertFalse(q.get("eligibilityFailures").isEmpty());
    }

    @Test
    void unknownGiftCardCodeSurfacedNotThrown() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, priced("Gift", "A33-GIFT", 1000000));
        String token = registerUser("q33-gift").get("token").asText();

        JsonNode baseOnly = quoteOk(token, roomId, req(today(3), today(5), 2, 0, 0, planId, null, null, null, null));
        BigDecimal base = dec(baseOnly.get("totalBeforeCustomerBenefits"));

        JsonNode q = quoteOk(token, roomId,
            req(today(3), today(5), 2, 0, 0, planId, null, null, null, "PYT-GC-0000-0000-0000"));
        assertFalse(q.get("giftCardPreview").get("eligible").asBoolean());
        assertEqDec(BigDecimal.ZERO, dec(q.get("giftCardApplied")));
        assertEqDec(base, dec(q.get("estimatedPayable")));
        assertFalse(q.get("eligibilityFailures").isEmpty());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 6. SECURITY — a foreign coupon id 404s (no cross-customer leak)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void anotherCustomersCouponIdReturns404() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, priced("Foreign", "A33-FGN", 1000000));

        String owner = registerUser("q33-owner").get("token").asText();
        String stranger = registerUser("q33-stranger").get("token").asText();
        String code = uniqueCode("fgn");
        createFixedCouponDef(code, "50000");
        Long ownerCouponId = claim(owner, code).get("id").asLong();

        // Stranger references the owner's claimed coupon id → 404, existence never leaks.
        mvc.perform(post("/api/me/rooms/" + roomId + "/pricing/quote")
                .header("Authorization", "Bearer " + stranger)
                .contentType(MediaType.APPLICATION_JSON)
                .content(req(today(3), today(5), 2, 0, 0, planId, ownerCouponId, null, null, null)))
            .andExpect(status().isNotFound());

        // A wholly non-existent coupon id also 404s.
        mvc.perform(post("/api/me/rooms/" + roomId + "/pricing/quote")
                .header("Authorization", "Bearer " + stranger)
                .contentType(MediaType.APPLICATION_JSON)
                .content(req(today(3), today(5), 2, 0, 0, planId, 999999L, null, null, null)))
            .andExpect(status().isNotFound());
    }

    @Test
    void unauthenticatedAccessRejected() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, priced("Auth", "A33-AUTH", 1000000));
        mvc.perform(post("/api/me/rooms/" + roomId + "/pricing/quote")
                .contentType(MediaType.APPLICATION_JSON)
                .content(req(today(3), today(5), 2, 0, 0, planId, null, null, null, null)))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 7. NO STATE MUTATION — the heart of this phase
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void quoteMutatesNothingAcrossEveryTable() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, priced("Immutable", "A33-IMM", 1000000));

        JsonNode user = registerUser("q33-imm");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();

        JsonNode baseOnly = quoteOk(token, roomId, req(today(3), today(5), 2, 0, 0, planId, null, null, null, null));
        BigDecimal base = dec(baseOnly.get("totalBeforeCustomerBenefits"));

        String code = uniqueCode("imm");
        createFixedCouponDef(code, base.divide(BigDecimal.valueOf(10), 2, RoundingMode.HALF_UP).toPlainString());
        Long couponId = claim(token, code).get("id").asLong();
        grantLoyaltyPoints(userId, 2000);
        grantCredits(userId, base.toPlainString());
        BigDecimal giftAmt = base.divide(BigDecimal.valueOf(8), 2, RoundingMode.HALF_UP);
        String giftCode = issueAndActivate(token, giftAmt);

        // Snapshot every ledger/entity table BEFORE the quote.
        long coupons = customerCouponRepo.count();
        long loyaltyTxns = loyaltyTxnRepo.count();
        long redemptions = redemptionRepo.count();
        long creditTxns = creditTxnRepo.count();
        long giftTxns = giftTxnRepo.count();
        long bookings = bookingRepo.count();
        long payments = paymentRepo.count();
        long reservations = reservationRepo.count();
        long notifications = notificationRepo.count();
        int inv3 = availableOn(roomId, today(3));
        int inv4 = availableOn(roomId, today(4));
        String couponStatusBefore = getJson(token, "/api/me/coupons/" + couponId).get("status").asText();
        BigDecimal creditBalBefore = dec(getJson(token, "/api/me/travel-credits").get("balance"));
        long loyaltyBalBefore = getJson(token, "/api/me/loyalty").get("currentBalance").asLong();
        BigDecimal giftBalBefore = dec(getJson(token, "/api/me/gift-cards/code/" + giftCode).get("currentBalance"));

        // Quote with ALL benefits engaged.
        JsonNode q = quoteOk(token, roomId,
            req(today(3), today(5), 2, 0, 0, planId, couponId, 1000L, giftAmt, giftCode));
        assertFalse(q.get("estimatedPayable").isNull());

        // Nothing changed anywhere.
        assertEquals(coupons, customerCouponRepo.count(), "no CustomerCoupon created");
        assertEquals(loyaltyTxns, loyaltyTxnRepo.count(), "no loyalty ledger row");
        assertEquals(redemptions, redemptionRepo.count(), "no loyalty redemption reserved");
        assertEquals(creditTxns, creditTxnRepo.count(), "no travel-credit ledger row");
        assertEquals(giftTxns, giftTxnRepo.count(), "no gift-card ledger row");
        assertEquals(bookings, bookingRepo.count(), "no booking created");
        assertEquals(payments, paymentRepo.count(), "no payment created");
        assertEquals(reservations, reservationRepo.count(), "no inventory reservation created");
        assertEquals(notifications, notificationRepo.count(), "no notification created");
        assertEquals(inv3, availableOn(roomId, today(3)), "inventory untouched (night 1)");
        assertEquals(inv4, availableOn(roomId, today(4)), "inventory untouched (night 2)");

        assertEquals(couponStatusBefore, getJson(token, "/api/me/coupons/" + couponId).get("status").asText(),
            "coupon stays AVAILABLE — never consumed by the preview");
        assertEquals("AVAILABLE", couponStatusBefore);
        assertEqDec(creditBalBefore, dec(getJson(token, "/api/me/travel-credits").get("balance")));
        assertEquals(loyaltyBalBefore, getJson(token, "/api/me/loyalty").get("currentBalance").asLong());
        assertEqDec(giftBalBefore, dec(getJson(token, "/api/me/gift-cards/code/" + giftCode).get("currentBalance")));

        // The coupon is still spendable at a real checkout afterwards.
        JsonNode booking = book(token, roomId, today(3), today(5), planId, code, null, null);
        assertEquals(code, booking.get("couponCode").asText());
    }

    @Test
    void quoteNeverCreatesTravelCreditAccountForCreditlessUser() throws Exception {
        // A brand-new customer with no travel-credit account must NOT have one created merely
        // by previewing a credit amount — previewAvailableBalance is strictly read-only.
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, priced("NoAcct", "A33-NA", 1000000));
        JsonNode user = registerUser("q33-na");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();

        assertTrue(creditAccountRepo.findByUserId(userId).isEmpty(), "precondition: no account yet");
        JsonNode q = quoteOk(token, roomId,
            req(today(3), today(5), 2, 0, 0, planId, null, null, new BigDecimal("50000"), null));
        // Requested credit could not be applied (zero balance) but no account row was created.
        assertEqDec(BigDecimal.ZERO, dec(q.get("travelCreditApplied")));
        assertTrue(creditAccountRepo.findByUserId(userId).isEmpty(),
            "previewing credit must not lazily create a TravelCreditAccount");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 8. NO ELIGIBLE PLAN → base returned, benefit stages null (still 200)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void noEligiblePlanReturnsBaseWithoutBenefitStages() throws Exception {
        Long roomId = provisionBookableRoom();
        Map<String, Object> p = priced("LongOnly", "A33-LONG", 1000000);
        p.put("minStayNights", 10);
        createPlanReturnId(roomId, p);
        JsonNode user = registerUser("q33-long");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        grantCredits(userId, "500000");

        JsonNode q = quoteOk(token, roomId,
            req(today(3), today(5), 2, 0, 0, null, null, null, new BigDecimal("100000"), null)); // 2 nights < 10
        assertTrue(q.get("baseQuote").get("selectedRatePlanId").isNull());
        assertTrue(q.get("totalBeforeCustomerBenefits").isNull(), "no price to layer benefits onto");
        assertTrue(q.get("estimatedPayable").isNull());
        assertTrue(q.get("travelCreditPreview").isNull(), "benefit stages skipped when no plan is eligible");
        assertFalse(q.get("eligibilityFailures").isEmpty());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private LocalDate today(int plus) { return LocalDate.now().plusDays(plus); }

    private int availableOn(Long roomId, LocalDate date) {
        return inventoryRepo.findByHotelRoomIdAndInventoryDate(roomId, date).orElseThrow().getAvailableInventory();
    }

    private String req(LocalDate ci, LocalDate co, int adults, int children, int extraBeds, Long ratePlanId,
                       Long couponId, Long requestedPoints, BigDecimal creditAmount, String giftCardCode) throws Exception {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("checkIn", ci.toString());
        m.put("checkOut", co.toString());
        m.put("adults", adults);
        m.put("children", children);
        m.put("extraBeds", extraBeds);
        if (ratePlanId != null) m.put("ratePlanId", ratePlanId);
        if (couponId != null) m.put("couponId", couponId);
        if (requestedPoints != null) m.put("requestedPoints", requestedPoints);
        if (creditAmount != null) m.put("travelCreditAmountRequested", creditAmount);
        if (giftCardCode != null) m.put("giftCardCode", giftCardCode);
        return mapper.writeValueAsString(m);
    }

    private JsonNode quoteOk(String token, Long roomId, String body) throws Exception {
        String resp = mvc.perform(post("/api/me/rooms/" + roomId + "/pricing/quote")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(body))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp);
    }

    private JsonNode loyaltyPreview(String token, String eligibleAmount, String requestedPoints) throws Exception {
        String resp = mvc.perform(post("/api/loyalty/redemptions/preview")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format("{\"bookingId\":null,\"eligibleAmount\":%s,\"requestedPoints\":%s}",
                    eligibleAmount, requestedPoints)))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp);
    }

    private JsonNode book(String token, Long roomId, LocalDate ci, LocalDate co, Long ratePlanId,
                          String couponCode, BigDecimal creditAmount, String giftCardCode) throws Exception {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("roomId", roomId);
        m.put("checkIn", ci.toString());
        m.put("checkOut", co.toString());
        m.put("adults", 2);
        m.put("children", 0);
        m.put("numberOfRooms", 1);
        if (ratePlanId != null) m.put("ratePlanId", ratePlanId);
        if (couponCode != null) m.put("couponCode", couponCode);
        if (creditAmount != null) m.put("creditAmount", creditAmount);
        if (giftCardCode != null) m.put("giftCardCode", giftCardCode);
        String resp = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(m)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp);
    }

    // ── Benefit setup ────────────────────────────────────────────────────────

    private JsonNode createFixedCouponDef(String code, String amount) throws Exception {
        return createCouponDef(code, "FIXED_AMOUNT", amount, null, null);
    }

    private JsonNode createCouponDef(String code, String discountType, String discountValue,
                                     String maxDiscountAmount, String minimumSpend) throws Exception {
        String payload = String.format("""
                {"code":"%s","name":"Auth %s","description":"Phase 7.33 test coupon",
                 "discountType":"%s","discountValue":%s,"maxDiscountAmount":%s,"minimumSpend":%s,
                 "validFrom":"%s","validUntil":"%s","active":true,"totalUsageLimit":null,"usageLimitPerUser":1}
                """,
            code, code, discountType, discountValue,
            maxDiscountAmount == null ? "null" : maxDiscountAmount,
            minimumSpend == null ? "null" : minimumSpend,
            LocalDate.now().minusDays(1), LocalDate.now().plusDays(60));
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
                    "{\"points\":%d,\"description\":\"Phase 7.33 test grant\"," +
                    "\"referenceType\":\"ADMIN\",\"referenceId\":null,\"idempotencyKey\":null}", points)))
            .andExpect(status().isCreated());
    }

    private void grantCredits(Long userId, String amount) throws Exception {
        mvc.perform(post("/api/admin/users/" + userId + "/travel-credits/grant")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"amount\":" + amount + ",\"currency\":\"VND\",\"description\":\"Phase 7.33 test grant\"}"))
            .andExpect(status().isCreated());
    }

    /** Creates a throwaway VND custom-amount product, issues a card to the caller, activates it, returns the full code. */
    private String issueAndActivate(String token, BigDecimal amount) throws Exception {
        String productCode = ("A33-GC-" + counter.getAndIncrement()).toUpperCase();
        String product = String.format("""
            {"productCode":"%s","name":"Auth gift %s","description":"Phase 7.33 test product",
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

    // ── Plan / provisioning (mirrors RoomPricingQuoteTest) ────────────────────

    private Map<String, Object> basePlan(String name, String code) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("rateName", name);
        m.put("rateType", "STANDARD");
        m.put("pricePerNight", 1000000);
        m.put("startDate", LocalDate.now().toString());
        m.put("endDate", LocalDate.now().plusDays(365).toString());
        m.put("active", true);
        if (code != null) m.put("code", code);
        return m;
    }

    private Map<String, Object> priced(String name, String code, long price) {
        Map<String, Object> m = basePlan(name, code);
        m.put("pricePerNight", price);
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

    private Long provisionBookableRoom() throws Exception {
        Long hotelId = createHotelPlace(uniq());
        createHotelDetail(hotelId);
        Long roomId = createRoom(hotelId, "RM-" + uniq());
        StringBuilder items = new StringBuilder();
        for (int i = 1; i <= 20; i++) {
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

    private String uniqueCode(String prefix) {
        return ("A33-" + prefix + "-" + counter.getAndIncrement()).toUpperCase();
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

    private Long createHotelPlace(String name) throws Exception {
        Long id = createDraftHotelPlace(name);
        patchStatus(id, "APPROVED");
        patchStatus(id, "PUBLISHED");
        return id;
    }

    private Long createDraftHotelPlace(String name) throws Exception {
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
        return mapper.readTree(resp).get("id").asLong();
    }

    private void patchStatus(Long id, String status) throws Exception {
        mvc.perform(patch("/api/admin/places/" + id + "/status")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"" + status + "\"}"))
            .andExpect(status().isOk());
    }

    private Long createHotelDetail(Long placeId) throws Exception {
        String req = """
            {"placeId":%d,"starRating":4,"checkInTime":"14:00:00","checkOutTime":"12:00:00",
             "totalRooms":10,"availableRooms":10,"freeCancellation":false,"prepaymentRequired":false,
             "breakfastIncluded":false,"airportShuttle":false}
            """.formatted(placeId);
        String resp = mvc.perform(post("/api/admin/hotels")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp).get("id").asLong();
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
        assertEqDec(expected, actual, null);
    }

    private void assertEqDec(BigDecimal expected, BigDecimal actual, String msg) {
        assertEquals(0, expected.compareTo(actual),
            (msg != null ? msg + " — " : "") + "expected " + expected.toPlainString() + " but was " + actual.toPlainString());
    }

    private JsonNode getJson(String token, String url) throws Exception {
        String body = mvc.perform(get(url).header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }
}
