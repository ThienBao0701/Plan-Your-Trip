package com.example.planyourtrip;

import com.example.planyourtrip.repository.AdminActivityLogRepository;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.AmenityRepository;
import com.example.planyourtrip.repository.CategoryRepository;
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
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * D14 — the status body shared by the amenity, category and location CMS switches.
 *
 * <p>{@code StatusRequest} used to be {@code record StatusRequest(boolean active)}. A primitive has no
 * "absent", so {@code {}}, {@code {"active":null}} and a misspelled key all bound to {@code false}: a
 * request that never said "deactivate" deactivated the row and wrote an audit entry claiming it had.
 * It is now a {@code @NotNull Boolean} validated with {@code @Valid}, so each of those is a 400 that
 * changes nothing and records nothing.
 *
 * <p>What must not have moved: an explicit {@code true}/{@code false} still works and is audited once,
 * and unknown keys are still ignored — the project's Jackson convention is untouched.
 *
 * <p><b>Isolation.</b> The class is {@code @Transactional}, so every probe amenity, category and
 * location a test creates — and every audit row its requests write — is rolled back when it ends,
 * leaving nothing in the shared H2 database and no dependency between tests. The status is read back
 * after a flush and a cleared persistence context, so each assertion sees the database's value, not
 * an entity a request left in memory.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class AdminStatusRequestContractTest {

    /** One of the three endpoints that share {@code StatusRequest}. */
    private record Resource(String label, String path, String statusAction) {}

    private static final List<Resource> RESOURCES = List.of(
        new Resource("amenity", "/api/admin/amenities", "AMENITY_STATUS_UPDATE"),
        new Resource("category", "/api/admin/categories", "CATEGORY_STATUS_UPDATE"),
        new Resource("location", "/api/admin/locations", "LOCATION_STATUS_UPDATE"));

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired AdminActivityLogRepository auditRepo;
    @Autowired AmenityRepository amenityRepo;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired EntityManager entityManager;

    private String adminToken;

    @BeforeEach
    void setup() throws Exception {
        adminToken = login("admin@planyourtrip.com", "admin123456");
    }

    @Test
    void anExplicitTrueOrFalseStillChangesTheStatusAndIsAuditedOnceEach() throws Exception {
        for (Resource r : RESOURCES) {
            Long id = create(r);
            long before = auditCount(r.statusAction());

            sendStatus(r, id, "{\"active\":false}", 200);
            assertFalse(isActive(r, id), r.label());
            assertEquals(before + 1, auditCount(r.statusAction()), r.label() + ": one audit row per change");

            sendStatus(r, id, "{\"active\":true}", 200);
            assertTrue(isActive(r, id), r.label());
            assertEquals(before + 2, auditCount(r.statusAction()), r.label() + ": one audit row per change");
        }
    }

    @Test
    void aBodyThatDoesNotStateActiveIsRefusedAndChangesNothing() throws Exception {
        List<String> bodies = List.of(
            "{}",
            "{\"active\":null}",
            "{\"activ\":true}",
            "{\"active\":\"\"}");
        for (Resource r : RESOURCES) {
            Long id = create(r);
            assertTrue(isActive(r, id), r.label() + " starts active");
            long statusAudits = auditCount(r.statusAction());
            long allAudits = auditTotal();

            for (String body : bodies) {
                String response = sendStatus(r, id, body, 400);
                String message = mapper.readTree(response).get("message").asText();
                assertTrue(message.startsWith("active:"), r.label() + " " + body + " -> " + message);
                assertTrue(isActive(r, id), r.label() + " " + body + " must not deactivate the row");
            }

            assertEquals(statusAudits, auditCount(r.statusAction()), r.label() + ": no status audit row");
            assertEquals(allAudits, auditTotal(), r.label() + ": no audit row of any kind");
        }
    }

    @Test
    void aMalformedBodyIsRefusedAndChangesNothing() throws Exception {
        List<String> bodies = List.of("", "{\"active\":", "not json", "[]", "{\"active\":\"yes\"}");
        for (Resource r : RESOURCES) {
            Long id = create(r);
            long allAudits = auditTotal();

            for (String body : bodies) {
                sendStatus(r, id, body, 400);
                assertTrue(isActive(r, id), r.label() + " [" + body + "] must not deactivate the row");
            }

            assertEquals(allAudits, auditTotal(), r.label() + ": no audit row");
        }
    }

    @Test
    void unknownKeysAlongsideActiveAreStillIgnored() throws Exception {
        for (Resource r : RESOURCES) {
            Long id = create(r);
            sendStatus(r, id, "{\"active\":false,\"reason\":\"D14 probe\"}", 200);
            assertFalse(isActive(r, id), r.label() + ": the unknown key is ignored, active is honoured");
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ══════════════════════════════════════════════════════════════════════════

    private Long create(Resource r) throws Exception {
        String sfx = suffix();
        String body = switch (r.label()) {
            case "amenity" -> """
                {"name":"D14 Status Amenity %s","slug":"d14-status-amenity-%s","icon":"star",
                 "groupName":"general","description":"D14 status probe","sortOrder":1}
                """.formatted(sfx, sfx);
            case "category" -> """
                {"name":"D14 Status Category %s","slug":"d14-status-category-%s","type":"PLACE",
                 "icon":"spa","color":"#112233","coverImageUrl":"https://example.com/d14.png","sortOrder":1}
                """.formatted(sfx, sfx);
            default -> """
                {"name":"D14 Status Location %s","slug":"d14-status-location-%s","type":"COUNTRY"}
                """.formatted(sfx, sfx);
        };
        String response = mvc.perform(post(r.path())
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8);
        return mapper.readTree(response).get("id").asLong();
    }

    private String sendStatus(Resource r, Long id, String body, int expected) throws Exception {
        return mvc.perform(patch(r.path() + "/" + id + "/status")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().is(expected))
            .andReturn().getResponse().getContentAsString(StandardCharsets.UTF_8);
    }

    private boolean isActive(Resource r, Long id) {
        entityManager.flush();
        entityManager.clear();
        return switch (r.label()) {
            case "amenity" -> amenityRepo.findById(id).orElseThrow().isActive();
            case "category" -> categoryRepo.findById(id).orElseThrow().isActive();
            default -> locationRepo.findById(id).orElseThrow().isActive();
        };
    }

    private long auditCount(String action) {
        return auditRepo.search(null, action, null, null, null, null, PageRequest.of(0, 1))
            .getTotalElements();
    }

    private long auditTotal() {
        return auditRepo.search(null, null, null, null, null, null, PageRequest.of(0, 1))
            .getTotalElements();
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
