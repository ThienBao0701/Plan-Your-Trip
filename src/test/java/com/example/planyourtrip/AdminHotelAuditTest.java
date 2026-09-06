package com.example.planyourtrip;

import com.example.planyourtrip.dto.HotelDetailDto.HotelDetailRequest;
import com.example.planyourtrip.model.AdminActivityLog;
import com.example.planyourtrip.model.HotelDetail;
import com.example.planyourtrip.repository.AdminActivityLogRepository;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.CategoryRepository;
import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.service.HotelDetailService;
import com.example.planyourtrip.service.HotelExperienceService;
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

import java.time.LocalTime;
import java.util.List;
import java.util.UUID;
import java.util.regex.Pattern;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * D3G — the administrative audit trail for hotel detail and hotel experience.
 *
 * <p>D3F closed the catalog and room gap and reported these three endpoints as the one adjacent
 * surface still committing with nothing recording who performed it: an admin could create or
 * wholesale-replace a hotel's detail, or replace its entire experience block, leaving no trace.
 *
 * <p>These tests pin the same properties D3F pinned for places and rooms — one row per successful
 * mutation, none for a refused one, the acting admin captured from the session, the place as the
 * target, compact scalar before/after values, and nothing resembling a payload dump or a
 * credential reaching permanent storage.
 */
@SpringBootTest
@AutoConfigureMockMvc
class AdminHotelAuditTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired AdminActivityLogRepository auditRepo;
    @Autowired UserRepository userRepo;
    @Autowired PlaceRepository placeRepo;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelDetailService hotelDetailService;
    @Autowired HotelExperienceService experienceService;
    @Autowired TransactionTemplate txTemplate;

    private String adminToken;
    private String partnerToken;
    private String userToken;
    private Long adminUserId;
    private Long seededHotelPlaceId;
    private Long accCategoryId;
    private Long hotelSubcategoryId;
    private Long cafeCategoryId;
    private Long locationId;

    @BeforeEach
    void setup() throws Exception {
        adminToken = login("admin@planyourtrip.com", "admin123456");
        partnerToken = login("partner@planyourtrip.com", "partner123456");
        userToken = login("demo@planyourtrip.com", "demo123456");
        adminUserId = userRepo.findByEmail("admin@planyourtrip.com").orElseThrow().getId();

        seededHotelPlaceId =
            placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        accCategoryId = categoryRepo.findBySlug("accommodation").orElseThrow().getId();
        hotelSubcategoryId = categoryRepo.findBySlug("hotel").orElseThrow().getId();
        cafeCategoryId = categoryRepo.findBySlug("cafe").orElseThrow().getId();
        locationId = locationRepo.findByCode("VT").orElseThrow().getId();
    }

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    private long countOf(String action) {
        return auditRepo.search(null, action, null, null, null, null, PageRequest.of(0, 1))
            .getTotalElements();
    }

    private List<AdminActivityLog> allFor(String action, Long targetId) {
        return auditRepo.search(null, action, null, targetId, null, null, PageRequest.of(0, 50))
            .getContent();
    }

    private String uid() {
        return UUID.randomUUID().toString().substring(0, 8);
    }

    /** A hotel-category place of this test's own, so the seeded catalogue is never mutated. */
    private Long createHotelPlace() throws Exception {
        return createPlace("D3G Hotel " + uid(), accCategoryId, hotelSubcategoryId);
    }

    private Long createCafePlace() throws Exception {
        return createPlace("D3G Cafe " + uid(), cafeCategoryId, null);
    }

    private Long createPlace(String name, Long categoryId, Long subcategoryId) throws Exception {
        String sub = subcategoryId == null ? "null" : subcategoryId.toString();
        String body = mvc.perform(post("/api/admin/places")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "name": "%s",
                      "categoryId": %d,
                      "subcategoryId": %s,
                      "administrativeUnitId": %d,
                      "address": "D3G Test Address",
                      "priceLevel": 2,
                      "status": "PUBLISHED"
                    }
                    """.formatted(name, categoryId, sub, locationId)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private String hotelPayload(Long placeId, int stars) {
        return """
            {
              "placeId": %d,
              "starRating": %d,
              "checkInTime": "14:00:00",
              "checkOutTime": "12:00:00",
              "distanceToBeachMeters": 300,
              "distanceToCityCenterMeters": 500,
              "totalRooms": 80,
              "availableRooms": 20,
              "freeCancellation": true,
              "breakfastIncluded": true,
              "airportShuttle": false,
              "prepaymentRequired": false
            }
            """.formatted(placeId, stars);
    }

    /** A hotel place that already has its detail, ready to be updated. */
    private Long hotelWithDetail() throws Exception {
        Long placeId = createHotelPlace();
        mvc.perform(post("/api/admin/hotels")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(hotelPayload(placeId, 4)))
            .andExpect(status().isCreated());
        return placeId;
    }

    private String experiencePayload(int facilities, String... languages) {
        StringBuilder fac = new StringBuilder();
        for (int i = 0; i < facilities; i++) {
            if (i > 0) fac.append(",");
            fac.append("""
                {"facilityName":"Pool %d","facilityGroup":"GENERAL","icon":"pool","sortOrder":%d}"""
                .formatted(i, i));
        }
        StringBuilder langs = new StringBuilder();
        for (int i = 0; i < languages.length; i++) {
            if (i > 0) langs.append(",");
            langs.append("\"").append(languages[i]).append("\"");
        }
        return """
            {
              "facilities": [%s],
              "services": [],
              "languages": [%s],
              "paymentMethods": ["VISA"],
              "parking": {"parkingAvailable": true, "parkingFree": false,
                          "parkingDescription": "Basement level"},
              "internet": {"wifiAvailable": true, "wifiFree": true,
                           "internetDescription": "Free in all areas"}
            }
            """.formatted(fac, langs);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // A · Success — one row per successful mutation, with the right shape
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void hotelDetailCreateIsAuditedAgainstThePlace() throws Exception {
        Long placeId = createHotelPlace();
        long before = countOf("HOTEL_DETAIL_CREATE");

        mvc.perform(post("/api/admin/hotels")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(hotelPayload(placeId, 4)))
            .andExpect(status().isCreated());

        assertEquals(before + 1, countOf("HOTEL_DETAIL_CREATE"), "exactly one row");
        AdminActivityLog log = allFor("HOTEL_DETAIL_CREATE", placeId).get(0);
        // The target is the PLACE, not the hotel-detail row: HotelDetail is a one-to-one
        // extension owned by its Place, and HOTEL_ASSIGN_OWNER already targets PLACE.
        assertEquals("PLACE", log.getTargetType());
        assertEquals(placeId, log.getTargetId());
        assertEquals(adminUserId, log.getActorUserId());
        assertEquals("admin@planyourtrip.com", log.getActorEmail());
        assertNull(log.getBeforeState(), "nothing existed before a creation");
        assertTrue(log.getAfterState().startsWith("stars:4"), log.getAfterState());
        assertNotNull(log.getCreatedAt());
    }

    @Test
    void hotelDetailUpdateIsAuditedWithADistinctBeforeAndAfter() throws Exception {
        Long placeId = hotelWithDetail();
        long before = countOf("HOTEL_DETAIL_UPDATE");

        mvc.perform(put("/api/admin/hotels/" + placeId)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(hotelPayload(placeId, 5)))
            .andExpect(status().isOk());

        assertEquals(before + 1, countOf("HOTEL_DETAIL_UPDATE"));
        AdminActivityLog log = allFor("HOTEL_DETAIL_UPDATE", placeId).get(0);
        assertEquals("PLACE", log.getTargetType());
        assertEquals(placeId, log.getTargetId());
        assertEquals(adminUserId, log.getActorUserId());
        // The classic mistake this pins: snapshotting a managed entity and reading the new value
        // back for both sides.
        assertTrue(log.getBeforeState().startsWith("stars:4"), log.getBeforeState());
        assertTrue(log.getAfterState().startsWith("stars:5"), log.getAfterState());
        assertNotEquals(log.getBeforeState(), log.getAfterState());
        assertTrue(log.getDescription().contains("whole hotel detail"),
            "a full replace must say so: " + log.getDescription());
    }

    @Test
    void hotelExperienceUpdateIsAuditedAsAShapeSummary() throws Exception {
        Long placeId = hotelWithDetail();
        // Seed a first experience block so the second call has a real "before" to move from.
        mvc.perform(put("/api/admin/hotels/" + placeId + "/experience")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(experiencePayload(3, "en", "vi")))
            .andExpect(status().isOk());

        long before = countOf("HOTEL_EXPERIENCE_UPDATE");
        mvc.perform(put("/api/admin/hotels/" + placeId + "/experience")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(experiencePayload(1, "en")))
            .andExpect(status().isOk());

        assertEquals(before + 1, countOf("HOTEL_EXPERIENCE_UPDATE"));
        AdminActivityLog log = allFor("HOTEL_EXPERIENCE_UPDATE", placeId).get(0);
        assertEquals("PLACE", log.getTargetType());
        assertEquals(placeId, log.getTargetId());
        assertEquals(adminUserId, log.getActorUserId());
        assertEquals("facilities:3 services:0 languages:2 payments:1 parking:true wifi:true",
            log.getBeforeState());
        assertEquals("facilities:1 services:0 languages:1 payments:1 parking:true wifi:true",
            log.getAfterState());
    }

    @Test
    void theExperienceAuditRecordsShapeAndNeverThePayload() throws Exception {
        Long placeId = hotelWithDetail();
        mvc.perform(put("/api/admin/hotels/" + placeId + "/experience")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(experiencePayload(2, "en")))
            .andExpect(status().isOk());

        AdminActivityLog log = allFor("HOTEL_EXPERIENCE_UPDATE", placeId).get(0);
        // Facility names, icons and the free-text parking/internet descriptions are all in the
        // request; none of them may reach the trail.
        for (String field : List.of(log.getDescription(), log.getBeforeState(),
                                    log.getAfterState())) {
            assertFalse(field.contains("Pool"), field);
            assertFalse(field.contains("Basement"), field);
            assertFalse(field.contains("Free in all areas"), field);
            assertFalse(field.contains("VISA"), field);
        }
    }

    @Test
    void theDetailAuditNeverCopiesFreeTextPolicyFields() throws Exception {
        Long placeId = createHotelPlace();
        String payload = """
            {
              "placeId": %d,
              "starRating": 3,
              "checkInTime": "15:00:00",
              "checkOutTime": "11:00:00",
              "totalRooms": 10,
              "availableRooms": 5,
              "freeCancellation": false,
              "prepaymentRequired": true,
              "cancellationPolicy": "SENSITIVE-POLICY-PROSE-MARKER",
              "paymentPolicy": "SENSITIVE-PAYMENT-PROSE-MARKER",
              "childrenPolicy": "SENSITIVE-CHILDREN-PROSE-MARKER",
              "petPolicy": "SENSITIVE-PET-PROSE-MARKER",
              "smokingPolicy": "SENSITIVE-SMOKING-PROSE-MARKER",
              "breakfastIncluded": false,
              "airportShuttle": true
            }
            """.formatted(placeId);

        mvc.perform(post("/api/admin/hotels")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isCreated());

        AdminActivityLog log = allFor("HOTEL_DETAIL_CREATE", placeId).get(0);
        // Operator prose of unbounded length and content is deliberately excluded.
        assertFalse(log.getAfterState().contains("MARKER"), log.getAfterState());
        assertFalse(log.getDescription().contains("MARKER"), log.getDescription());
        assertTrue(log.getAfterState().contains("stars:3"), log.getAfterState());
        assertTrue(log.getAfterState().contains("shuttle:true"), log.getAfterState());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // B · Failure — a refused mutation leaves no trace
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void aDuplicateHotelDetailIsRejectedAndNotAudited() throws Exception {
        Long placeId = hotelWithDetail();
        long before = countOf("HOTEL_DETAIL_CREATE");

        mvc.perform(post("/api/admin/hotels")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(hotelPayload(placeId, 4)))
            .andExpect(status().isConflict());

        assertEquals(before, countOf("HOTEL_DETAIL_CREATE"),
            "a 409 must not leave a row claiming the detail was created");
        assertEquals(1, allFor("HOTEL_DETAIL_CREATE", placeId).size(),
            "only the one creation that actually happened is recorded");
    }

    @Test
    void aNonHotelCategoryIsRejectedAndNotAudited() throws Exception {
        Long cafeId = createCafePlace();
        long before = countOf("HOTEL_DETAIL_CREATE");

        mvc.perform(post("/api/admin/hotels")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(hotelPayload(cafeId, 4)))
            .andExpect(status().isBadRequest());

        assertEquals(before, countOf("HOTEL_DETAIL_CREATE"));
        assertTrue(allFor("HOTEL_DETAIL_CREATE", cafeId).isEmpty());
        assertTrue(hotelDetailRepo.findByPlaceId(cafeId).isEmpty());
    }

    @Test
    void aBeanValidationFailureIsRejectedAndNotAudited() throws Exception {
        Long placeId = createHotelPlace();
        long before = countOf("HOTEL_DETAIL_CREATE");

        // starRating is @Min(1) @Max(5); checkInTime is @NotNull.
        mvc.perform(post("/api/admin/hotels")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(hotelPayload(placeId, 9)))
            .andExpect(status().isBadRequest());

        assertEquals(before, countOf("HOTEL_DETAIL_CREATE"));
        assertTrue(allFor("HOTEL_DETAIL_CREATE", placeId).isEmpty());
    }

    @Test
    void aMissingPlaceIsNotFoundAndNotAudited() throws Exception {
        long createBefore = countOf("HOTEL_DETAIL_CREATE");
        long updateBefore = countOf("HOTEL_DETAIL_UPDATE");
        long expBefore = countOf("HOTEL_EXPERIENCE_UPDATE");

        mvc.perform(post("/api/admin/hotels")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(hotelPayload(99999999L, 4)))
            .andExpect(status().isNotFound());
        mvc.perform(put("/api/admin/hotels/99999999")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(hotelPayload(99999999L, 4)))
            .andExpect(status().isNotFound());
        mvc.perform(put("/api/admin/hotels/99999999/experience")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(experiencePayload(1, "en")))
            .andExpect(status().isNotFound());

        assertEquals(createBefore, countOf("HOTEL_DETAIL_CREATE"));
        assertEquals(updateBefore, countOf("HOTEL_DETAIL_UPDATE"));
        assertEquals(expBefore, countOf("HOTEL_EXPERIENCE_UPDATE"));
    }

    @Test
    void updatingAHotelPlaceWithNoDetailIsNotFoundAndNotAudited() throws Exception {
        Long placeId = createHotelPlace();
        long before = countOf("HOTEL_DETAIL_UPDATE");

        mvc.perform(put("/api/admin/hotels/" + placeId)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(hotelPayload(placeId, 4)))
            .andExpect(status().isNotFound());

        assertEquals(before, countOf("HOTEL_DETAIL_UPDATE"));
        assertTrue(allFor("HOTEL_DETAIL_UPDATE", placeId).isEmpty());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // C · Authorization — unchanged, and no audit for a refused caller
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void nonAdminsRemainForbiddenAndWriteNoAudit() throws Exception {
        Long placeId = hotelWithDetail();
        int starsBefore = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getStarRating();
        long createBefore = countOf("HOTEL_DETAIL_CREATE");
        long updateBefore = countOf("HOTEL_DETAIL_UPDATE");
        long expBefore = countOf("HOTEL_EXPERIENCE_UPDATE");

        for (String token : List.of(partnerToken, userToken)) {
            mvc.perform(post("/api/admin/hotels")
                    .header("Authorization", "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(hotelPayload(placeId, 5)))
                .andExpect(status().isForbidden());
            mvc.perform(put("/api/admin/hotels/" + placeId)
                    .header("Authorization", "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(hotelPayload(placeId, 5)))
                .andExpect(status().isForbidden());
            mvc.perform(put("/api/admin/hotels/" + placeId + "/experience")
                    .header("Authorization", "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(experiencePayload(1, "en")))
                .andExpect(status().isForbidden());
        }

        mvc.perform(put("/api/admin/hotels/" + placeId)
                .contentType(MediaType.APPLICATION_JSON)
                .content(hotelPayload(placeId, 5)))
            .andExpect(status().isUnauthorized());

        assertEquals(createBefore, countOf("HOTEL_DETAIL_CREATE"));
        assertEquals(updateBefore, countOf("HOTEL_DETAIL_UPDATE"));
        assertEquals(expBefore, countOf("HOTEL_EXPERIENCE_UPDATE"));
        assertEquals(starsBefore,
            hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getStarRating(),
            "a refused caller must not have mutated anything");
    }

    @Test
    void theActorComesFromTheSessionAndNotFromTheRequest() throws Exception {
        Long placeId = createHotelPlace();
        // The request body carries no actor field, and the path carries none either: the only
        // source is @AuthUser, resolved from the security context.
        mvc.perform(post("/api/admin/hotels")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(hotelPayload(placeId, 4)))
            .andExpect(status().isCreated());

        AdminActivityLog log = allFor("HOTEL_DETAIL_CREATE", placeId).get(0);
        assertEquals(adminUserId, log.getActorUserId());
        assertNotEquals(userRepo.findByEmail("partner@planyourtrip.com").orElseThrow().getId(),
            log.getActorUserId());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // D · Transaction — mutation and audit commit or roll back together
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void aRolledBackDetailUpdateLeavesNoAuditAndNoChange() throws Exception {
        Long placeId = hotelWithDetail();
        long auditBefore = auditRepo.count();
        int starsBefore = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getStarRating();

        HotelDetailRequest req = new HotelDetailRequest(
            placeId, 2, LocalTime.of(13, 0), LocalTime.of(10, 0),
            100, 200, 40, 10, false, null, true, null, null, null, null, false, true);

        assertThrows(RuntimeException.class, () -> txTemplate.executeWithoutResult(status -> {
            hotelDetailService.update(placeId, req, adminUserId);
            throw new RuntimeException("simulated failure after the audited mutation");
        }));

        assertEquals(auditBefore, auditRepo.count(), "no orphan audit row may survive a rollback");
        assertTrue(allFor("HOTEL_DETAIL_UPDATE", placeId).isEmpty());
        assertEquals(starsBefore,
            hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getStarRating(),
            "and the mutation itself must be gone too");
    }

    @Test
    void aRolledBackExperienceUpdateLeavesNoAuditAndNoChange() throws Exception {
        Long placeId = hotelWithDetail();
        mvc.perform(put("/api/admin/hotels/" + placeId + "/experience")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(experiencePayload(2, "en", "vi")))
            .andExpect(status().isOk());

        long auditBefore = auditRepo.count();
        long rowsBefore = allFor("HOTEL_EXPERIENCE_UPDATE", placeId).size();

        assertThrows(RuntimeException.class, () -> txTemplate.executeWithoutResult(status -> {
            experienceService.updateExperience(placeId,
                new com.example.planyourtrip.dto.HotelExperienceDto.ExperienceRequest(
                    List.of(), List.of(), List.of(), List.of(), null, null),
                adminUserId);
            throw new RuntimeException("simulated failure after the audited mutation");
        }));

        assertEquals(auditBefore, auditRepo.count(), "no orphan audit row may survive a rollback");
        assertEquals(rowsBefore, allFor("HOTEL_EXPERIENCE_UPDATE", placeId).size());
        // Read back through the API rather than off a detached entity: languages is a lazy
        // element collection and has no session outside the transaction.
        String after = mvc.perform(get("/api/admin/hotels/" + placeId + "/experience")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals(2, mapper.readTree(after).get("languages").size(),
            "the languages the rolled-back call would have cleared must still be there");
        assertEquals(2, mapper.readTree(after).get("facilities").size(),
            "and the facilities it would have replaced must still be there");
    }

    // ══════════════════════════════════════════════════════════════════════════
    // E · Repeat / no-op — the endpoints' real semantics
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void anIdenticalRepeatedUpdateIsStillAMutationAndIsRecordedAsOne() throws Exception {
        Long placeId = hotelWithDetail();
        long before = countOf("HOTEL_DETAIL_UPDATE");

        // Neither service detects a no-op: both call fill(...) and save(...) unconditionally and
        // answer 200. So a repeat is a second mutation and is recorded as one, with an identical
        // before/after pair that shows nothing moved.
        for (int i = 0; i < 2; i++) {
            mvc.perform(put("/api/admin/hotels/" + placeId)
                    .header("Authorization", "Bearer " + adminToken)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(hotelPayload(placeId, 4)))
                .andExpect(status().isOk());
        }

        assertEquals(before + 2, countOf("HOTEL_DETAIL_UPDATE"), "one row per call");
        List<AdminActivityLog> rows = allFor("HOTEL_DETAIL_UPDATE", placeId);
        assertEquals(2, rows.size());
        assertEquals(rows.get(0).getBeforeState(), rows.get(0).getAfterState(),
            "the second call changed nothing, and the pair says so");
    }

    @Test
    void aRepeatedExperienceReplaceIsRecordedOncePerCall() throws Exception {
        Long placeId = hotelWithDetail();
        long before = countOf("HOTEL_EXPERIENCE_UPDATE");

        for (int i = 0; i < 2; i++) {
            mvc.perform(put("/api/admin/hotels/" + placeId + "/experience")
                    .header("Authorization", "Bearer " + adminToken)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(experiencePayload(2, "en")))
                .andExpect(status().isOk());
        }

        assertEquals(before + 2, countOf("HOTEL_EXPERIENCE_UPDATE"));
        assertEquals(2, allFor("HOTEL_EXPERIENCE_UPDATE", placeId).size());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // F · No duplicates, and nothing sensitive in the stored rows
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void oneMutationProducesExactlyOneRowAcrossAllThreeEndpoints() throws Exception {
        Long placeId = createHotelPlace();

        long total = auditRepo.count();
        mvc.perform(post("/api/admin/hotels")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(hotelPayload(placeId, 4)))
            .andExpect(status().isCreated());
        assertEquals(total + 1, auditRepo.count(), "create: no controller+service double logging");

        total = auditRepo.count();
        mvc.perform(put("/api/admin/hotels/" + placeId)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(hotelPayload(placeId, 5)))
            .andExpect(status().isOk());
        assertEquals(total + 1, auditRepo.count(), "update: exactly one row");

        total = auditRepo.count();
        mvc.perform(put("/api/admin/hotels/" + placeId + "/experience")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(experiencePayload(1, "en")))
            .andExpect(status().isOk());
        assertEquals(total + 1, auditRepo.count(), "experience: exactly one row");

        assertEquals(1, allFor("HOTEL_DETAIL_CREATE", placeId).size());
        assertEquals(1, allFor("HOTEL_DETAIL_UPDATE", placeId).size());
        assertEquals(1, allFor("HOTEL_EXPERIENCE_UPDATE", placeId).size());
    }

    @Test
    void noHotelAuditRowCarriesCredentialShapedOrDumpedText() {
        Pattern forbidden = Pattern.compile(
            "(?i)(password|passwd|secret|bearer\\s|eyJ[A-Za-z0-9_-]{10,}|api[_-]?key"
                + "|private[_-]?key|authorization|cookie|cvv|iban|swift|\\b\\d{13,19}\\b"
                + "|HotelDetail@|ExperienceRequest\\[|\\{\"|https?://)");
        List<String> actions =
            List.of("HOTEL_DETAIL_CREATE", "HOTEL_DETAIL_UPDATE", "HOTEL_EXPERIENCE_UPDATE");

        // D3J: exhaustive rather than the first page of 200 — see AdminAuditScan.
        for (String action : actions) {
            var result = AdminAuditScan.scanAction(auditRepo, action, log -> {
                for (String field : List.of(
                        String.valueOf(log.getDescription()),
                        String.valueOf(log.getBeforeState()),
                        String.valueOf(log.getAfterState()))) {
                    assertFalse(forbidden.matcher(field).find(),
                        action + " wrote unsafe text: " + field);
                }
            });
            result.assertComplete();
            assertTrue(result.scanned() > 0, action + " produced no rows to inspect");
        }
    }

    @Test
    void statesAreShortScalarSummaries_neverSerialisedEntities() throws Exception {
        Long placeId = hotelWithDetail();
        mvc.perform(put("/api/admin/hotels/" + placeId + "/experience")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(experiencePayload(2, "en")))
            .andExpect(status().isOk());

        for (String action : List.of("HOTEL_DETAIL_CREATE", "HOTEL_DETAIL_UPDATE",
                                     "HOTEL_EXPERIENCE_UPDATE")) {
            for (AdminActivityLog log : allFor(action, placeId)) {
                for (String state : List.of(String.valueOf(log.getBeforeState()),
                                            String.valueOf(log.getAfterState()))) {
                    if ("null".equals(state)) continue;
                    assertTrue(state.length() < 200,
                        action + " state must stay compact, got: " + state);
                    assertFalse(state.contains("{") || state.contains("[") || state.contains("@"),
                        action + " state must not be a serialised object: " + state);
                }
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // G · The existing audit query still works with the new actions
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void theNewActionsAreQueryableThroughTheExistingAuditApi() throws Exception {
        Long placeId = hotelWithDetail();
        mvc.perform(put("/api/admin/hotels/" + placeId + "/experience")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(experiencePayload(1, "en")))
            .andExpect(status().isOk());

        for (String action : List.of("HOTEL_DETAIL_CREATE", "HOTEL_EXPERIENCE_UPDATE")) {
            String body = mvc.perform(get("/api/admin/activity-logs")
                    .param("action", action)
                    .param("targetType", "PLACE")
                    .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content").isArray())
                .andExpect(jsonPath("$.totalElements").isNumber())
                .andReturn().getResponse().getContentAsString();
            var page = mapper.readTree(body);
            // The frozen PageResponse envelope is unchanged.
            for (String key : List.of("content", "page", "size", "totalElements", "totalPages")) {
                assertTrue(page.has(key), "missing envelope field " + key);
            }
            assertTrue(page.get("totalElements").asLong() > 0, action + " is not queryable");
        }

        mvc.perform(get("/api/admin/activity-logs")
                .param("action", "HOTEL_DETAIL_CREATE")
                .header("Authorization", "Bearer " + partnerToken))
            .andExpect(status().isForbidden());
    }
}
