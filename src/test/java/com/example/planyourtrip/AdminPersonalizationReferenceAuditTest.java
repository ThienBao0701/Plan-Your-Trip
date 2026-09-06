package com.example.planyourtrip;

import com.example.planyourtrip.model.AdminActivityLog;
import com.example.planyourtrip.repository.AdminActivityLogRepository;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.AmenityRepository;
import com.example.planyourtrip.repository.CategoryRepository;
import com.example.planyourtrip.repository.PersonalizationRuleRepository;
import com.example.planyourtrip.repository.UserRepository;
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

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * D3I — the administrative audit trail for personalization rules and reference data.
 *
 * <p>These are the last thirteen Admin mutations that committed with nothing recording who
 * performed them. They are lower risk than D3H's pricing surface, but not no risk: a
 * personalization rule decides which offers a customer is shown, and deactivating a category or a
 * location silently removes every place that hangs off it from the catalogue.
 *
 * <p>Reference data is also the first surface where operator free text belongs in the trail —
 * "who renamed this, and to what" is the whole question these rows exist to answer — so the tests
 * below pin both halves of that: the name is recorded, and a name that looks like a credential is
 * redacted rather than being allowed to roll the rename back.
 */
@SpringBootTest
@AutoConfigureMockMvc
class AdminPersonalizationReferenceAuditTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired AdminActivityLogRepository auditRepo;
    @Autowired UserRepository userRepo;
    @Autowired AmenityRepository amenityRepo;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired PersonalizationRuleRepository ruleRepo;

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
    // PERSONALIZATION RULES — 4 mutations
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void personalizationRuleCreateIsAudited() throws Exception {
        Long id = null;
        try {
            id = idOf(adminPost("/api/admin/personalization-rules", rule(code("PC"), "TRENDING", 7), 201));
            AdminActivityLog log = one("PERSONALIZATION_RULE_CREATE", id);
            assertEquals("PERSONALIZATION_RULE", log.getTargetType());
            assertEquals(id, log.getTargetId());
            assertEquals(adminUserId, log.getActorUserId());
            assertNull(log.getBeforeState());
            assertTrue(log.getAfterState().contains("type:TRENDING"), log.getAfterState());
            assertTrue(log.getAfterState().contains("priority:7"), log.getAfterState());
            assertTrue(log.getAfterState().startsWith("active:true"), log.getAfterState());
        } finally {
            deleteRule(id);
        }
    }

    @Test
    void personalizationRuleUpdateIsAudited() throws Exception {
        Long id = null;
        try {
            String c = code("PU");
            id = idOf(adminPost("/api/admin/personalization-rules", rule(c, "TRENDING", 3), 201));
            adminPut("/api/admin/personalization-rules/" + id, rule(c, "REENGAGEMENT", 9), 200);

            AdminActivityLog log = one("PERSONALIZATION_RULE_UPDATE", id);
            assertEquals("PERSONALIZATION_RULE", log.getTargetType());
            assertEquals(adminUserId, log.getActorUserId());
            assertTrue(log.getBeforeState().contains("type:TRENDING"), log.getBeforeState());
            assertTrue(log.getBeforeState().contains("priority:3"), log.getBeforeState());
            assertTrue(log.getAfterState().contains("type:REENGAGEMENT"), log.getAfterState());
            assertTrue(log.getAfterState().contains("priority:9"), log.getAfterState());
        } finally {
            deleteRule(id);
        }
    }

    @Test
    void personalizationRuleActivateAndDeactivateAreAudited() throws Exception {
        Long id = null;
        try {
            id = idOf(adminPost("/api/admin/personalization-rules", rule(code("PA"), "TRENDING", 1), 201));

            adminPatch("/api/admin/personalization-rules/" + id + "/deactivate", 200);
            AdminActivityLog off = one("PERSONALIZATION_RULE_DEACTIVATE", id);
            assertEquals("PERSONALIZATION_RULE", off.getTargetType());
            assertEquals(adminUserId, off.getActorUserId());
            assertTrue(off.getBeforeState().startsWith("active:true"), off.getBeforeState());
            assertTrue(off.getAfterState().startsWith("active:false"), off.getAfterState());

            adminPatch("/api/admin/personalization-rules/" + id + "/activate", 200);
            AdminActivityLog on = one("PERSONALIZATION_RULE_ACTIVATE", id);
            assertTrue(on.getBeforeState().startsWith("active:false"), on.getBeforeState());
            assertTrue(on.getAfterState().startsWith("active:true"), on.getAfterState());
        } finally {
            deleteRule(id);
        }
    }

    /**
     * {@code configurationJson} is a {@code TEXT} column whose only write-side validation is that
     * it parses, so an operator can put an arbitrary document of arbitrary size in it. The trail
     * must record that it changed without becoming a copy of it.
     */
    @Test
    void ruleConfigurationJsonIsShapeSummarisedNotStored() throws Exception {
        Long id = null;
        try {
            String c = code("PJ");
            String secretish = "{\"apiKey\":\"AKIA1234567890SECRETVALUE\",\"threshold\":5,\"weights\":[1,2,3]}";
            var body = rule(c, "TRENDING", 1);
            id = idOf(adminPost("/api/admin/personalization-rules",
                body.replace("\"active\":true", "\"active\":true,\"configurationJson\":"
                    + mapper.writeValueAsString(secretish)), 201));

            AdminActivityLog log = one("PERSONALIZATION_RULE_CREATE", id);
            String all = log.getDescription() + "|" + log.getBeforeState() + "|" + log.getAfterState();
            assertFalse(all.contains("AKIA1234567890SECRETVALUE"),
                "the configuration document must not reach the trail: " + all);
            assertFalse(all.toLowerCase().contains("apikey"), all);
            assertTrue(log.getAfterState().contains("config:object(entries=3,bytes="),
                "the shape must still say what changed: " + log.getAfterState());

            // The document itself is untouched on the rule — the trail summarises, it does not edit.
            JsonNode stored = mapper.readTree(adminGet("/api/admin/personalization-rules/" + id));
            assertEquals(secretish, stored.get("configurationJson").asText());
        } finally {
            deleteRule(id);
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // REFERENCE DATA — 9 mutations, one shape
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void amenityCreateUpdateAndStatusAreAudited() throws Exception {
        String slug = "d3i-amenity-" + suffix();
        Long id = idOf(adminPost("/api/admin/amenities", amenity("D3I Pool", slug, 4), 201));
        try {
            AdminActivityLog created = one("AMENITY_CREATE", id);
            assertEquals("AMENITY", created.getTargetType());
            assertEquals(id, created.getTargetId());
            assertEquals(adminUserId, created.getActorUserId());
            assertNull(created.getBeforeState());
            assertTrue(created.getAfterState().contains("name:D3I Pool"), created.getAfterState());
            assertTrue(created.getAfterState().contains("slug:" + slug), created.getAfterState());

            adminPut("/api/admin/amenities/" + id, amenity("D3I Sauna", slug, 11), 200);
            AdminActivityLog updated = one("AMENITY_UPDATE", id);
            assertTrue(updated.getBeforeState().contains("name:D3I Pool"), updated.getBeforeState());
            assertTrue(updated.getAfterState().contains("name:D3I Sauna"),
                "a rename is the whole question this row answers: " + updated.getAfterState());
            assertTrue(updated.getAfterState().contains("sortOrder:11"), updated.getAfterState());

            adminPatchBody("/api/admin/amenities/" + id + "/status", "{\"active\":false}", 200);
            AdminActivityLog status = one("AMENITY_STATUS_UPDATE", id);
            assertTrue(status.getBeforeState().startsWith("active:true"), status.getBeforeState());
            assertTrue(status.getAfterState().startsWith("active:false"), status.getAfterState());
            assertTrue(status.getDescription().contains("active=false"), status.getDescription());
            assertFalse(amenityRepo.findById(id).orElseThrow().isActive());
        } finally {
            deactivate("/api/admin/amenities/" + id + "/status");
        }
    }

    @Test
    void categoryCreateUpdateAndStatusAreAudited() throws Exception {
        String slug = "d3i-category-" + suffix();
        Long id = idOf(adminPost("/api/admin/categories", category("D3I Spa", slug, 4), 201));
        try {
            AdminActivityLog created = one("CATEGORY_CREATE", id);
            assertEquals("CATEGORY", created.getTargetType());
            assertEquals(id, created.getTargetId());
            assertEquals(adminUserId, created.getActorUserId());
            assertTrue(created.getAfterState().contains("name:D3I Spa"), created.getAfterState());

            adminPut("/api/admin/categories/" + id, category("D3I Wellness", slug, 12), 200);
            AdminActivityLog updated = one("CATEGORY_UPDATE", id);
            assertTrue(updated.getBeforeState().contains("name:D3I Spa"), updated.getBeforeState());
            assertTrue(updated.getAfterState().contains("name:D3I Wellness"), updated.getAfterState());
            assertFalse(updated.getAfterState().contains("coverImage"),
                "a cover image URL can be a signed URL and must stay out: " + updated.getAfterState());

            adminPatchBody("/api/admin/categories/" + id + "/status", "{\"active\":false}", 200);
            AdminActivityLog status = one("CATEGORY_STATUS_UPDATE", id);
            assertTrue(status.getBeforeState().startsWith("active:true"), status.getBeforeState());
            assertTrue(status.getAfterState().startsWith("active:false"), status.getAfterState());
            assertFalse(categoryRepo.findById(id).orElseThrow().isActive());
        } finally {
            deactivate("/api/admin/categories/" + id + "/status");
        }
    }

    @Test
    void locationCreateUpdateAndStatusAreAudited() throws Exception {
        String slug = "d3i-location-" + suffix();
        Long id = idOf(adminPost("/api/admin/locations", location("D3I Town", slug, "CITY", 2), 201));
        try {
            AdminActivityLog created = one("LOCATION_CREATE", id);
            assertEquals("LOCATION", created.getTargetType());
            assertEquals(id, created.getTargetId());
            assertEquals(adminUserId, created.getActorUserId());
            assertTrue(created.getAfterState().contains("name:D3I Town"), created.getAfterState());
            assertTrue(created.getAfterState().contains("type:CITY"), created.getAfterState());

            adminPut("/api/admin/locations/" + id, location("D3I City", slug, "PROVINCE", 1), 200);
            AdminActivityLog updated = one("LOCATION_UPDATE", id);
            assertTrue(updated.getBeforeState().contains("name:D3I Town"), updated.getBeforeState());
            assertTrue(updated.getBeforeState().contains("type:CITY"), updated.getBeforeState());
            assertTrue(updated.getAfterState().contains("name:D3I City"), updated.getAfterState());
            assertTrue(updated.getAfterState().contains("type:PROVINCE"), updated.getAfterState());

            adminPatchBody("/api/admin/locations/" + id + "/status", "{\"active\":false}", 200);
            AdminActivityLog status = one("LOCATION_STATUS_UPDATE", id);
            assertTrue(status.getBeforeState().startsWith("active:true"), status.getBeforeState());
            assertTrue(status.getAfterState().startsWith("active:false"), status.getAfterState());
            assertFalse(locationRepo.findById(id).orElseThrow().isActive());
        } finally {
            deactivate("/api/admin/locations/" + id + "/status");
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // NO ROW FOR A MUTATION THAT DID NOT HAPPEN
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void refusedMutationsRecordNothing() throws Exception {
        long amenityCreates = count("AMENITY_CREATE");
        long categoryUpdates = count("CATEGORY_UPDATE");
        long locationCreates = count("LOCATION_CREATE");
        long ruleCreates = count("PERSONALIZATION_RULE_CREATE");

        // 400 — @NotBlank name.
        mvc.perform(post("/api/admin/amenities")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"\",\"slug\":\"d3i-blank-" + suffix() + "\"}"))
            .andExpect(status().isBadRequest());

        // 404 — no such category.
        mvc.perform(put("/api/admin/categories/99999999")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(category("Ghost", "d3i-ghost-" + suffix(), 1)))
            .andExpect(status().isNotFound());

        // 409 — duplicate location slug.
        String slug = "d3i-dup-" + suffix();
        Long taken = idOf(adminPost("/api/admin/locations", location("D3I Dup", slug, "CITY", 2), 201));
        mvc.perform(post("/api/admin/locations")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(location("D3I Dup Two", slug, "CITY", 2)))
            .andExpect(status().isConflict());

        // 400 — a MANUAL rule with no target.
        mvc.perform(post("/api/admin/personalization-rules")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(rule(code("PX"), "MANUAL", 1)))
            .andExpect(status().isBadRequest());

        assertEquals(amenityCreates, count("AMENITY_CREATE"));
        assertEquals(categoryUpdates, count("CATEGORY_UPDATE"));
        assertEquals(locationCreates + 1, count("LOCATION_CREATE"),
            "only the one location that was actually created may be recorded");
        assertEquals(ruleCreates, count("PERSONALIZATION_RULE_CREATE"));

        deactivate("/api/admin/locations/" + taken + "/status");
    }

    @Test
    void unauthenticatedAndNonAdminCallersRecordNothing() throws Exception {
        long before = totalRows();
        String body = amenity("D3I Denied", "d3i-denied-" + suffix(), 1);

        mvc.perform(post("/api/admin/amenities")
                .contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().isUnauthorized());

        for (String token : List.of(userToken, partnerToken)) {
            mvc.perform(post("/api/admin/amenities")
                    .header("Authorization", "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isForbidden());
            mvc.perform(patch("/api/admin/categories/1/status")
                    .header("Authorization", "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON).content("{\"active\":false}"))
                .andExpect(status().isForbidden());
            mvc.perform(post("/api/admin/personalization-rules")
                    .header("Authorization", "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(rule(code("PD"), "TRENDING", 1)))
                .andExpect(status().isForbidden());
        }

        assertEquals(before, totalRows(),
            "a refused caller must not add any administrative row");
    }

    // ══════════════════════════════════════════════════════════════════════════
    // ROLLBACK — mutation and audit commit or roll back together
    // ══════════════════════════════════════════════════════════════════════════

    /**
     * The personalization inline architecture. {@code fill} applies name, description and rule type
     * to the managed entity <em>before</em> it validates the priority, targets and configuration
     * JSON, so a rejected update is a genuinely half-mutated entity at the moment the exception is
     * thrown. Both halves must come back: the rule unchanged, and no audit row.
     */
    @Test
    void rejectedRuleUpdateRollsBackBothTheEntityAndTheAudit() throws Exception {
        Long id = null;
        try {
            String c = code("PR");
            id = idOf(adminPost("/api/admin/personalization-rules", rule(c, "TRENDING", 2), 201));
            long updatesBefore = count("PERSONALIZATION_RULE_UPDATE");

            // Malformed configurationJson — rejected at the very end of fill(), after the setters.
            mvc.perform(put("/api/admin/personalization-rules/" + id)
                    .header("Authorization", "Bearer " + adminToken)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(rule(c, "REENGAGEMENT", 5)
                        .replace("\"active\":true", "\"active\":true,\"configurationJson\":\"{not json\"")))
                .andExpect(status().isBadRequest());

            var stored = ruleRepo.findById(id).orElseThrow();
            assertEquals("TRENDING", stored.getRuleType().name(),
                "the half-applied rule type must have rolled back");
            assertEquals(2, stored.getPriority(), "the half-applied priority must have rolled back");
            assertEquals(updatesBefore, count("PERSONALIZATION_RULE_UPDATE"),
                "no audit row may describe an update that rolled back");
        } finally {
            deleteRule(id);
        }
    }

    /**
     * The reference-data inline architecture. Here the conflict is detected before {@code fill}
     * runs, so the entity is never touched — the property to pin is the same one either way:
     * a refused update leaves the row and the audit count exactly as they were.
     */
    @Test
    void rejectedReferenceUpdateLeavesRowAndAuditUnchanged() throws Exception {
        String slugA = "d3i-rb-a-" + suffix();
        String slugB = "d3i-rb-b-" + suffix();
        Long a = idOf(adminPost("/api/admin/amenities", amenity("D3I RB A", slugA, 1), 201));
        Long b = idOf(adminPost("/api/admin/amenities", amenity("D3I RB B", slugB, 2), 201));
        try {
            long updatesBefore = count("AMENITY_UPDATE");

            // Renaming B onto A's slug conflicts.
            mvc.perform(put("/api/admin/amenities/" + b)
                    .header("Authorization", "Bearer " + adminToken)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(amenity("D3I RB B Renamed", slugA, 99)))
                .andExpect(status().isConflict());

            var stored = amenityRepo.findById(b).orElseThrow();
            assertEquals("D3I RB B", stored.getName());
            assertEquals(slugB, stored.getSlug());
            assertEquals(2, stored.getSortOrder());
            assertEquals(updatesBefore, count("AMENITY_UPDATE"));
        } finally {
            deactivate("/api/admin/amenities/" + a + "/status");
            deactivate("/api/admin/amenities/" + b + "/status");
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // WHAT THE TRAIL MAY AND MAY NOT CARRY
    // ══════════════════════════════════════════════════════════════════════════

    /**
     * Reference-data names are recorded, so a credential-shaped one would reach the audit guard —
     * and because the audit write shares the mutation's transaction, that would roll back a
     * perfectly legitimate rename. The guard is not weakened; the text is redacted before it gets
     * there, and the mutation still commits.
     */
    @Test
    void credentialShapedNameIsRedactedAndTheMutationStillCommits() throws Exception {
        String slug = "d3i-red-" + suffix();
        String nasty = "password reset bearer token";
        Long id = idOf(adminPost("/api/admin/amenities", amenity(nasty, slug, 1), 201));
        try {
            AdminActivityLog log = one("AMENITY_CREATE", id);
            String all = log.getDescription() + "|" + log.getBeforeState() + "|" + log.getAfterState();
            assertFalse(all.toLowerCase().contains("password"), all);
            assertFalse(all.toLowerCase().contains("bearer"), all);
            assertTrue(log.getAfterState().contains("name:(redacted)"), log.getAfterState());

            // The amenity itself was created, unredacted — the guard protects the trail, not the row.
            assertEquals(nasty, amenityRepo.findById(id).orElseThrow().getName());
        } finally {
            deactivate("/api/admin/amenities/" + id + "/status");
        }
    }

    /**
     * 200 characters, not 400: {@code Amenity.name} is a defaulted {@code varchar(255)} and
     * {@code AmenityRequest} puts no {@code @Size} on it, so anything longer is a 500 from the
     * INSERT rather than a 400 from validation. That is a pre-existing input-validation gap
     * (finding F-2), it is reached before any audit code runs, and closing it would change the
     * endpoint's validation contract — out of scope here.
     */
    @Test
    void longOperatorTextIsBoundedWellInsideTheStateBudget() throws Exception {
        String slug = "d3i-long-" + suffix();
        String longName = "D3I " + "x".repeat(200);
        Long id = idOf(adminPost("/api/admin/amenities", amenity(longName, slug, 1), 201));
        try {
            AdminActivityLog log = one("AMENITY_CREATE", id);
            assertTrue(log.getAfterState().length() < 500,
                "state must stay inside the 500-char column: " + log.getAfterState().length());
            assertTrue(log.getAfterState().contains("..."), log.getAfterState());
            assertFalse(log.getAfterState().contains("x".repeat(100)),
                "the full name must not be stored: " + log.getAfterState());
            assertEquals(longName, amenityRepo.findById(id).orElseThrow().getName());
        } finally {
            deactivate("/api/admin/amenities/" + id + "/status");
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // AUDIT API — unchanged, and serving the new actions
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void auditApiServesTheThirteenNewActionsUnchanged() throws Exception {
        personalizationRuleCreateIsAudited();
        personalizationRuleUpdateIsAudited();
        personalizationRuleActivateAndDeactivateAreAudited();
        amenityCreateUpdateAndStatusAreAudited();
        categoryCreateUpdateAndStatusAreAudited();
        locationCreateUpdateAndStatusAreAudited();

        List<String> actions = List.of(
            "PERSONALIZATION_RULE_CREATE", "PERSONALIZATION_RULE_UPDATE",
            "PERSONALIZATION_RULE_ACTIVATE", "PERSONALIZATION_RULE_DEACTIVATE",
            "AMENITY_CREATE", "AMENITY_UPDATE", "AMENITY_STATUS_UPDATE",
            "CATEGORY_CREATE", "CATEGORY_UPDATE", "CATEGORY_STATUS_UPDATE",
            "LOCATION_CREATE", "LOCATION_UPDATE", "LOCATION_STATUS_UPDATE");
        assertEquals(13, actions.size(), "D3I closes exactly thirteen mutations");

        JsonNode page = mapper.readTree(adminGet("/api/admin/activity-logs?size=1"));
        for (String key : List.of("content", "page", "size", "totalElements", "totalPages")) {
            assertTrue(page.has(key), "the PageResponse envelope lost " + key);
        }

        for (String action : actions) {
            JsonNode byAction = mapper.readTree(
                adminGet("/api/admin/activity-logs?action=" + action + "&size=10"));
            assertTrue(byAction.get("totalElements").asLong() > 0,
                "the audit API returns nothing for action=" + action);
            for (JsonNode row : byAction.get("content")) {
                assertEquals(action, row.get("action").asText());
                assertEquals(adminUserId, row.get("actorUserId").asLong(), action);
                assertFalse(row.get("targetId").isNull(), action + " recorded no target id");
                assertFalse(row.get("targetType").isNull(), action + " recorded no target type");
            }
        }

        // Persisted-content scan: nothing credential-shaped, and no digit run long enough to look
        // like a card or account number, ever reached storage on any of the thirteen new actions.
        List<String> forbidden = List.of("password", "passwd", "secret", "bearer ", "api_key",
            "api-key", "apikey", "private_key", "private-key", "jwt", "cvv", "iban", "swift",
            "authorization", "cookie", "eyj");
        for (String action : actions) {
            for (JsonNode row : mapper.readTree(
                    adminGet("/api/admin/activity-logs?action=" + action + "&size=50")).get("content")) {
                String blob = (row.get("description").asText("") + " "
                    + row.get("beforeState").asText("") + " "
                    + row.get("afterState").asText("")).toLowerCase();
                for (String word : forbidden) {
                    assertFalse(blob.contains(word),
                        action + " persisted credential-shaped text (" + word + "): " + blob);
                }
                for (String run : blob.split("\\D+")) {
                    assertTrue(run.length() < 13,
                        action + " persisted a " + run.length() + "-digit run: " + blob);
                }
                assertTrue(row.get("beforeState").asText("").length() <= 500);
                assertTrue(row.get("afterState").asText("").length() <= 500);
                assertTrue(row.get("description").asText("").length() <= 4000);
            }
        }

        for (String targetType : List.of("PERSONALIZATION_RULE", "AMENITY", "CATEGORY", "LOCATION")) {
            JsonNode byType = mapper.readTree(
                adminGet("/api/admin/activity-logs?targetType=" + targetType + "&size=5"));
            assertTrue(byType.get("totalElements").asLong() > 0, targetType);
            for (JsonNode row : byType.get("content")) {
                assertEquals(targetType, row.get("targetType").asText());
            }
        }

        // action + targetType, actor filter, date filter, paging clamp — all unchanged.
        assertTrue(mapper.readTree(adminGet(
            "/api/admin/activity-logs?action=AMENITY_CREATE&targetType=AMENITY&size=5"))
            .get("totalElements").asLong() > 0);
        assertTrue(mapper.readTree(adminGet(
            "/api/admin/activity-logs?actorUserId=" + adminUserId + "&action=LOCATION_CREATE&size=5"))
            .get("totalElements").asLong() > 0);
        // ...and the actor filter is actually applied, not silently ignored.
        assertEquals(0, mapper.readTree(adminGet(
            "/api/admin/activity-logs?actorUserId=99999999&action=LOCATION_CREATE&size=5"))
            .get("totalElements").asLong());
        assertTrue(mapper.readTree(adminGet(
            "/api/admin/activity-logs?from=2020-01-01T00:00:00Z&action=CATEGORY_CREATE&size=5"))
            .get("totalElements").asLong() > 0);
        mvc.perform(get("/api/admin/activity-logs?page=-5&size=0")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());

        // Old actions stay queryable.
        assertTrue(mapper.readTree(adminGet("/api/admin/activity-logs?action=PLACE_CREATE&size=1"))
            .get("totalElements").asLong() >= 0);

        // Role guard intact.
        mvc.perform(get("/api/admin/activity-logs")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/admin/activity-logs")
                .header("Authorization", "Bearer " + userToken)).andExpect(status().isForbidden());
        mvc.perform(get("/api/admin/activity-logs")
                .header("Authorization", "Bearer " + partnerToken)).andExpect(status().isForbidden());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // helpers
    // ══════════════════════════════════════════════════════════════════════════

    private long count(String action) {
        return auditRepo.search(null, action, null, null, null, null, PageRequest.of(0, 1))
            .getTotalElements();
    }

    private long totalRows() {
        return auditRepo.search(null, null, null, null, null, null, PageRequest.of(0, 1))
            .getTotalElements();
    }

    private AdminActivityLog one(String action, Long targetId) {
        List<AdminActivityLog> rows = auditRepo
            .search(null, action, null, targetId, null, null, PageRequest.of(0, 10)).getContent();
        assertEquals(1, rows.size(),
            "exactly one " + action + " row expected for target " + targetId + ", got " + rows.size());
        return rows.get(0);
    }

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private static String suffix() {
        return UUID.randomUUID().toString().substring(0, 8);
    }

    private static String code(String prefix) {
        return "D3I-" + prefix + "-" + suffix().toUpperCase();
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
        var req = post(path).header("Authorization", "Bearer " + adminToken);
        if (body != null) req = req.contentType(MediaType.APPLICATION_JSON).content(body);
        return mvc.perform(req).andExpect(status().is(expected))
            .andReturn().getResponse().getContentAsString();
    }

    private void adminPut(String path, String body, int expected) throws Exception {
        mvc.perform(put(path)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().is(expected));
    }

    private void adminPatch(String path, int expected) throws Exception {
        mvc.perform(patch(path).header("Authorization", "Bearer " + adminToken))
            .andExpect(status().is(expected));
    }

    private void adminPatchBody(String path, String body, int expected) throws Exception {
        mvc.perform(patch(path)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().is(expected));
    }

    /** Leave no active probe row behind; these domains have no delete endpoint. */
    private void deactivate(String statusPath) throws Exception {
        mvc.perform(patch(statusPath)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON).content("{\"active\":false}"));
    }

    /** An active rule feeds recommendation generation, so probe rules are removed outright. */
    private void deleteRule(Long id) throws Exception {
        if (id == null) return;
        mvc.perform(delete("/api/admin/personalization-rules/" + id)
                .header("Authorization", "Bearer " + adminToken));
    }

    // ── payloads ──────────────────────────────────────────────────────────────

    private static String rule(String ruleCode, String ruleType, int priority) {
        return """
            {"ruleCode":"%s","name":"D3I Rule %s","description":"probe","ruleType":"%s",
             "priority":%d,"active":true}
            """.formatted(ruleCode, ruleCode, ruleType, priority);
    }

    private static String amenity(String name, String slug, int sortOrder) {
        return """
            {"name":%s,"slug":"%s","icon":"star","groupName":"general",
             "description":"D3I probe amenity","sortOrder":%d}
            """.formatted(quote(name), slug, sortOrder);
    }

    private static String category(String name, String slug, int sortOrder) {
        return """
            {"name":%s,"slug":"%s","type":"PLACE","icon":"spa","color":"#112233",
             "coverImageUrl":"https://example.com/d3i-cover.png","sortOrder":%d}
            """.formatted(quote(name), slug, sortOrder);
    }

    private static String location(String name, String slug, String type, int level) {
        return """
            {"name":%s,"slug":"%s","code":"D3I%s","type":"%s","level":%d,
             "latitude":10.5,"longitude":107.25,"sortOrder":3}
            """.formatted(quote(name), slug, suffix().substring(0, 4).toUpperCase(), type, level);
    }

    private static String quote(String raw) {
        return "\"" + raw.replace("\\", "\\\\").replace("\"", "\\\"") + "\"";
    }
}
