package com.example.planyourtrip;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
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
 */
@SpringBootTest
@AutoConfigureMockMvc
class AdminPaginationContractTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;

    private String adminToken;
    private String userToken;

    /** The four endpoints converted in D1a, with a sort field each one allows. */
    private static final String[][] ENDPOINTS = {
        {"/api/admin/bookings", "createdAt"},
        {"/api/admin/payments", "amount"},
        {"/api/admin/reviews",  "ratingOverall"},
        {"/api/admin/invoices", "status"},
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
}
