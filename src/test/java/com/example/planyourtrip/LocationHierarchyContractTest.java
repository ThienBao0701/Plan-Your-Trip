package com.example.planyourtrip;

import com.example.planyourtrip.config.LocationPathBackfill;
import com.example.planyourtrip.config.LocationPathBackfill.BackfillResult;
import com.example.planyourtrip.config.LocationPathBackfillRunner;
import com.example.planyourtrip.model.AdministrativeUnit;
import com.example.planyourtrip.model.UnitType;
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

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Deque;
import java.util.EnumMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
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
 * <p><b>D13</b> adds the hierarchy matrix — COUNTRY top level only, PROVINCE and CITY under a
 * COUNTRY, AREA under a PROVINCE or CITY, WARD and COMMUNE reserved. Every fixture below that
 * used to build {@code CITY → CITY} chains or top-level CITY rows now builds a legal shape instead;
 * what each test asserts is unchanged unless the old fixture only worked because the hierarchy was
 * unconstrained, and those cases say so where they are.
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
            location("D12 Dup One", slug, "COUNTRY", null, code()), 201));
        assertNotNull(first);

        mvc.perform(post("/api/admin/locations")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(location("D12 Dup Two", slug, "COUNTRY", null, code())))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.message").value(containsSlug(slug)));
    }

    @Test
    void duplicateCodeIsRejectedWithConflict() throws Exception {
        String sharedCode = code();
        Long first = idOf(adminPost("/api/admin/locations",
            location("D12 Code One", "d12-code-one-" + suffix(), "COUNTRY", null, sharedCode),
            201));
        assertNotNull(first);

        String body = mvc.perform(post("/api/admin/locations")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(location("D12 Code Two", "d12-code-two-" + suffix(), "COUNTRY", null,
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
            .andExpect(status().isBadRequest())
            // D13: the D12 guard still answers first. A COUNTRY with a parent is also illegal under
            // the matrix, so the message is what proves which rule refused it.
            .andExpect(jsonPath("$.message").value(containsText("own parent")));

        assertNull(locationRepo.findById(id).orElseThrow().getParent(),
            "a refused move must leave the parent exactly as it was");
    }

    @Test
    void aDirectTwoNodeCycleIsRejected() throws Exception {
        Long a = newRoot("D12 Cycle A");
        Long b = newCity("D12 Cycle B", a);

        // A -> B would make A a child of its own child.
        mvc.perform(put("/api/admin/locations/" + a)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(location("D12 Cycle A", slugOf(a), "COUNTRY", b, codeOf(a))))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.message").value(containsText("own descendant")));

        assertNull(locationRepo.findById(a).orElseThrow().getParent());
        assertEquals(a, locationRepo.findById(b).orElseThrow().getParent().getId());
    }

    @Test
    void aLongerCycleIsRejected() throws Exception {
        Long a = newRoot("D12 Deep A");
        Long b = newCity("D12 Deep B", a);
        Long c = newArea("D12 Deep C", b);

        // A -> C: C is A's grandchild, so this is A -> B -> C -> A.
        mvc.perform(put("/api/admin/locations/" + a)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(location("D12 Deep A", slugOf(a), "COUNTRY", c, codeOf(a))))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.message").value(containsText("own descendant")));

        assertNull(locationRepo.findById(a).orElseThrow().getParent());
        assertEquals(b, locationRepo.findById(c).orElseThrow().getParent().getId());
    }

    @Test
    void aValidReparentStillSucceeds() throws Exception {
        Long oldParent = newRoot("D12 Old Parent");
        Long newParent = newRoot("D12 New Parent");
        Long child = newCity("D12 Mover", oldParent);

        adminPut("/api/admin/locations/" + child,
            location("D12 Mover", slugOf(child), "CITY", newParent, codeOf(child)), 200);

        assertEquals(newParent, locationRepo.findById(child).orElseThrow().getParent().getId());
    }

    /**
     * D13 changed this behaviour on purpose. Only a COUNTRY may be top level and a COUNTRY can
     * never be a child, so there is no legal "detach to root" left: a child that is not a COUNTRY
     * has no top-level position to move to. Before D13 this test proved a detached CITY's path
     * collapsed to its own name; that path rule for top-level rows is still pinned by
     * {@link #rootCreateDerivesItsOwnPath}.
     */
    @Test
    void aChildCannotBeDetachedToTopLevel() throws Exception {
        Long parent = newRoot("D12 Detach Parent");
        Long child = newCity("D12 Detach Child", parent);
        String pathBefore = pathOf(child);

        String message = rejectedPut(child,
            location("D12 Detach Child", slugOf(child), "CITY", null, codeOf(child)));
        assertTrue(message.contains("top-level"), message);

        assertEquals(parent, parentOf(child), "a refused detach leaves the parent where it was");
        assertEquals(pathBefore, pathOf(child));
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
        Long child = newCity("D12 Path Child", parent);
        assertEquals("D12 Path Parent" + LocationService.PATH_SEPARATOR + "D12 Path Child",
            pathOf(child));
    }

    @Test
    void aGrandchildCarriesTheWholeAncestry() throws Exception {
        Long a = newRoot("D12 A");
        Long b = newCity("D12 B", a);
        Long c = newArea("D12 C", b);
        assertEquals("D12 A > D12 B > D12 C", pathOf(c),
            "the separator stays the one DataInitializer has always written");
    }

    @Test
    void aCallerSuppliedPathIsIgnoredOnCreate() throws Exception {
        String body = """
            {"name":"D12 Liar","slug":"d12-liar-%s","code":"%s","type":"COUNTRY",
             "fullPath":"Totally > Made > Up"}
            """.formatted(suffix(), code());
        Long id = idOf(adminPost("/api/admin/locations", body, 201));
        assertEquals("D12 Liar", pathOf(id),
            "the server derives the path; the request's value is not authoritative");
    }

    @Test
    void aCallerSuppliedPathIsIgnoredOnUpdate() throws Exception {
        Long parent = newRoot("D12 Honest Parent");
        Long child = newCity("D12 Honest Child", parent);

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
        Long child = newCity("D12 Absent Child", parent);

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
        // D13: the canonical tree is three tiers deep, so the old four-tier CITY chain is gone.
        // The rename of a middle node still reaches its child, and a rename of the root is what
        // now has to reach a grandchild.
        Long country = newRoot("D12 Vietnam");
        Long city = newCity("D12 Ho Chi Minh City", country);
        Long area = newArea("D12 District 1", city);

        assertEquals("D12 Vietnam > D12 Ho Chi Minh City > D12 District 1", pathOf(area));

        adminPut("/api/admin/locations/" + city,
            location("D12 Ho Chi Minh", slugOf(city), "CITY", country, codeOf(city)), 200);

        assertEquals("D12 Vietnam > D12 Ho Chi Minh", pathOf(city));
        assertEquals("D12 Vietnam > D12 Ho Chi Minh > D12 District 1", pathOf(area));

        adminPut("/api/admin/locations/" + country,
            location("D12 Viet Nam", slugOf(country), "COUNTRY", null, codeOf(country)), 200);

        assertEquals("D12 Viet Nam", pathOf(country));
        assertEquals("D12 Viet Nam > D12 Ho Chi Minh", pathOf(city));
        assertEquals("D12 Viet Nam > D12 Ho Chi Minh > D12 District 1", pathOf(area),
            "a rename must not leave a grandchild pointing at the old name");
    }

    @Test
    void reparentingRecalculatesTheNodeAndEveryDescendant() throws Exception {
        Long vietnam = newRoot("D12 Old Country");
        Long laos = newRoot("D12 New Country");
        Long city = newCity("D12 Da Nang", vietnam);
        Long district = newArea("D12 Hai Chau", city);

        assertEquals("D12 Old Country > D12 Da Nang > D12 Hai Chau", pathOf(district));

        adminPut("/api/admin/locations/" + city,
            location("D12 Da Nang", slugOf(city), "CITY", laos, codeOf(city)), 200);

        assertEquals("D12 New Country > D12 Da Nang", pathOf(city));
        assertEquals("D12 New Country > D12 Da Nang > D12 Hai Chau", pathOf(district));
    }

    @Test
    void anUntouchedSiblingSubtreeIsLeftAlone() throws Exception {
        Long country = newRoot("D12 Stable Country");
        Long moved = newCity("D12 Moved", country);
        Long movedChild = newArea("D12 Moved Child", moved);
        Long sibling = newCity("D12 Sibling", country);
        Long siblingChild = newArea("D12 Sibling Child", sibling);

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
        Long city = newCity("D12 Atomic City", country);
        Long district = newArea("D12 Atomic District", city);
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
    // D13 — THE HIERARCHY MATRIX
    //
    //   COUNTRY  → top level only
    //   PROVINCE → COUNTRY
    //   CITY     → COUNTRY
    //   AREA     → PROVINCE | CITY
    //   WARD, COMMUNE → reserved: never a root, never a child
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void theMatrixAllowsExactlyTheCanonicalPlacements() {
        Set<String> allowed = Set.of(
            "COUNTRY>null", "PROVINCE>COUNTRY", "CITY>COUNTRY", "AREA>PROVINCE", "AREA>CITY");
        List<UnitType> parents = new ArrayList<>(Arrays.asList(UnitType.values()));
        parents.add(null);

        int checked = 0;
        for (UnitType type : UnitType.values()) {
            for (UnitType parent : parents) {
                assertEquals(allowed.contains(type + ">" + parent),
                    LocationService.isAllowedPlacement(type, parent),
                    type + " under " + (parent == null ? "no parent" : parent));
                checked++;
            }
        }
        assertEquals(UnitType.values().length * (UnitType.values().length + 1), checked,
            "every type against every parent type and top level");
        assertFalse(LocationService.isAssignable(UnitType.WARD));
        assertFalse(LocationService.isAssignable(UnitType.COMMUNE));
    }

    @Test
    void aCountryCannotHaveAParent() throws Exception {
        Long host = newRoot("D13 Host Country");
        String slug = "d13-nested-country-" + suffix();

        String message = rejectedPost(
            location("D13 Nested Country", slug, "COUNTRY", host, code()));

        assertTrue(message.contains("cannot have a parent"), message);
        assertTrue(locationRepo.findBySlug(slug).isEmpty(), "nothing may be created");
    }

    @Test
    void onlyACountryMayBeTopLevel() throws Exception {
        for (String type : List.of("PROVINCE", "CITY", "AREA")) {
            String slug = "d13-root-" + type.toLowerCase() + "-" + suffix();
            String message = rejectedPost(location("D13 Root " + type, slug, type, null, code()));
            assertTrue(message.contains("top-level"), type + ": " + message);
            assertTrue(locationRepo.findBySlug(slug).isEmpty(), type + " must not be created");
        }
        for (String type : List.of("WARD", "COMMUNE")) {
            String slug = "d13-root-" + type.toLowerCase() + "-" + suffix();
            String message = rejectedPost(location("D13 Root " + type, slug, type, null, code()));
            assertTrue(message.contains("reserved"), type + ": " + message);
            assertTrue(locationRepo.findBySlug(slug).isEmpty(), type + " must not be created");
        }
    }

    @Test
    void theFourCanonicalPlacementsAreAccepted() throws Exception {
        Long country = newRoot("D13 Canon Country");
        Long province = newProvince("D13 Canon Province", country);
        Long city = newCity("D13 Canon City", country);
        Long provinceArea = newArea("D13 Canon Province Area", province);
        Long cityArea = newArea("D13 Canon City Area", city);

        assertEquals(country, parentOf(province));
        assertEquals(country, parentOf(city));
        assertEquals(province, parentOf(provinceArea));
        assertEquals(city, parentOf(cityArea));
        assertEquals("D13 Canon Country > D13 Canon Province > D13 Canon Province Area",
            pathOf(provinceArea));
        assertEquals("D13 Canon Country > D13 Canon City > D13 Canon City Area", pathOf(cityArea));
    }

    @Test
    void everyForbiddenPlacementIsRefused() throws Exception {
        Long country = newRoot("D13 Forbid Country");
        Long province = newProvince("D13 Forbid Province", country);
        Long city = newCity("D13 Forbid City", country);
        Long area = newArea("D13 Forbid Area", province);

        record Case(String type, Long parent, String fragment) {}
        List<Case> cases = List.of(
            new Case("PROVINCE", city, "cannot be placed under"),
            new Case("CITY", province, "cannot be placed under"),
            new Case("AREA", area, "cannot be placed under"),
            new Case("PROVINCE", province, "cannot be placed under"),
            new Case("CITY", city, "cannot be placed under"),
            new Case("AREA", country, "cannot be placed under"),
            new Case("PROVINCE", area, "cannot be placed under"),
            new Case("CITY", area, "cannot be placed under"),
            new Case("WARD", country, "reserved"),
            new Case("WARD", province, "reserved"),
            new Case("WARD", city, "reserved"),
            new Case("WARD", area, "reserved"),
            new Case("COMMUNE", country, "reserved"),
            new Case("COMMUNE", province, "reserved"),
            new Case("COMMUNE", city, "reserved"),
            new Case("COMMUNE", area, "reserved"));

        for (Case c : cases) {
            String slug = "d13-forbid-" + suffix();
            String message = rejectedPost(
                location("D13 Forbidden " + c.type(), slug, c.type(), c.parent(), code()));
            assertTrue(message.contains(c.fragment()), c + ": " + message);
            assertTrue(locationRepo.findBySlug(slug).isEmpty(), c + " must not be created");
        }
    }

    @Test
    void aTypeChangeThatStaysValidIsAccepted() throws Exception {
        Long country = newRoot("D13 Swap Country");
        Long node = newProvince("D13 Swap Node", country);
        Long child = newArea("D13 Swap Child", node);

        adminPut("/api/admin/locations/" + node,
            location("D13 Swap Node", slugOf(node), "CITY", country, codeOf(node)), 200);

        assertEquals(UnitType.CITY, typeOf(node));
        assertEquals(country, parentOf(node));
        assertEquals(node, parentOf(child), "an AREA is as legal under a CITY as under a PROVINCE");
    }

    @Test
    void aTypeChangeIllegalUnderTheCurrentParentIsRefused() throws Exception {
        Long country = newRoot("D13 Demote Country");
        Long node = newProvince("D13 Demote Node", country);

        String message = rejectedPut(node,
            location("D13 Demote Node", slugOf(node), "AREA", country, codeOf(node)));

        assertTrue(message.contains("cannot be placed under"), message);
        assertEquals(UnitType.PROVINCE, typeOf(node), "a refused change leaves the type as it was");
    }

    @Test
    void aTypeChangeThatWouldStrandAnExistingChildIsRefused() throws Exception {
        // Under the matrix, a type change that is legal for the node's parent can only break a
        // child when it arrives together with a move: CITY → AREA is illegal under a COUNTRY but
        // legal under a PROVINCE, and an AREA may have no children at all.
        Long country = newRoot("D13 Strand Country");
        Long node = newCity("D13 Strand Node", country);
        Long child = newArea("D13 Strand Child", node);
        Long province = newProvince("D13 Strand Province", country);

        String message = rejectedPut(node,
            location("D13 Strand Node", slugOf(node), "AREA", province, codeOf(node)));

        assertTrue(message.contains("child location " + child), message);
        assertEquals(UnitType.CITY, typeOf(node));
        assertEquals(country, parentOf(node), "neither the type change nor the move may half-apply");
        assertEquals(node, parentOf(child));
        assertEquals("D13 Strand Country > D13 Strand Node > D13 Strand Child", pathOf(child));
    }

    @Test
    void aTypeChangeToAReservedTypeIsRefused() throws Exception {
        Long country = newRoot("D13 Reserve Country");
        Long node = newCity("D13 Reserve Node", country);

        for (String reserved : List.of("WARD", "COMMUNE")) {
            String message = rejectedPut(node,
                location("D13 Reserve Node", slugOf(node), reserved, country, codeOf(node)));
            assertTrue(message.contains("reserved"), reserved + ": " + message);
            assertEquals(UnitType.CITY, typeOf(node));
        }
    }

    @Test
    void anAreaMayMoveBetweenAProvinceAndACity() throws Exception {
        Long country = newRoot("D13 Move Country");
        Long province = newProvince("D13 Move Province", country);
        Long city = newCity("D13 Move City", country);
        Long area = newArea("D13 Move Area", province);
        assertEquals("D13 Move Country > D13 Move Province > D13 Move Area", pathOf(area));

        adminPut("/api/admin/locations/" + area,
            location("D13 Move Area", slugOf(area), "AREA", city, codeOf(area)), 200);

        assertEquals(city, parentOf(area));
        assertEquals("D13 Move Country > D13 Move City > D13 Move Area", pathOf(area),
            "the D12 derivation still follows a matrix-legal move");
    }

    @Test
    void aMoveUnderATypeIncompatibleParentIsRefused() throws Exception {
        Long country = newRoot("D13 Bad Move Country");
        Long province = newProvince("D13 Bad Move Province", country);
        Long area = newArea("D13 Bad Move Area", province);
        String pathBefore = pathOf(area);

        String message = rejectedPut(area,
            location("D13 Bad Move Area", slugOf(area), "AREA", country, codeOf(area)));

        assertTrue(message.contains("cannot be placed under"), message);
        assertEquals(province, parentOf(area));
        assertEquals(pathBefore, pathOf(area));
    }

    /**
     * The seeded tree must already satisfy the matrix, or enforcing it would strand real data.
     *
     * <p>Walked from the seeded country rather than over the whole table: in a full-suite run other
     * classes write locations straight through the repository (top-level PROVINCE rows, a
     * deliberately cyclic pair) to exercise unrelated services, and those bypass this contract.
     */
    @Test
    void theSeededTreeSatisfiesTheMatrix() {
        AdministrativeUnit vietnam = locationRepo.findByCode("VN").orElseThrow();
        assertNull(vietnam.getParent(), "the seeded country is top level");
        assertTrue(LocationService.isAllowedPlacement(vietnam.getType(), null));

        Map<UnitType, Integer> counts = new EnumMap<>(UnitType.class);
        Set<Long> seen = new HashSet<>();
        Deque<AdministrativeUnit> queue = new ArrayDeque<>(List.of(vietnam));
        while (!queue.isEmpty()) {
            AdministrativeUnit node = queue.poll();
            if (!seen.add(node.getId())) continue;
            counts.merge(node.getType(), 1, Integer::sum);
            for (AdministrativeUnit child : locationRepo.findByParentId(node.getId())) {
                assertTrue(LocationService.isAllowedPlacement(child.getType(), node.getType()),
                    child.getCode() + " (" + child.getType() + ") under " + node.getCode()
                        + " (" + node.getType() + ")");
                queue.add(child);
            }
        }

        assertTrue(seen.size() >= 45, "all 45 seeded locations are reachable: " + seen.size());
        assertEquals(1, counts.get(UnitType.COUNTRY), counts.toString());
        assertTrue(counts.getOrDefault(UnitType.PROVINCE, 0) >= 29, counts.toString());
        assertTrue(counts.getOrDefault(UnitType.CITY, 0) >= 5, counts.toString());
        assertTrue(counts.getOrDefault(UnitType.AREA, 0) >= 10, counts.toString());
        assertNull(counts.get(UnitType.WARD), "WARD is reserved and never seeded");
        assertNull(counts.get(UnitType.COMMUNE), "COMMUNE is reserved and never seeded");
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
        Long child = newCity("D12 Public Child", parent);
        newArea("D12 Public Grandchild", child);

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
            location(unique, "d12-find-" + suffix(), "COUNTRY", null, code()), 201));

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

    private Long newProvince(String name, Long countryId) throws Exception {
        return newTyped(name, "PROVINCE", countryId);
    }

    private Long newCity(String name, Long countryId) throws Exception {
        return newTyped(name, "CITY", countryId);
    }

    private Long newArea(String name, Long parentId) throws Exception {
        return newTyped(name, "AREA", parentId);
    }

    private Long newTyped(String name, String type, Long parentId) throws Exception {
        return idOf(adminPost("/api/admin/locations",
            location(name, slugFor(name), type, parentId, code()), 201));
    }

    private Long parentOf(Long id) {
        AdministrativeUnit parent = locationRepo.findById(id).orElseThrow().getParent();
        return parent == null ? null : parent.getId();
    }

    private UnitType typeOf(Long id) {
        return locationRepo.findById(id).orElseThrow().getType();
    }

    /** POSTs a location that must be refused with 400, and returns the server's message. */
    private String rejectedPost(String body) throws Exception {
        return messageOf(mvc.perform(post("/api/admin/locations")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().isBadRequest())
            .andReturn().getResponse().getContentAsString());
    }

    /** PUTs a location update that must be refused with 400, and returns the server's message. */
    private String rejectedPut(Long id, String body) throws Exception {
        return messageOf(mvc.perform(put("/api/admin/locations/" + id)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().isBadRequest())
            .andReturn().getResponse().getContentAsString());
    }

    private String messageOf(String body) throws Exception {
        return mapper.readTree(body).get("message").asText();
    }

    private static org.hamcrest.Matcher<String> containsText(String fragment) {
        return org.hamcrest.Matchers.containsString(fragment);
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
