package com.example.planyourtrip;

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
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * CouponCreditLifecycleTest — Phase 7.16 (Coupon &amp; Credit Lifecycle
 * Completion). Covers the refund-to-credits flow for cancelled paid bookings
 * (REFUND_CREDIT ledger row with deterministic idempotency, booking/payment →
 * REFUNDED, full rollback on failure), admin-triggered credit expiration
 * processing (FIFO unconsumed computation, per-grant idempotency across runs),
 * admin coupon revocation (terminal REVOKED, total-usage slot freed, checkout
 * rejection) and invoice surfacing of coupon/credit discount lines. Amounts
 * for booking flows are never hard-coded — every expectation is derived from
 * the observed booking/payment responses, so seeded prices and promotions can
 * change freely.
 */
@SpringBootTest
@AutoConfigureMockMvc
class CouponCreditLifecycleTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;

    private static final AtomicInteger counter = new AtomicInteger(1);
    private static final LocalDate TODAY = LocalDate.now();

    private Long stdTwinRoomId;

    @BeforeEach
    void setup() {
        // Same seeded-room resolution as CheckoutCouponCreditTest (Phase 7.15).
        Long placeId  = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        stdTwinRoomId = hotelRoomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "STD-TWIN".equals(r.getRoomCode()))
            .findFirst().orElseThrow().getId();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 1. REFUND-TO-CREDITS (cancelled paid booking → promotional credits)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void refundToCreditsGrantsCreditsAndMarksBookingAndPaymentRefunded() throws Exception {
        LocalDate ci = TODAY.plusDays(85), co = ci.plusDays(1);
        JsonNode user = registerUser("lc-refund");
        String token = user.get("token").asText();

        JsonNode booking = book(token, bookingPayload(stdTwinRoomId, ci, co, null, null),
            status().isCreated());
        Long bookingId = booking.get("id").asLong();
        BigDecimal paid = new BigDecimal(booking.get("finalPrice").asText());

        Long paymentId = payAndSucceed(token, bookingId, paid);
        cancel(token, bookingId, status().isOk());

        JsonNode refunded = postAdmin("/api/admin/bookings/" + bookingId + "/refund-to-credits",
            status().isOk());
        assertEquals("REFUNDED", refunded.get("status").asText());

        // Booking and payment both flipped to REFUNDED.
        assertEquals("REFUNDED", getJson(token, "/api/bookings/" + bookingId).get("status").asText());
        JsonNode payment = getJson(adminToken(), "/api/admin/payments/" + paymentId);
        assertEquals("REFUNDED", payment.get("status").asText());
        assertFalse(payment.get("refundedAt").isNull());

        // Exactly the paid amount arrived as credits, via one REFUND_CREDIT row.
        assertDecimal(paid, getJson(token, "/api/me/travel-credits").get("balance"));
        JsonNode rows = getJson(token, "/api/me/travel-credits/transactions?type=REFUND_CREDIT")
            .get("content");
        assertEquals(1, rows.size());
        JsonNode tx = rows.get(0);
        assertDecimal(paid, tx.get("amount"));
        assertEquals("REFUND", tx.get("referenceType").asText());
        assertEquals(paymentId, tx.get("referenceId").asLong());
        assertEquals("booking-" + bookingId + "-refund-credit", tx.get("idempotencyKey").asText());

        // Both the booking-level and the credit-level notifications were sent.
        List<String> titles = notificationTitles(token);
        assertTrue(titles.contains("Booking refunded"), "booking refund notification expected");
        assertTrue(titles.contains("Travel credits added"), "credit grant notification expected");
    }

    @Test
    void refundToCreditsRejectedUnlessBookingCancelled() throws Exception {
        LocalDate ci = TODAY.plusDays(85), co = ci.plusDays(1);
        String token = registerUser("lc-notcancelled").get("token").asText();

        JsonNode booking = book(token, bookingPayload(stdTwinRoomId, ci, co, null, null),
            status().isCreated());
        Long bookingId = booking.get("id").asLong();

        // PENDING — not refundable.
        postAdmin("/api/admin/bookings/" + bookingId + "/refund-to-credits",
            status().isUnprocessableEntity());

        // CONFIRMED (paid) — still not refundable until cancelled.
        payAndSucceed(token, bookingId, new BigDecimal(booking.get("finalPrice").asText()));
        postAdmin("/api/admin/bookings/" + bookingId + "/refund-to-credits",
            status().isUnprocessableEntity());

        // Unknown booking — 404.
        postAdmin("/api/admin/bookings/99999999/refund-to-credits", status().isNotFound());

        assertDecimal(BigDecimal.ZERO, getJson(token, "/api/me/travel-credits").get("balance"));
    }

    @Test
    void refundToCreditsWithoutPaidPaymentRejected() throws Exception {
        LocalDate ci = TODAY.plusDays(86), co = ci.plusDays(1);
        String token = registerUser("lc-unpaid").get("token").asText();

        Long bookingId = book(token, bookingPayload(stdTwinRoomId, ci, co, null, null),
            status().isCreated()).get("id").asLong();
        cancel(token, bookingId, status().isOk());

        // Cancelled but never paid — nothing to refund.
        postAdmin("/api/admin/bookings/" + bookingId + "/refund-to-credits",
            status().isUnprocessableEntity());

        assertEquals("CANCELLED", getJson(token, "/api/bookings/" + bookingId).get("status").asText());
        assertDecimal(BigDecimal.ZERO, getJson(token, "/api/me/travel-credits").get("balance"));
    }

    @Test
    void refundToCreditsCannotRunTwiceOrDoubleCredit() throws Exception {
        LocalDate ci = TODAY.plusDays(86), co = ci.plusDays(1);
        String token = registerUser("lc-twice").get("token").asText();

        JsonNode booking = book(token, bookingPayload(stdTwinRoomId, ci, co, null, null),
            status().isCreated());
        Long bookingId = booking.get("id").asLong();
        BigDecimal paid = new BigDecimal(booking.get("finalPrice").asText());

        payAndSucceed(token, bookingId, paid);
        cancel(token, bookingId, status().isOk());
        postAdmin("/api/admin/bookings/" + bookingId + "/refund-to-credits", status().isOk());

        // Repeat trigger is rejected at the state gate and credits nothing.
        postAdmin("/api/admin/bookings/" + bookingId + "/refund-to-credits",
            status().isUnprocessableEntity());

        assertDecimal(paid, getJson(token, "/api/me/travel-credits").get("balance"));
        assertEquals(1, getJson(token, "/api/me/travel-credits/transactions?type=REFUND_CREDIT")
            .get("content").size());
    }

    @Test
    void refundToCreditsAfterCashRefundRejected() throws Exception {
        LocalDate ci = TODAY.plusDays(87), co = ci.plusDays(1);
        String token = registerUser("lc-cash").get("token").asText();

        JsonNode booking = book(token, bookingPayload(stdTwinRoomId, ci, co, null, null),
            status().isCreated());
        Long bookingId = booking.get("id").asLong();
        Long paymentId = payAndSucceed(token, bookingId,
            new BigDecimal(booking.get("finalPrice").asText()));
        cancel(token, bookingId, status().isOk());

        // Payment already refunded through the pre-existing cash-refund path.
        mvc.perform(post("/api/admin/payments/" + paymentId + "/refund")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk());

        // One refund path per payment — refund-to-credits finds no PAID payment.
        postAdmin("/api/admin/bookings/" + bookingId + "/refund-to-credits",
            status().isUnprocessableEntity());
        assertDecimal(BigDecimal.ZERO, getJson(token, "/api/me/travel-credits").get("balance"));
    }

    @Test
    void refundToCreditsCurrencyMismatchRollsBackAtomically() throws Exception {
        LocalDate ci = TODAY.plusDays(87), co = ci.plusDays(1);
        String token = registerUser("lc-usd").get("token").asText();

        // Give the user a USD credit account BEFORE the refund attempt.
        mvc.perform(put("/api/me/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"preferredCurrency\":\"USD\",\"marketingConsent\":false}"))
            .andExpect(status().isOk());
        assertEquals("USD", getJson(token, "/api/me/travel-credits").get("currency").asText());

        JsonNode booking = book(token, bookingPayload(stdTwinRoomId, ci, co, null, null),
            status().isCreated());
        Long bookingId = booking.get("id").asLong();
        Long paymentId = payAndSucceed(token, bookingId,
            new BigDecimal(booking.get("finalPrice").asText()));
        cancel(token, bookingId, status().isOk());

        // VND payment vs USD account → 400, and NOTHING is left half-done.
        postAdmin("/api/admin/bookings/" + bookingId + "/refund-to-credits",
            status().isBadRequest());

        assertEquals("CANCELLED", getJson(token, "/api/bookings/" + bookingId).get("status").asText(),
            "booking must stay CANCELLED after the failed refund");
        assertEquals("PAID",
            getJson(adminToken(), "/api/admin/payments/" + paymentId).get("status").asText(),
            "payment must stay PAID after the failed refund");
        assertDecimal(BigDecimal.ZERO, getJson(token, "/api/me/travel-credits").get("balance"));
        assertEquals(0, getJson(token, "/api/me/travel-credits/transactions?type=REFUND_CREDIT")
            .get("content").size());
    }

    @Test
    void refundToCreditsRequiresAdmin() throws Exception {
        LocalDate ci = TODAY.plusDays(88), co = ci.plusDays(1);
        String token = registerUser("lc-refauth").get("token").asText();

        JsonNode booking = book(token, bookingPayload(stdTwinRoomId, ci, co, null, null),
            status().isCreated());
        Long bookingId = booking.get("id").asLong();
        payAndSucceed(token, bookingId, new BigDecimal(booking.get("finalPrice").asText()));
        cancel(token, bookingId, status().isOk());

        // Even the booking's owner cannot trigger the refund — admin only.
        mvc.perform(post("/api/admin/bookings/" + bookingId + "/refund-to-credits")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
        mvc.perform(post("/api/admin/bookings/" + bookingId + "/refund-to-credits"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void cancellationReversalAndRefundToCreditsStackCorrectly() throws Exception {
        LocalDate ci = TODAY.plusDays(88), co = ci.plusDays(1);
        JsonNode user = registerUser("lc-stack");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();

        BigDecimal grant = new BigDecimal("200000.00");
        BigDecimal use = new BigDecimal("50000.00");
        grantCredits(userId, grant.toPlainString(), null);

        JsonNode booking = book(token,
            bookingPayload(stdTwinRoomId, ci, co, null, use.toPlainString()), status().isCreated());
        Long bookingId = booking.get("id").asLong();
        BigDecimal paid = new BigDecimal(booking.get("finalPrice").asText()); // total minus credits

        payAndSucceed(token, bookingId, paid);
        cancel(token, bookingId, status().isOk());
        // Cancellation already restored the redeemed credits (REVERSAL).
        assertDecimal(grant, getJson(token, "/api/me/travel-credits").get("balance"));

        postAdmin("/api/admin/bookings/" + bookingId + "/refund-to-credits", status().isOk());

        // Refund adds ONLY the money actually paid — no double count of the
        // credits that the reversal already restored.
        assertDecimal(grant.add(paid), getJson(token, "/api/me/travel-credits").get("balance"));
        assertEquals(1, getJson(token, "/api/me/travel-credits/transactions?type=REVERSAL")
            .get("content").size());
        assertEquals(1, getJson(token, "/api/me/travel-credits/transactions?type=REFUND_CREDIT")
            .get("content").size());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 2. CREDIT EXPIRATION PROCESSING (admin manual trigger)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void processExpirationsExpiresUnconsumedExpiredGrant() throws Exception {
        JsonNode user = registerUser("lc-expire");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        Long accountId = getJson(token, "/api/me/travel-credits").get("id").asLong();

        BigDecimal amount = new BigDecimal("100000.00");
        Long grantTxId = grantCredits(userId, amount.toPlainString(),
            TODAY.minusDays(1)).get("id").asLong();
        assertDecimal(amount, getJson(token, "/api/me/travel-credits").get("balance"));

        JsonNode run = postAdmin("/api/admin/travel-credits/process-expirations", status().isOk());
        List<JsonNode> mine = expirationsForAccount(run, accountId);
        assertEquals(1, mine.size());
        JsonNode tx = mine.get(0);
        assertEquals("EXPIRATION", tx.get("transactionType").asText());
        assertDecimal(amount, tx.get("amount"));
        assertEquals("SYSTEM", tx.get("referenceType").asText());
        assertEquals(grantTxId, tx.get("referenceId").asLong());
        assertEquals("credit-tx-" + grantTxId + "-expiration", tx.get("idempotencyKey").asText());

        assertDecimal(BigDecimal.ZERO, getJson(token, "/api/me/travel-credits").get("balance"));
        assertTrue(notificationTitles(token).contains("Travel credits expired"),
            "expiration notification expected");
    }

    @Test
    void processExpirationsIsIdempotentAcrossRuns() throws Exception {
        JsonNode user = registerUser("lc-exp-idem");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        Long accountId = getJson(token, "/api/me/travel-credits").get("id").asLong();

        grantCredits(userId, "50000.00", TODAY.minusDays(2));

        JsonNode firstRun = postAdmin("/api/admin/travel-credits/process-expirations", status().isOk());
        assertEquals(1, expirationsForAccount(firstRun, accountId).size());

        JsonNode secondRun = postAdmin("/api/admin/travel-credits/process-expirations", status().isOk());
        assertEquals(0, expirationsForAccount(secondRun, accountId).size(),
            "an already-processed grant must not expire twice");

        assertDecimal(BigDecimal.ZERO, getJson(token, "/api/me/travel-credits").get("balance"));
        assertEquals(1, getJson(token, "/api/me/travel-credits/transactions?type=EXPIRATION")
            .get("content").size());
    }

    @Test
    void processExpirationsLeavesUnexpiredAndPerpetualGrantsUntouched() throws Exception {
        JsonNode user = registerUser("lc-exp-keep");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        Long accountId = getJson(token, "/api/me/travel-credits").get("id").asLong();

        grantCredits(userId, "40000.00", TODAY.plusDays(30)); // future expiry
        grantCredits(userId, "60000.00", null);               // never expires
        grantCredits(userId, "10000.00", TODAY);              // valid THROUGH today

        JsonNode run = postAdmin("/api/admin/travel-credits/process-expirations", status().isOk());
        assertEquals(0, expirationsForAccount(run, accountId).size());
        assertDecimal(new BigDecimal("110000.00"), getJson(token, "/api/me/travel-credits").get("balance"));
    }

    @Test
    void processExpirationsExpiresOnlyUnredeemedPortion() throws Exception {
        JsonNode user = registerUser("lc-exp-part");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        Long accountId = getJson(token, "/api/me/travel-credits").get("id").asLong();

        grantCredits(userId, "100000.00", TODAY.minusDays(1));
        deductCredits(userId, "30000.00"); // 30k already spent before expiry processing

        JsonNode run = postAdmin("/api/admin/travel-credits/process-expirations", status().isOk());
        List<JsonNode> mine = expirationsForAccount(run, accountId);
        assertEquals(1, mine.size());
        assertDecimal(new BigDecimal("70000.00"), mine.get(0).get("amount"));
        assertDecimal(BigDecimal.ZERO, getJson(token, "/api/me/travel-credits").get("balance"));
    }

    @Test
    void processExpirationsNeverTouchesCreditsGrantedAfterExpiredOnes() throws Exception {
        JsonNode user = registerUser("lc-exp-fifo");
        String token = user.get("token").asText();
        Long userId = user.get("user").get("id").asLong();
        Long accountId = getJson(token, "/api/me/travel-credits").get("id").asLong();

        grantCredits(userId, "100000.00", TODAY.minusDays(1)); // expired, but…
        grantCredits(userId, "50000.00", null);                // newer, never expires
        deductCredits(userId, "120000.00"); // FIFO: consumes all 100k expired + 20k of the newer

        JsonNode run = postAdmin("/api/admin/travel-credits/process-expirations", status().isOk());
        assertEquals(0, expirationsForAccount(run, accountId).size(),
            "a fully-consumed expired grant must expire nothing");
        assertDecimal(new BigDecimal("30000.00"), getJson(token, "/api/me/travel-credits").get("balance"),
            "the remaining balance belongs to the newer grant and must survive");
    }

    @Test
    void processExpirationsHandlesMultipleAccountsInOneRun() throws Exception {
        JsonNode u1 = registerUser("lc-exp-multi1");
        JsonNode u2 = registerUser("lc-exp-multi2");
        String t1 = u1.get("token").asText(), t2 = u2.get("token").asText();
        Long a1 = getJson(t1, "/api/me/travel-credits").get("id").asLong();
        Long a2 = getJson(t2, "/api/me/travel-credits").get("id").asLong();

        grantCredits(u1.get("user").get("id").asLong(), "25000.00", TODAY.minusDays(3));
        grantCredits(u2.get("user").get("id").asLong(), "35000.00", TODAY.minusDays(3));

        JsonNode run = postAdmin("/api/admin/travel-credits/process-expirations", status().isOk());
        assertEquals(1, expirationsForAccount(run, a1).size());
        assertEquals(1, expirationsForAccount(run, a2).size());
        assertTrue(run.get("accountsAffected").asInt() >= 2);
        assertTrue(run.get("transactionsExpired").asInt() >= 2);
        assertTrue(new BigDecimal(run.get("totalAmountExpired").asText())
            .compareTo(new BigDecimal("60000.00")) >= 0);

        assertDecimal(BigDecimal.ZERO, getJson(t1, "/api/me/travel-credits").get("balance"));
        assertDecimal(BigDecimal.ZERO, getJson(t2, "/api/me/travel-credits").get("balance"));
    }

    @Test
    void processExpirationsRequiresAdminRole() throws Exception {
        String token = registerUser("lc-exp-auth").get("token").asText();
        mvc.perform(post("/api/admin/travel-credits/process-expirations")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
        mvc.perform(post("/api/admin/travel-credits/process-expirations"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 3. ADMIN COUPON REVOCATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void adminRevokeMakesCouponRevokedAndFreesTotalUsageSlot() throws Exception {
        String code = uniqueCode("revoke");
        createCouponDef(code, "PERCENTAGE", "10", null, null, 1); // totalUsageLimit = 1

        JsonNode u1 = registerUser("lc-revoke1");
        String t1 = u1.get("token").asText();
        Long uid1 = u1.get("user").get("id").asLong();
        Long couponId = claim(t1, code, status().isCreated()).get("id").asLong();

        // Total pool exhausted — a second user cannot claim.
        JsonNode u2 = registerUser("lc-revoke2");
        String t2 = u2.get("token").asText();
        claim(t2, code, status().isConflict());

        JsonNode revoked = postAdmin("/api/admin/users/" + uid1 + "/coupons/" + couponId + "/revoke",
            status().isOk());
        assertEquals("REVOKED", revoked.get("status").asText());
        assertEquals("REVOKED", revoked.get("effectiveStatus").asText());
        assertEquals(0, revoked.get("coupon").get("currentUsageCount").asInt(),
            "revocation must free the total-usage slot");

        // The freed slot is claimable by another customer…
        claim(t2, code, status().isCreated());
        // …but the revoked user cannot simply re-claim (punitive by design).
        claim(t1, code, status().isConflict());

        assertTrue(notificationTitles(t1).contains("Coupon revoked"),
            "revocation notification expected");
    }

    @Test
    void revokedCouponRejectedAtCheckoutAndIneligibleInPreview() throws Exception {
        LocalDate ci = TODAY.plusDays(85), co = ci.plusDays(1);
        String code = uniqueCode("revuse");
        createCouponDef(code, "PERCENTAGE", "10", null, null, null);

        JsonNode user = registerUser("lc-revuse");
        String token = user.get("token").asText();
        Long uid = user.get("user").get("id").asLong();
        Long couponId = claim(token, code, status().isCreated()).get("id").asLong();

        postAdmin("/api/admin/users/" + uid + "/coupons/" + couponId + "/revoke", status().isOk());

        // Checkout: claimed but no AVAILABLE instance → 409.
        book(token, bookingPayload(stdTwinRoomId, ci, co, code, null), status().isConflict());

        // Preview: ineligible with the REVOKED status surfaced.
        String previewBody = mvc.perform(post("/api/me/coupons/" + couponId + "/preview")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"orderAmount\":1000000}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode preview = mapper.readTree(previewBody);
        assertFalse(preview.get("eligible").asBoolean());
        assertTrue(preview.get("reason").asText().contains("REVOKED"));
    }

    @Test
    void revokeRejectedForUsedOrAlreadyRevokedCoupon() throws Exception {
        LocalDate ci = TODAY.plusDays(85), co = ci.plusDays(1);

        // (a) USED coupon — history attached to a booking, cannot be revoked.
        String usedCode = uniqueCode("revused");
        createCouponDef(usedCode, "PERCENTAGE", "10", null, null, null);
        JsonNode user = registerUser("lc-revused");
        String token = user.get("token").asText();
        Long uid = user.get("user").get("id").asLong();
        Long usedId = claim(token, usedCode, status().isCreated()).get("id").asLong();
        book(token, bookingPayload(stdTwinRoomId, ci, co, usedCode, null), status().isCreated());
        postAdmin("/api/admin/users/" + uid + "/coupons/" + usedId + "/revoke",
            status().isConflict());

        // (b) double revoke — the second call is a 409 repeat.
        String twiceCode = uniqueCode("revtwice");
        createCouponDef(twiceCode, "PERCENTAGE", "10", null, null, null);
        Long twiceId = claim(token, twiceCode, status().isCreated()).get("id").asLong();
        postAdmin("/api/admin/users/" + uid + "/coupons/" + twiceId + "/revoke", status().isOk());
        postAdmin("/api/admin/users/" + uid + "/coupons/" + twiceId + "/revoke",
            status().isConflict());
    }

    @Test
    void revokeReturns404ForWrongUserOrUnknownCoupon() throws Exception {
        String code = uniqueCode("rev404");
        createCouponDef(code, "PERCENTAGE", "10", null, null, null);

        JsonNode owner = registerUser("lc-rev404a");
        JsonNode other = registerUser("lc-rev404b");
        Long ownerId = owner.get("user").get("id").asLong();
        Long otherId = other.get("user").get("id").asLong();
        Long couponId = claim(owner.get("token").asText(), code, status().isCreated())
            .get("id").asLong();

        // Existing coupon under the WRONG user's path — 404, never 403.
        postAdmin("/api/admin/users/" + otherId + "/coupons/" + couponId + "/revoke",
            status().isNotFound());
        // Unknown coupon id — 404.
        postAdmin("/api/admin/users/" + ownerId + "/coupons/99999999/revoke",
            status().isNotFound());
        // Unknown user id — 404.
        postAdmin("/api/admin/users/99999999/coupons/" + couponId + "/revoke",
            status().isNotFound());

        // The coupon survived all of it.
        assertEquals("AVAILABLE", getJson(owner.get("token").asText(),
            "/api/me/coupons/" + couponId).get("status").asText());
    }

    @Test
    void revokeRequiresAdmin() throws Exception {
        String code = uniqueCode("revauth");
        createCouponDef(code, "PERCENTAGE", "10", null, null, null);
        JsonNode user = registerUser("lc-revauth");
        String token = user.get("token").asText();
        Long uid = user.get("user").get("id").asLong();
        Long couponId = claim(token, code, status().isCreated()).get("id").asLong();

        // The coupon's own owner cannot revoke it — admin only.
        mvc.perform(post("/api/admin/users/" + uid + "/coupons/" + couponId + "/revoke")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
        mvc.perform(post("/api/admin/users/" + uid + "/coupons/" + couponId + "/revoke"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 4. INVOICE DISCOUNT SURFACING
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void invoiceSurfacesCouponAndCreditDiscountLines() throws Exception {
        LocalDate ci = TODAY.plusDays(86), co = ci.plusDays(1);
        String code = uniqueCode("invoice");
        createCouponDef(code, "FIXED_AMOUNT", "100000", null, null, null);

        JsonNode user = registerUser("lc-invoice");
        String token = user.get("token").asText();
        Long uid = user.get("user").get("id").asLong();
        claim(token, code, status().isCreated());
        grantCredits(uid, "50000.00", null);

        JsonNode booking = book(token,
            bookingPayload(stdTwinRoomId, ci, co, code, "50000.00"), status().isCreated());
        Long bookingId = booking.get("id").asLong();
        Long paymentId = payAndSucceed(token, bookingId,
            new BigDecimal(booking.get("finalPrice").asText()));

        String invBody = mvc.perform(post("/api/invoices")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"paymentId\":" + paymentId + "}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        JsonNode invoice = mapper.readTree(invBody);

        // New itemized lines mirror the booking exactly.
        assertEquals(code, invoice.get("couponCode").asText());
        assertDecimal(new BigDecimal(booking.get("couponDiscountAmount").asText()),
            invoice.get("couponDiscountAmount"));
        assertDecimal(new BigDecimal("50000.00"), invoice.get("creditAmountUsed"));
        // Pre-existing lines unchanged: promotion discount + paid total.
        assertDecimal(new BigDecimal(booking.get("discountAmount").asText()),
            invoice.get("discountAmount"));
        assertDecimal(new BigDecimal(booking.get("finalPrice").asText()),
            invoice.get("totalAmount"));

        // Subsequent GET surfaces the same lines.
        JsonNode fetched = getJson(token, "/api/invoices/" + invoice.get("id").asLong());
        assertEquals(code, fetched.get("couponCode").asText());
        assertDecimal(new BigDecimal(booking.get("couponDiscountAmount").asText()),
            fetched.get("couponDiscountAmount"));
        assertDecimal(new BigDecimal("50000.00"), fetched.get("creditAmountUsed"));
    }

    @Test
    void invoiceWithoutCouponOrCreditsKeepsNewFieldsNull() throws Exception {
        LocalDate ci = TODAY.plusDays(87), co = ci.plusDays(1);
        String token = registerUser("lc-plaininv").get("token").asText();

        JsonNode booking = book(token, bookingPayload(stdTwinRoomId, ci, co, null, null),
            status().isCreated());
        Long bookingId = booking.get("id").asLong();
        Long paymentId = payAndSucceed(token, bookingId,
            new BigDecimal(booking.get("finalPrice").asText()));

        String invBody = mvc.perform(post("/api/invoices")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"paymentId\":" + paymentId + "}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        JsonNode invoice = mapper.readTree(invBody);

        assertTrue(invoice.get("couponCode").isNull());
        assertTrue(invoice.get("couponDiscountAmount").isNull());
        assertTrue(invoice.get("creditAmountUsed").isNull());
        // Legacy fields regression: still present and non-null.
        assertFalse(invoice.get("subtotal").isNull());
        assertFalse(invoice.get("discountAmount").isNull());
        assertFalse(invoice.get("totalAmount").isNull());
        assertDecimal(new BigDecimal(booking.get("finalPrice").asText()),
            invoice.get("totalAmount"));
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

    private void cancel(String token, Long bookingId, ResultMatcher expected) throws Exception {
        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + token))
            .andExpect(expected);
    }

    /** Creates a MOCK payment for the booking, asserts its amount, marks it PAID. */
    private Long payAndSucceed(String token, Long bookingId, BigDecimal expectedAmount) throws Exception {
        String payBody = mvc.perform(post("/api/payments")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"paymentMethod\":\"MOCK\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        JsonNode payment = mapper.readTree(payBody);
        assertDecimal(expectedAmount, payment.get("amount"));
        Long paymentId = payment.get("id").asLong();
        mvc.perform(post("/api/payments/" + paymentId + "/mock-success")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}"))
            .andExpect(status().isOk());
        return paymentId;
    }

    private JsonNode createCouponDef(String code, String discountType, String discountValue,
                                      String maxDiscountAmount, String minimumSpend,
                                      Integer totalUsageLimit) throws Exception {
        String payload = String.format("""
                {"code":"%s","name":"Lifecycle %s","description":"Phase 7.16 test coupon",
                 "discountType":"%s","discountValue":%s,"maxDiscountAmount":%s,"minimumSpend":%s,
                 "validFrom":"%s","validUntil":"%s","active":true,"totalUsageLimit":%s,"usageLimitPerUser":1}
                """,
            code, code, discountType, discountValue,
            maxDiscountAmount == null ? "null" : maxDiscountAmount,
            minimumSpend == null ? "null" : minimumSpend,
            TODAY.minusDays(1), TODAY.plusDays(60),
            totalUsageLimit == null ? "null" : totalUsageLimit.toString());
        String body = mvc.perform(post("/api/admin/coupon-definitions")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode claim(String token, String code, ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/me/coupons/claim")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"" + code + "\"}"))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
    }

    /** Admin grant; {@code expiresAt} null = perpetual. Returns the ledger row. */
    private JsonNode grantCredits(Long userId, String amount, LocalDate expiresAt) throws Exception {
        String body = mvc.perform(post("/api/admin/users/" + userId + "/travel-credits/grant")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"amount\":" + amount + ",\"currency\":\"VND\"," +
                         "\"description\":\"Phase 7.16 test grant\"," +
                         "\"expiresAt\":" + (expiresAt == null ? "null" : "\"" + expiresAt + "\"") + "}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private void deductCredits(Long userId, String amount) throws Exception {
        mvc.perform(post("/api/admin/users/" + userId + "/travel-credits/deduct")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"amount\":" + amount + ",\"currency\":\"VND\"," +
                         "\"description\":\"Phase 7.16 test deduction\"}"))
            .andExpect(status().isCreated());
    }

    /** POST with the admin token; returns the parsed body (null when empty). */
    private JsonNode postAdmin(String url, ResultMatcher expected) throws Exception {
        String body = mvc.perform(post(url)
                .header("Authorization", "Bearer " + adminToken()))
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

    /**
     * The sweep is system-wide and other tests may leave their own candidates,
     * so run-result assertions are always filtered down to the account under test.
     */
    private List<JsonNode> expirationsForAccount(JsonNode run, Long accountId) {
        List<JsonNode> mine = new ArrayList<>();
        for (JsonNode tx : run.get("expirations")) {
            if (tx.get("accountId").asLong() == accountId) mine.add(tx);
        }
        return mine;
    }

    private List<String> notificationTitles(String token) throws Exception {
        List<String> titles = new ArrayList<>();
        for (JsonNode n : getJson(token, "/api/me/notifications")) {
            titles.add(n.get("title").asText());
        }
        return titles;
    }

    private String uniqueCode(String prefix) {
        return ("LC-" + prefix + "-" + counter.getAndIncrement()).toUpperCase();
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
