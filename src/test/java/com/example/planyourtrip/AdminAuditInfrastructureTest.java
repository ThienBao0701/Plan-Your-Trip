package com.example.planyourtrip;

import com.example.planyourtrip.model.AdminActivityLog;
import com.example.planyourtrip.repository.AdminActivityLogRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.service.AdminActivityLogService;
import com.example.planyourtrip.service.AuditHelperBridge;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * D3J — the infrastructure that stores, validates, queries and verifies the administrative audit
 * trail, as opposed to the business mutations that write into it.
 *
 * <p>D3F through D3I brought Admin audit coverage to 110 of 110 mutations. Every one of those
 * phases proved its own actions were recorded correctly by reading the stored rows back — and every
 * one of them did that with a single {@code PageRequest.of(0, 200)}. That was adequate when the
 * trail held a few dozen rows and is not adequate now: it is a "newest 200" read presented as a
 * full scan, and the rows it silently drops are the oldest ones, which is precisely the direction
 * in which nobody would notice. {@link #theOldCappedReadMissesASecretThatTheExhaustiveScanFinds}
 * demonstrates the gap on real data rather than describing it.
 *
 * <p>Rows are planted through the repository rather than the service where a test needs a row the
 * write-time guard would refuse — that is the whole point of a persisted-data scan, which exists to
 * catch what did not come through the front door. Those tests are {@code @Transactional} and roll
 * back, so nothing they plant survives into another test or into the global scan.
 */
@SpringBootTest
@AutoConfigureMockMvc
class AdminAuditInfrastructureTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired AdminActivityLogRepository auditRepo;
    @Autowired AdminActivityLogService auditService;
    @Autowired UserRepository userRepo;

    /** The guard's own pattern, restated here so a change to it fails this test loudly. */
    private static final Pattern FORBIDDEN = Pattern.compile(
        "(?i)(password|passwd|secret|bearer\\s|eyJ[A-Za-z0-9_-]{10,}|api[_-]?key|private[_-]?key"
            + "|cvv|iban|swift|\\b\\d{13,19}\\b)");

    private String adminToken;
    private String userToken;
    private String partnerToken;
    private Long adminUserId;

    @BeforeEach
    void setup() throws Exception {
        adminToken = login("admin@planyourtrip.com", "admin123456");
        userToken = login("demo@planyourtrip.com", "demo123456");
        partnerToken = login("partner@planyourtrip.com", "partner123456");
        adminUserId = userRepo.findByEmail("admin@planyourtrip.com").orElseThrow().getId();
    }

    // ══════════════════════════════════════════════════════════════════════════
    // 1–9 · EXHAUSTIVENESS — the finding this phase exists to close
    // ══════════════════════════════════════════════════════════════════════════

    /** 1. Zero rows: the loop must terminate immediately and claim nothing. */
    @Test
    void scanOfAnEmptyResultSetTerminatesAndReadsNothing() {
        var result = AdminAuditScan.scanAction(auditRepo, "D3J_NO_SUCH_ACTION_" + tag(), null);
        result.assertComplete();
        assertEquals(0, result.declaredTotal());
        assertEquals(0, result.scanned());
        assertEquals(1, result.pagesRead(), "one empty page is read, then the loop stops");
    }

    /** 2. Exactly one full page — the boundary the old code happened to sit on. */
    @Test
    @Transactional
    void scanOfExactlyOnePageIsComplete() {
        String action = plant(AdminAuditScan.BATCH, -1);
        var result = AdminAuditScan.scanAction(auditRepo, action, null);
        result.assertComplete();
        assertEquals(AdminAuditScan.BATCH, result.scanned());
        assertEquals(1, result.pagesRead());
    }

    /** 3. One row past the page size — the classic off-by-one boundary. */
    @Test
    @Transactional
    void scanOfPageSizePlusOneReadsBothPages() {
        String action = plant(AdminAuditScan.BATCH + 1, -1);
        var result = AdminAuditScan.scanAction(auditRepo, action, null);
        result.assertComplete();
        assertEquals(AdminAuditScan.BATCH + 1, result.scanned());
        assertEquals(2, result.pagesRead(), "the last page holds a single row and must still be read");
    }

    /** 4 + 7. Well past 200 rows, several pages, no early stop. */
    @Test
    @Transactional
    void scanOfMoreThanTwoHundredRowsCoversEveryPage() {
        String action = plant(523, -1);
        var result = AdminAuditScan.scanAction(auditRepo, action, null);
        result.assertComplete();
        assertEquals(523, result.scanned());
        assertEquals(3, result.pagesRead(), "523 rows at a batch of 200 is three pages");
        assertTrue(result.pagesRead() > 1, "a scan that stopped after page 0 would be the old bug");
    }

    /**
     * 5. The regression proof. A credential-shaped row is planted so it lands beyond the first
     * page, then the old capped read and the new exhaustive scan are run over the same data. The
     * old one reports the trail clean; the new one finds the row. This is the finding, demonstrated
     * rather than asserted.
     */
    @Test
    @Transactional
    void theOldCappedReadMissesASecretThatTheExhaustiveScanFinds() {
        int secretAt = 201;
        String action = plant(400, secretAt);

        // The old mechanism: one page, size 200, inspect getContent().
        List<AdminActivityLog> cappedPage = auditRepo
            .search(null, action, null, null, null, null, PageRequest.of(0, AdminAuditScan.BATCH))
            .getContent();
        assertEquals(200, cappedPage.size());
        assertFalse(cappedPage.stream().anyMatch(this::looksLikeACredential),
            "precondition: the planted secret must sit outside the first page");

        // The new mechanism.
        List<AdminActivityLog> flagged = new ArrayList<>();
        var result = AdminAuditScan.scanAction(auditRepo, action,
            row -> { if (looksLikeACredential(row)) flagged.add(row); });
        result.assertComplete();

        assertEquals(400, result.scanned());
        assertEquals(1, flagged.size(),
            "the exhaustive scan must find the row the capped read could not see");
        int index = result.idsInOrder().indexOf(flagged.get(0).getId());
        assertTrue(index >= AdminAuditScan.BATCH,
            "the secret was expected beyond the first page but sat at scan index " + index);
        assertEquals(secretAt, index, "the planted position must be where the scan reports it");
    }

    /** 6. Deeper still — a third-page row, and the last row of all. */
    @Test
    @Transactional
    void secretsOnALaterPageAndOnTheFinalRowAreBothDetected() {
        for (int secretAt : new int[]{401, 449}) {
            String action = plant(450, secretAt);
            List<AdminActivityLog> flagged = new ArrayList<>();
            var result = AdminAuditScan.scanAction(auditRepo, action,
                row -> { if (looksLikeACredential(row)) flagged.add(row); });
            result.assertComplete();
            assertEquals(450, result.scanned());
            assertEquals(1, flagged.size(), "no secret detected with the plant at index " + secretAt);
            assertEquals(secretAt, result.idsInOrder().indexOf(flagged.get(0).getId()),
                "wrong position for the plant at index " + secretAt);
        }
    }

    /** 8. No duplicates across page boundaries. */
    @Test
    @Transactional
    void multiPagePaginationServesNoRowTwice() {
        String action = plant(605, -1);
        var result = AdminAuditScan.scanAction(auditRepo, action, null);
        assertTrue(result.duplicateIds().isEmpty(), "duplicated rows: " + result.duplicateIds());
        assertEquals(result.idsInOrder().size(), new LinkedHashSet<>(result.idsInOrder()).size());
        result.assertComplete();
    }

    /** 9. No omissions: distinct rows seen must equal what the query declared. */
    @Test
    @Transactional
    void multiPagePaginationOmitsNoRow() {
        String action = plant(605, -1);
        var result = AdminAuditScan.scanAction(auditRepo, action, null);
        assertEquals(605L, result.declaredTotal());
        assertEquals(605, result.scanned());
        result.assertComplete();
    }

    /**
     * 17. Ordering. Paging is only sound over a total order; {@code createdAt} alone is not one,
     * because rows written inside a single transaction share it to the microsecond. The repository
     * already breaks the tie on {@code id}, and this proves it: two independent full passes over a
     * static dataset return the identical sequence.
     */
    @Test
    @Transactional
    void orderingIsTotalAndRepeatableSoPagingCannotDriftBetweenPasses() {
        String action = plant(450, -1);
        var first = AdminAuditScan.scanAction(auditRepo, action, null);
        var second = AdminAuditScan.scanAction(auditRepo, action, null);
        first.assertComplete();
        second.assertComplete();
        assertEquals(first.idsInOrder(), second.idsInOrder(),
            "two passes over an unchanged dataset returned different orders");

        // And the order really is newest-first with the id as tiebreaker.
        List<Long> ids = first.idsInOrder();
        for (int i = 1; i < ids.size(); i++) {
            assertTrue(ids.get(i - 1) > ids.get(i),
                "ids must descend within one createdAt tick: " + ids.get(i - 1) + " then " + ids.get(i));
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // 10–14 · ACTION AND TARGET INVENTORY, FROM SOURCE
    // ══════════════════════════════════════════════════════════════════════════

    /**
     * 10 + 22. The inventory is derived by reading {@code src/main/java}, not by trusting a list
     * kept in a test. It proves every action name is emitted from exactly one call site, which is
     * the structural half of duplicate-audit protection: a second call site for an existing action
     * is how one mutation quietly starts writing two rows.
     */
    @Test
    void sourceInventoryHasOneCallSitePerActionAndNoCollisions() throws IOException {
        Map<String, List<String>> sites = actionCallSitesFromSource();
        Assumptions.assumeFalse(sites.isEmpty(), "source tree not reachable from the test working dir");

        List<String> emittedTwice = sites.entrySet().stream()
            .filter(e -> e.getValue().size() > 1)
            .map(e -> e.getKey() + " <- " + e.getValue()).toList();
        assertTrue(emittedTwice.isEmpty(),
            "an action emitted from more than one call site can double-record: " + emittedTwice);

        List<String> malformed = sites.keySet().stream()
            .filter(a -> !a.matches("[A-Z][A-Z0-9_]{2,79}")).toList();
        assertTrue(malformed.isEmpty(), "malformed action names: " + malformed);

        // Phase A deliberately adds four: ADMIN_LOGIN_SUCCESS, ADMIN_LOGIN_FAILED, ADMIN_PASSWORD_CHANGE and
        // ADMIN_PASSWORD_RESET (AuthService, AccountService), each from one call site.
        // RBAC R3a deliberately adds two: ADMIN_STEP_UP and ADMIN_STEP_UP_FAILED (AuthService.stepUp, §22.3).
        // RBAC R6 deliberately adds four (§22.3, §22.5): ADMIN_PROFILE_GRANT and ADMIN_PROFILE_REVOKE
        // (AdminProfileService), TRAVEL_WALLET_VIEW and CONVERSATION_VIEW (AdminReadAuditService).
        // RBAC R6 dual control deliberately adds six (§22.3, §22.6), each from one call site in AdminDualControlService:
        // DUAL_CONTROL_REQUEST, DUAL_CONTROL_APPROVE, DUAL_CONTROL_REJECT, DUAL_CONTROL_CANCEL, DUAL_CONTROL_EXPIRE and
        // DUAL_CONTROL_STALE. HOTEL_ASSIGN_OWNER keeps its single call site and now runs only on approval.
        assertEquals(126, sites.size(),
            "RBAC R6: the trail emits exactly 126 distinct administrative actions (116 after R3a + 2 profile + 2 read audit"
                + " + 6 dual control). "
                + "If a later phase legitimately adds one, update this number deliberately. Found: "
                + sites.size());
    }

    /**
     * 11 + 12. Every action the source declares is queryable through the API, and the filter is
     * exact — no other action leaks into the result.
     */
    @Test
    void everySourceActionIsQueryableAndTheFilterIsExact() throws Exception {
        Map<String, List<String>> sites = actionCallSitesFromSource();
        Assumptions.assumeFalse(sites.isEmpty(), "source tree not reachable from the test working dir");

        List<String> rejected = new ArrayList<>();
        List<String> leaked = new ArrayList<>();
        for (String action : sites.keySet()) {
            var res = mvc.perform(get("/api/admin/activity-logs?size=50&action=" + action)
                    .header("Authorization", "Bearer " + adminToken))
                .andReturn().getResponse();
            if (res.getStatus() != 200) {
                rejected.add(action + " -> " + res.getStatus());
                continue;
            }
            for (JsonNode row : mapper.readTree(res.getContentAsString()).get("content")) {
                if (!action.equals(row.get("action").asText())) {
                    leaked.add(action + " returned " + row.get("action").asText());
                }
            }
        }
        assertTrue(rejected.isEmpty(), "the audit API refused these action filters: " + rejected);
        assertTrue(leaked.isEmpty(), "the action filter leaked other actions: " + leaked);
    }

    /** 13. Target types: queryable, well formed, and no cross-target leakage. */
    @Test
    void everyTargetTypeIsQueryableWithNoCrossTargetLeakage() throws Exception {
        Set<String> targetTypes = targetTypesFromSource();
        Assumptions.assumeFalse(targetTypes.isEmpty(), "source tree not reachable");

        // RBAC R6 dual control deliberately adds one: DUAL_CONTROL_REQUEST.
        assertEquals(36, targetTypes.size(),
            "The trail uses exactly 36 target types (35 + DUAL_CONTROL_REQUEST). Found: " + targetTypes.size());

        for (String targetType : targetTypes) {
            assertTrue(targetType.matches("[A-Z][A-Z0-9_]{2,59}"), "malformed target type: " + targetType);
            JsonNode page = getJson("/api/admin/activity-logs?size=25&targetType=" + targetType);
            for (JsonNode row : page.get("content")) {
                assertEquals(targetType, row.get("targetType").asText(),
                    "targetType filter leaked a different target");
            }
        }
    }

    /**
     * 14. Filter combinations, each proven to actually narrow rather than be ignored. The row it
     * filters on is created here rather than borrowed from whatever another test class happened to
     * leave behind, so this passes when the class runs alone.
     */
    @Test
    void filterCombinationsNarrowRatherThanBeingIgnored() throws Exception {
        long amenityId = createAmenity("D3J Filters");

        // action + targetType
        JsonNode combined = getJson(
            "/api/admin/activity-logs?size=25&action=AMENITY_CREATE&targetType=AMENITY");
        assertTrue(combined.get("totalElements").asLong() > 0);
        for (JsonNode row : combined.get("content")) {
            assertEquals("AMENITY_CREATE", row.get("action").asText());
            assertEquals("AMENITY", row.get("targetType").asText());
        }
        assertEquals(0, getJson("/api/admin/activity-logs?size=5"
            + "&action=AMENITY_CREATE&targetType=BOOKING").get("totalElements").asLong(),
            "a mismatched action/targetType pair must return nothing, not everything");

        // action + targetId narrows to the single row just written
        assertEquals(1, getJson("/api/admin/activity-logs?size=5&action=AMENITY_CREATE&targetId="
            + amenityId).get("totalElements").asLong());

        // action + actorUserId
        assertTrue(getJson("/api/admin/activity-logs?size=5&action=AMENITY_CREATE&actorUserId="
            + adminUserId).get("totalElements").asLong() > 0);
        assertEquals(0, getJson("/api/admin/activity-logs?size=5&action=AMENITY_CREATE"
            + "&actorUserId=99999999").get("totalElements").asLong(),
            "the actor filter must be applied, not ignored");

        // action + from/to
        assertTrue(getJson("/api/admin/activity-logs?size=5&action=AMENITY_CREATE"
            + "&from=2020-01-01T00:00:00Z").get("totalElements").asLong() > 0);
        assertEquals(0, getJson("/api/admin/activity-logs?size=5&action=AMENITY_CREATE"
            + "&to=2020-01-01T00:00:00Z").get("totalElements").asLong(),
            "the date filter must be applied, not ignored");

        // action + pagination
        JsonNode paged = getJson("/api/admin/activity-logs?size=2&page=0&action=AMENITY_CREATE");
        assertEquals(2, paged.get("size").asInt());
        assertEquals(0, paged.get("page").asInt());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // 15–16, 23–25 · THE READ API'S PAGINATION CONTRACT
    // ══════════════════════════════════════════════════════════════════════════

    /** 16 + 23 + 24 + 25. Envelope, bounds, clamping and out-of-range behaviour. */
    @Test
    void paginationEnvelopeBoundsAndClampingAreUnchanged() throws Exception {
        JsonNode first = getJson("/api/admin/activity-logs?page=0&size=5");
        for (String key : List.of("content", "page", "size", "totalElements", "totalPages")) {
            assertTrue(first.has(key), "the PageResponse envelope lost " + key);
        }
        assertEquals(0, first.get("page").asInt());
        assertEquals(5, first.get("size").asInt());
        long total = first.get("totalElements").asLong();
        int totalPages = first.get("totalPages").asInt();
        assertTrue(total > 0);
        assertEquals((int) Math.ceil(total / 5.0), totalPages, "totalPages must match totalElements");

        // Last page is partial and non-empty.
        JsonNode last = getJson("/api/admin/activity-logs?page=" + (totalPages - 1) + "&size=5");
        assertFalse(last.get("content").isEmpty(), "the last declared page must not be empty");

        // A page beyond the end is empty but still a well-formed envelope with the true total.
        JsonNode beyond = getJson("/api/admin/activity-logs?page=" + (totalPages + 50) + "&size=5");
        assertTrue(beyond.get("content").isEmpty());
        assertEquals(total, beyond.get("totalElements").asLong());

        // Clamping, unchanged: size is capped at 200, size<1 becomes 20, page<0 becomes 0.
        assertEquals(200, getJson("/api/admin/activity-logs?size=100000").get("size").asInt());
        assertEquals(20, getJson("/api/admin/activity-logs?size=0").get("size").asInt());
        assertEquals(0, getJson("/api/admin/activity-logs?page=-5&size=0").get("page").asInt());

        // An empty result set is still a well-formed envelope.
        JsonNode empty = getJson("/api/admin/activity-logs?action=D3J_NOTHING_" + tag());
        assertTrue(empty.get("content").isEmpty());
        assertEquals(0, empty.get("totalElements").asLong());
        assertEquals(0, empty.get("totalPages").asInt());

        // Malformed date range is refused, not silently ignored.
        mvc.perform(get("/api/admin/activity-logs?from=2030-01-01T00:00:00Z&to=2020-01-01T00:00:00Z")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isBadRequest());
    }

    /**
     * 8 + 9, at the API layer: walking every page loses and repeats nothing. Four rows are written
     * first and the walk uses {@code size=1}, so the multi-page condition holds even when this
     * class runs on its own; the same walk is then repeated over the entire trail.
     */
    @Test
    void walkingEveryApiPageServesEachRowExactlyOnce() throws Exception {
        for (int i = 0; i < 4; i++) {
            createAmenity("D3J Walk " + i);
        }

        // A controlled, guaranteed multi-page result set.
        assertPageWalkIsExact("/api/admin/activity-logs?action=AMENITY_CREATE", 1, true);

        // And the whole trail, at a realistic page size.
        assertPageWalkIsExact("/api/admin/activity-logs", 50, false);
    }

    /** Walks every declared page of {@code baseQuery} and proves the union is exact. */
    private void assertPageWalkIsExact(String baseQuery, int size, boolean requireMultiplePages)
            throws Exception {
        String sep = baseQuery.contains("?") ? "&" : "?";
        JsonNode head = getJson(baseQuery + sep + "page=0&size=" + size);
        long total = head.get("totalElements").asLong();
        int pages = head.get("totalPages").asInt();
        if (requireMultiplePages) {
            assertTrue(pages > 1, "expected more than one page for " + baseQuery + ", got " + pages);
        }

        Set<Long> seen = new LinkedHashSet<>();
        List<Long> duplicates = new ArrayList<>();
        for (int p = 0; p < pages; p++) {
            for (JsonNode row : getJson(baseQuery + sep + "page=" + p + "&size=" + size)
                    .get("content")) {
                if (!seen.add(row.get("id").asLong())) duplicates.add(row.get("id").asLong());
            }
        }
        assertTrue(duplicates.isEmpty(), baseQuery + " served these rows twice: " + duplicates);
        assertEquals(total, seen.size(),
            baseQuery + " walking every page did not cover every declared row");
    }

    /** 15. Role matrix on the trail itself. */
    @Test
    void auditTrailIsReadableByAdminsOnly() throws Exception {
        mvc.perform(get("/api/admin/activity-logs")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/admin/activity-logs")
                .header("Authorization", "Bearer " + userToken)).andExpect(status().isForbidden());
        mvc.perform(get("/api/admin/activity-logs")
                .header("Authorization", "Bearer " + partnerToken)).andExpect(status().isForbidden());
        mvc.perform(get("/api/admin/activity-logs")
                .header("Authorization", "Bearer " + adminToken)).andExpect(status().isOk());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // 18–19 · THE WRITE-TIME GUARD
    // ══════════════════════════════════════════════════════════════════════════

    /** 18 + 19. Every credential shape is refused, in each of the three text fields. */
    @Test
    void writeTimeGuardRefusesEveryCredentialShapeInEveryTextField() {
        List<String> shapes = List.of(
            "the password is hunter2",
            "Authorization: Bearer abc.def.ghi",
            "token eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
            "api_key=AKIAIOSFODNN7EXAMPLE",
            "api-key AKIAIOSFODNN7EXAMPLE",
            "private_key -----BEGIN",
            "client secret rotated",
            "cvv 123",
            "iban DE89370400440532013000",
            "swift DEUTDEFF",
            "card 4532015112830366");

        for (String shape : shapes) {
            assertThrows(IllegalArgumentException.class,
                () -> auditService.record(adminUserId, "D3J_GUARD_PROBE", "USER", 1L, shape),
                "description accepted a credential shape: " + shape);
            assertThrows(IllegalArgumentException.class,
                () -> auditService.record(adminUserId, "D3J_GUARD_PROBE", "USER", 1L, "safe", shape, null),
                "beforeState accepted a credential shape: " + shape);
            assertThrows(IllegalArgumentException.class,
                () -> auditService.record(adminUserId, "D3J_GUARD_PROBE", "USER", 1L, "safe", null, shape),
                "afterState accepted a credential shape: " + shape);
        }
    }

    /**
     * 19. Credential-shaped numbers, at the exact boundaries of the 13–19 digit rule, and the
     * documented reason 12 and 20 digits pass: the rule targets card and account numbers, and the
     * helpers added by D3H/D3I keep legitimate values from ever reaching it.
     */
    @Test
    void credentialShapedNumberBoundariesBehaveAsSpecified() {
        assertDoesNotThrow(() -> AuditHelperBridge.safeNumber(null));

        // 12 digits passes the guard, 13 through 19 do not, 20 passes again.
        assertFalse(FORBIDDEN.matcher("ref:123456789012").find(), "12 digits is below the rule");
        for (int len : new int[]{13, 16, 19}) {
            assertTrue(FORBIDDEN.matcher("ref:" + "9".repeat(len)).find(), len + " digits must match");
        }
        assertFalse(FORBIDDEN.matcher("ref:" + "9".repeat(20)).find(), "20 digits is above the rule");

        // D3H's helper keeps a legitimate precision-15 amount from tripping it at all.
        assertEquals("(out-of-range)", AuditHelperBridge.safeNumber(new java.math.BigDecimal("9999999999999")));
        assertEquals("999999999999", AuditHelperBridge.safeNumber(new java.math.BigDecimal("999999999999")));
        assertFalse(FORBIDDEN.matcher("price:" + AuditHelperBridge
            .safeNumber(new java.math.BigDecimal("9999999999999.00"))).find());

        // D3I's helper redacts rather than letting operator text roll a mutation back.
        assertEquals("(redacted)", AuditHelperBridge.safeText("my password is x", 40));
        assertEquals("Rooftop Pool", AuditHelperBridge.safeText("  Rooftop   Pool ", 40));
        assertEquals("-", AuditHelperBridge.safeText(null, 40));
    }

    /**
     * The guard inspects the whole string, not just the part that will survive truncation. If it
     * ran after {@code truncate}, a secret past character 4000 would be stored unseen.
     */
    @Test
    void guardInspectsTheFullTextNotOnlyThePortionThatWillBeStored() {
        String longThenSecret = "x".repeat(4500) + " password";
        assertThrows(IllegalArgumentException.class,
            () -> auditService.record(adminUserId, "D3J_GUARD_PROBE", "USER", 1L, longThenSecret),
            "a secret beyond the truncation point must still be refused");
    }

    /**
     * The suite's known false positives, pinned so they stay understood rather than being made to
     * disappear by loosening the pattern. "assigned" contains "signed"; neither is a credential,
     * and neither is what the rule targets — the rule has no "signed" term at all, which is exactly
     * why these two descriptions are safe and why the scanners must not invent one.
     */
    @Test
    void knownFalsePositivesAreUnderstoodAndTheGuardIsNotWeakened() {
        String assigned = "Admin manually assigned membership tier for user 42";
        String assignedHotel = "Admin assigned hotel 7 to partner profile 3";
        assertFalse(FORBIDDEN.matcher(assigned).find(),
            "the guard itself never flagged 'assigned' — only a scanner's own broader word list did");
        assertFalse(FORBIDDEN.matcher(assignedHotel).find());
        assertDoesNotThrow(() -> auditService.record(adminUserId, "D3J_GUARD_PROBE", "USER", 1L, assigned));

        // The pattern still carries every term it is supposed to.
        for (String term : List.of("password", "passwd", "secret", "bearer ", "api_key",
                "private_key", "cvv", "iban", "swift")) {
            assertTrue(FORBIDDEN.matcher("x " + term + " y").find(),
                "the guard lost its '" + term + "' term");
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // 20 · COLUMN AND PAYLOAD BOUNDARIES
    // ══════════════════════════════════════════════════════════════════════════

    /**
     * 20. The state columns are {@code varchar(500)} and description is {@code TEXT}; the service
     * truncates to 500/4000 rather than letting the driver raise. Oversized input must be bounded,
     * stored, and never cause a DB error — the audit write shares the mutation's transaction, so a
     * column overflow here would roll back the business change it was recording.
     */
    @Test
    @Transactional
    void oversizedTextIsBoundedRatherThanFailingTheTransaction() {
        String action = "D3J_BOUNDS_" + tag();
        String hugeState = "s".repeat(5_000);
        String hugeDescription = "d".repeat(9_000);

        assertDoesNotThrow(() -> auditService.record(
            adminUserId, action, "USER", 1L, hugeDescription, hugeState, hugeState));

        AdminActivityLog row = AdminAuditScan.scanAction(auditRepo, action, null).idsInOrder().stream()
            .findFirst().flatMap(auditRepo::findById).orElseThrow();
        assertEquals(500, row.getBeforeState().length(), "beforeState must be bounded to the column");
        assertEquals(500, row.getAfterState().length());
        assertEquals(4_000, row.getDescription().length());

        // Exactly at the boundary: stored whole, not clipped by one.
        String exactState = "e".repeat(500);
        String exactDescription = "f".repeat(4_000);
        auditService.record(adminUserId, action, "USER", 2L, exactDescription, exactState, exactState);
        AdminActivityLog exact = auditRepo
            .search(null, action, null, 2L, null, null, PageRequest.of(0, 1)).getContent().get(0);
        assertEquals(exactState, exact.getBeforeState());
        assertEquals(exactDescription, exact.getDescription());
    }

    /** 20. Multibyte text must not overflow a character-counted column or corrupt on read-back. */
    @Test
    @Transactional
    void multibyteTextIsTruncatedByCharactersAndReadsBackIntact() {
        String action = "D3J_UTF8_" + tag();
        String vietnamese = "Khách sạn Vũng Tàu ";
        String state = vietnamese.repeat(60);            // > 500 characters, many multibyte
        assertTrue(state.length() > 500);

        assertDoesNotThrow(() ->
            auditService.record(adminUserId, action, "PLACE", 1L, "multibyte probe", state, state));

        AdminActivityLog row = auditRepo
            .search(null, action, null, null, null, null, PageRequest.of(0, 1)).getContent().get(0);
        assertEquals(500, row.getBeforeState().length());
        assertEquals(state.substring(0, 500), row.getBeforeState(),
            "multibyte content must survive the round trip unmangled");
        assertTrue(row.getBeforeState().contains("Vũng Tàu"));
    }

    // ══════════════════════════════════════════════════════════════════════════
    // 21–22 · ORPHANS AND DUPLICATES, THROUGH THE REAL ENDPOINTS
    // ══════════════════════════════════════════════════════════════════════════

    /**
     * 21. A refused mutation leaves no audit row, across every refusal class the API produces.
     * The counts are taken over the whole trail, so a stray row anywhere is caught.
     */
    @Test
    void refusedMutationsLeaveNoOrphanAuditRow() throws Exception {
        long before = auditRepo.count();

        // 401 anonymous
        mvc.perform(post("/api/admin/amenities").contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"D3J orphan\"}"))
            .andExpect(status().isUnauthorized());
        // 403 wrong role
        mvc.perform(post("/api/admin/amenities").header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON).content("{\"name\":\"D3J orphan\"}"))
            .andExpect(status().isForbidden());
        // 400 validation
        mvc.perform(post("/api/admin/amenities").header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON).content("{\"name\":\"\"}"))
            .andExpect(status().isBadRequest());
        // 404 unknown id
        mvc.perform(patch("/api/admin/amenities/99999999/status")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON).content("{\"active\":false}"))
            .andExpect(status().isNotFound());
        // 409 conflict
        String slug = "d3j-conflict-" + tag();
        mvc.perform(post("/api/admin/amenities").header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"D3J Conflict\",\"slug\":\"" + slug + "\"}"))
            .andExpect(status().isCreated());
        mvc.perform(post("/api/admin/amenities").header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"D3J Conflict Two\",\"slug\":\"" + slug + "\"}"))
            .andExpect(status().isConflict());

        assertEquals(before + 1, auditRepo.count(),
            "exactly one row — the single amenity that was actually created");
    }

    /** 22. One successful mutation writes exactly one row, counted over the whole trail. */
    @Test
    void oneSuccessfulMutationWritesExactlyOneRow() throws Exception {
        long totalBefore = auditRepo.count();
        long actionBefore = countOf("AMENITY_CREATE");

        String body = "{\"name\":\"D3J Single\",\"slug\":\"d3j-single-" + tag() + "\"}";
        long id = mapper.readTree(mvc.perform(post("/api/admin/amenities")
                    .header("Authorization", "Bearer " + adminToken)
                    .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString())
            .get("id").asLong();

        assertEquals(totalBefore + 1, auditRepo.count(), "the trail grew by more than one row");
        assertEquals(actionBefore + 1, countOf("AMENITY_CREATE"));
        assertEquals(1, auditRepo.search(null, "AMENITY_CREATE", null, id, null, null,
            PageRequest.of(0, 10)).getTotalElements(), "duplicate rows for one mutation");
    }

    // ══════════════════════════════════════════════════════════════════════════
    // THE GLOBAL SCAN — now exhaustive, over everything the suite produced
    // ══════════════════════════════════════════════════════════════════════════

    /**
     * The replacement for the capped scan, run over the real trail: every stored row, every text
     * field, plus the actor/target sanity the checkpoint phases asserted separately.
     */
    @Test
    void everyStoredRowIsSafeAndWellFormed() {
        List<String> problems = new ArrayList<>();
        var result = AdminAuditScan.scanAll(auditRepo, row -> {
            for (String field : new String[]{row.getDescription(), row.getBeforeState(), row.getAfterState()}) {
                if (field != null && FORBIDDEN.matcher(field).find()) {
                    problems.add("row " + row.getId() + " (" + row.getAction() + ") stored credential-shaped text");
                }
            }
            if (row.getAction() == null || !row.getAction().matches("[A-Z][A-Z0-9_]{2,79}")) {
                problems.add("row " + row.getId() + " has a malformed action: " + row.getAction());
            }
            if (row.getActorEmail() == null || row.getActorEmail().isBlank()) {
                problems.add("row " + row.getId() + " has no actor snapshot");
            }
            if (row.getBeforeState() != null && row.getBeforeState().length() > 500) {
                problems.add("row " + row.getId() + " overflowed beforeState");
            }
            if (row.getAfterState() != null && row.getAfterState().length() > 500) {
                problems.add("row " + row.getId() + " overflowed afterState");
            }
        });
        result.assertComplete();

        assertTrue(problems.isEmpty(), "problems in the stored trail: " + problems);
        assertEquals(auditRepo.count(), result.declaredTotal(),
            "the filtered query's total disagrees with the table count");
        assertEquals(result.declaredTotal(), result.scanned(),
            "the scan must cover every row the query declared");

        // When the trail really is bigger than one page — which it is in a full-suite run — the
        // scan must have read more than one. Asserted conditionally so the class also passes alone.
        if (result.declaredTotal() > AdminAuditScan.BATCH) {
            assertTrue(result.pagesRead() > 1,
                "a trail of " + result.declaredTotal() + " rows was scanned in one page");
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // helpers
    // ══════════════════════════════════════════════════════════════════════════

    private boolean looksLikeACredential(AdminActivityLog row) {
        for (String field : new String[]{row.getDescription(), row.getBeforeState(), row.getAfterState()}) {
            if (field != null && FORBIDDEN.matcher(field).find()) return true;
        }
        return false;
    }

    /**
     * Plants {@code count} rows under a fresh action, optionally making the row that will land at
     * scan index {@code secretAt} credential-shaped. Rows go in through the repository because the
     * service guard would refuse the planted secret — which is exactly the situation a persisted
     * scan exists for. The caller is {@code @Transactional}, so none of this survives the test.
     *
     * <p>Scan order is newest-first with the id as tiebreaker, so insertion order reverses: the row
     * inserted at index {@code count - 1 - secretAt} is the one that lands at scan index
     * {@code secretAt}. The tests assert the position they got rather than trusting this arithmetic.
     */
    private String plant(int count, int secretAt) {
        String action = "D3J_PLANT_" + tag();
        int secretInsertIndex = secretAt < 0 ? -1 : count - 1 - secretAt;
        for (int i = 0; i < count; i++) {
            AdminActivityLog row = new AdminActivityLog();
            row.setActorUserId(adminUserId);
            row.setActorEmail("admin@planyourtrip.com");
            row.setAction(action);
            row.setTargetType("USER");
            row.setTargetId((long) i);
            row.setDescription(i == secretInsertIndex
                ? "planted row " + i + " carrying a password value"
                : "planted row " + i);
            row.setBeforeState("i:" + i);
            row.setAfterState("i:" + (i + 1));
            auditRepo.save(row);
        }
        return action;
    }

    /** One real, committed administrative mutation, so filter/paging checks have genuine rows. */
    private long createAmenity(String name) throws Exception {
        String body = "{\"name\":\"" + name + "\",\"slug\":\"d3j-" + tag().toLowerCase() + "\"}";
        return mapper.readTree(mvc.perform(post("/api/admin/amenities")
                    .header("Authorization", "Bearer " + adminToken)
                    .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString())
            .get("id").asLong();
    }

    private long countOf(String action) {
        return auditRepo.search(null, action, null, null, null, null, PageRequest.of(0, 1))
            .getTotalElements();
    }

    private static String tag() {
        return UUID.randomUUID().toString().substring(0, 8).toUpperCase().replace('-', 'X');
    }

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private JsonNode getJson(String path) throws Exception {
        return mapper.readTree(mvc.perform(get(path).header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
    }

    // ── source-derived inventory ──────────────────────────────────────────────

    private static final Pattern RECORD_CALL =
        Pattern.compile("\\.(record|recordSystem)\\s*\\(");

    /** action -> the call sites that emit it, read out of {@code src/main/java}. */
    private static Map<String, List<String>> actionCallSitesFromSource() throws IOException {
        Path root = Paths.get("src", "main", "java", "com", "example", "planyourtrip");
        if (!Files.isDirectory(root)) return Map.of();

        Map<String, List<String>> sites = new LinkedHashMap<>();
        try (Stream<Path> files = Files.walk(root)) {
            for (Path file : files.filter(p -> p.toString().endsWith(".java")).toList()) {
                String src = Files.readString(file, StandardCharsets.UTF_8);
                Matcher call = RECORD_CALL.matcher(src);
                while (call.find()) {
                    // The action is the first string literal after the opening paren: the actor
                    // argument before it is always a variable or null, never a literal.
                    Matcher literal = Pattern.compile("\"([^\"]*)\"").matcher(src);
                    if (!literal.find(call.end())) continue;
                    String action = literal.group(1);
                    if (!action.matches("[A-Z][A-Z0-9_]{2,79}")) continue;
                    sites.computeIfAbsent(action, k -> new ArrayList<>())
                        .add(file.getFileName().toString());
                }
            }
        }
        return sites;
    }

    /** The distinct target types named at those same call sites. */
    private static Set<String> targetTypesFromSource() throws IOException {
        Path root = Paths.get("src", "main", "java", "com", "example", "planyourtrip");
        if (!Files.isDirectory(root)) return Set.of();

        Set<String> types = new LinkedHashSet<>();
        try (Stream<Path> files = Files.walk(root)) {
            for (Path file : files.filter(p -> p.toString().endsWith(".java")).toList()) {
                String src = Files.readString(file, StandardCharsets.UTF_8);
                Matcher call = RECORD_CALL.matcher(src);
                while (call.find()) {
                    boolean system = "recordSystem".equals(call.group(1));
                    Matcher literal = Pattern.compile("\"([^\"]*)\"").matcher(src);
                    int at = call.end();
                    // record(...): action then targetType. recordSystem(...): action then targetType.
                    if (!literal.find(at)) continue;
                    if (!literal.group(1).matches("[A-Z][A-Z0-9_]{2,79}")) continue;
                    if (!literal.find(literal.end())) continue;
                    String targetType = literal.group(1);
                    if (targetType.matches("[A-Z][A-Z0-9_]{2,59}")) types.add(targetType);
                }
            }
        }
        return types;
    }
}
