package com.example.planyourtrip;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import jakarta.persistence.EntityManagerFactory;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * D1a — the pagination contract for the P0 admin collections.
 *
 * <p>D0-2 found 20 of 24 admin collections returning unbounded {@code List<T>} while silently
 * ignoring {@code ?page/size}. The four highest-growth grids — bookings, payments, reviews,
 * invoices — now return the project's existing {@code PageResponse} envelope, page in the database
 * rather than in Java, and accept only allowlisted sort fields.
 *
 * <p><b>D1c</b> extends the same contract to the collections whose row counts are driven by
 * end-user activity rather than by administrative curation: notifications (one row per recipient
 * per broadcast), payment sessions (one row per checkout attempt, abandoned ones included),
 * conversations, and the partner roster. They are added to {@link #ENDPOINTS} rather than given
 * their own assertions, so every rule above is enforced on them by construction.
 */
@SpringBootTest
@AutoConfigureMockMvc
class AdminPaginationContractTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired EntityManagerFactory emf;

    private String adminToken;
    private String userToken;

    /** Every paginated admin collection, with a sort field each one allows. */
    private static final String[][] ENDPOINTS = {
        // D1a
        {"/api/admin/bookings", "createdAt"},
        {"/api/admin/payments", "amount"},
        {"/api/admin/reviews",  "ratingOverall"},
        {"/api/admin/invoices", "status"},
        // D1c
        {"/api/admin/notifications",    "createdAt"},
        {"/api/admin/conversations",    "lastMessageAt"},
        {"/api/admin/payment-sessions", "amount"},
        {"/api/admin/partners",         "businessName"},
    };

    @BeforeEach
    void setup() throws Exception {
        adminToken = login("admin@planyourtrip.com", "admin123456");
        userToken = login("demo@planyourtrip.com", "demo123456");
    }

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private JsonNode get(String url) throws Exception {
        String body = mvc.perform(MockMvcRequestBuilders.get(url)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    @Test
    void defaultPage_returnsTheProjectPageEnvelope() throws Exception {
        for (String[] ep : ENDPOINTS) {
            JsonNode env = get(ep[0]);
            assertTrue(env.has("content"), ep[0] + " must return content");
            assertTrue(env.has("page") && env.has("size")
                    && env.has("totalElements") && env.has("totalPages"),
                ep[0] + " must return the full PageResponse envelope");
            assertEquals(0, env.get("page").asInt(), ep[0] + " defaults to page 0");
            assertEquals(20, env.get("size").asInt(), ep[0] + " defaults to size 20");
        }
    }

    @Test
    void explicitSize_isHonouredByTheDatabaseNotBySlicingInJava() throws Exception {
        for (String[] ep : ENDPOINTS) {
            JsonNode env = get(ep[0] + "?page=0&size=1");
            assertEquals(1, env.get("size").asInt(), ep[0]);
            assertTrue(env.get("content").size() <= 1, ep[0] + " must return at most one row");
        }
    }

    @Test
    void totalsAreConsistentWithPageSize() throws Exception {
        for (String[] ep : ENDPOINTS) {
            JsonNode env = get(ep[0] + "?page=0&size=1");
            long total = env.get("totalElements").asLong();
            int pages = env.get("totalPages").asInt();
            assertEquals(total, pages, ep[0] + ": with size=1, totalPages must equal totalElements");
        }
    }

    /**
     * Pagination must be stable. Rows sharing a {@code createdAt} (the seeded bookings do) would
     * otherwise come back in an arbitrary order per query, so consecutive pages could repeat one row
     * and silently skip another. {@code AdminPaging} appends a unique id tiebreaker to every sort.
     */
    @Test
    void pagingIsStable_consecutivePagesDoNotRepeatOrSkipRows() throws Exception {
        JsonNode first = get("/api/admin/bookings?page=0&size=1");
        long total = first.get("totalElements").asLong();
        if (total < 2) return;   // needs at least two rows

        JsonNode second = get("/api/admin/bookings?page=1&size=1");
        assertEquals(1, second.get("page").asInt());
        long firstId = first.get("content").get(0).get("id").asLong();
        long secondId = second.get("content").get(0).get("id").asLong();
        assertNotEquals(firstId, secondId, "a later page must return a different row");

        // Walking every page must yield exactly the full set, with no duplicate and no omission.
        java.util.Set<Long> seen = new java.util.HashSet<>();
        for (int p = 0; p < total; p++) {
            JsonNode page = get("/api/admin/bookings?page=" + p + "&size=1");
            for (JsonNode n : page.get("content")) {
                assertTrue(seen.add(n.get("id").asLong()),
                    "row " + n.get("id") + " appeared on more than one page");
            }
        }
        assertEquals(total, seen.size(), "paging must visit every row exactly once");

        // And the same request twice must return the same row (deterministic ordering).
        assertEquals(firstId, get("/api/admin/bookings?page=0&size=1")
            .get("content").get(0).get("id").asLong(), "ordering must be deterministic");
    }

    @Test
    void allowedSortField_isAccepted() throws Exception {
        for (String[] ep : ENDPOINTS) {
            get(ep[0] + "?sort=" + ep[1]);
            get(ep[0] + "?sort=" + ep[1] + ",asc");
            get(ep[0] + "?sort=" + ep[1] + ",desc");
        }
    }

    /** The injection guard: a field outside the allowlist is a 400, never a query fragment. */
    @Test
    void disallowedSortField_isRejectedWith400() throws Exception {
        for (String[] ep : ENDPOINTS) {
            mvc.perform(MockMvcRequestBuilders.get(ep[0] + "?sort=id;DROP TABLE bookings")
                    .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isBadRequest());
            mvc.perform(MockMvcRequestBuilders.get(ep[0] + "?sort=passwordHash")
                    .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isBadRequest());
        }
    }

    @Test
    void invalidSortDirection_isRejectedWith400() throws Exception {
        mvc.perform(MockMvcRequestBuilders.get("/api/admin/bookings?sort=createdAt,sideways")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isBadRequest());
    }

    /** Malformed paging must be clamped, never surface as the 500 found in H-FIX verification. */
    @Test
    void malformedPaging_isClampedNot500() throws Exception {
        for (String[] ep : ENDPOINTS) {
            get(ep[0] + "?page=-1&size=5");
            get(ep[0] + "?page=0&size=0");
            get(ep[0] + "?page=0&size=-3");
        }
    }

    /** An admin cannot use size to pull the whole table back in one request. */
    @Test
    void oversizedPage_isClampedToTheCeiling() throws Exception {
        JsonNode env = get("/api/admin/bookings?size=100000");
        assertEquals(200, env.get("size").asInt(), "size must be clamped to the 200-row ceiling");
    }

    @Test
    void meaningfulFilters_areAppliedServerSide() throws Exception {
        JsonNode confirmed = get("/api/admin/bookings?status=CONFIRMED&size=200");
        for (JsonNode n : confirmed.get("content")) {
            assertEquals("CONFIRMED", n.get("status").asText());
        }
        JsonNode paid = get("/api/admin/payments?status=PAID&size=200");
        for (JsonNode n : paid.get("content")) {
            assertEquals("PAID", n.get("status").asText());
        }
        JsonNode approved = get("/api/admin/reviews?status=APPROVED&size=200");
        for (JsonNode n : approved.get("content")) {
            assertEquals("APPROVED", n.get("status").asText());
        }
    }

    @Test
    void authorizationIsUnchangedOnTheConvertedEndpoints() throws Exception {
        for (String[] ep : ENDPOINTS) {
            mvc.perform(MockMvcRequestBuilders.get(ep[0])
                    .header("Authorization", "Bearer " + userToken))
                .andExpect(status().isForbidden());
            mvc.perform(MockMvcRequestBuilders.get(ep[0]))
                .andExpect(status().isUnauthorized());
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // D1c
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * The partner trail is paged but deliberately has no {@code sort} parameter: its ordering is
     * fixed newest-first in the query, exactly like the administrative audit trail's own read
     * contract, so it carries no sort-injection surface at all.
     */
    @Test
    void partnerActivityLog_isPagedWithNoClientControlledOrdering() throws Exception {
        JsonNode env = get("/api/admin/partners/1/activity-logs");
        assertTrue(env.has("content") && env.get("content").isArray());
        assertTrue(env.has("page") && env.has("size")
            && env.has("totalElements") && env.has("totalPages"));
        assertEquals(0, env.get("page").asInt());
        assertEquals(20, env.get("size").asInt());

        // A sort parameter is simply not part of the contract. Supplying one must neither fail
        // nor change the ordering: it is ignored, so there is nothing to inject into.
        assertEquals(env.get("content").toString(),
            get("/api/admin/partners/1/activity-logs?sort=passwordHash,asc")
                .get("content").toString(),
            "an unrecognised sort parameter must not affect the trail's fixed ordering");

        // Same clamping rules as every other admin collection.
        get("/api/admin/partners/1/activity-logs?page=-1&size=0");
        assertEquals(200, get("/api/admin/partners/1/activity-logs?size=100000")
            .get("size").asInt());
    }

    /**
     * The conversation grid used to cost {@code 1 + 2N} queries: one per row for the newest
     * message, one per row for the lazy booking. Paging alone would not have fixed that — it would
     * only have capped N at the page size, so a 200-row page would still fire 400 extra queries.
     *
     * <p>The property that matters is that the query count is <b>independent of how many rows come
     * back</b>. Asserting a fixed number would be brittle across seed states; asserting that a
     * 200-row page costs no more queries than a 1-row page is the invariant an N+1 violates.
     */
    @Test
    void conversationGrid_queryCountDoesNotGrowWithPageSize() throws Exception {
        Statistics stats = emf.unwrap(SessionFactory.class).getStatistics();
        boolean wasEnabled = stats.isStatisticsEnabled();
        stats.setStatisticsEnabled(true);
        try {
            stats.clear();
            get("/api/admin/conversations?size=1");
            long smallPage = stats.getPrepareStatementCount();

            stats.clear();
            JsonNode big = get("/api/admin/conversations?size=200");
            long bigPage = stats.getPrepareStatementCount();

            assertTrue(bigPage <= smallPage,
                "a " + big.get("content").size() + "-row page issued " + bigPage
                    + " statements against " + smallPage + " for a 1-row page — the grid is "
                    + "loading per row again (N+1 reintroduced)");
        } finally {
            stats.setStatisticsEnabled(wasEnabled);
        }
    }

    /** An inverted date window is a client error, not an empty page and not a 500. */
    @Test
    void invertedDateRange_isRejectedWith400() throws Exception {
        for (String path : new String[]{"/api/admin/notifications", "/api/admin/payment-sessions"}) {
            mvc.perform(MockMvcRequestBuilders
                    .get(path + "?from=2030-01-02T00:00:00Z&to=2030-01-01T00:00:00Z")
                    .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isBadRequest());
        }
    }

    /** Every D1c filter must narrow the result set in the database, not in the client. */
    @Test
    void d1cFilters_areAppliedServerSide() throws Exception {
        JsonNode unread = get("/api/admin/notifications?read=false&size=200");
        for (JsonNode n : unread.get("content")) {
            assertFalse(n.get("read").asBoolean(), "read=false must exclude read notifications");
        }

        JsonNode approved = get("/api/admin/partners?verificationStatus=APPROVED&size=200");
        for (JsonNode n : approved.get("content")) {
            assertEquals("APPROVED", n.get("verificationStatus").asText());
        }

        JsonNode open = get("/api/admin/conversations?status=OPEN&size=200");
        for (JsonNode n : open.get("content")) {
            assertEquals("OPEN", n.get("status").asText());
        }

        JsonNode captured = get("/api/admin/payment-sessions?status=CAPTURED&size=200");
        for (JsonNode n : captured.get("content")) {
            assertEquals("CAPTURED", n.get("status").asText());
        }
    }

    /** The partner free-text search matches business name, representative name or contact email. */
    @Test
    void partnerSearch_matchesCaseInsensitivelyAndNarrowsTheSet() throws Exception {
        JsonNode all = get("/api/admin/partners?size=200");
        if (all.get("content").isEmpty()) return;

        String businessName = all.get("content").get(0).get("businessName").asText();
        String fragment = businessName.substring(0, Math.min(4, businessName.length()));

        JsonNode hits = get("/api/admin/partners?size=200&q="
            + java.net.URLEncoder.encode(fragment.toLowerCase(), java.nio.charset.StandardCharsets.UTF_8));
        assertTrue(hits.get("totalElements").asLong() >= 1, "the search must find its own source row");
        assertTrue(hits.get("totalElements").asLong() <= all.get("totalElements").asLong(),
            "a filter must never widen the result set");

        assertEquals(0, get("/api/admin/partners?q=zzz-no-such-partner-zzz")
            .get("totalElements").asLong());
    }

    /**
     * The conversation grid loads every row's newest message in one query rather than one query
     * per row. The preview it produces must still be the newest message — the point of the change
     * was the query count, not the answer.
     */
    @Test
    void conversationPreview_isTheNewestMessageDespiteBatchLoading() throws Exception {
        JsonNode env = get("/api/admin/conversations?size=200");
        for (JsonNode c : env.get("content")) {
            long id = c.get("id").asLong();
            JsonNode detail = get("/api/admin/conversations/" + id);
            JsonNode messages = detail.get("messages");
            if (messages == null || messages.isEmpty()) {
                assertTrue(c.get("lastMessagePreview").isNull(),
                    "a conversation with no messages must have no preview");
                continue;
            }
            // Compare against the highest message id rather than the last element of a
            // createdAt-ordered list: messages written in one transaction share a timestamp, and
            // only the identity column separates them deterministically.
            JsonNode newest = null;
            for (JsonNode m : messages) {
                if (newest == null || m.get("id").asLong() > newest.get("id").asLong()) newest = m;
            }
            assertEquals(newest.get("body").asText(), c.get("lastMessagePreview").asText(),
                "conversation " + id + " preview must be its newest message");
        }
    }
}
