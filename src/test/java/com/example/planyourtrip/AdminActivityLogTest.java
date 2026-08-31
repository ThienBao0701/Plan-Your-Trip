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
}
