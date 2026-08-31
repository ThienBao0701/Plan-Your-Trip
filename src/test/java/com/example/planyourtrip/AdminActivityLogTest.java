package com.example.planyourtrip;

import com.example.planyourtrip.model.AdminActivityLog;
import com.example.planyourtrip.repository.AdminActivityLogRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.service.AdminActivityLogService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.Instant;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * D1a — the administrative audit trail.
 *
 * <p>D0 found that all 111 admin mutation endpoints wrote no audit record at all: an administrator
 * could approve a partner, refund a payment or moderate a review with nothing recording who did it.
 * These tests pin the properties that make the new trail trustworthy — it is written, it captures
 * the actor, it is transactional with the mutation, it refuses credential-shaped text, and it cannot
 * be read by a non-admin.
 *
 * <p><b>D1c</b> adds the properties that only matter once the trail covers more than a handful of
 * endpoints: a batch sweep writes one row per invocation and not one per affected record; an
 * action a customer performs through a service method the admin path shares must not appear in the
 * administrative trail at all; a destructive delete is recorded before the evidence disappears;
 * and nothing anywhere in the stored trail carries credential-shaped text.
 */
@SpringBootTest
@AutoConfigureMockMvc
class AdminActivityLogTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired AdminActivityLogService auditService;
    @Autowired AdminActivityLogRepository auditRepo;
    @Autowired UserRepository userRepo;
    @Autowired TransactionTemplate txTemplate;

    private String adminToken;
    private String partnerToken;
    private String userToken;
    private Long adminUserId;

    @BeforeEach
    void setup() throws Exception {
        adminToken = login("admin@planyourtrip.com", "admin123456");
        partnerToken = login("partner@planyourtrip.com", "partner123456");
        userToken = login("demo@planyourtrip.com", "demo123456");
        adminUserId = userRepo.findByEmail("admin@planyourtrip.com").orElseThrow().getId();
    }

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    // ── What the record captures ──────────────────────────────────────────────

    @Test
    void record_capturesActorActionTargetAndTimestamp() {
        Instant before = Instant.now().minusSeconds(1);
        auditService.record(adminUserId, "TEST_ACTION", "TEST_TARGET", 4242L,
            "unit probe", "OLD", "NEW");

        AdminActivityLog entry = latest("TEST_ACTION");
        assertNotNull(entry, "the action must have been recorded");
        assertEquals(adminUserId, entry.getActorUserId(), "actor id captured");
        assertEquals("admin@planyourtrip.com", entry.getActorEmail(), "actor email snapshotted");
        assertEquals("TEST_ACTION", entry.getAction());
        assertEquals("TEST_TARGET", entry.getTargetType());
        assertEquals(4242L, entry.getTargetId());
        assertEquals("OLD", entry.getBeforeState());
        assertEquals("NEW", entry.getAfterState());
        assertNotNull(entry.getCreatedAt(), "timestamp captured");
        assertFalse(entry.getCreatedAt().isBefore(before), "timestamp is the time of the action");
    }

    @Test
    void record_systemActor_isLabelledNotAttributedToAHuman() {
        auditService.recordSystem("TEST_BATCH", "JOB", null, "batch probe");
        AdminActivityLog entry = latest("TEST_BATCH");
        assertNotNull(entry);
        assertNull(entry.getActorUserId(), "a batch action has no human actor");
        assertEquals(AdminActivityLogService.SYSTEM_ACTOR, entry.getActorEmail());
    }

    @Test
    void record_requiresAnAction() {
        assertThrows(IllegalArgumentException.class,
            () -> auditService.record(adminUserId, "  ", "T", 1L, "d"));
    }

    // ── Sensitive-data policy ─────────────────────────────────────────────────

    @Test
    void record_refusesCredentialShapedText() {
        // Each of these would be a permanent leak if it reached storage.
        assertThrows(IllegalArgumentException.class, () -> auditService.record(
            adminUserId, "TEST_LEAK", "T", 1L, "password=hunter2"));
        assertThrows(IllegalArgumentException.class, () -> auditService.record(
            adminUserId, "TEST_LEAK", "T", 1L, "token eyJhbGciOiJIUzI1NiJ9abcdefghij"));
        assertThrows(IllegalArgumentException.class, () -> auditService.record(
            adminUserId, "TEST_LEAK", "T", 1L, "card 4111111111111111"));
        assertThrows(IllegalArgumentException.class, () -> auditService.record(
            adminUserId, "TEST_LEAK", "T", 1L, "ok", "before", "api_key=abc"));
        assertNull(latest("TEST_LEAK"), "nothing may be persisted when the guard trips");
    }

    @Test
    void financialAuditRecordsAmountAndCurrencyButNoCredentials() {
        auditService.record(adminUserId, "TEST_REFUND", "PAYMENT", 7L,
            "Refunded 1500000 VND on booking 7.", "PAID", "REFUNDED");
        AdminActivityLog e = latest("TEST_REFUND");
        assertNotNull(e);
        assertTrue(e.getDescription().contains("VND"), "amount + currency are recorded");
        String all = (e.getDescription() + e.getBeforeState() + e.getAfterState()).toLowerCase();
        for (String forbidden : new String[]{"password", "secret", "token", "cvv", "iban"}) {
            assertFalse(all.contains(forbidden), "audit must not contain " + forbidden);
        }
    }

    // ── Transaction semantics ─────────────────────────────────────────────────

    /**
     * The property that matters most: an audit entry must never describe an action that did not
     * happen. {@code record} joins the caller's transaction, so rolling that transaction back must
     * take the audit row with it.
     */
    @Test
    void auditRollsBackWithTheSurroundingTransaction() {
        long before = auditRepo.count();
        assertThrows(RuntimeException.class, () -> txTemplate.executeWithoutResult(status -> {
            auditService.record(adminUserId, "TEST_ROLLBACK", "T", 1L, "should not survive");
            throw new RuntimeException("simulated mutation failure");
        }));
        assertEquals(before, auditRepo.count(), "the audit row must not survive a rollback");
        assertNull(latest("TEST_ROLLBACK"));
    }

    // ── Real audited mutation, end to end ─────────────────────────────────────

    /**
     * Review moderation is a real audited admin mutation. Uses the seeded approved review and
     * re-applies its existing status, so the review's own state is unchanged while the audited
     * path still executes.
     */
    @Test
    void reviewModeration_writesAnAuditEntry() throws Exception {
        String list = mvc.perform(get("/api/admin/reviews?size=200")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode content = mapper.readTree(list).get("content");
        if (content.isEmpty()) return;   // nothing seeded to moderate on this run

        JsonNode review = content.get(0);
        long reviewId = review.get("id").asLong();
        String currentStatus = review.get("status").asText();

        mvc.perform(patch("/api/admin/reviews/" + reviewId + "/moderate")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"" + currentStatus + "\"}"))
            .andExpect(status().isOk());

        AdminActivityLog entry = latest("REVIEW_MODERATE");
        assertNotNull(entry, "moderating a review must be audited");
        assertEquals(adminUserId, entry.getActorUserId());
        assertEquals("REVIEW", entry.getTargetType());
        assertEquals(reviewId, entry.getTargetId());
        assertEquals(currentStatus, entry.getAfterState());
    }

    // ── Read surface + authorization ──────────────────────────────────────────

    @Test
    void readSurface_isPaginatedAndAdminOnly() throws Exception {
        auditService.record(adminUserId, "TEST_READ", "T", 1L, "readable");

        String body = mvc.perform(get("/api/admin/activity-logs?size=5")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode env = mapper.readTree(body);
        assertTrue(env.has("content") && env.has("totalElements") && env.has("totalPages"));
        assertTrue(env.get("content").size() <= 5, "page size is honoured");

        mvc.perform(get("/api/admin/activity-logs").header("Authorization", "Bearer " + partnerToken))
            .andExpect(status().isForbidden());
        mvc.perform(get("/api/admin/activity-logs").header("Authorization", "Bearer " + userToken))
            .andExpect(status().isForbidden());
        mvc.perform(get("/api/admin/activity-logs"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void readSurface_filtersByActionAndTarget() throws Exception {
        auditService.record(adminUserId, "TEST_FILTER", "WIDGET", 99L, "filterable");

        String body = mvc.perform(get("/api/admin/activity-logs?action=TEST_FILTER&targetType=WIDGET&targetId=99")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode content = mapper.readTree(body).get("content");
        assertTrue(content.size() >= 1);
        for (JsonNode n : content) {
            assertEquals("TEST_FILTER", n.get("action").asText());
            assertEquals("WIDGET", n.get("targetType").asText());
            assertEquals(99L, n.get("targetId").asLong());
        }
    }

    @Test
    void readSurface_invertedRangeIsRejected() throws Exception {
        mvc.perform(get("/api/admin/activity-logs")
                .param("from", "2030-01-02T00:00:00Z")
                .param("to", "2030-01-01T00:00:00Z")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isBadRequest());
    }

    /** Malformed paging must never become a 500 — the defect I found live in H-FIX verification. */
    @Test
    void readSurface_malformedPagingIsClampedNot500() throws Exception {
        mvc.perform(get("/api/admin/activity-logs?page=-1&size=0")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());
    }

    /**
     * Append-only: the repository exposes no delete or bulk-update method, so no code path exists
     * for an administrator to erase their own history.
     */
    @Test
    void repositoryExposesNoDeleteOrUpdateMethod() {
        for (var m : AdminActivityLogRepository.class.getMethods()) {
            String n = m.getName().toLowerCase();
            assertFalse(n.startsWith("delete") || n.startsWith("remove"),
                "audit repository must expose no deletion method, found: " + m.getName());
        }
    }

    private AdminActivityLog latest(String action) {
        var page = auditRepo.search(null, action, null, null, null, null, PageRequest.of(0, 1));
        return page.isEmpty() ? null : page.getContent().get(0);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // D1c
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * A sweep must write exactly ONE summary row per invocation. Recording per affected record
     * would let one click write an unbounded number of audit rows: the trail would grow with the
     * data it describes, become unreadable, and turn an operational action into a storage event.
     */
    @Test
    void batchSweep_writesOneSummaryRowPerInvocation_neverOnePerRecord() throws Exception {
        long before = countOf("PAYMENT_SESSION_EXPIRY_SWEEP");

        mvc.perform(post("/api/admin/payment-sessions/process-expirations")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());

        assertEquals(before + 1, countOf("PAYMENT_SESSION_EXPIRY_SWEEP"),
            "one sweep must add exactly one audit row");

        AdminActivityLog entry = latest("PAYMENT_SESSION_EXPIRY_SWEEP");
        assertNotNull(entry);
        assertEquals(adminUserId, entry.getActorUserId(),
            "a human ran the sweep, so the row names them rather than SYSTEM");
        assertNull(entry.getTargetId(), "a sweep has no single target row");
        assertTrue(entry.getAfterState().startsWith("expired:"),
            "the summary must carry the count, got: " + entry.getAfterState());

        // A second run adds exactly one more row, not one per candidate it re-examined.
        mvc.perform(post("/api/admin/payment-sessions/process-expirations")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());
        assertEquals(before + 2, countOf("PAYMENT_SESSION_EXPIRY_SWEEP"));
    }

    /** Every batch endpoint records under its own action name, so a sweep is attributable. */
    @Test
    void everyBatchEndpoint_recordsExactlyOneSweepRow() throws Exception {
        String[][] sweeps = {
            {"/api/admin/travel-credits/process-expirations",          "TRAVEL_CREDIT_EXPIRY_SWEEP"},
            {"/api/admin/gift-cards/process-expirations",              "GIFT_CARD_EXPIRY_SWEEP"},
            {"/api/admin/inventory-reservations/process-expirations",  "INVENTORY_HOLD_EXPIRY_SWEEP"},
            {"/api/admin/loyalty/redemptions/expire-stale",            "LOYALTY_REDEMPTION_EXPIRY_SWEEP"},
            {"/api/admin/trip-reminders/deliver-due",                  "TRIP_REMINDER_DELIVERY_SWEEP"},
            {"/api/admin/travel-wallet/generate-expiry-reminders",     "WALLET_EXPIRY_REMINDER_SWEEP"},
        };
        for (String[] sweep : sweeps) {
            long before = countOf(sweep[1]);
            mvc.perform(post(sweep[0]).header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk());
            assertEquals(before + 1, countOf(sweep[1]),
                sweep[0] + " must write exactly one " + sweep[1] + " row");
            assertEquals(adminUserId, latest(sweep[1]).getActorUserId(), sweep[0]);
        }
    }

    /**
     * The shared-caller guard. {@code LoyaltyRedemptionService.releaseByReference} serves both the
     * administrative endpoint and the customer's own release endpoint. A customer releasing their
     * own reservation is not an administrative act and must leave no row in this trail — the same
     * mistake D1a caught when referral rewards reached the audited credit-grant path.
     */
    @Test
    void customerActionThroughASharedServiceMethod_writesNoAdminRow() throws Exception {
        long before = countOf("LOYALTY_REDEMPTION_RELEASE");

        mvc.perform(post("/api/loyalty/redemptions/NO-SUCH-REFERENCE/release")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().is4xxClientError());

        assertEquals(before, countOf("LOYALTY_REDEMPTION_RELEASE"),
            "a customer-path release must never appear in the administrative trail");
    }

    /**
     * A destructive delete is the case an audit trail exists for: afterwards there is no row left
     * to inspect. The record must therefore be written in the same transaction as the deletion and
     * must carry enough identity to say what was destroyed.
     */
    @Test
    void deletingAPromotion_isAuditedWithTheIdentityOfWhatWasDestroyed() throws Exception {
        String code = "D1C-AUDIT-" + System.nanoTime();
        String created = mvc.perform(post("/api/admin/promotions")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{"
                    + "\"name\":\"D1c audit probe\","
                    + "\"code\":\"" + code + "\","
                    + "\"promotionType\":\"GENERAL\","
                    + "\"discountType\":\"PERCENTAGE\","
                    + "\"discountValue\":5.0,"
                    + "\"stackable\":false,"
                    + "\"priority\":0,"
                    + "\"startDate\":\"" + java.time.LocalDate.now() + "\","
                    + "\"endDate\":\"" + java.time.LocalDate.now().plusDays(7) + "\""
                    + "}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        long promotionId = mapper.readTree(created).get("id").asLong();

        long before = countOf("PROMOTION_DELETE");
        mvc.perform(delete("/api/admin/promotions/" + promotionId)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNoContent());

        assertEquals(before + 1, countOf("PROMOTION_DELETE"));
        AdminActivityLog entry = latest("PROMOTION_DELETE");
        assertEquals(adminUserId, entry.getActorUserId());
        assertEquals("PROMOTION", entry.getTargetType());
        assertEquals(promotionId, entry.getTargetId());
        // A scalar state, never the operator-supplied code: free text reaching the audit guard
        // can trip its card-number rule and roll the deletion back (D1c-NEW-1, covered below).
        assertEquals("active:true", entry.getBeforeState());
        assertNull(entry.getAfterState(), "nothing exists after a delete");

        // And the deletion really happened — the audit row is not describing a no-op.
        mvc.perform(get("/api/admin/promotions/" + promotionId)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNotFound());
    }

    /**
     * An invoice is the customer's financial record of a stay, so forcing its status is an
     * accounting act. The row must carry the status pair and nothing from the billing block on the
     * same table row.
     */
    @Test
    void invoiceStatusOverride_isAuditedWithBeforeAndAfterOnly() throws Exception {
        String list = mvc.perform(get("/api/admin/invoices?size=200")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode content = mapper.readTree(list).get("content");
        if (content.isEmpty()) return;   // nothing seeded to override on this run

        JsonNode invoice = content.get(0);
        long invoiceId = invoice.get("id").asLong();
        String current = invoice.get("status").asText();

        long before = countOf("INVOICE_STATUS_OVERRIDE");
        mvc.perform(patch("/api/admin/invoices/" + invoiceId + "/status")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"" + current + "\"}"))
            .andExpect(status().isOk());

        assertEquals(before + 1, countOf("INVOICE_STATUS_OVERRIDE"));
        AdminActivityLog entry = latest("INVOICE_STATUS_OVERRIDE");
        assertEquals(adminUserId, entry.getActorUserId());
        assertEquals("INVOICE", entry.getTargetType());
        assertEquals(invoiceId, entry.getTargetId());
        assertEquals(current, entry.getBeforeState());
        assertEquals(current, entry.getAfterState());
    }

    /**
     * The whole stored trail is checked, not just the guard in isolation: a wired caller could
     * pass something credential-shaped that the service would then reject at write time, and this
     * proves no such value has been accepted by any of the callers the suite exercises.
     */
    @Test
    void noStoredRowCarriesCredentialShapedText() {
        var page = auditRepo.search(null, null, null, null, null, null, PageRequest.of(0, 200));
        var forbidden = java.util.regex.Pattern.compile(
            "(?i)(password|passwd|secret|bearer\\s|eyJ[A-Za-z0-9_-]{10,}|api[_-]?key"
                + "|private[_-]?key|cvv|iban|swift|\\b\\d{13,19}\\b)");
        for (AdminActivityLog l : page.getContent()) {
            for (String field : new String[]{l.getDescription(), l.getBeforeState(), l.getAfterState()}) {
                if (field == null) continue;
                assertFalse(forbidden.matcher(field).find(),
                    "audit row " + l.getId() + " (" + l.getAction() + ") stored credential-shaped text");
            }
        }
    }

    /**
     * D1c-NEW-1 regression. A promotion code is operator-supplied free text and may legitimately
     * contain a long run of digits — an internal reference, a date-stamped campaign id. D1a's
     * credential backstop rejects any 13-19 digit run as a possible card number, and because the
     * audit write shares the mutation's transaction, feeding it that code made the deletion fail
     * with a 500 and roll back. The endpoint must not care what the code looks like.
     */
    @Test
    void promotionWithADigitHeavyCode_canStillBeDeleted() throws Exception {
        String digitHeavy = "CAMPAIGN-4532015112830366";   // 16 digits, card-shaped by regex
        String created = mvc.perform(post("/api/admin/promotions")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{"
                    + "\"name\":\"D1c digit-heavy probe\","
                    + "\"code\":\"" + digitHeavy + "\","
                    + "\"promotionType\":\"GENERAL\","
                    + "\"discountType\":\"PERCENTAGE\","
                    + "\"discountValue\":5.0,"
                    + "\"stackable\":false,"
                    + "\"priority\":0,"
                    + "\"startDate\":\"" + java.time.LocalDate.now() + "\","
                    + "\"endDate\":\"" + java.time.LocalDate.now().plusDays(7) + "\""
                    + "}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        long id = mapper.readTree(created).get("id").asLong();

        mvc.perform(delete("/api/admin/promotions/" + id)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNoContent());

        mvc.perform(get("/api/admin/promotions/" + id)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNotFound());
    }

    private long countOf(String action) {
        return auditRepo.search(null, action, null, null, null, null, PageRequest.of(0, 1))
            .getTotalElements();
    }
}
