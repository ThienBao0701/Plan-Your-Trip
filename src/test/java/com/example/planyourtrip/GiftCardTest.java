package com.example.planyourtrip;

import com.example.planyourtrip.repository.GiftCardRepository;
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
import java.time.Instant;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * GiftCardTest — Phase 7.24 (Gift Cards Foundation).
 * Covers admin gift-card product CRUD, mock/internal issuance (self, to a
 * registered recipient, to an unregistered email), the unique masked
 * redeemable code, the immutable ISSUE/ACTIVATE/ADJUSTMENT/CANCELLATION/
 * EXPIRATION ledger, activation/claim (including idempotency and wrong-user
 * rejection), ownership-scoped reads (404 — never 403 — for unrelated users),
 * the read-only redemption preview, admin credit/debit adjustment,
 * cancellation, the manual expiration processor, notifications (amount/currency
 * only — never the full code), security and the seeded standard product.
 * Every scenario registers its own throwaway user(s)/product so state never
 * leaks across tests — mirrors TravelCreditTest's conventions.
 */
@SpringBootTest
@AutoConfigureMockMvc
class GiftCardTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired GiftCardRepository giftCardRepo;

    private static final AtomicInteger counter = new AtomicInteger(1);

    // ═══════════════════════════════════════════════════════════════════════════
    // 1-3: ADMIN PRODUCT CRUD / VALIDATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void adminCreatesGiftCardProduct() throws Exception {
        String code = uniqueCode("PRODCREATE");
        JsonNode res = createProduct(productPayload(code, "Test Product", "VND",
            null, "50000", "500000", true, 180, true, null, null), status().isCreated());

        assertEquals(code, res.get("productCode").asText());
        assertEquals("VND", res.get("currency").asText());
        assertTrue(res.get("customAmountAllowed").asBoolean());
        assertTrue(res.get("active").asBoolean());
        assertEquals(180, res.get("validDaysAfterActivation").asInt());
        assertDecimal("50000", res.get("minimumAmount"));
        assertDecimal("500000", res.get("maximumAmount"));
    }

    @Test
    void duplicateProductCodeRejectedCaseInsensitively() throws Exception {
        String code = uniqueCode("PRODDUP");
        createProduct(productPayload(code, "Original", "VND", null, "1000", "100000",
            true, 365, true, null, null), status().isCreated());

        mvc.perform(post("/api/admin/gift-card-products")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(productPayload(code.toLowerCase(), "Dup attempt", "VND", null, "1000", "100000",
                    true, 365, true, null, null)))
            .andExpect(status().isConflict());
    }

    @Test
    void invalidProductAmountRulesRejected() throws Exception {
        // maximumAmount < minimumAmount
        mvc.perform(post("/api/admin/gift-card-products")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(productPayload(uniqueCode("BADMAX"), "Bad max", "VND", null, "500000", "100000",
                    true, 365, true, null, null)))
            .andExpect(status().isBadRequest());

        // fixedAmount outside min/max range
        mvc.perform(post("/api/admin/gift-card-products")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(productPayload(uniqueCode("BADFIXED"), "Bad fixed", "VND", "50000", "100000", "200000",
                    true, 365, true, null, null)))
            .andExpect(status().isBadRequest());

        // customAmountAllowed=false without a fixedAmount
        mvc.perform(post("/api/admin/gift-card-products")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(productPayload(uniqueCode("NOFIXED"), "No fixed", "VND", null, null, null,
                    false, 365, true, null, null)))
            .andExpect(status().isBadRequest());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 4: INACTIVE / OUT-OF-WINDOW PRODUCT CANNOT ISSUE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void inactiveOrOutOfWindowProductCannotIssue() throws Exception {
        String inactiveCode = uniqueCode("INACTIVE");
        createProduct(productPayload(inactiveCode, "Inactive product", "VND", null, "1000", "100000",
            true, 365, false, null, null), status().isCreated());

        JsonNode user = registerUser("gc-inactive");
        issueCustomer(user.get("token").asText(),
            issuePayload(inactiveCode, "20000", null, null, null, null), status().isBadRequest());

        String futureCode = uniqueCode("FUTURE");
        createProduct(productPayload(futureCode, "Future product", "VND", null, "1000", "100000",
            true, 365, true, java.time.LocalDate.now().plusDays(10).toString(), null), status().isCreated());
        issueCustomer(user.get("token").asText(),
            issuePayload(futureCode, "20000", null, null, null, null), status().isBadRequest());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 5, 9, 10: ADMIN ISSUANCE / INITIAL BALANCE / ISSUE LEDGER
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void adminIssuesGiftCardWithInitialBalanceAndLedger() throws Exception {
        JsonNode product = defaultProduct("ADMINISSUE");

        JsonNode card = issueAdmin(adminIssuePayload(product.get("productCode").asText(), "150000",
            null, null, null, "Admin house grant", null), status().isCreated());

        assertEquals("ISSUED", card.get("status").asText());
        assertDecimal("150000", card.get("originalAmount"));
        assertDecimal("150000", card.get("currentBalance"), "initial balance equals original amount");
        assertNotNull(card.get("fullCode"), "admin issuance response includes the full code once");
        assertTrue(card.get("fullCode").asText().matches("^PYT-GC-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$"));

        Long cardId = card.get("id").asLong();
        JsonNode txPage = mapper.readTree(mvc.perform(get("/api/admin/gift-cards/" + cardId + "/transactions")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertEquals(1, txPage.get("totalElements").asLong(), "issue ledger transaction created");
        JsonNode issueTx = txPage.get("content").get(0);
        assertEquals("ISSUE", issueTx.get("transactionType").asText());
        assertDecimal("0", issueTx.get("balanceBefore"));
        assertDecimal("150000", issueTx.get("balanceAfter"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 6, 34, 35: CUSTOMER ISSUES TO A REGISTERED RECIPIENT / NOTIFICATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void customerIssuesToRegisteredRecipientAndNotifies() throws Exception {
        JsonNode product = defaultProduct("GIFTREG");
        JsonNode purchaser = registerUser("gc-purchaser");
        JsonNode recipient = registerUser("gc-recipient");
        Long recipientId = recipient.get("user").get("id").asLong();

        JsonNode card = issueCustomer(purchaser.get("token").asText(),
            issuePayload(product.get("productCode").asText(), "200000", recipientId, null,
                "Happy travels!", null), status().isCreated());

        assertEquals(recipientId, card.get("recipient").get("id").asLong());
        assertEquals("Happy travels!", card.get("personalMessage").asText());
        String fullCode = card.get("fullCode").asText();

        JsonNode notifications = mapper.readTree(mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + recipient.get("token").asText()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        JsonNode found = null;
        for (JsonNode n : notifications) if ("You received a gift card".equals(n.get("title").asText())) found = n;
        assertNotNull(found, "recipient must receive a 'You received a gift card' notification");
        assertTrue(found.get("message").asText().contains("200000"));
        assertTrue(found.get("message").asText().contains("VND"));
        assertFalse(found.get("message").asText().contains(fullCode), "notification must never include the full code");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 7: CUSTOMER ISSUES TO AN UNREGISTERED EMAIL
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void customerIssuesToUnregisteredEmail() throws Exception {
        JsonNode product = defaultProduct("GIFTEMAIL");
        JsonNode purchaser = registerUser("gc-emailpurchaser");
        String email = "unclaimed" + counter.getAndIncrement() + "@test.com";

        JsonNode card = issueCustomer(purchaser.get("token").asText(),
            issuePayload(product.get("productCode").asText(), "100000", null, email, null, null),
            status().isCreated());

        assertEquals(email, card.get("recipientEmail").asText());
        assertTrue(card.get("recipient") == null || card.get("recipient").isNull(),
            "no recipientUser bound yet — unclaimed");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 8: CODE UNIQUE AND CORRECTLY FORMATTED
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void giftCardCodeUniqueAndCorrectlyFormatted() throws Exception {
        JsonNode product = defaultProduct("CODEFMT");
        JsonNode user = registerUser("gc-codefmt");

        JsonNode card1 = issueCustomer(user.get("token").asText(),
            issuePayload(product.get("productCode").asText(), "50000", null, null, null, null), status().isCreated());
        JsonNode card2 = issueCustomer(user.get("token").asText(),
            issuePayload(product.get("productCode").asText(), "50000", null, null, null, null), status().isCreated());

        String code1 = card1.get("fullCode").asText();
        String code2 = card2.get("fullCode").asText();
        assertTrue(code1.matches("^PYT-GC-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$"));
        assertTrue(code2.matches("^PYT-GC-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$"));
        assertNotEquals(code1, code2, "codes must be unique per issuance");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 11, 12: RECIPIENT ACTIVATES / WRONG USER CANNOT ACTIVATE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void recipientActivatesAndWrongUserCannotActivate() throws Exception {
        JsonNode product = defaultProduct("ACTIVATE");
        JsonNode purchaser = registerUser("gc-actpurchaser");
        JsonNode recipient = registerUser("gc-actrecipient");
        JsonNode stranger = registerUser("gc-actstranger");
        Long recipientId = recipient.get("user").get("id").asLong();

        JsonNode card = issueCustomer(purchaser.get("token").asText(),
            issuePayload(product.get("productCode").asText(), "80000", recipientId, null, null, null),
            status().isCreated());
        Long cardId = card.get("id").asLong();

        // Wrong user (unrelated stranger) cannot activate — 404, not 403.
        mvc.perform(post("/api/me/gift-cards/" + cardId + "/activate")
                .header("Authorization", "Bearer " + stranger.get("token").asText()))
            .andExpect(status().isNotFound());

        JsonNode activated = mapper.readTree(mvc.perform(post("/api/me/gift-cards/" + cardId + "/activate")
                .header("Authorization", "Bearer " + recipient.get("token").asText()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertEquals("ACTIVE", activated.get("status").asText());
        assertNotNull(activated.get("activatedAt"));
        assertNotNull(activated.get("expiresAt"), "expiry derived from product validDaysAfterActivation");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 13, 14: EMAIL RECIPIENT CLAIMS / CLAIM IS IDEMPOTENT
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void emailRecipientClaimsAndClaimIsIdempotent() throws Exception {
        JsonNode product = defaultProduct("CLAIM");
        JsonNode purchaser = registerUser("gc-claimpurchaser");
        String claimantEmail = "claimant" + counter.getAndIncrement() + "@test.com";

        JsonNode card = issueCustomer(purchaser.get("token").asText(),
            issuePayload(product.get("productCode").asText(), "60000", null, claimantEmail, null, null),
            status().isCreated());
        String code = card.get("fullCode").asText();
        Long cardId = card.get("id").asLong();

        JsonNode claimant = mapper.readTree(mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"Claimant\",\"email\":\"" + claimantEmail + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString());
        String claimantToken = claimant.get("token").asText();

        JsonNode claimed = claim(claimantToken, code, status().isOk());
        assertEquals("ACTIVE", claimed.get("status").asText());
        assertEquals(claimant.get("user").get("id").asLong(), claimed.get("recipient").get("id").asLong());

        // Idempotent replay — same state, no duplicate ACTIVATE ledger row.
        JsonNode claimedAgain = claim(claimantToken, code, status().isOk());
        assertEquals("ACTIVE", claimedAgain.get("status").asText());

        JsonNode txPage = getJson(claimantToken, "/api/me/gift-cards/" + cardId + "/transactions");
        assertEquals(2, txPage.get("totalElements").asLong(), "exactly ISSUE + ACTIVATE — claim replay adds nothing");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 15, 16, 17, 33: LISTING / OWNERSHIP / MASKING
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void purchaserAndRecipientListCardsUnrelatedUserGets404AndCodeIsMasked() throws Exception {
        JsonNode product = defaultProduct("LISTOWN");
        JsonNode purchaser = registerUser("gc-listpurchaser");
        JsonNode recipient = registerUser("gc-listrecipient");
        JsonNode stranger = registerUser("gc-liststranger");
        Long recipientId = recipient.get("user").get("id").asLong();

        JsonNode card = issueCustomer(purchaser.get("token").asText(),
            issuePayload(product.get("productCode").asText(), "40000", recipientId, null, null, null),
            status().isCreated());
        Long cardId = card.get("id").asLong();
        String code = card.get("fullCode").asText();

        JsonNode purchaserList = getJson(purchaser.get("token").asText(), "/api/me/gift-cards");
        assertTrue(containsCardId(purchaserList, cardId), "purchaser lists the issued card");

        JsonNode recipientList = getJson(recipient.get("token").asText(), "/api/me/gift-cards");
        assertTrue(containsCardId(recipientList, cardId), "recipient lists the received card");

        mvc.perform(get("/api/me/gift-cards/" + cardId)
                .header("Authorization", "Bearer " + stranger.get("token").asText()))
            .andExpect(status().isNotFound());
        mvc.perform(get("/api/me/gift-cards/code/" + code)
                .header("Authorization", "Bearer " + stranger.get("token").asText()))
            .andExpect(status().isNotFound());

        // Masked in the normal (non-issuance) response — never re-echoes the full code.
        JsonNode viewed = getJson(purchaser.get("token").asText(), "/api/me/gift-cards/" + cardId);
        assertTrue(viewed.get("fullCode") == null || viewed.get("fullCode").isNull());
        String masked = viewed.get("maskedCode").asText();
        assertTrue(masked.startsWith("PYT-GC-****-****-"));
        assertTrue(code.endsWith(masked.substring(masked.length() - 4)));
    }

    private boolean containsCardId(JsonNode page, Long id) {
        for (JsonNode n : page.get("content")) if (n.get("id").asLong() == id) return true;
        return false;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 18, 19, 20, 21: PREVIEW
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void previewComputesRedeemableAmountCapsAndRejectsCurrencyMismatchWithoutMutating() throws Exception {
        JsonNode product = defaultProduct("PREVIEW");
        JsonNode user = registerUser("gc-preview");
        JsonNode card = issueCustomer(user.get("token").asText(),
            issuePayload(product.get("productCode").asText(), "200000", null, null, null, null), status().isCreated());
        Long cardId = card.get("id").asLong();
        String code = card.get("fullCode").asText();
        activateCustomer(user.get("token").asText(), cardId, status().isOk());

        // Order amount smaller than balance — fully redeemable, no payable remainder.
        JsonNode p1 = preview(user.get("token").asText(),
            previewPayload(code, "50000", "VND"), status().isOk());
        assertTrue(p1.get("eligible").asBoolean());
        assertDecimal("50000", p1.get("redeemableAmount"));
        assertDecimal("0", p1.get("finalPayableAmount"));
        assertDecimal("200000", p1.get("availableBalance"));

        // Order amount larger than balance — redemption caps at the balance.
        JsonNode p2 = preview(user.get("token").asText(),
            previewPayload(code, "500000", "VND"), status().isOk());
        assertTrue(p2.get("eligible").asBoolean());
        assertDecimal("200000", p2.get("redeemableAmount"), "capped at the lesser of balance or order amount");
        assertDecimal("300000", p2.get("finalPayableAmount"));

        // Currency mismatch.
        JsonNode p3 = preview(user.get("token").asText(),
            previewPayload(code, "50000", "USD"), status().isOk());
        assertFalse(p3.get("eligible").asBoolean());
        assertTrue(p3.get("reason").asText().toLowerCase().contains("currency"));

        // Preview never mutates the balance, no matter how many times it runs.
        JsonNode reread = getJson(user.get("token").asText(), "/api/me/gift-cards/" + cardId);
        assertDecimal("200000", reread.get("currentBalance"), "preview must never change the balance");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 22, 23, 24, 25: ADMIN ADJUSTMENT
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void adminCreditAndDebitAdjustmentWorkAndDebitCannotOverdraw() throws Exception {
        JsonNode product = defaultProduct("ADJUST");
        JsonNode card = issueAdmin(adminIssuePayload(product.get("productCode").asText(), "100000",
            null, null, null, null, null), status().isCreated());
        Long cardId = card.get("id").asLong();

        JsonNode creditTx = adminAdjust(cardId, adjustPayload("30000", "CREDIT", "Goodwill credit", null),
            status().isOk());
        assertEquals("ADJUSTMENT", creditTx.get("transactionType").asText());
        assertDecimal("100000", creditTx.get("balanceBefore"));
        assertDecimal("130000", creditTx.get("balanceAfter"));

        JsonNode debitTx = adminAdjust(cardId, adjustPayload("50000", "DEBIT", "Correction", null),
            status().isOk());
        assertDecimal("130000", debitTx.get("balanceBefore"));
        assertDecimal("80000", debitTx.get("balanceAfter"));

        // Debit exceeding the balance must be rejected and must not mutate anything.
        adminAdjust(cardId, adjustPayload("999999", "DEBIT", "Overdraw attempt", null), status().isConflict());
        JsonNode reread = getJson(adminToken(), "/api/admin/gift-cards/" + cardId);
        assertDecimal("80000", reread.get("currentBalance"), "failed debit must not change the balance");
    }

    @Test
    void adjustmentIdempotencyKeyPreventsDoubleMutation() throws Exception {
        JsonNode product = defaultProduct("ADJUSTIDEM");
        JsonNode card = issueAdmin(adminIssuePayload(product.get("productCode").asText(), "100000",
            null, null, null, null, null), status().isCreated());
        Long cardId = card.get("id").asLong();
        String key = "adjust-idem-" + counter.getAndIncrement();

        JsonNode first = adminAdjust(cardId, adjustPayload("25000", "CREDIT", "Idempotent credit", key), status().isOk());
        JsonNode replay = adminAdjust(cardId, adjustPayload("25000", "CREDIT", "Idempotent credit", key), status().isOk());
        assertEquals(first.get("id").asLong(), replay.get("id").asLong(), "replay returns the original transaction");

        JsonNode reread = getJson(adminToken(), "/api/admin/gift-cards/" + cardId);
        assertDecimal("125000", reread.get("currentBalance"), "balance changed exactly once");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 26, 27, 28: CANCELLATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void cancellationZeroesBalanceAndWritesLedgerRow() throws Exception {
        JsonNode product = defaultProduct("CANCEL");
        JsonNode card = issueAdmin(adminIssuePayload(product.get("productCode").asText(), "70000",
            null, null, null, null, null), status().isCreated());
        Long cardId = card.get("id").asLong();

        JsonNode cancelled = adminCancel(cardId, status().isOk());
        assertEquals("CANCELLED", cancelled.get("status").asText());
        assertDecimal("0", cancelled.get("currentBalance"));
        assertNotNull(cancelled.get("cancelledAt"));

        JsonNode txPage = getJson(adminToken(), "/api/admin/gift-cards/" + cardId + "/transactions");
        JsonNode cancellationTx = null;
        for (JsonNode t : txPage.get("content")) if ("CANCELLATION".equals(t.get("transactionType").asText())) cancellationTx = t;
        assertNotNull(cancellationTx, "cancellation ledger transaction created");
        assertDecimal("70000", cancellationTx.get("balanceBefore"));
        assertDecimal("0", cancellationTx.get("balanceAfter"));

        // Repeated cancellation is idempotent — returns the existing state.
        JsonNode again = adminCancel(cardId, status().isOk());
        assertEquals("CANCELLED", again.get("status").asText());
    }

    @Test
    void fullyRedeemedCardCannotCancel() throws Exception {
        JsonNode product = defaultProduct("FRCANCEL");
        JsonNode card = issueAdmin(adminIssuePayload(product.get("productCode").asText(), "40000",
            null, null, null, null, null), status().isCreated());
        Long cardId = card.get("id").asLong();

        adminAdjust(cardId, adjustPayload("40000", "DEBIT", "Drain to zero", null), status().isOk());
        JsonNode reread = getJson(adminToken(), "/api/admin/gift-cards/" + cardId);
        assertEquals("FULLY_REDEEMED", reread.get("status").asText());

        adminCancel(cardId, status().isConflict());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 29, 30, 31: EXPIRATION PROCESSOR
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void expirationProcessorExpiresEligibleCardsIdempotentlyAndBlocksActivation() throws Exception {
        JsonNode product = defaultProduct("EXPIRE");
        JsonNode user = registerUser("gc-expire");
        JsonNode card = issueCustomer(user.get("token").asText(),
            issuePayload(product.get("productCode").asText(), "90000", null, null, null, null), status().isCreated());
        Long cardId = card.get("id").asLong();
        activateCustomer(user.get("token").asText(), cardId, status().isOk());

        // Force the card into an already-expired state (same technique as
        // LoyaltyRedemptionTest/CheckoutCouponCreditTest: directly backdate
        // expiresAt via the repository — there is no public API to set an
        // arbitrary expiry, since it is always derived from the product).
        var row = giftCardRepo.findById(cardId).orElseThrow();
        row.setExpiresAt(Instant.now().minusSeconds(60));
        giftCardRepo.save(row);

        JsonNode result = mapper.readTree(mvc.perform(post("/api/admin/gift-cards/process-expirations")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertTrue(result.get("cardsExpired").asInt() >= 1);

        JsonNode reread = getJson(adminToken(), "/api/admin/gift-cards/" + cardId);
        assertEquals("EXPIRED", reread.get("status").asText());
        assertDecimal("0", reread.get("currentBalance"));

        // Idempotent — running again finds nothing left to expire for this card.
        JsonNode secondRun = mapper.readTree(mvc.perform(post("/api/admin/gift-cards/process-expirations")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        boolean thisCardExpiredAgain = false;
        for (JsonNode e : secondRun.get("expirations"))
            if (e.get("giftCardId").asLong() == cardId) thisCardExpiredAgain = true;
        assertFalse(thisCardExpiredAgain, "second run must not re-expire the same card");

        // A separate, still-ISSUED (never activated) card cannot activate once expired via forced backdating
        // is not applicable pre-activation (expiresAt is null until activation) — instead verify the now-EXPIRED
        // card itself can no longer be activated.
        mvc.perform(post("/api/me/gift-cards/" + cardId + "/activate")
                .header("Authorization", "Bearer " + user.get("token").asText()))
            .andExpect(status().isConflict());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 32: TRANSACTION HISTORY IMMUTABILITY (structural — every ledger read is a fresh row set)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void transactionHistoryRemainsImmutableAcrossOperations() throws Exception {
        JsonNode product = defaultProduct("IMMUTABLE");
        JsonNode card = issueAdmin(adminIssuePayload(product.get("productCode").asText(), "60000",
            null, null, null, null, null), status().isCreated());
        Long cardId = card.get("id").asLong();

        adminAdjust(cardId, adjustPayload("10000", "CREDIT", "First", null), status().isOk());
        JsonNode firstRead = getJson(adminToken(), "/api/admin/gift-cards/" + cardId + "/transactions");
        JsonNode issueTxFirstRead = null;
        for (JsonNode t : firstRead.get("content")) if ("ISSUE".equals(t.get("transactionType").asText())) issueTxFirstRead = t;
        assertNotNull(issueTxFirstRead);

        adminAdjust(cardId, adjustPayload("5000", "DEBIT", "Second", null), status().isOk());
        JsonNode secondRead = getJson(adminToken(), "/api/admin/gift-cards/" + cardId + "/transactions");
        JsonNode issueTxSecondRead = null;
        for (JsonNode t : secondRead.get("content")) if ("ISSUE".equals(t.get("transactionType").asText())) issueTxSecondRead = t;
        assertNotNull(issueTxSecondRead);

        assertEquals(issueTxFirstRead.get("id").asLong(), issueTxSecondRead.get("id").asLong());
        assertEquals(issueTxFirstRead.get("balanceBefore").asText(), issueTxSecondRead.get("balanceBefore").asText());
        assertEquals(issueTxFirstRead.get("balanceAfter").asText(), issueTxSecondRead.get("balanceAfter").asText());
        assertEquals(3, secondRead.get("totalElements").asLong(), "ISSUE + 2 ADJUSTMENT rows, nothing rewritten");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 36, 37: SECURITY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void nonAdminGiftCardAdminEndpointsRejected() throws Exception {
        JsonNode user = registerUser("gc-nonadmin");
        String token = user.get("token").asText();

        mvc.perform(get("/api/admin/gift-card-products").header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
        mvc.perform(post("/api/admin/gift-card-products")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(productPayload(uniqueCode("NOADMIN"), "x", "VND", null, "1000", "10000", true, 30, true, null, null)))
            .andExpect(status().isForbidden());
        mvc.perform(get("/api/admin/gift-cards").header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
        mvc.perform(post("/api/admin/gift-cards/issue")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(adminIssuePayload("PYT_STANDARD_GIFT", "100000", null, null, null, null, null)))
            .andExpect(status().isForbidden());
        mvc.perform(post("/api/admin/gift-cards/1/cancel").header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
        mvc.perform(post("/api/admin/gift-cards/process-expirations").header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
    }

    @Test
    void unauthenticatedGiftCardCustomerEndpointsRejected() throws Exception {
        mvc.perform(get("/api/me/gift-cards")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/me/gift-cards/issue")
                .contentType(MediaType.APPLICATION_JSON)
                .content(issuePayload("PYT_STANDARD_GIFT", "100000", null, null, null, null)))
            .andExpect(status().isUnauthorized());
        mvc.perform(post("/api/me/gift-cards/preview")
                .contentType(MediaType.APPLICATION_JSON)
                .content(previewPayload("PYT-GC-0000-0000-0000", "1000", "VND")))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 38, 39: SEEDED PRODUCT
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void seededStandardProductExistsExactlyOnce() throws Exception {
        JsonNode all = mapper.readTree(mvc.perform(get("/api/admin/gift-card-products")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());

        int matches = 0;
        JsonNode seeded = null;
        for (JsonNode p : all) {
            if ("PYT_STANDARD_GIFT".equals(p.get("productCode").asText())) { matches++; seeded = p; }
        }
        assertEquals(1, matches, "seeded product exists exactly once — restart-safe, no duplicates");
        assertNotNull(seeded);
        assertEquals("VND", seeded.get("currency").asText());
        assertTrue(seeded.get("customAmountAllowed").asBoolean());
        assertDecimal("100000", seeded.get("minimumAmount"));
        assertDecimal("10000000", seeded.get("maximumAmount"));
        assertEquals(365, seeded.get("validDaysAfterActivation").asInt());
        assertTrue(seeded.get("active").asBoolean());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 40: ORDINARY EXISTING BEHAVIOR UNCHANGED (smoke check — full suite is the real gate)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void ordinaryTravelCreditAndCouponEndpointsStillWork() throws Exception {
        JsonNode user = registerUser("gc-regression");
        String token = user.get("token").asText();
        mvc.perform(get("/api/me/travel-credits").header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
        mvc.perform(get("/api/me/coupons").header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
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

    private String uniqueCode(String prefix) {
        return "GC-" + prefix + "-" + counter.getAndIncrement();
    }

    private JsonNode defaultProduct(String prefix) throws Exception {
        String code = uniqueCode(prefix);
        return createProduct(productPayload(code, "Test Gift Card " + code, "VND",
            null, "10000", "5000000", true, 365, true, null, null), status().isCreated());
    }

    private String productPayload(String code, String name, String currency,
                                   String fixedAmount, String minAmount, String maxAmount,
                                   boolean customAmountAllowed, Integer validDays, boolean active,
                                   String validFrom, String validUntil) {
        return String.format("""
            {"productCode":"%s","name":"%s","description":"Test product","currency":"%s",
             "fixedAmount":%s,"minimumAmount":%s,"maximumAmount":%s,
             "customAmountAllowed":%s,"validDaysAfterActivation":%s,"active":%s,
             "validFrom":%s,"validUntil":%s}
            """,
            code, name, currency,
            numOrNull(fixedAmount), numOrNull(minAmount), numOrNull(maxAmount),
            customAmountAllowed, validDays == null ? "null" : validDays, active,
            strOrNull(validFrom), strOrNull(validUntil));
    }

    private String issuePayload(String productCode, String amount, Long recipientUserId, String recipientEmail,
                                 String personalMessage, String idempotencyKey) {
        return String.format("""
            {"productCode":"%s","amount":%s,"recipientUserId":%s,"recipientEmail":%s,
             "personalMessage":%s,"idempotencyKey":%s}
            """,
            productCode, amount,
            recipientUserId == null ? "null" : recipientUserId,
            strOrNull(recipientEmail), strOrNull(personalMessage), strOrNull(idempotencyKey));
    }

    private String adminIssuePayload(String productCode, String amount, Long purchaserUserId, Long recipientUserId,
                                      String recipientEmail, String personalMessage, String idempotencyKey) {
        return String.format("""
            {"productCode":"%s","amount":%s,"purchaserUserId":%s,"recipientUserId":%s,
             "recipientEmail":%s,"personalMessage":%s,"idempotencyKey":%s}
            """,
            productCode, amount,
            purchaserUserId == null ? "null" : purchaserUserId,
            recipientUserId == null ? "null" : recipientUserId,
            strOrNull(recipientEmail), strOrNull(personalMessage), strOrNull(idempotencyKey));
    }

    private String previewPayload(String code, String orderAmount, String currency) {
        return String.format("{\"giftCardCode\":\"%s\",\"orderAmount\":%s,\"currency\":\"%s\"}",
            code, orderAmount, currency);
    }

    private String adjustPayload(String amount, String direction, String description, String idempotencyKey) {
        return String.format("""
            {"amount":%s,"direction":"%s","description":"%s","referenceType":"ADMIN","referenceId":null,"idempotencyKey":%s}
            """,
            amount, direction, description, strOrNull(idempotencyKey));
    }

    private String numOrNull(String s) { return s == null ? "null" : s; }
    private String strOrNull(String s) { return s == null ? "null" : "\"" + s + "\""; }

    private JsonNode createProduct(String payload, ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/admin/gift-card-products")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
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

    private JsonNode issueAdmin(String payload, ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/admin/gift-cards/issue")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
    }

    private JsonNode activateCustomer(String token, Long id, ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/me/gift-cards/" + id + "/activate")
                .header("Authorization", "Bearer " + token))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
    }

    private JsonNode claim(String token, String code, ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/me/gift-cards/claim")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"" + code + "\"}"))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
    }

    private JsonNode preview(String token, String payload, ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/me/gift-cards/preview")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
    }

    private JsonNode adminAdjust(Long id, String payload, ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/admin/gift-cards/" + id + "/adjust")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
    }

    private JsonNode adminCancel(Long id, ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/admin/gift-cards/" + id + "/cancel")
                .header("Authorization", "Bearer " + adminToken()))
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

    private void assertDecimal(String expected, JsonNode actual) {
        assertDecimal(expected, actual, null);
    }

    private void assertDecimal(String expected, JsonNode actual, String message) {
        assertNotNull(actual, message);
        assertEquals(0, new BigDecimal(expected).compareTo(new BigDecimal(actual.asText())),
            (message != null ? message + " — " : "") + "expected " + expected + " but was " + actual.asText());
    }
}
