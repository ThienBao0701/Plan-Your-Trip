package com.example.planyourtrip;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * TravelCreditTest — Phase 7.14 (Customer Coupons &amp; Travel Credits Foundation).
 * Covers the lazily-created promotional credit account (with preferred-currency
 * default), admin grant/deduct, the immutable balanceBefore/balanceAfter
 * ledger, idempotency-key replay, negative-balance prevention, customer
 * transaction filters, the grant notification (amount + currency only — never
 * the internal admin note) and security (customers can never mutate credits).
 * Every scenario registers its own throwaway user(s) so account/ledger state
 * never leaks across tests — mirrors TravelWalletTest's conventions.
 */
@SpringBootTest
@AutoConfigureMockMvc
class TravelCreditTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;

    private static final AtomicInteger counter = new AtomicInteger(1);
    private static final LocalDate TODAY = LocalDate.now();

    // ═══════════════════════════════════════════════════════════════════════════
    // 1: LAZY ACCOUNT CREATION / DEFAULT CURRENCY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void createsDefaultAccountLazilyWithPreferredCurrency() throws Exception {
        // Fresh user with no customer profile — falls back to VND, balance 0.
        JsonNode plain = registerUser("credit-lazy-vnd");
        JsonNode account = getJson(plain.get("token").asText(), "/api/me/travel-credits");
        assertNotNull(account.get("id"));
        assertEquals("VND", account.get("currency").asText());
        assertDecimal("0", account.get("balance"));

        // User whose profile prefers USD — the lazily-created account picks it up.
        JsonNode usdUser = registerUser("credit-lazy-usd");
        String usdToken = usdUser.get("token").asText();
        mvc.perform(put("/api/me/profile")
                .header("Authorization", "Bearer " + usdToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"preferredCurrency\":\"USD\"}"))
            .andExpect(status().isOk());

        JsonNode usdAccount = getJson(usdToken, "/api/me/travel-credits");
        assertEquals("USD", usdAccount.get("currency").asText());
        assertDecimal("0", usdAccount.get("balance"));

        // Repeat access returns the same account (one per user), not a second one.
        JsonNode again = getJson(usdToken, "/api/me/travel-credits");
        assertEquals(usdAccount.get("id").asLong(), again.get("id").asLong());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 2-6: GRANT / LEDGER / IDEMPOTENCY / DEDUCT / OVERDRAW
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void adminGrantsTravelCredits() throws Exception {
        JsonNode user = registerUser("credit-grant");
        Long userId = user.get("user").get("id").asLong();

        JsonNode tx = grant(userId, adjustmentPayload("250000", "VND", "Support goodwill", null, null),
            status().isCreated());

        assertEquals("GRANT", tx.get("transactionType").asText());
        assertDecimal("250000", tx.get("amount"));
        assertDecimal("0", tx.get("balanceBefore"));
        assertDecimal("250000", tx.get("balanceAfter"));

        JsonNode account = getJson(user.get("token").asText(), "/api/me/travel-credits");
        assertDecimal("250000", account.get("balance"));
    }

    @Test
    void grantCreatesImmutableLedgerTransaction() throws Exception {
        JsonNode user = registerUser("credit-ledger");
        Long userId = user.get("user").get("id").asLong();

        grant(userId, adjustmentPayload("100000", "VND", "First grant", null, null), status().isCreated());
        grant(userId, adjustmentPayload("50000", "VND", "Second grant", null, null), status().isCreated());

        JsonNode page = getJson(user.get("token").asText(), "/api/me/travel-credits/transactions");
        assertEquals(2, page.get("totalElements").asLong());

        // Newest first — the second grant chains exactly off the first one's balanceAfter.
        JsonNode second = page.get("content").get(0);
        JsonNode first = page.get("content").get(1);
        assertDecimal("0", first.get("balanceBefore"));
        assertDecimal("100000", first.get("balanceAfter"));
        assertDecimal("100000", second.get("balanceBefore"));
        assertDecimal("150000", second.get("balanceAfter"));
        assertEquals("First grant", first.get("description").asText());

        // Re-reading returns identical ledger rows — nothing rewrote the first transaction.
        JsonNode reread = getJson(user.get("token").asText(), "/api/me/travel-credits/transactions");
        assertEquals(first.get("id").asLong(), reread.get("content").get(1).get("id").asLong());
        assertDecimal("100000", reread.get("content").get(1).get("balanceAfter"));
    }

    @Test
    void duplicateIdempotencyKeyDoesNotDoubleGrant() throws Exception {
        JsonNode user = registerUser("credit-idem");
        Long userId = user.get("user").get("id").asLong();
        String key = "idem-key-" + counter.getAndIncrement();

        JsonNode firstTx = grant(userId, adjustmentPayload("80000", "VND", "Idempotent grant", key, null),
            status().isCreated());
        JsonNode replayTx = grant(userId, adjustmentPayload("80000", "VND", "Idempotent grant", key, null),
            status().isCreated());

        assertEquals(firstTx.get("id").asLong(), replayTx.get("id").asLong(),
            "replay returns the original transaction");

        JsonNode account = getJson(user.get("token").asText(), "/api/me/travel-credits");
        assertDecimal("80000", account.get("balance"), "balance granted exactly once");

        JsonNode page = getJson(user.get("token").asText(), "/api/me/travel-credits/transactions");
        assertEquals(1, page.get("totalElements").asLong(), "no second ledger row");
    }

    @Test
    void adminDeductsTravelCredits() throws Exception {
        JsonNode user = registerUser("credit-deduct");
        Long userId = user.get("user").get("id").asLong();
        grant(userId, adjustmentPayload("300000", "VND", "Initial grant", null, null), status().isCreated());

        JsonNode tx = deduct(userId, adjustmentPayload("100000", "VND", "Correction", null, "REDEMPTION"),
            status().isCreated());

        assertEquals("REDEMPTION", tx.get("transactionType").asText());
        assertDecimal("100000", tx.get("amount"), "amount stays positive — direction comes from the type");
        assertDecimal("300000", tx.get("balanceBefore"));
        assertDecimal("200000", tx.get("balanceAfter"));

        JsonNode account = getJson(user.get("token").asText(), "/api/me/travel-credits");
        assertDecimal("200000", account.get("balance"));
    }

    @Test
    void deductionCannotMakeBalanceNegative() throws Exception {
        JsonNode user = registerUser("credit-overdraw");
        Long userId = user.get("user").get("id").asLong();
        grant(userId, adjustmentPayload("50000", "VND", "Small grant", null, null), status().isCreated());

        deduct(userId, adjustmentPayload("100000", "VND", "Overdraw attempt", null, null),
            status().isConflict());

        JsonNode account = getJson(user.get("token").asText(), "/api/me/travel-credits");
        assertDecimal("50000", account.get("balance"), "failed deduction must not change the balance");

        JsonNode page = getJson(user.get("token").asText(), "/api/me/travel-credits/transactions");
        assertEquals(1, page.get("totalElements").asLong(), "failed deduction must not write a ledger row");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 7: TRANSACTION HISTORY FILTERS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void customerListsOwnCreditTransactionsWithFilters() throws Exception {
        JsonNode user = registerUser("credit-filters");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();

        grant(userId, adjustmentPayload("200000", "VND", "Grant tx", null, null), status().isCreated());
        deduct(userId, adjustmentPayload("50000", "VND", "Redeem tx", null, "REDEMPTION"), status().isCreated());

        JsonNode all = getJson(token, "/api/me/travel-credits/transactions");
        assertEquals(2, all.get("totalElements").asLong());

        JsonNode grantsOnly = getJson(token, "/api/me/travel-credits/transactions?type=GRANT");
        assertEquals(1, grantsOnly.get("totalElements").asLong());
        assertEquals("GRANT", grantsOnly.get("content").get(0).get("transactionType").asText());

        JsonNode inRange = getJson(token, "/api/me/travel-credits/transactions?from="
            + TODAY.minusDays(1) + "&to=" + TODAY.plusDays(1));
        assertEquals(2, inRange.get("totalElements").asLong());

        JsonNode outOfRange = getJson(token, "/api/me/travel-credits/transactions?from=" + TODAY.plusDays(2));
        assertEquals(0, outOfRange.get("totalElements").asLong());

        JsonNode paged = getJson(token, "/api/me/travel-credits/transactions?page=0&size=1");
        assertEquals(1, paged.get("content").size());
        assertEquals(2, paged.get("totalElements").asLong());
        assertEquals(2, paged.get("totalPages").asInt());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 8-9: SECURITY — CUSTOMERS CAN NEVER MUTATE CREDITS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void userCannotGrantTheirOwnCredits() throws Exception {
        JsonNode user = registerUser("credit-selfgrant");
        Long userId = user.get("user").get("id").asLong();

        mvc.perform(post("/api/admin/users/" + userId + "/travel-credits/grant")
                .header("Authorization", "Bearer " + user.get("token").asText())
                .contentType(MediaType.APPLICATION_JSON)
                .content(adjustmentPayload("999999", "VND", "Self grant attempt", null, null)))
            .andExpect(status().isForbidden());

        JsonNode account = getJson(user.get("token").asText(), "/api/me/travel-credits");
        assertDecimal("0", account.get("balance"));
    }

    @Test
    void nonAdminTravelCreditAdminEndpointsRejected() throws Exception {
        JsonNode user = registerUser("credit-nonadmin");
        Long userId = user.get("user").get("id").asLong();
        String token = user.get("token").asText();

        mvc.perform(get("/api/admin/users/" + userId + "/travel-credits")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
        mvc.perform(get("/api/admin/users/" + userId + "/coupons")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
        mvc.perform(post("/api/admin/users/" + userId + "/travel-credits/deduct")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(adjustmentPayload("1000", "VND", "Nope", null, null)))
            .andExpect(status().isForbidden());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 10: GRANT NOTIFICATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void travelCreditGrantNotificationCreated() throws Exception {
        JsonNode user = registerUser("credit-notify");
        Long userId = user.get("user").get("id").asLong();

        grant(userId, adjustmentPayload("120000", "VND", "INTERNAL-ADMIN-NOTE compensation case #42", null, null),
            status().isCreated());

        JsonNode notifications = mapper.readTree(mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + user.get("token").asText()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());

        JsonNode found = null;
        for (JsonNode n : notifications) {
            if ("Travel credits added".equals(n.get("title").asText())) found = n;
        }
        assertNotNull(found, "grant must create a 'Travel credits added' notification");
        assertEquals("PAYMENT", found.get("notificationType").asText());
        String message = found.get("message").asText();
        assertTrue(message.contains("120000") && message.contains("VND"),
            "message must include amount and currency");
        assertFalse(message.contains("INTERNAL-ADMIN-NOTE"),
            "internal admin note must never leak into the user-facing message");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 11-12: ADMIN SUPPORT VIEW / UNAUTHENTICATED
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void adminSupportViewShowsBalanceAndRecentTransactions() throws Exception {
        JsonNode user = registerUser("credit-adminview");
        Long userId = user.get("user").get("id").asLong();

        // Before any credit activity: read-only view reports no account, and does not create one.
        JsonNode empty = mapper.readTree(mvc.perform(get("/api/admin/users/" + userId + "/travel-credits")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertTrue(empty.get("account") == null || empty.get("account").isNull());
        assertEquals(0, empty.get("recentTransactions").size());

        grant(userId, adjustmentPayload("70000", "VND", "Visible to support", null, null), status().isCreated());

        JsonNode view = mapper.readTree(mvc.perform(get("/api/admin/users/" + userId + "/travel-credits")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertDecimal("70000", view.get("account").get("balance"));
        assertEquals(1, view.get("recentTransactions").size());
    }

    @Test
    void unauthenticatedTravelCreditEndpointsRejected() throws Exception {
        mvc.perform(get("/api/me/travel-credits")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/me/travel-credits/transactions")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/admin/users/1/travel-credits")).andExpect(status().isUnauthorized());
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

    private String adjustmentPayload(String amount, String currency, String description,
                                      String idempotencyKey, String transactionType) {
        return String.format("""
                {"amount":%s,"currency":"%s","description":"%s",
                 "referenceType":"ADMIN","referenceId":null,
                 "idempotencyKey":%s,"expiresAt":null,"transactionType":%s}
                """,
            amount, currency, description,
            idempotencyKey == null ? "null" : "\"" + idempotencyKey + "\"",
            transactionType == null ? "null" : "\"" + transactionType + "\"");
    }

    private JsonNode grant(Long userId, String payload,
                            org.springframework.test.web.servlet.ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/admin/users/" + userId + "/travel-credits/grant")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
    }

    private JsonNode deduct(Long userId, String payload,
                             org.springframework.test.web.servlet.ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/admin/users/" + userId + "/travel-credits/deduct")
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

    private void assertDecimal(String expected, JsonNode actual) {
        assertDecimal(expected, actual, null);
    }

    private void assertDecimal(String expected, JsonNode actual, String message) {
        assertNotNull(actual, message);
        assertEquals(0, new BigDecimal(expected).compareTo(new BigDecimal(actual.asText())),
            (message != null ? message + " — " : "") + "expected " + expected + " but was " + actual.asText());
    }
}
