package com.example.planyourtrip;

import com.example.planyourtrip.config.LocationPathBackfill;
import com.example.planyourtrip.config.LocationPathBackfill.BackfillResult;
import com.example.planyourtrip.config.LocationPathBackfillRunner;
import com.example.planyourtrip.model.AdministrativeUnit;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.service.LocationService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * D12 — the Location hierarchy contract.
 *
 * <p>Three behaviours are new here and are the reason this class exists:
 *
 * <ol>
 *   <li><b>A location can no longer become its own ancestor.</b> Before D12 the service resolved a
 *       parent by existence alone, so self-parenting and longer cycles were accepted — and a cycled
 *       node vanished from {@code /api/locations/roots} while still being returned by search, so two
 *       public endpoints disagreed about whether it existed.</li>
 *   <li><b>{@code fullPath} is derived, never accepted from the caller.</b> It is not an internal
 *       field: {@code PlaceDto.LocationRef} publishes it on every place response and the traveller
 *       app parses it into the place's province, which is a match key in its hotel-destination and
 *       saved-place searches. A stale or hand-typed value changes what customers can find.</li>
 *   <li><b>A blank public search no longer dumps the table.</b></li>
 * </ol>
 *
 * <p>Everything else about the surface is asserted here precisely because it must <em>not</em> have
 * moved: the four admin operations, both 409 axes, the 404 on an unknown parent, and the shape of
 * every public read.
 */
@SpringBootTest
@AutoConfigureMockMvc
class LocationHierarchyContractTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired UserRepository userRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired LocationPathBackfill backfill;
    @Autowired ApplicationContext ctx;

    private String adminToken;

    @BeforeEach
    void setup() throws Exception {
        adminToken = login("admin@planyourtrip.com", "admin123456");
        assertNotNull(userRepo.findByEmail("admin@planyourtrip.com").orElseThrow().getId());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // ADMIN CONTRACT — unchanged by D12
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void adminListReturnsLocations() throws Exception {
        String body = adminGet("/api/admin/locations");
        JsonNode rows = mapper.readTree(body);
        assertTrue(rows.isArray(), "the admin list is a bare array, not a page envelope");
        assertTrue(rows.size() > 0, "the seeded tree must be listable");
        JsonNode first = rows.get(0);
        for (String field : List.of("id", "parentId", "code", "name", "slug", "type", "level",
                "oldName", "fullPath", "latitude", "longitude", "sortOrder", "active",
                "createdAt", "updatedAt")) {
            assertTrue(first.has(field), "LocationResponse lost " + field);
        }
    }

    @Test
    void duplicateSlugIsRejectedWithConflict() throws Exception {
        String slug = "d12-dup-slug-" + suffix();
        Long first = idOf(adminPost("/api/admin/locations",
            location("D12 Dup One", slug, "CITY", null, code()), 201));
        assertNotNull(first);

        mvc.perform(post("/api/admin/locations")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(location("D12 Dup Two", slug, "CITY", null, code())))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.message").value(containsSlug(slug)));
    }

    @Test
    void duplicateCodeIsRejectedWithConflict() throws Exception {
        String sharedCode = code();
        Long first = idOf(adminPost("/api/admin/locations",
            location("D12 Code One", "d12-code-one-" + suffix(), "CITY", null, sharedCode), 201));
        assertNotNull(first);

        String body = mvc.perform(post("/api/admin/locations")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(location("D12 Code Two", "d12-code-two-" + suffix(), "CITY", null,
                    sharedCode)))
            .andExpect(status().isConflict())
            .andReturn().getResponse().getContentAsString();
        assertTrue(mapper.readTree(body).get("message").asText().contains(sharedCode),
            "the 409 must name the code that collided: " + body);
    }

    @Test
    void anUnknownParentStillAnswersNotFound() throws Exception {
        mvc.perform(post("/api/admin/locations")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(location("D12 Orphan", "d12-orphan-" + suffix(), "CITY", 99999999L,
                    code())))
            .andExpect(status().isNotFound());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // HIERARCHY — cycles are refused
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void rootCreationStillSucceeds() throws Exception {
        Long id = idOf(adminPost("/api/admin/locations",
            location("D12 Root", "d12-root-" + suffix(), "COUNTRY", null, code()), 201));
        AdministrativeUnit saved = locationRepo.findById(id).orElseThrow();
        assertNull(saved.getParent(), "a root keeps parentId null");
    }

    @Test
    void selfParentingIsRejected() throws Exception {
        Long id = newRoot("D12 Self");
        mvc.perform(put("/api/admin/locations/" + id)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(location("D12 Self", slugOf(id), "COUNTRY", id, codeOf(id))))
            .andExpect(status().isBadRequest());

        assertNull(locationRepo.findById(id).orElseThrow().getParent(),
            "a refused move must leave the parent exactly as it was");
    }

    @Test
    void aDirectTwoNodeCycleIsRejected() throws Exception {
        Long a = newRoot("D12 Cycle A");
        Long b = newChild("D12 Cycle B", a);

        // A -> B would make A a child of its own child.
        mvc.perform(put("/api/admin/locations/" + a)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(location("D12 Cycle A", slugOf(a), "COUNTRY", b, codeOf(a))))
            .andExpect(status().isBadRequest());

        assertNull(locationRepo.findById(a).orElseThrow().getParent());
        assertEquals(a, locationRepo.findById(b).orElseThrow().getParent().getId());
    }

    @Test
    void aLongerCycleIsRejected() throws Exception {
        Long a = newRoot("D12 Deep A");
        Long b = newChild("D12 Deep B", a);
        Long c = newChild("D12 Deep C", b);

        // A -> C: C is A's grandchild, so this is A -> B -> C -> A.
        mvc.perform(put("/api/admin/locations/" + a)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(location("D12 Deep A", slugOf(a), "COUNTRY", c, codeOf(a))))
            .andExpect(status().isBadRequest());

        assertNull(locationRepo.findById(a).orElseThrow().getParent());
        assertEquals(b, locationRepo.findById(c).orElseThrow().getParent().getId());
    }

    @Test
    void aValidReparentStillSucceeds() throws Exception {
        Long oldParent = newRoot("D12 Old Parent");
        Long newParent = newRoot("D12 New Parent");
        Long child = newChild("D12 Mover", oldParent);

        adminPut("/api/admin/locations/" + child,
            location("D12 Mover", slugOf(child), "CITY", newParent, codeOf(child)), 200);

        assertEquals(newParent, locationRepo.findById(child).orElseThrow().getParent().getId());
    }

    @Test
    void aNodeMayBeDetachedBackToRoot() throws Exception {
        Long parent = newRoot("D12 Detach Parent");
        Long child = newChild("D12 Detach Child", parent);

        adminPut("/api/admin/locations/" + child,
            location("D12 Detach Child", slugOf(child), "CITY", null, codeOf(child)), 200);

        AdministrativeUnit saved = locationRepo.findById(child).orElseThrow();
        assertNull(saved.getParent());
        assertEquals("D12 Detach Child", saved.getFullPath(),
            "a detached node's path collapses to its own name");
    }

    // ══════════════════════════════════════════════════════════════════════════
    // fullPath — derived, never trusted from the caller
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void rootCreateDerivesItsOwnPath() throws Exception {
        Long id = newRoot("D12 Path Root");
        assertEquals("D12 Path Root", pathOf(id));
    }

    @Test
    void childCreateDerivesFromItsParent() throws Exception {
        Long parent = newRoot("D12 Path Parent");
        Long child = newChild("D12 Path Child", parent);
        assertEquals("D12 Path Parent" + LocationService.PATH_SEPARATOR + "D12 Path Child",
            pathOf(child));
    }

    @Test
    void aGrandchildCarriesTheWholeAncestry() throws Exception {
        Long a = newRoot("D12 A");
        Long b = newChild("D12 B", a);
        Long c = newChild("D12 C", b);
        assertEquals("D12 A > D12 B > D12 C", pathOf(c),
            "the separator stays the one DataInitializer has always written");
    }

    @Test
    void aCallerSuppliedPathIsIgnoredOnCreate() throws Exception {
        String body = """
            {"name":"D12 Liar","slug":"d12-liar-%s","code":"%s","type":"CITY",
             "fullPath":"Totally > Made > Up"}
            """.formatted(suffix(), code());
        Long id = idOf(adminPost("/api/admin/locations", body, 201));
        assertEquals("D12 Liar", pathOf(id),
            "the server derives the path; the request's value is not authoritative");
    }

    @Test
    void aCallerSuppliedPathIsIgnoredOnUpdate() throws Exception {
        Long parent = newRoot("D12 Honest Parent");
        Long child = newChild("D12 Honest Child", parent);

        String body = """
            {"name":"D12 Honest Child","slug":"%s","code":"%s","type":"CITY","parentId":%d,
             "fullPath":"Nonsense"}
            """.formatted(slugOf(child), codeOf(child), parent);
        adminPut("/api/admin/locations/" + child, body, 200);

        assertEquals("D12 Honest Parent > D12 Honest Child", pathOf(child));
    }

    @Test
    void anAbsentPathIsStillDerivedRatherThanNulled() throws Exception {
        Long parent = newRoot("D12 Absent Parent");
        Long child = newChild("D12 Absent Child", parent);

        // No fullPath key at all — the old contract would have written null, which reaches
        // customers through PlaceDto.LocationRef.
        String body = """
            {"name":"D12 Absent Child","slug":"%s","code":"%s","type":"CITY","parentId":%d}
            """.formatted(slugOf(child), codeOf(child), parent);
        adminPut("/api/admin/locations/" + child, body, 200);

        assertEquals("D12 Absent Parent > D12 Absent Child", pathOf(child));
    }

    @Test
    void renamingRecalculatesTheNodeAndEveryDescendant() throws Exception {
        Long country = newRoot("D12 Vietnam");
        Long city = newChild("D12 Ho Chi Minh City", country);
        Long district = newChild("D12 District 1", city);
        Long ward = newChild("D12 Ward 5", district);

        assertEquals("D12 Vietnam > D12 Ho Chi Minh City > D12 District 1 > D12 Ward 5",
            pathOf(ward));

        adminPut("/api/admin/locations/" + city,
            location("D12 Ho Chi Minh", slugOf(city), "CITY", country, codeOf(city)), 200);

        assertEquals("D12 Vietnam > D12 Ho Chi Minh", pathOf(city));
        assertEquals("D12 Vietnam > D12 Ho Chi Minh > D12 District 1", pathOf(district));
        assertEquals("D12 Vietnam > D12 Ho Chi Minh > D12 District 1 > D12 Ward 5", pathOf(ward),
            "a rename must not leave a grandchild pointing at the old name");
    }

    @Test
    void reparentingRecalculatesTheNodeAndEveryDescendant() throws Exception {
        Long vietnam = newRoot("D12 Old Country");
        Long laos = newRoot("D12 New Country");
        Long city = newChild("D12 Da Nang", vietnam);
        Long district = newChild("D12 Hai Chau", city);

        assertEquals("D12 Old Country > D12 Da Nang > D12 Hai Chau", pathOf(district));

        adminPut("/api/admin/locations/" + city,
            location("D12 Da Nang", slugOf(city), "CITY", laos, codeOf(city)), 200);

        assertEquals("D12 New Country > D12 Da Nang", pathOf(city));
        assertEquals("D12 New Country > D12 Da Nang > D12 Hai Chau", pathOf(district));
    }

    @Test
    void anUntouchedSiblingSubtreeIsLeftAlone() throws Exception {
        Long country = newRoot("D12 Stable Country");
        Long moved = newChild("D12 Moved", country);
        Long movedChild = newChild("D12 Moved Child", moved);
        Long sibling = newChild("D12 Sibling", country);
        Long siblingChild = newChild("D12 Sibling Child", sibling);

        String siblingPathBefore = pathOf(sibling);
        String siblingChildPathBefore = pathOf(siblingChild);

        adminPut("/api/admin/locations/" + moved,
            location("D12 Renamed", slugOf(moved), "CITY", country, codeOf(moved)), 200);

        assertEquals("D12 Stable Country > D12 Renamed > D12 Moved Child", pathOf(movedChild));
        assertEquals(siblingPathBefore, pathOf(sibling), "a sibling must not move");
        assertEquals(siblingChildPathBefore, pathOf(siblingChild));
    }

    @Test
    void aRefusedUpdateLeavesNoPartialSubtreeState() throws Exception {
        Long country = newRoot("D12 Atomic Country");
        Long city = newChild("D12 Atomic City", country);
        Long district = newChild("D12 Atomic District", city);
        Long other = newRoot("D12 Atomic Other");
        String takenSlug = slugOf(other);

        String cityPathBefore = pathOf(city);
        String districtPathBefore = pathOf(district);

        // A 409 thrown after the entity has already been filled: the whole unit of work, the
        // cascade included, must roll back.
        mvc.perform(put("/api/admin/locations/" + city)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(location("D12 Atomic Renamed", takenSlug, "CITY", country, codeOf(city))))
            .andExpect(status().isConflict());

        assertEquals(cityPathBefore, pathOf(city), "the refused node kept its path");
        assertEquals(districtPathBefore, pathOf(district),
            "and so did its descendant — no half-cascaded subtree");
    }

    @Test
    void theResponseCarriesTheDerivedPathImmediately() throws Exception {
        Long parent = newRoot("D12 Echo Parent");
        String body = adminPost("/api/admin/locations",
            location("D12 Echo Child", "d12-echo-" + suffix(), "CITY", parent, code()), 201);
        assertEquals("D12 Echo Parent > D12 Echo Child",
            mapper.readTree(body).get("fullPath").asText(),
            "the create response already shows the derived path");
    }

    // ══════════════════════════════════════════════════════════════════════════
    // PUBLIC ENDPOINTS
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void publicRootsReturnsTopLevelLocationsUnauthenticated() throws Exception {
        String body = mvc.perform(get("/api/locations/roots"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode rows = mapper.readTree(body);
        assertTrue(rows.isArray());
        assertTrue(rows.size() > 0, "the seeded country is a root");
        for (JsonNode row : rows) {
            assertTrue(row.get("parentId").isNull(), "a root has no parent");
        }
    }

    @Test
    void publicChildrenReturnsOneLevelAndFourOhFoursOnAnUnknownParent() throws Exception {
        Long parent = newRoot("D12 Public Parent");
        Long child = newChild("D12 Public Child", parent);
        newChild("D12 Public Grandchild", child);

        String body = mvc.perform(get("/api/locations/" + parent + "/children"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode rows = mapper.readTree(body);
        assertEquals(1, rows.size(), "children is one level, never the whole subtree");
        assertEquals(child, rows.get(0).get("id").asLong());

        mvc.perform(get("/api/locations/99999999/children"))
            .andExpect(status().isNotFound());
    }

    @Test
    void aBlankKeywordSearchNoLongerReturnsTheWholeTable() throws Exception {
        long total = locationRepo.count();
        assertTrue(total > 0, "there must be rows for this assertion to mean anything");

        for (String url : List.of("/api/locations/search", "/api/locations/search?keyword=",
                "/api/locations/search?keyword=%20%20")) {
            String body = mvc.perform(get(url))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
            JsonNode rows = mapper.readTree(body);
            assertTrue(rows.isArray(), url + " must still answer with an array");
            assertEquals(0, rows.size(),
                url + " must not dump the table (" + total + " rows exist)");
        }
    }

    @Test
    void aKeywordSearchStillWorksExactlyAsBefore() throws Exception {
        String unique = "D12Findable" + suffix();
        Long id = idOf(adminPost("/api/admin/locations",
            location(unique, "d12-find-" + suffix(), "CITY", null, code()), 201));

        String body = mvc.perform(get("/api/locations/search").param("keyword", unique))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode rows = mapper.readTree(body);
        assertEquals(1, rows.size(), "an exact-ish keyword finds the one row: " + body);
        assertEquals(id, rows.get(0).get("id").asLong());
    }

    @Test
    void accentInsensitiveAndLegacyNameSearchStillWork() throws Exception {
        // The seeded tree carries "Đà Nẵng" (oldName "Da Nang") and "TP Hồ Chí Minh"
        // (oldName "Sai Gon"); both routes through the query must keep working.
        assertFalse(searchIds("Da Nang").isEmpty(),
            "normalized search must still match an accented name");
        assertFalse(searchIds("Sai Gon").isEmpty(),
            "oldName is a legacy alias customers still search by");
    }

    // ══════════════════════════════════════════════════════════════════════════
    // BACKFILL
    // ══════════════════════════════════════════════════════════════════════════

    /**
     * The invariant that actually matters: the seeded tree's paths are the ones customers read, and
     * a backfill must not move any of them.
     *
     * <p>Asserted over the seeded rows by code rather than over the whole table, because in a
     * full-suite run this database is shared and other classes create locations of their own —
     * some straight through the repository with no path at all. Correcting those is the backfill
     * doing its job, not a regression.
     */
    @Test
    void theSeededTreeKeepsItsExactPathsThroughABackfill() {
        List<String> seededCodes = List.of("VN", "HN", "HCM", "DNG", "KHO", "LDG");
        Map<String, String> before = new LinkedHashMap<>();
        for (String c : seededCodes) {
            locationRepo.findByCode(c)
                .ifPresent(u -> before.put(c, String.valueOf(u.getFullPath())));
        }
        assertFalse(before.isEmpty(), "the seeded tree must be present for this to mean anything");

        BackfillResult result = backfill.backfill();
        assertTrue(result.inspected() > 0, "the seeded tree must be reachable from its root");

        for (var entry : before.entrySet()) {
            AdministrativeUnit after = locationRepo.findByCode(entry.getKey()).orElseThrow();
            assertEquals(entry.getValue(), String.valueOf(after.getFullPath()),
                "seeded location " + entry.getKey() + " must keep the exact path customers see");
        }
        // And each one is genuinely hierarchy-derived, not merely unchanged.
        AdministrativeUnit country = locationRepo.findByCode("VN").orElseThrow();
        assertEquals(country.getName().trim(), country.getFullPath(),
            "the seeded root's path is its own name");
    }

    /**
     * The backfill is an operation, not a startup hook.
     *
     * <p>This context carries no {@code app.location.path-backfill.enabled}, which is the default
     * everywhere including production — so the runner bean must not exist and no full-table walk is
     * attached to boot. The operation itself stays injectable and callable.
     */
    @Test
    void theBackfillDoesNotRunOnStartupByDefault() {
        assertEquals(0, ctx.getBeanNamesForType(LocationPathBackfillRunner.class).length,
            "the opt-in runner must not be created unless the property asks for it");
        assertNotNull(backfill, "the operation itself is always available to call explicitly");
        assertTrue(backfill.backfill().inspected() > 0,
            "and calling it directly still works");
    }

    @Test
    void theBackfillIsIdempotent() {
        // A first pass may legitimately correct rows other test classes left pathless; what must
        // hold is that a second pass finds nothing left to do.
        backfill.backfill();
        BackfillResult second = backfill.backfill();
        assertEquals(0, second.changed(), "a second pass must write nothing");
        assertEquals(second.inspected(), second.unchanged(),
            "every reachable row is correct once the first pass has run");
    }

    @Test
    @Transactional
    void aLegacyPathIsCorrectedFromTheActualHierarchy() {
        AdministrativeUnit root = new AdministrativeUnit();
        root.setName("D12 Backfill Root");
        root.setSlug("d12-bf-root-" + suffix());
        root.setType(com.example.planyourtrip.model.UnitType.COUNTRY);
        root.setFullPath("WRONG ROOT PATH");
        root = locationRepo.save(root);

        AdministrativeUnit child = new AdministrativeUnit();
        child.setName("D12 Backfill Child");
        child.setSlug("d12-bf-child-" + suffix());
        child.setType(com.example.planyourtrip.model.UnitType.CITY);
        child.setParent(root);
        child.setFullPath(null);
        child = locationRepo.save(child);

        BackfillResult result = backfill.backfill();
        assertTrue(result.changed() >= 2, "both drifted rows must be corrected");

        assertEquals("D12 Backfill Root",
            locationRepo.findById(root.getId()).orElseThrow().getFullPath());
        assertEquals("D12 Backfill Root > D12 Backfill Child",
            locationRepo.findById(child.getId()).orElseThrow().getFullPath(),
            "a null legacy path is rebuilt, not left null");
    }

    @Test
    @Transactional
    void aCyclicRowIsReportedAndLeftUntouchedRatherThanLooping() {
        // Two nodes pointing at each other: neither is reachable from a root. Written straight
        // through the repository because the service now refuses to create this shape at all.
        AdministrativeUnit a = new AdministrativeUnit();
        a.setName("D12 Cyc A");
        a.setSlug("d12-cyc-a-" + suffix());
        a.setType(com.example.planyourtrip.model.UnitType.AREA);
        a.setFullPath("legacy A");
        a = locationRepo.save(a);

        AdministrativeUnit b = new AdministrativeUnit();
        b.setName("D12 Cyc B");
        b.setSlug("d12-cyc-b-" + suffix());
        b.setType(com.example.planyourtrip.model.UnitType.AREA);
        b.setParent(a);
        b.setFullPath("legacy B");
        b = locationRepo.save(b);

        a.setParent(b);
        locationRepo.save(a);
        locationRepo.flush();

        BackfillResult result = backfill.backfill();

        assertTrue(result.unreachable().contains(a.getId()));
        assertTrue(result.unreachable().contains(b.getId()));
        assertEquals("legacy A", locationRepo.findById(a.getId()).orElseThrow().getFullPath(),
            "an underivable path is reported, never invented");
        assertEquals("legacy B", locationRepo.findById(b.getId()).orElseThrow().getFullPath());
        assertFalse(result.isClean());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // CUSTOMER-FACING REGRESSION — the path is published, so its shape matters
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void theSeededPathsKeepTheSeparatorTheTravellerAppParses() {
        // `_provinceFromFullPath` in the Flutter app splits on " > " and takes the second-to-last
        // segment to show a place's province, which is in turn a match key in its hotel and
        // saved-place searches. A path whose separator or arity changed would silently change what
        // customers can find.
        List<AdministrativeUnit> all = locationRepo.findAll();
        for (AdministrativeUnit u : all) {
            if (u.getParent() == null) continue;
            String path = u.getFullPath();
            if (path == null) continue;
            assertTrue(path.contains(LocationService.PATH_SEPARATOR),
                "a non-root location's path must stay parseable: " + path);
            assertTrue(path.endsWith(LocationService.PATH_SEPARATOR + u.getName().trim())
                    || path.equals(u.getName().trim()),
                "a path must end with its own name: " + path);
        }
    }

    @Test
    void aPlaceResponseStillCarriesTheLocationPath() throws Exception {
        String body = mvc.perform(get("/api/places"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode rows = mapper.readTree(body);
        assertTrue(rows.isArray(), "the public place list answers with a bare array");
        if (rows.isEmpty()) return;
        JsonNode unit = rows.get(0).get("administrativeUnit");
        assertNotNull(unit, "PlaceDto still embeds the location reference");
        for (String field : List.of("id", "name", "slug", "fullPath")) {
            assertTrue(unit.has(field), "LocationRef lost " + field);
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // helpers
    // ══════════════════════════════════════════════════════════════════════════

    private List<Long> searchIds(String keyword) throws Exception {
        String body = mvc.perform(get("/api/locations/search").param("keyword", keyword))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        List<Long> ids = new java.util.ArrayList<>();
        for (JsonNode row : mapper.readTree(body)) ids.add(row.get("id").asLong());
        return ids;
    }

    private org.hamcrest.Matcher<String> containsSlug(String slug) {
        return org.hamcrest.Matchers.containsString(slug);
    }

    private Long newRoot(String name) throws Exception {
        return idOf(adminPost("/api/admin/locations",
            location(name, slugFor(name), "COUNTRY", null, code()), 201));
    }

    private Long newChild(String name, Long parentId) throws Exception {
        return idOf(adminPost("/api/admin/locations",
            location(name, slugFor(name), "CITY", parentId, code()), 201));
    }

    private String pathOf(Long id) {
        return locationRepo.findById(id).orElseThrow().getFullPath();
    }

    private String slugOf(Long id) {
        return locationRepo.findById(id).orElseThrow().getSlug();
    }

    private String codeOf(Long id) {
        return locationRepo.findById(id).orElseThrow().getCode();
    }

    private static String slugFor(String name) {
        return name.toLowerCase().replaceAll("[^a-z0-9]+", "-") + "-" + suffix();
    }

    private static String suffix() {
        return UUID.randomUUID().toString().substring(0, 8);
    }

    /** Codes are globally unique, so every probe row gets its own. */
    private static String code() {
        return "D12" + UUID.randomUUID().toString().substring(0, 6).toUpperCase();
    }

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private Long idOf(String body) throws Exception {
        return mapper.readTree(body).get("id").asLong();
    }

    private String adminGet(String path) throws Exception {
        return mvc.perform(get(path).header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
    }

    private String adminPost(String path, String body, int expected) throws Exception {
        return mvc.perform(post(path)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().is(expected))
            .andReturn().getResponse().getContentAsString();
    }

    private void adminPut(String path, String body, int expected) throws Exception {
        mvc.perform(put(path)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().is(expected));
    }

    /** `LocationRequest` with the fields these tests vary; the rest stay absent. */
    private static String location(String name, String slug, String type, Long parentId,
                                   String code) {
        return """
            {"name":%s,"slug":"%s","code":"%s","type":"%s"%s}
            """.formatted(quote(name), slug, code, type,
                parentId == null ? "" : ",\"parentId\":" + parentId);
    }

    private static String quote(String raw) {
        return "\"" + raw.replace("\\", "\\\\").replace("\"", "\\\"") + "\"";
    }
}
