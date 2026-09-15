package com.example.planyourtrip;

import com.example.planyourtrip.dto.LocationDto;
import com.example.planyourtrip.model.AdministrativeUnit;
import com.example.planyourtrip.repository.AdminActivityLogRepository;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.service.LocationService;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.PageRequest;
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
 * D14 — {@code LocationRequest} validation.
 *
 * <p>Every rule here turns input the database would refuse — or silently store in an unusable form —
 * into a clean 400 before any service code runs:
 *
 * <ul>
 *   <li>name ≤ {@value LocationDto#NAME_MAX}, code ≤ {@value LocationDto#CODE_MAX}, slug ≤
 *       {@value LocationDto#SLUG_MAX}, former name ≤ {@value LocationDto#OLD_NAME_MAX} — and the name
 *       bound is what keeps the longest derived {@code fullPath} inside its 255-character column;</li>
 *   <li>a blank code is no code;</li>
 *   <li>a slug that resolves to an empty string is refused, not stored;</li>
 *   <li>coordinates, when present, are finite and inside the geographic range.</li>
 * </ul>
 *
 * <p>Each refusal is checked to leave no location row and no audit row behind, and a refused update
 * to leave the stored row exactly as it was.
 *
 * <p><b>Isolation.</b> The class is {@code @Transactional}, so every row a test creates — locations and
 * their audit rows — is rolled back when it ends, leaving nothing in the shared H2 database and no
 * dependency between tests. Because the requests join that transaction, stored state is read back
 * through {@link #stored}, which flushes first — so the database still applies its own column limits,
 * the 255-character {@code full_path} included — and clears the persistence context, so the value
 * comes from the database rather than from an entity a request left in memory.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class LocationRequestValidationTest {

    private static final String LOCATIONS = "/api/admin/locations";

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired AdminActivityLogRepository auditRepo;
    @Autowired EntityManager entityManager;

    private String adminToken;

    @BeforeEach
    void setup() throws Exception {
        adminToken = login("admin@planyourtrip.com", "admin123456");
    }

    // ══════════════════════════════════════════════════════════════════════════
    // STRING BOUNDS
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void aNameOfEightyCharactersIsAcceptedAndEightyOneIsNot() throws Exception {
        String sfx = suffix();
        Long ok = create(country(ofLength(LocationDto.NAME_MAX, sfx), "d14-name-ok-" + sfx));
        assertEquals(LocationDto.NAME_MAX, stored(ok).getName().length());

        assertRejectedCreate(country(ofLength(LocationDto.NAME_MAX + 1, sfx), "d14-name-long-" + sfx), "name");
    }

    @Test
    void aCodeOfThirtyTwoCharactersIsAcceptedAndThirtyThreeIsNot() throws Exception {
        String sfx = suffix();
        String code = codeOfLength(LocationDto.CODE_MAX, sfx);
        Long ok = create(with(country("D14 Code " + sfx, "d14-code-ok-" + sfx), "code", code));
        assertEquals(code, stored(ok).getCode());

        assertRejectedCreate(with(country("D14 Code Long " + sfx, "d14-code-long-" + sfx),
            "code", codeOfLength(LocationDto.CODE_MAX + 1, sfx)), "code");
    }

    @Test
    void aFormerNameOf255CharactersIsAcceptedAnd256IsNot() throws Exception {
        String sfx = suffix();
        String oldName = "o".repeat(LocationDto.OLD_NAME_MAX);
        Long ok = create(with(country("D14 Old " + sfx, "d14-old-ok-" + sfx), "oldName", oldName));
        assertEquals(oldName, stored(ok).getOldName());

        assertRejectedCreate(with(country("D14 Old Long " + sfx, "d14-old-long-" + sfx),
            "oldName", "o".repeat(LocationDto.OLD_NAME_MAX + 1)), "oldName");
    }

    @Test
    void aSlugOf100CharactersIsAcceptedAnd101IsNot() throws Exception {
        String sfx = suffix();
        String slug = slugOfLength(LocationDto.SLUG_MAX, sfx);
        Long ok = create(country("D14 Slug " + sfx, slug));
        assertEquals(slug, stored(ok).getSlug());

        assertRejectedCreate(country("D14 Slug Long " + sfx, slugOfLength(LocationDto.SLUG_MAX + 1, sfx)),
            "slug");
    }

    @Test
    void eightyCharacterNamesAtEveryTierStillFitTheStoredPath() throws Exception {
        String sfx = suffix();
        String name = ofLength(LocationDto.NAME_MAX, sfx);
        Long country = create(country(name, "d14-deep-country-" + sfx));
        Long province = create(typed(name, "d14-deep-province-" + sfx, "PROVINCE", country));
        Long area = create(typed(name, "d14-deep-area-" + sfx, "AREA", province));

        int longest = 3 * LocationDto.NAME_MAX + 2 * LocationService.PATH_SEPARATOR.length();
        String path = stored(area).getFullPath();
        assertEquals(longest, path.length());
        assertTrue(path.length() <= 255, "the deepest derived path fits the existing 255-character column");

        // A rename at the top cascades through a maximum-length path without overflowing it.
        String renamed = name.replace('x', 'y');
        update(country, country(renamed, "d14-deep-country-" + sfx), 200);
        String cascaded = stored(area).getFullPath();
        assertTrue(cascaded.startsWith(renamed + LocationService.PATH_SEPARATOR), cascaded);
        assertEquals(longest, cascaded.length());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // BLANK CODE
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void aBlankCodeIsStoredAsNoCode() throws Exception {
        String sfx = suffix();
        List<Long> ids = new ArrayList<>();
        int n = 0;
        // Two of each: a blank value stored as a real code would make the second one a 409.
        for (String blank : List.of("", "   ", "", "   ")) {
            Long id = create(with(country("D14 Blank Code " + sfx, "d14-blank-code-" + (n++) + "-" + sfx),
                "code", blank));
            assertNull(stored(id).getCode(), "[" + blank + "] is stored as null");
            ids.add(id);
        }
        assertEquals(4, ids.size());

        Long target = ids.get(0);
        update(target, with(country("D14 Blank Code " + sfx, slugOf(target)), "code", "  "), 200);
        assertNull(stored(target).getCode(), "the update path agrees");
    }

    // ══════════════════════════════════════════════════════════════════════════
    // EMPTY RESOLVED SLUG
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void aSlugThatResolvesToNothingIsABadRequestNotAConflict() throws Exception {
        // The repeat proves the first refusal stored nothing: a stored "" would make it a 409.
        for (String name : List.of("北京", "!!!", "北京")) {
            assertRejectedCreate(country(name, null), "slug");
        }

        String sfx = suffix();
        String slug = "d14-beijing-explicit-" + sfx;
        Long explicit = create(country("北京", slug));
        assertEquals("北京", stored(explicit).getName(),
            "the same name is fine with an explicit slug");

        long audits = auditCount("LOCATION_UPDATE");
        String response = content(mvc.perform(put(LOCATIONS + "/" + explicit)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(country("!!!", "   "))))
            .andExpect(status().isBadRequest()));
        assertTrue(messageOf(response).startsWith("slug:"), response);

        AdministrativeUnit after = stored(explicit);
        assertEquals("北京", after.getName(), "a refused update leaves the row as it was");
        assertEquals(slug, after.getSlug());
        assertEquals(audits, auditCount("LOCATION_UPDATE"), "and writes no audit row");
    }

    // ══════════════════════════════════════════════════════════════════════════
    // COORDINATES
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void coordinatesInsideTheGeographicRangeAreAccepted() throws Exception {
        String sfx = suffix();
        Double[][] valid = {
            {null, null}, {0.0, 0.0}, {90.0, 180.0}, {-90.0, -180.0}, {10.8231, null}, {null, 106.6297}
        };
        int n = 0;
        for (Double[] pair : valid) {
            Map<String, Object> body = country("D14 Coord " + sfx, "d14-coord-ok-" + (n++) + "-" + sfx);
            body.put("latitude", pair[0]);
            body.put("longitude", pair[1]);
            AdministrativeUnit saved = stored(create(body));
            assertEquals(pair[0], saved.getLatitude(), "latitude " + pair[0]);
            assertEquals(pair[1], saved.getLongitude(), "longitude " + pair[1]);
        }
    }

    @Test
    void coordinatesOutsideTheRangeOrNotFiniteAreRejected() throws Exception {
        String sfx = suffix();
        Object[][] invalid = {
            {"latitude", 90.0001}, {"latitude", -90.0001},
            {"longitude", 180.0001}, {"longitude", -180.0001},
            {"latitude", 1000.0}, {"longitude", -1000.0},
            {"latitude", "NaN"}, {"longitude", "NaN"},
            {"latitude", "Infinity"}, {"longitude", "Infinity"},
            {"latitude", "-Infinity"}, {"longitude", "-Infinity"},
        };
        int n = 0;
        for (Object[] c : invalid) {
            Map<String, Object> body = country("D14 Coord Bad " + sfx, "d14-coord-bad-" + (n++) + "-" + sfx);
            body.put((String) c[0], c[1]);
            assertRejectedCreate(body, (String) c[0]);
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // A REFUSED UPDATE CHANGES NOTHING
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void aRefusedUpdateLeavesTheRowAsItWas() throws Exception {
        String sfx = suffix();
        String name = "D14 Update " + sfx;
        String slug = "d14-update-" + sfx;
        Long id = create(with(with(country(name, slug), "oldName", "Before"), "latitude", 10.0));
        long audits = auditCount("LOCATION_UPDATE");

        List<Map<String, Object>> refused = List.of(
            country(ofLength(LocationDto.NAME_MAX + 1, sfx), slug),
            with(country(name, slug), "code", codeOfLength(LocationDto.CODE_MAX + 1, sfx)),
            with(country(name, slug), "oldName", "o".repeat(LocationDto.OLD_NAME_MAX + 1)),
            country(name, slugOfLength(LocationDto.SLUG_MAX + 1, sfx)),
            with(country(name, slug), "latitude", 91.0),
            with(country(name, slug), "longitude", "NaN"));
        for (Map<String, Object> body : refused) {
            update(id, body, 400);
        }

        AdministrativeUnit after = stored(id);
        assertEquals(name, after.getName());
        assertEquals(slug, after.getSlug());
        assertNull(after.getCode());
        assertEquals("Before", after.getOldName());
        assertEquals(10.0, after.getLatitude());
        assertNull(after.getLongitude());
        assertEquals(name, after.getFullPath(), "the derived path is untouched");
        assertEquals(audits, auditCount("LOCATION_UPDATE"), "no refused update is audited");
    }

    // ══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ══════════════════════════════════════════════════════════════════════════

    private void assertRejectedCreate(Map<String, Object> body, String field) throws Exception {
        long rows = locationRepo.count();
        long audits = auditCount("LOCATION_CREATE");
        String response = content(mvc.perform(post(LOCATIONS)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(body)))
            .andExpect(status().isBadRequest()));
        String message = messageOf(response);
        assertTrue(message.startsWith(field + ":"),
            "expected a " + field + " validation message for " + body + ", got: " + message);
        assertEquals(rows, locationRepo.count(), "a refused create writes no location: " + body);
        assertEquals(audits, auditCount("LOCATION_CREATE"), "a refused create writes no audit row: " + body);
    }

    private Long create(Map<String, Object> body) throws Exception {
        String response = content(mvc.perform(post(LOCATIONS)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(body)))
            .andExpect(status().isCreated()));
        return mapper.readTree(response).get("id").asLong();
    }

    private void update(Long id, Map<String, Object> body, int expected) throws Exception {
        mvc.perform(put(LOCATIONS + "/" + id)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(body)))
            .andExpect(status().is(expected));
    }

    /** A top-level COUNTRY body. A null slug is left out, so the server derives one. */
    private static Map<String, Object> country(String name, String slug) {
        return typed(name, slug, "COUNTRY", null);
    }

    private static Map<String, Object> typed(String name, String slug, String type, Long parentId) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("name", name);
        if (slug != null) body.put("slug", slug);
        body.put("type", type);
        if (parentId != null) body.put("parentId", parentId);
        return body;
    }

    private static Map<String, Object> with(Map<String, Object> body, String key, Object value) {
        body.put(key, value);
        return body;
    }

    /** A name of exactly [length] characters that still carries the per-test suffix. */
    private static String ofLength(int length, String sfx) {
        String base = "D14 " + sfx + " ";
        return base + "x".repeat(length - base.length());
    }

    private static String codeOfLength(int length, String sfx) {
        String base = "D14" + sfx.toUpperCase();
        return base + "X".repeat(length - base.length());
    }

    private static String slugOfLength(int length, String sfx) {
        String base = "d14-" + sfx + "-";
        return base + "s".repeat(length - base.length());
    }

    private String slugOf(Long id) {
        return stored(id).getSlug();
    }

    /**
     * The row as the database now holds it. Every request in a test joins the test transaction, so
     * pending changes are flushed first — making the database apply its own column limits — and the
     * persistence context is cleared, so the row is read back from the database rather than returned
     * from memory.
     */
    private AdministrativeUnit stored(Long id) {
        entityManager.flush();
        entityManager.clear();
        return locationRepo.findById(id).orElseThrow();
    }

    private long auditCount(String action) {
        return auditRepo.search(null, action, null, null, null, null, PageRequest.of(0, 1))
            .getTotalElements();
    }

    private String messageOf(String errorBody) throws Exception {
        return mapper.readTree(errorBody).get("message").asText();
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
