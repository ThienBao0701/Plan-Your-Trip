package com.example.planyourtrip;

import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.service.LocationService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * D14 — public location search hardening.
 *
 * <p>D12 stopped a blank keyword from exporting the location table. D14 closes the ways a
 * <em>non-blank</em> keyword could still do it, without changing what the search looks at:
 *
 * <ul>
 *   <li>{@code %}, {@code _} and SQL Server's {@code [} are literal, not pattern operators;</li>
 *   <li>a keyword that normalises to nothing (no Latin characters) cannot turn the accent-free
 *       predicate into {@code LIKE '%%'};</li>
 *   <li>at most {@value LocationService#SEARCH_RESULT_LIMIT} rows, ordered {@code name, id};</li>
 *   <li>a keyword longer than {@value LocationService#SEARCH_KEYWORD_MAX_LENGTH} characters is a
 *       400.</li>
 * </ul>
 *
 * <p>The response is still a bare JSON array, and the four fields — name, accent-free name, slug and
 * former name — still match as they did.
 *
 * <p><b>Isolation.</b> The class is {@code @Transactional}, the convention the audit infrastructure
 * tests already use. MockMvc runs every request on the test thread, so each probe location a test
 * creates — and the audit row that create writes — joins the test's transaction and is rolled back
 * when the test ends: nothing is left in the shared H2 database, and no test depends on another having
 * run. Creates are inserted immediately (identity keys) and search is a JPQL query, which Hibernate
 * flushes pending changes ahead of, so every assertion still reads what the database returns.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class LocationSearchHardeningTest {

    private static final String SEARCH = "/api/locations/search";

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired AdministrativeUnitRepository locationRepo;

    private String adminToken;

    @BeforeEach
    void setup() throws Exception {
        adminToken = login("admin@planyourtrip.com", "admin123456");
    }

    // ══════════════════════════════════════════════════════════════════════════
    // BLANK STAYS EMPTY — the D12 rule, unchanged
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void aBlankOrMissingKeywordStillReturnsAnEmptyArray() throws Exception {
        for (String url : List.of(SEARCH, SEARCH + "?keyword=")) {
            JsonNode rows = mapper.readTree(content(mvc.perform(get(url)).andExpect(status().isOk())));
            assertTrue(rows.isArray(), url);
            assertEquals(0, rows.size(), url);
        }
        // Blank wins over length: whitespace longer than the keyword cap is still blank, not a 400.
        for (String blank : List.of("   ", " ".repeat(LocationService.SEARCH_KEYWORD_MAX_LENGTH + 50))) {
            assertEquals(List.of(), searchIds(blank), "a blank keyword of length " + blank.length());
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // ORDINARY MATCHING — the four fields still match
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void anOrdinaryKeywordStillMatchesEachOfTheFourFields() throws Exception {
        String sfx = suffix();
        Long id = create("D14 Hội An " + sfx, "d14-hoi-an-" + sfx, "Faifo" + sfx);

        assertTrue(searchIds("hội an " + sfx).contains(id), "name, accented, case-insensitive");
        assertTrue(searchIds("HOI AN " + sfx).contains(id),
            "accent-free name: only nameNormalized contains 'hoi an'");
        assertTrue(searchIds("d14-hoi-an-" + sfx).contains(id), "slug");
        assertTrue(searchIds("faifo" + sfx).contains(id), "former name");
    }

    // ══════════════════════════════════════════════════════════════════════════
    // WILDCARDS ARE LITERAL
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void aPercentSignIsMatchedLiterally() throws Exception {
        String sfx = suffix();
        Long literal = create("D14 Deal 100% " + sfx, "d14-deal-pct-" + sfx, null);
        Long lookalike = create("D14 Deal 1000 " + sfx, "d14-deal-num-" + sfx, null);

        List<Long> ids = searchIds("100% " + sfx);
        assertTrue(ids.contains(literal), ids.toString());
        assertFalse(ids.contains(lookalike), "an unescaped % would have matched '1000 '");

        List<JsonNode> rows = searchRows("%");
        assertTrue(ids(rows).contains(literal));
        for (JsonNode row : rows) {
            assertTrue(anyFieldContains(row, "%"), "a lone % is literal, not match-all: " + row);
        }
    }

    @Test
    void anUnderscoreIsMatchedLiterally() throws Exception {
        String sfx = suffix();
        Long literal = create("D14 Key a_b " + sfx, "d14-key-us-" + sfx, null);
        Long lookalike = create("D14 Key axb " + sfx, "d14-key-x-" + sfx, null);

        List<Long> ids = searchIds("a_b " + sfx);
        assertTrue(ids.contains(literal), ids.toString());
        assertFalse(ids.contains(lookalike), "an unescaped _ would have matched 'axb'");

        List<JsonNode> rows = searchRows("_");
        assertTrue(ids(rows).contains(literal));
        for (JsonNode row : rows) {
            assertTrue(anyFieldContains(row, "_"), "a lone _ is literal, not any-character: " + row);
        }
    }

    @Test
    void aSqlServerBracketIsMatchedLiterally() throws Exception {
        String sfx = suffix();
        Long literal = create("D14 Tag [abc] " + sfx, "d14-tag-bracket-" + sfx, null);
        Long lookalike = create("D14 Tag b " + sfx, "d14-tag-b-" + sfx, null);

        List<Long> ids = searchIds("[abc] " + sfx);
        assertTrue(ids.contains(literal), "the escaped pattern still matches the literal text");
        // On SQL Server an unescaped [abc] is a character class and would match 'b'. H2 has no
        // character classes, so the rule that makes it literal on SQL Server is pinned directly.
        assertFalse(ids.contains(lookalike));
        assertEquals("![abc] " + sfx, LocationService.escapeLike("[abc] " + sfx));
    }

    @Test
    void theEscapeCharacterItselfIsMatchedLiterally() throws Exception {
        String sfx = suffix();
        Long literal = create("D14 Wow! " + sfx, "d14-wow-bang-" + sfx, null);
        Long plain = create("D14 Wow " + sfx, "d14-wow-plain-" + sfx, null);

        List<Long> ids = searchIds("wow! " + sfx);
        assertTrue(ids.contains(literal), ids.toString());
        assertFalse(ids.contains(plain));
    }

    @Test
    void theEscapeRuleCoversEveryLikeMetacharacterAndNothingElse() {
        assertEquals('!', AdministrativeUnitRepository.LIKE_ESCAPE);
        assertEquals("100!%", LocationService.escapeLike("100%"));
        assertEquals("a!_b", LocationService.escapeLike("a_b"));
        assertEquals("![abc]", LocationService.escapeLike("[abc]"));
        assertEquals("wow!!", LocationService.escapeLike("wow!"));
        assertEquals("đà nẵng - vũng tàu] 42", LocationService.escapeLike("đà nẵng - vũng tàu] 42"),
            "ordinary text, and a closing bracket on its own, is untouched");
    }

    // ══════════════════════════════════════════════════════════════════════════
    // AN EMPTY NORMALISED KEYWORD NEVER MATCHES EVERYTHING
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void aKeywordWithNoLatinCharactersNeverMatchesTheWholeTable() throws Exception {
        String sfx = suffix();
        Long beijing = create("D14 北京 " + sfx, "d14-beijing-" + sfx, null);
        assertTrue(locationRepo.count() > 1, "the table must hold more than the probe row");

        List<JsonNode> rows = searchRows("北京");
        assertTrue(ids(rows).contains(beijing), "the name as typed is still matched");
        for (JsonNode row : rows) {
            assertTrue(anyFieldContains(row, "北京"), "only rows that contain the keyword: " + row);
        }

        assertEquals(List.of(), searchIds("東京"),
            "a keyword no row contains matches nothing — the empty normalised form is not a wildcard");
    }

    // ══════════════════════════════════════════════════════════════════════════
    // CAP AND ORDER
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void resultsAreCappedAtFiftyAndOrderedByName() throws Exception {
        String token = "d14cap" + suffix();
        int created = LocationService.SEARCH_RESULT_LIMIT + 5;
        // Created in descending name order, so id order is the reverse of name order: rows returned
        // in insertion order would fail the name assertions below.
        for (int i = created; i >= 1; i--) {
            create("D14 Cap " + token + " " + twoDigits(i), token + "-" + i, null);
        }

        List<JsonNode> rows = searchRows(token);
        assertEquals(LocationService.SEARCH_RESULT_LIMIT, rows.size(),
            created + " rows match; no more than the cap may be returned");
        for (int i = 0; i < rows.size(); i++) {
            assertEquals("D14 Cap " + token + " " + twoDigits(i + 1), rows.get(i).get("name").asText(),
                "position " + i);
        }
    }

    @Test
    void rowsThatShareANameAreOrderedById() throws Exception {
        String token = "d14tie" + suffix();
        Long first = create("D14 Tie " + token, token + "-1", null);
        Long second = create("D14 Tie " + token, token + "-2", null);
        Long byName = create("D14 Tia " + token, token + "-0", null);
        assertTrue(first < second && second < byName, "ids follow creation order");

        assertEquals(List.of(byName, first, second), searchIds(token),
            "name first ('Tia' before 'Tie'), then id for the two rows that share a name");
    }

    // ══════════════════════════════════════════════════════════════════════════
    // KEYWORD LENGTH
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void aKeywordLongerThanOneHundredCharactersIsABadRequest() throws Exception {
        int max = LocationService.SEARCH_KEYWORD_MAX_LENGTH;
        mvc.perform(get(SEARCH).param("keyword", "k".repeat(max))).andExpect(status().isOk());

        String body = content(mvc.perform(get(SEARCH).param("keyword", "k".repeat(max + 1)))
            .andExpect(status().isBadRequest()));
        JsonNode error = mapper.readTree(body);
        assertEquals(400, error.get("status").asInt());
        assertTrue(error.get("message").asText().startsWith("keyword:"), body);

        // Surrounding whitespace is not part of the keyword that is searched.
        mvc.perform(get(SEARCH).param("keyword", "  " + "k".repeat(max) + "  "))
            .andExpect(status().isOk());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // SHAPE — unchanged
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void theResponseIsStillABareArrayOfLocations() throws Exception {
        String sfx = suffix();
        Long id = create("D14 Shape " + sfx, "d14-shape-" + sfx, null);

        JsonNode rows = mapper.readTree(content(mvc.perform(get(SEARCH).param("keyword", "d14 shape " + sfx))
            .andExpect(status().isOk())));
        assertTrue(rows.isArray(), "no page envelope");
        assertEquals(1, rows.size());
        assertEquals(id, rows.get(0).get("id").asLong());
        for (String field : List.of("id", "parentId", "code", "name", "slug", "type", "level", "oldName",
                "fullPath", "latitude", "longitude", "sortOrder", "active", "createdAt", "updatedAt")) {
            assertTrue(rows.get(0).has(field), "LocationResponse still carries " + field);
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ══════════════════════════════════════════════════════════════════════════

    /** A top-level COUNTRY — the one type that needs no parent — with the given fields. */
    private Long create(String name, String slug, String oldName) throws Exception {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("name", name);
        body.put("slug", slug);
        body.put("type", "COUNTRY");
        if (oldName != null) body.put("oldName", oldName);
        String response = content(mvc.perform(post("/api/admin/locations")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(body)))
            .andExpect(status().isCreated()));
        return mapper.readTree(response).get("id").asLong();
    }

    private List<JsonNode> searchRows(String keyword) throws Exception {
        JsonNode rows = mapper.readTree(content(mvc.perform(get(SEARCH).param("keyword", keyword))
            .andExpect(status().isOk())));
        assertTrue(rows.isArray(), "search must answer with a bare JSON array");
        List<JsonNode> out = new ArrayList<>();
        rows.forEach(out::add);
        return out;
    }

    private List<Long> searchIds(String keyword) throws Exception {
        return ids(searchRows(keyword));
    }

    private static List<Long> ids(List<JsonNode> rows) {
        return rows.stream().map(row -> row.get("id").asLong()).toList();
    }

    private static boolean anyFieldContains(JsonNode row, String text) {
        String needle = text.toLowerCase();
        for (String field : List.of("name", "slug", "oldName")) {
            JsonNode value = row.get(field);
            if (value != null && !value.isNull() && value.asText().toLowerCase().contains(needle)) {
                return true;
            }
        }
        return false;
    }

    private static String twoDigits(int n) {
        return (n < 10 ? "0" : "") + n;
    }

    private static String content(ResultActions actions) throws Exception {
        return actions.andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8);
    }

    private static String suffix() {
        return UUID.randomUUID().toString().substring(0, 8);
    }

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }
}
