package com.example.planyourtrip;

import com.example.planyourtrip.repository.GiftCardRepository;
import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PlaceRepository;
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
import java.time.Instant;
import java.time.LocalDate;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * GiftCardCheckoutTest — Phase 7.25 (Gift Card Checkout Integration).
 * Covers redeeming a gift card as the LAST discount source at booking creation
 * (after promotion/coupon/loyalty/travel-credit): successful redemption, partial
 * redemption (card balance exceeds payable) and full redemption (card drained),
 * the immutable REDEMPTION ledger row + deterministic idempotency key, the
 * three-way payment split (success keeps / payment-failure releases / booking
 * cancellation refunds — both restores producing exactly one REFUND row via the
 * shared refund key, safe under a fail-then-cancel double callback), and all the
 * redemption-rule rejections (expired, cancelled, currency mismatch, ownership
 * 404). Also the booking-scoped preview and the untouched legacy checkout flow.
 * Prices are never hard-coded — each scenario derives its expected amounts from a
 * throwaway baseline booking on the same room/dates, mirroring
 * CheckoutCouponCreditTest.
 */
@SpringBootTest
@AutoConfigureMockMvc
class GiftCardCheckoutTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;
    @Autowired GiftCardRepository giftCardRepo;

    private static final AtomicInteger counter = new AtomicInteger(1);
    private static final LocalDate TODAY = LocalDate.now();

    private Long stdTwinRoomId;

    @BeforeEach
    void setup() {
        Long placeId  = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        stdTwinRoomId = hotelRoomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "STD-TWIN".equals(r.getRoomCode()))
            .findFirst().orElseThrow().getId();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 1. SUCCESSFUL / FULL REDEMPTION (card fully drained by a larger payable)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void giftCardRedeemedAtCheckoutReducesFinalPriceAndWritesLedgerRow() throws Exception {
        LocalDate ci = TODAY.plusDays(24), co = ci.plusDays(2);
        BigDecimal base = baselinePrice(ci, co);
        BigDecimal cardAmt = base.divide(BigDecimal.valueOf(2), 2, RoundingMode.HALF_UP); // < payable → fully drained

        JsonNode user = registerUser("gcc-full");
        String token = user.get("token").asText();
        JsonNode card = issueAndActivate(token, cardAmt);
        Long cardId = card.get("id").asLong();
        String code = card.get("fullCode").asText();

        JsonNode res = book(token, bookingPayload(stdTwinRoomId, ci, co, code), status().isCreated());
        Long bookingId = res.get("id").asLong();

        assertDecimal(cardAmt, res.get("giftCardAmountUsed"));
        assertDecimal(base.subtract(cardAmt), res.get("finalPrice"), "payable reduced by the redeemed amount");
        String maskedRef = res.get("giftCardReference").asText();
        assertTrue(maskedRef.startsWith("PYT-GC-****-****-"), "reference is the masked code, never the secret");
        assertTrue(code.endsWith(maskedRef.substring(maskedRef.length() - 4)));
        assertFalse(code.equals(maskedRef));

        // Card drained → FULLY_REDEEMED, one REDEMPTION ledger row anchored to the booking.
        JsonNode reread = getJson(token, "/api/me/gift-cards/" + cardId);
        assertDecimal("0", reread.get("currentBalance"));
        assertEquals("FULLY_REDEEMED", reread.get("status").asText());

        JsonNode redemption = txOfType(token, cardId, "REDEMPTION");
        assertNotNull(redemption, "a REDEMPTION ledger row must exist");
        assertEquals("BOOKING", redemption.get("referenceType").asText());
        assertEquals(bookingId, redemption.get("referenceId").asLong());
        assertEquals("booking-" + bookingId + "-giftcard-redemption", redemption.get("idempotencyKey").asText());
        assertDecimal(cardAmt, redemption.get("balanceBefore"));
        assertDecimal("0", redemption.get("balanceAfter"));

        // Discounted total flows straight into the payment amount.
        JsonNode pay = createPayment(token, bookingId);
        assertDecimal(base.subtract(cardAmt), pay.get("amount"),
            "payment amount is the gift-card-discounted payable");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 2. PARTIAL REDEMPTION (card balance exceeds payable → only part of card used)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void giftCardRedemptionCapsAtPayableWhenBalanceExceedsIt() throws Exception {
        LocalDate ci = TODAY.plusDays(27), co = ci.plusDays(2);
        BigDecimal base = baselinePrice(ci, co);
        BigDecimal cardAmt = base.multiply(BigDecimal.valueOf(2)).setScale(2, RoundingMode.HALF_UP); // > payable

        JsonNode user = registerUser("gcc-partial");
        String token = user.get("token").asText();
        JsonNode card = issueAndActivate(token, cardAmt);
        Long cardId = card.get("id").asLong();
        String code = card.get("fullCode").asText();

        JsonNode res = book(token, bookingPayload(stdTwinRoomId, ci, co, code), status().isCreated());

        assertDecimal(base, res.get("giftCardAmountUsed"), "redemption capped at the payable, never exceeds it");
        assertDecimal("0", res.get("finalPrice"), "gift card covered the whole payable");

        JsonNode reread = getJson(token, "/api/me/gift-cards/" + cardId);
        assertDecimal(cardAmt.subtract(base), reread.get("currentBalance"), "unused balance remains");
        assertEquals("PARTIALLY_REDEEMED", reread.get("status").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 3. PAYMENT FAILURE → RELEASE (restore balance, un-apply discount)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void paymentFailureReleasesGiftCardAndRestoresBalance() throws Exception {
        LocalDate ci = TODAY.plusDays(30), co = ci.plusDays(1);
        BigDecimal base = baselinePrice(ci, co);
        BigDecimal cardAmt = base.divide(BigDecimal.valueOf(2), 2, RoundingMode.HALF_UP);

        JsonNode user = registerUser("gcc-payfail");
        String token = user.get("token").asText();
        JsonNode card = issueAndActivate(token, cardAmt);
        Long cardId = card.get("id").asLong();
        String code = card.get("fullCode").asText();

        Long bookingId = book(token, bookingPayload(stdTwinRoomId, ci, co, code), status().isCreated())
            .get("id").asLong();
        assertDecimal("0", getJson(token, "/api/me/gift-cards/" + cardId).get("currentBalance"));

        Long paymentId = createPayment(token, bookingId).get("id").asLong();
        mvc.perform(post("/api/payments/" + paymentId + "/mock-fail")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        // Balance fully restored, exactly one REFUND row, booking discount un-applied.
        JsonNode reread = getJson(token, "/api/me/gift-cards/" + cardId);
        assertDecimal(cardAmt, reread.get("currentBalance"));
        assertEquals("ACTIVE", reread.get("status").asText(), "reopened — no longer fully redeemed");

        JsonNode refund = txOfType(token, cardId, "REFUND");
        assertNotNull(refund);
        assertEquals("booking-" + bookingId + "-giftcard-refund", refund.get("idempotencyKey").asText());

        JsonNode booking = getJson(token, "/api/bookings/" + bookingId);
        assertTrue(booking.get("giftCardAmountUsed").isNull(), "gift-card fields cleared on release");
        assertTrue(booking.get("giftCardReference").isNull());
        assertDecimal(base, booking.get("finalPrice"), "payable restored to the pre-gift-card amount");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 4. BOOKING CANCELLATION → REFUND + DOUBLE-CALLBACK IDEMPOTENCY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void cancellationRefundsGiftCardOnceEvenAfterPaymentFailureRelease() throws Exception {
        LocalDate ci = TODAY.plusDays(33), co = ci.plusDays(2);
        BigDecimal base = baselinePrice(ci, co);
        BigDecimal cardAmt = base.divide(BigDecimal.valueOf(2), 2, RoundingMode.HALF_UP);

        JsonNode user = registerUser("gcc-cancel");
        String token = user.get("token").asText();
        JsonNode card = issueAndActivate(token, cardAmt);
        Long cardId = card.get("id").asLong();
        String code = card.get("fullCode").asText();

        Long bookingId = book(token, bookingPayload(stdTwinRoomId, ci, co, code), status().isCreated())
            .get("id").asLong();

        // Payment fails first (release), then the customer cancels (refund) — the
        // second restore must be a no-op: same refund key, balance restored once.
        Long paymentId = createPayment(token, bookingId).get("id").asLong();
        mvc.perform(post("/api/payments/" + paymentId + "/mock-fail")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        JsonNode reread = getJson(token, "/api/me/gift-cards/" + cardId);
        assertDecimal(cardAmt, reread.get("currentBalance"), "restored exactly once, never doubled");
        assertEquals(1, countTxOfType(token, cardId, "REFUND"), "exactly one REFUND row across both callbacks");
    }

    @Test
    void plainCancellationRefundsGiftCard() throws Exception {
        LocalDate ci = TODAY.plusDays(36), co = ci.plusDays(1);
        BigDecimal base = baselinePrice(ci, co);
        BigDecimal cardAmt = base.divide(BigDecimal.valueOf(2), 2, RoundingMode.HALF_UP);

        JsonNode user = registerUser("gcc-plaincancel");
        String token = user.get("token").asText();
        JsonNode card = issueAndActivate(token, cardAmt);
        Long cardId = card.get("id").asLong();
        String code = card.get("fullCode").asText();

        Long bookingId = book(token, bookingPayload(stdTwinRoomId, ci, co, code), status().isCreated())
            .get("id").asLong();
        assertDecimal("0", getJson(token, "/api/me/gift-cards/" + cardId).get("currentBalance"));

        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        JsonNode reread = getJson(token, "/api/me/gift-cards/" + cardId);
        assertDecimal(cardAmt, reread.get("currentBalance"));
        JsonNode refund = txOfType(token, cardId, "REFUND");
        assertNotNull(refund);
        assertEquals("BOOKING", refund.get("referenceType").asText());
        assertEquals(bookingId, refund.get("referenceId").asLong());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 5. REDEMPTION-RULE REJECTIONS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void expiredGiftCardRejectedAtCheckout() throws Exception {
        LocalDate ci = TODAY.plusDays(39), co = ci.plusDays(1);
        baselinePrice(ci, co);

        JsonNode user = registerUser("gcc-expired");
        String token = user.get("token").asText();
        JsonNode card = issueAndActivate(token, new BigDecimal("200000"));
        Long cardId = card.get("id").asLong();
        String code = card.get("fullCode").asText();

        // Backdate the derived expiry directly (no public API sets an arbitrary expiry).
        var row = giftCardRepo.findById(cardId).orElseThrow();
        row.setExpiresAt(Instant.now().minusSeconds(60));
        giftCardRepo.save(row);

        book(token, bookingPayload(stdTwinRoomId, ci, co, code), status().isConflict());
        // Rejection burned nothing.
        assertDecimal("200000", getJson(token, "/api/me/gift-cards/" + cardId).get("currentBalance"));
    }

    @Test
    void cancelledGiftCardRejectedAtCheckout() throws Exception {
        LocalDate ci = TODAY.plusDays(42), co = ci.plusDays(1);
        baselinePrice(ci, co);

        JsonNode user = registerUser("gcc-cancelled");
        String token = user.get("token").asText();
        JsonNode card = issueAndActivate(token, new BigDecimal("200000"));
        Long cardId = card.get("id").asLong();
        String code = card.get("fullCode").asText();

        // Admin cancels the card (owned by the user, so ownership passes → status is the blocker).
        mvc.perform(post("/api/admin/gift-cards/" + cardId + "/cancel")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk());

        book(token, bookingPayload(stdTwinRoomId, ci, co, code), status().isConflict());
    }

    @Test
    void issuedButNotActivatedGiftCardRejectedAtCheckout() throws Exception {
        LocalDate ci = TODAY.plusDays(44), co = ci.plusDays(1);
        baselinePrice(ci, co);

        JsonNode user = registerUser("gcc-issued");
        String token = user.get("token").asText();
        // Issued but never activated → not redeemable.
        JsonNode card = issueCustomer(token, issuePayload(defaultProductCode("VND"), "200000"),
            status().isCreated());
        book(token, bookingPayload(stdTwinRoomId, ci, co, card.get("fullCode").asText()),
            status().isConflict());
    }

    @Test
    void currencyMismatchRejectedAtCheckout() throws Exception {
        LocalDate ci = TODAY.plusDays(47), co = ci.plusDays(1);
        baselinePrice(ci, co);

        // A USD product + activated USD card cannot pay a VND booking.
        String usdProduct = defaultProductCode("USD");
        JsonNode user = registerUser("gcc-currency");
        String token = user.get("token").asText();
        JsonNode card = issueCustomer(token, issuePayload(usdProduct, "200000"), status().isCreated());
        activateCustomer(token, card.get("id").asLong());

        book(token, bookingPayload(stdTwinRoomId, ci, co, card.get("fullCode").asText()),
            status().isBadRequest());
    }

    @Test
    void unrelatedUsersGiftCardIsNotFoundAtCheckout() throws Exception {
        LocalDate ci = TODAY.plusDays(50), co = ci.plusDays(1);
        baselinePrice(ci, co);

        JsonNode owner = registerUser("gcc-owner");
        JsonNode card = issueAndActivate(owner.get("token").asText(), new BigDecimal("200000"));
        String code = card.get("fullCode").asText();

        // A stranger who holds the code but neither purchased nor received it → 404 (existence never leaks).
        String stranger = registerUser("gcc-stranger").get("token").asText();
        book(stranger, bookingPayload(stdTwinRoomId, ci, co, code), status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 6. BOOKING PREVIEW
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void bookingPreviewReportsAppliedRemainingBalanceAndPayableWithoutMutating() throws Exception {
        LocalDate ci = TODAY.plusDays(53), co = ci.plusDays(2);
        BigDecimal base = baselinePrice(ci, co);
        BigDecimal cardAmt = base.multiply(BigDecimal.valueOf(2)).setScale(2, RoundingMode.HALF_UP);

        JsonNode user = registerUser("gcc-preview");
        String token = user.get("token").asText();
        JsonNode card = issueAndActivate(token, cardAmt);
        Long cardId = card.get("id").asLong();
        String code = card.get("fullCode").asText();

        // A plain booking (no gift card) whose payable we then preview against.
        Long bookingId = book(token, bookingPayload(stdTwinRoomId, ci, co, null), status().isCreated())
            .get("id").asLong();

        JsonNode preview = previewBooking(token, code, bookingId, status().isOk());
        assertTrue(preview.get("eligible").asBoolean());
        assertDecimal(base, preview.get("giftCardApplied"), "applies min(balance, payable)");
        assertDecimal(cardAmt.subtract(base), preview.get("remainingBalance"));
        assertDecimal("0", preview.get("remainingPayable"));

        // Preview never mutates the balance.
        assertDecimal(cardAmt, getJson(token, "/api/me/gift-cards/" + cardId).get("currentBalance"));

        // Unrelated / unknown card previews soft-ineligible (never 404 on this read-only endpoint).
        JsonNode ineligible = previewBooking(token, "PYT-GC-0000-0000-0000", bookingId, status().isOk());
        assertFalse(ineligible.get("eligible").asBoolean());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 7. LEGACY / REGRESSION / SECURITY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void bookingWithoutGiftCardBehavesExactlyAsBefore() throws Exception {
        LocalDate ci = TODAY.plusDays(56), co = ci.plusDays(2);
        BigDecimal base = baselinePrice(ci, co);

        String token = registerUser("gcc-legacy").get("token").asText();
        // Pre-7.25 payload shape — no giftCardCode key at all.
        String legacyPayload = String.format(
            "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\"," +
            "\"adults\":2,\"children\":0,\"numberOfRooms\":1,\"specialRequest\":null}",
            stdTwinRoomId, ci, co);
        JsonNode res = book(token, legacyPayload, status().isCreated());

        assertDecimal(base, res.get("finalPrice"));
        assertTrue(res.get("giftCardAmountUsed").isNull());
        assertTrue(res.get("giftCardReference").isNull());
    }

    @Test
    void unauthenticatedBookingPreviewRejected() throws Exception {
        mvc.perform(post("/api/me/gift-cards/preview-booking")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"giftCardCode\":\"PYT-GC-0000-0000-0000\",\"bookingId\":1}"))
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

    /** Baseline promotion-discounted total for these dates (mirrors CheckoutCouponCreditTest). */
    private BigDecimal baselinePrice(LocalDate ci, LocalDate co) throws Exception {
        String token = registerUser("gcc-baseline").get("token").asText();
        JsonNode res = book(token, bookingPayload(stdTwinRoomId, ci, co, null), status().isCreated());
        BigDecimal price = new BigDecimal(res.get("finalPrice").asText());
        assertTrue(price.signum() > 0, "baseline price must be positive");
        return price;
    }

    /** Creates a throwaway custom-amount product (currency-parameterised) and returns its code. */
    private String defaultProductCode(String currency) throws Exception {
        String code = ("GCC-PROD-" + currency + "-" + counter.getAndIncrement()).toUpperCase();
        String payload = String.format("""
            {"productCode":"%s","name":"Checkout gift %s","description":"Phase 7.25 test product",
             "currency":"%s","fixedAmount":null,"minimumAmount":10000,"maximumAmount":50000000,
             "customAmountAllowed":true,"validDaysAfterActivation":365,"active":true,
             "validFrom":null,"validUntil":null}
            """, code, code, currency);
        mvc.perform(post("/api/admin/gift-card-products")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isCreated());
        return code;
    }

    /** Issues a VND custom-amount card to the caller and activates it. */
    private JsonNode issueAndActivate(String token, BigDecimal amount) throws Exception {
        String product = defaultProductCode("VND");
        JsonNode card = issueCustomer(token, issuePayload(product, amount.toPlainString()), status().isCreated());
        activateCustomer(token, card.get("id").asLong());
        return card;
    }

    private String issuePayload(String productCode, String amount) {
        return String.format("""
            {"productCode":"%s","amount":%s,"recipientUserId":null,"recipientEmail":null,
             "personalMessage":null,"idempotencyKey":null}
            """, productCode, amount);
    }

    private JsonNode issueCustomer(String token, String payload, ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/me/gift-cards/issue")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
    }

    private void activateCustomer(String token, Long id) throws Exception {
        mvc.perform(post("/api/me/gift-cards/" + id + "/activate")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
    }

    private String bookingPayload(Long roomId, LocalDate ci, LocalDate co, String giftCardCode) {
        return String.format(
            "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\"," +
            "\"adults\":2,\"children\":0,\"numberOfRooms\":1,\"specialRequest\":null," +
            "\"giftCardCode\":%s}",
            roomId, ci, co,
            giftCardCode == null ? "null" : "\"" + giftCardCode + "\"");
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

    private JsonNode createPayment(String token, Long bookingId) throws Exception {
        String body = mvc.perform(post("/api/payments")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"paymentMethod\":\"MOCK\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode previewBooking(String token, String code, Long bookingId, ResultMatcher expected)
            throws Exception {
        String body = mvc.perform(post("/api/me/gift-cards/preview-booking")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"giftCardCode\":\"" + code + "\",\"bookingId\":" + bookingId + "}"))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
    }

    private JsonNode getJson(String token, String url) throws Exception {
        String body = mvc.perform(get(url).header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode txOfType(String token, Long cardId, String type) throws Exception {
        JsonNode page = getJson(token, "/api/me/gift-cards/" + cardId + "/transactions");
        for (JsonNode t : page.get("content"))
            if (type.equals(t.get("transactionType").asText())) return t;
        return null;
    }

    private int countTxOfType(String token, Long cardId, String type) throws Exception {
        JsonNode page = getJson(token, "/api/me/gift-cards/" + cardId + "/transactions");
        int n = 0;
        for (JsonNode t : page.get("content"))
            if (type.equals(t.get("transactionType").asText())) n++;
        return n;
    }

    private void assertDecimal(String expected, JsonNode actual) {
        assertDecimal(new BigDecimal(expected), actual, null);
    }

    private void assertDecimal(String expected, JsonNode actual, String message) {
        assertDecimal(new BigDecimal(expected), actual, message);
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
