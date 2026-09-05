package com.example.planyourtrip;

import com.example.planyourtrip.dto.HotelRoomDto.HotelRoomRequest;
import com.example.planyourtrip.dto.PlaceDto.PlaceRequest;
import com.example.planyourtrip.model.AdminActivityLog;
import com.example.planyourtrip.model.BedType;
import com.example.planyourtrip.model.HotelRoom;
import com.example.planyourtrip.model.RoomType;
import com.example.planyourtrip.model.Place;
import com.example.planyourtrip.model.PlaceStatus;
import com.example.planyourtrip.repository.AdminActivityLogRepository;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.service.HotelRoomService;
import com.example.planyourtrip.service.PlaceService;
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

import java.util.List;
import java.util.regex.Pattern;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * D3F — the administrative audit trail for the catalog and room surfaces.
 *
 * <p>D3E's checkpoint found that every Admin Catalog and Admin Room mutation committed with nothing
 * recording who performed it: a place could be published, archived, verified or featured, and a
 * room created, rewritten or deactivated, leaving no administrative trace. These tests pin the
 * properties that make the new coverage trustworthy — one row per successful mutation, none for a
 * refused one, the acting admin captured, the right target, safe scalar before/after values, and
 * nothing a partner does through the same room service leaking into the administrative trail.
 */
@SpringBootTest
@AutoConfigureMockMvc
class AdminCatalogRoomAuditTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired AdminActivityLogRepository auditRepo;
    @Autowired UserRepository userRepo;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelRoomRepository roomRepo;
    @Autowired PlaceService placeService;
    @Autowired HotelRoomService roomService;
    @Autowired TransactionTemplate txTemplate;

    private String adminToken;
    private String partnerToken;
    private String userToken;
    private Long adminUserId;

    @BeforeEach
    void setup() throws Exception {
        adminToken = login("admin@planyourtrip.com", "admin123456");
        partnerToken = login("partner@planyourtrip.com", "partner123456");
        userToken = login("demo@planyourtrip.com", "demo123456");
        adminUserId = userRepo.findByEmail("admin@planyourtrip.com").orElseThrow().getId();
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

    private AdminActivityLog latest(String action) {
        return auditRepo.search(null, action, null, null, null, null, PageRequest.of(0, 1))
            .getContent().stream().findFirst().orElse(null);
    }

    private List<AdminActivityLog> allFor(String action, Long targetId) {
        return auditRepo.search(null, action, null, targetId, null, null, PageRequest.of(0, 50))
            .getContent();
    }

    /**
     * A place of this test's own, created through the real admin endpoint so the seeded catalogue
     * is never mutated. Created as DRAFT and then walked to [status] through the status endpoint,
     * because that is the only path the transition table allows.
     */
    private Place freshPlace(PlaceStatus status) throws Exception {
        Place template = placeRepo.findAll().get(0);
        String body = mapper.writeValueAsString(new PlaceRequest(
            "D3F Probe " + System.nanoTime(),
            template.getCategory().getId(), null,
            template.getAdministrativeUnit().getId(),
            "1 Probe Road", null, 10.3, 107.0, "probe", "probe place",
            0, null, false, false, PlaceStatus.DRAFT, List.of(), List.of(), List.of()));

        String created = mvc.perform(post("/api/admin/places")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(body))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long id = mapper.readTree(created).get("id").asLong();

        if (status != PlaceStatus.DRAFT) {
            mvc.perform(patch("/api/admin/places/" + id + "/status")
                    .header("Authorization", "Bearer " + adminToken)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("{\"status\":\"" + status + "\"}"))
                .andExpect(status().isOk());
        }
        return placeRepo.findById(id).orElseThrow();
    }

    private HotelRoomRequest roomRequest(Long placeId, String code, Integer quantity) {
        return new HotelRoomRequest(placeId, "D3F Room", code, RoomType.SUITE, "probe",
            BedType.KING, 1, 2, 1, 3, 30.0, 4, false, true, true, true,
            null, null, quantity, quantity, true, List.of());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // A · Success — one row per successful mutation, with the right shape
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void placeStatusUpdate_writesExactlyOneAuditRowWithBeforeAndAfter() throws Exception {
        Place place = freshPlace(PlaceStatus.APPROVED);
        long before = countOf("PLACE_STATUS_UPDATE");

        mvc.perform(patch("/api/admin/places/" + place.getId() + "/status")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"PUBLISHED\"}"))
            .andExpect(status().isOk());

        assertEquals(before + 1, countOf("PLACE_STATUS_UPDATE"), "exactly one row");
        AdminActivityLog log = allFor("PLACE_STATUS_UPDATE", place.getId()).get(0);
        assertEquals("PLACE", log.getTargetType());
        assertEquals(place.getId(), log.getTargetId());
        assertEquals(adminUserId, log.getActorUserId());
        assertEquals("admin@planyourtrip.com", log.getActorEmail());
        assertEquals("status:APPROVED", log.getBeforeState());
        assertEquals("status:PUBLISHED", log.getAfterState());
        assertNotNull(log.getCreatedAt());
    }

    @Test
    void archivingAPlaceRecordsThatItIsTerminal() throws Exception {
        Place place = freshPlace(PlaceStatus.PUBLISHED);

        mvc.perform(patch("/api/admin/places/" + place.getId() + "/status")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"ARCHIVED\"}"))
            .andExpect(status().isOk());

        AdminActivityLog log = allFor("PLACE_STATUS_UPDATE", place.getId()).get(0);
        assertTrue(log.getDescription().contains("terminal"),
            "an irreversible transition must say so: " + log.getDescription());
        assertEquals("status:ARCHIVED", log.getAfterState());
    }

    @Test
    void placeVerifiedAndFeaturedUpdatesAreAuditedSeparately() throws Exception {
        Place place = freshPlace(PlaceStatus.APPROVED);

        mvc.perform(patch("/api/admin/places/" + place.getId() + "/verified")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"value\":true}"))
            .andExpect(status().isOk());
        mvc.perform(patch("/api/admin/places/" + place.getId() + "/featured")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"value\":true}"))
            .andExpect(status().isOk());

        AdminActivityLog verified = allFor("PLACE_VERIFIED_UPDATE", place.getId()).get(0);
        assertEquals("verified:false", verified.getBeforeState());
        assertEquals("verified:true", verified.getAfterState());
        assertEquals("PLACE", verified.getTargetType());

        AdminActivityLog featured = allFor("PLACE_FEATURED_UPDATE", place.getId()).get(0);
        assertEquals("featured:false", featured.getBeforeState());
        assertEquals("featured:true", featured.getAfterState());
        assertEquals("PLACE", featured.getTargetType());
    }

    @Test
    void roomCreateUpdateAndDeactivateAreAudited() throws Exception {
        Long placeId = seededHotelPlaceId();
        String code = "D3F-" + System.nanoTime();

        String created = mvc.perform(post("/api/admin/rooms")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(roomRequest(placeId, code, 5))))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long roomId = mapper.readTree(created).get("id").asLong();

        AdminActivityLog createLog = allFor("ROOM_CREATE", roomId).get(0);
        assertEquals("HOTEL_ROOM", createLog.getTargetType());
        assertEquals(roomId, createLog.getTargetId());
        assertEquals(adminUserId, createLog.getActorUserId());
        assertEquals("active:true", createLog.getAfterState());

        mvc.perform(put("/api/admin/rooms/" + roomId)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(roomRequest(placeId, code, 6))))
            .andExpect(status().isOk());
        AdminActivityLog updateLog = allFor("ROOM_UPDATE", roomId).get(0);
        assertEquals("HOTEL_ROOM", updateLog.getTargetType());
        assertTrue(updateLog.getDescription().contains("amenities were replaced"),
            "the destructive part of the update must be named: " + updateLog.getDescription());

        mvc.perform(patch("/api/admin/rooms/" + roomId + "/deactivate")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNoContent());
        AdminActivityLog offLog = allFor("ROOM_DEACTIVATE", roomId).get(0);
        assertEquals("HOTEL_ROOM", offLog.getTargetType());
        assertEquals("active:true", offLog.getBeforeState());
        assertEquals("active:false", offLog.getAfterState());
        assertFalse(roomRepo.findById(roomId).orElseThrow().isActive());
    }

    /** The place backing the seeded hotel — the only one with a HotelDetail to hang rooms on. */
    private Long seededHotelPlaceId() throws Exception {
        String body = mvc.perform(get("/api/admin/places?size=100")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        var content = mapper.readTree(body).get("content");
        for (var row : content) {
            long id = row.get("id").asLong();
            var res = mvc.perform(get("/api/admin/hotels/" + id + "/rooms")
                    .header("Authorization", "Bearer " + adminToken))
                .andReturn().getResponse();
            if (res.getStatus() == 200) return id;
        }
        throw new IllegalStateException("no seeded hotel place found");
    }

    // ══════════════════════════════════════════════════════════════════════════
    // B · Failure — a refused mutation leaves no trace
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void anIllegalStatusTransitionIsRefusedAndNotAudited() throws Exception {
        Place place = freshPlace(PlaceStatus.PUBLISHED);
        long before = countOf("PLACE_STATUS_UPDATE");

        // PUBLISHED -> APPROVED is not in ALLOWED_TRANSITIONS.
        mvc.perform(patch("/api/admin/places/" + place.getId() + "/status")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"APPROVED\"}"))
            .andExpect(status().isBadRequest());

        assertEquals(before, countOf("PLACE_STATUS_UPDATE"),
            "a refused transition must not be recorded as one that happened");
        assertEquals(1, allFor("PLACE_STATUS_UPDATE", place.getId()).size(),
            "only the DRAFT -> PUBLISHED step that actually happened is recorded");
    }

    @Test
    void settingAFlagOnAnIneligiblePlaceIsRefusedAndNotAudited() throws Exception {
        // validateFeaturedVerified refuses true outside APPROVED/PUBLISHED.
        Place place = freshPlace(PlaceStatus.DRAFT);
        long before = countOf("PLACE_FEATURED_UPDATE");

        mvc.perform(patch("/api/admin/places/" + place.getId() + "/featured")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"value\":true}"))
            .andExpect(status().isBadRequest());

        assertEquals(before, countOf("PLACE_FEATURED_UPDATE"));
        assertTrue(allFor("PLACE_FEATURED_UPDATE", place.getId()).isEmpty());
        assertFalse(placeRepo.findById(place.getId()).orElseThrow().isFeatured());
    }

    @Test
    void aMissingPlaceIsNotFoundAndNotAudited() throws Exception {
        long before = countOf("PLACE_STATUS_UPDATE");
        mvc.perform(patch("/api/admin/places/99999999/status")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"HIDDEN\"}"))
            .andExpect(status().isNotFound());
        assertEquals(before, countOf("PLACE_STATUS_UPDATE"));
    }

    @Test
    void aDuplicateRoomCodeIsRejectedAndNotAudited() throws Exception {
        Long placeId = seededHotelPlaceId();
        String code = "D3F-DUP-" + System.nanoTime();
        mvc.perform(post("/api/admin/rooms")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(roomRequest(placeId, code, 3))))
            .andExpect(status().isCreated());

        long before = countOf("ROOM_CREATE");
        mvc.perform(post("/api/admin/rooms")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(roomRequest(placeId, code, 3))))
            .andExpect(status().isConflict());

        assertEquals(before, countOf("ROOM_CREATE"),
            "a 409 must not leave a row claiming the room was created");
    }

    @Test
    void aMissingRoomIsNotFoundAndNotAudited() throws Exception {
        long before = countOf("ROOM_DEACTIVATE");
        mvc.perform(patch("/api/admin/rooms/99999999/deactivate")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNotFound());
        assertEquals(before, countOf("ROOM_DEACTIVATE"));
    }

    // ══════════════════════════════════════════════════════════════════════════
    // C · Authorization — unchanged, and no audit for a refused caller
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void nonAdminsRemainForbiddenAndWriteNoAudit() throws Exception {
        Place place = freshPlace(PlaceStatus.APPROVED);
        long placeBefore = countOf("PLACE_STATUS_UPDATE");
        long roomBefore = countOf("ROOM_DEACTIVATE");

        for (String token : List.of(partnerToken, userToken)) {
            mvc.perform(patch("/api/admin/places/" + place.getId() + "/status")
                    .header("Authorization", "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("{\"status\":\"PUBLISHED\"}"))
                .andExpect(status().isForbidden());
            mvc.perform(patch("/api/admin/rooms/1/deactivate")
                    .header("Authorization", "Bearer " + token))
                .andExpect(status().isForbidden());
        }
        mvc.perform(patch("/api/admin/places/" + place.getId() + "/status")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"PUBLISHED\"}"))
            .andExpect(status().isUnauthorized());

        assertEquals(placeBefore, countOf("PLACE_STATUS_UPDATE"));
        assertEquals(roomBefore, countOf("ROOM_DEACTIVATE"));
        assertEquals(PlaceStatus.APPROVED,
            placeRepo.findById(place.getId()).orElseThrow().getStatus());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // D · Transaction — mutation and audit commit or roll back together
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void aRolledBackPlaceMutationLeavesNoAuditAndNoChange() throws Exception {
        Place place = freshPlace(PlaceStatus.APPROVED);
        long before = auditRepo.count();

        assertThrows(RuntimeException.class, () -> txTemplate.executeWithoutResult(status -> {
            placeService.updateVerified(place.getId(), true, adminUserId);
            throw new RuntimeException("simulated failure after the audited mutation");
        }));

        assertEquals(before, auditRepo.count(), "no orphan audit row may survive the rollback");
        assertTrue(allFor("PLACE_VERIFIED_UPDATE", place.getId()).isEmpty());
        assertFalse(placeRepo.findById(place.getId()).orElseThrow().isVerified(),
            "and the mutation itself must be gone too");
    }

    @Test
    void aRolledBackRoomMutationLeavesNoAuditAndNoChange() throws Exception {
        Long placeId = seededHotelPlaceId();
        String created = mvc.perform(post("/api/admin/rooms")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(
                    roomRequest(placeId, "D3F-RB-" + System.nanoTime(), 4))))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long roomId = mapper.readTree(created).get("id").asLong();

        long before = auditRepo.count();
        assertThrows(RuntimeException.class, () -> txTemplate.executeWithoutResult(status -> {
            roomService.adminDeactivate(adminUserId, roomId);
            throw new RuntimeException("simulated failure after the audited mutation");
        }));

        assertEquals(before, auditRepo.count(), "no orphan audit row may survive the rollback");
        assertTrue(allFor("ROOM_DEACTIVATE", roomId).isEmpty());
        assertTrue(roomRepo.findById(roomId).orElseThrow().isActive(),
            "the room must still be active");
    }

    // ══════════════════════════════════════════════════════════════════════════
    // E · Repeat / no-op — the endpoint's real semantics, recorded honestly
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void reapplyingAFlagIsStillAMutationAndIsRecordedAsUnchanged() throws Exception {
        Place place = freshPlace(PlaceStatus.APPROVED);
        mvc.perform(patch("/api/admin/places/" + place.getId() + "/verified")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"value\":true}"))
            .andExpect(status().isOk());

        // The endpoint saves and answers 200 whether or not the value changed, so a second call
        // is a second mutation and is recorded as one — with a before/after pair that shows it
        // changed nothing, rather than being silently dropped.
        mvc.perform(patch("/api/admin/places/" + place.getId() + "/verified")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"value\":true}"))
            .andExpect(status().isOk());

        List<AdminActivityLog> rows = allFor("PLACE_VERIFIED_UPDATE", place.getId());
        assertEquals(2, rows.size(), "one row per call, never more and never fewer");
        AdminActivityLog second = rows.get(0);
        assertEquals("verified:true", second.getBeforeState());
        assertEquals("verified:true", second.getAfterState());
        assertTrue(second.getDescription().contains("(unchanged)"),
            "a no-op call must be visibly a no-op: " + second.getDescription());
    }

    @Test
    void reapplyingTheSameStatusIsASuccessfulMutationAndIsAuditedAsOne() throws Exception {
        Place place = freshPlace(PlaceStatus.PUBLISHED);
        long before = countOf("PLACE_STATUS_UPDATE");

        // validateTransition short-circuits `from == to`, so a same-status PATCH is a 200 and a
        // real save - it still stamps approvedBy/approvedAt for APPROVED and PUBLISHED. The audit
        // follows that semantics rather than inventing a no-op, and the before/after pair is what
        // shows the status did not move.
        mvc.perform(patch("/api/admin/places/" + place.getId() + "/status")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"PUBLISHED\"}"))
            .andExpect(status().isOk());

        assertEquals(before + 1, countOf("PLACE_STATUS_UPDATE"), "one row for one call");
        AdminActivityLog log = allFor("PLACE_STATUS_UPDATE", place.getId()).get(0);
        assertEquals("status:PUBLISHED", log.getBeforeState());
        assertEquals("status:PUBLISHED", log.getAfterState());
    }

    @Test
    void deactivatingAnAlreadyInactiveRoomIsRecordedAsSuch() throws Exception {
        Long placeId = seededHotelPlaceId();
        String created = mvc.perform(post("/api/admin/rooms")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(
                    roomRequest(placeId, "D3F-OFF-" + System.nanoTime(), 2))))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long roomId = mapper.readTree(created).get("id").asLong();

        mvc.perform(patch("/api/admin/rooms/" + roomId + "/deactivate")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNoContent());
        mvc.perform(patch("/api/admin/rooms/" + roomId + "/deactivate")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNoContent());

        List<AdminActivityLog> rows = allFor("ROOM_DEACTIVATE", roomId);
        assertEquals(2, rows.size(), "the endpoint is mutative both times, so both are recorded");
        assertTrue(rows.get(0).getDescription().contains("already inactive"),
            "the second call must show it changed nothing: " + rows.get(0).getDescription());
        assertEquals("active:false", rows.get(0).getBeforeState());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // F · Boundaries — partner actions, and what never reaches the trail
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void aPartnerUpdatingItsOwnRoomWritesNoAdministrativeAudit() throws Exception {
        // PartnerRoomService reaches HotelRoomService.update/activate/deactivate directly. Those
        // shared bodies must stay unaudited so a partner's own housekeeping never appears as an
        // administrative action — the audit lives in the admin* wrappers instead.
        // A room of this test's own. Driving the shared methods against the seeded room would
        // rewrite it for every other test in the suite - HotelRoomTest asserts its seeded field
        // values - so the probe owns the row it mutates.
        Long placeId = seededHotelPlaceId();
        String code = "D3F-PARTNER-" + System.nanoTime();
        String created = mvc.perform(post("/api/admin/rooms")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(roomRequest(placeId, code, 2))))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long roomId = mapper.readTree(created).get("id").asLong();

        // Counted after the creation, so only the partner-path calls are measured.
        long before = auditRepo.count();

        txTemplate.executeWithoutResult(status -> {
            HotelRoom room = roomRepo.findById(roomId).orElseThrow();
            roomService.update(roomId, roomRequest(placeId, code, room.getQuantity()));
            roomService.deactivate(roomId);
            roomService.activate(roomId);
        });

        assertEquals(before, auditRepo.count(),
            "the shared room service must not write to the administrative trail");
    }

    @Test
    void noCatalogOrRoomAuditRowCarriesCredentialShapedText() {
        // The descriptions are built from ids and short scalar states only — never a request body,
        // a header or a free-text field an operator could paste a secret into.
        Pattern forbidden = Pattern.compile(
            "(?i)(password|passwd|secret|bearer\\s|eyJ[A-Za-z0-9_-]{10,}|api[_-]?key"
                + "|authorization|cookie|cvv|iban|\\b\\d{13,19}\\b)");
        List<String> actions = List.of(
            "PLACE_CREATE", "PLACE_UPDATE", "PLACE_STATUS_UPDATE", "PLACE_VERIFIED_UPDATE",
            "PLACE_FEATURED_UPDATE", "PLACE_METADATA_UPSERT",
            "ROOM_CREATE", "ROOM_UPDATE", "ROOM_DEACTIVATE");

        for (String action : actions) {
            for (AdminActivityLog log : auditRepo
                    .search(null, action, null, null, null, null, PageRequest.of(0, 200))
                    .getContent()) {
                for (String field : List.of(
                        String.valueOf(log.getDescription()),
                        String.valueOf(log.getBeforeState()),
                        String.valueOf(log.getAfterState()))) {
                    assertFalse(forbidden.matcher(field).find(),
                        action + " wrote credential-shaped text: " + field);
                }
            }
        }
    }

    @Test
    void beforeAndAfterStatesAreShortScalars_neverSerialisedEntities() throws Exception {
        Place place = freshPlace(PlaceStatus.APPROVED);
        mvc.perform(patch("/api/admin/places/" + place.getId() + "/featured")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"value\":true}"))
            .andExpect(status().isOk());

        AdminActivityLog log = allFor("PLACE_FEATURED_UPDATE", place.getId()).get(0);
        for (String state : List.of(log.getBeforeState(), log.getAfterState())) {
            assertNotNull(state);
            assertTrue(state.length() < 40, "state must be a short scalar, got: " + state);
            assertFalse(state.contains("{") || state.contains("Place@") || state.contains("["),
                "state must not be a serialised entity or collection: " + state);
        }
    }

    @Test
    void everyAuditedCatalogAndRoomActionUsesTheProjectTargetTypes() throws Exception {
        Place place = freshPlace(PlaceStatus.APPROVED);
        mvc.perform(patch("/api/admin/places/" + place.getId() + "/verified")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"value\":true}"))
            .andExpect(status().isOk());

        // PLACE is the target type the existing HOTEL_ASSIGN_OWNER audit already uses, and
        // HOTEL_ROOM follows the entity-name convention of MEDIA_ASSET / PARTNER_PROFILE.
        for (String action : List.of("PLACE_VERIFIED_UPDATE", "PLACE_STATUS_UPDATE")) {
            AdminActivityLog log = latest(action);
            if (log != null) assertEquals("PLACE", log.getTargetType(), action);
        }
        AdminActivityLog room = latest("ROOM_DEACTIVATE");
        if (room != null) assertEquals("HOTEL_ROOM", room.getTargetType());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // G · The remaining catalog mutations
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void placeMetadataUpsertIsAuditedAgainstThePlace() throws Exception {
        Place place = freshPlace(PlaceStatus.APPROVED);

        mvc.perform(put("/api/admin/places/" + place.getId() + "/metadata")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"travelStyles\":[],\"bestVisitTimes\":[],\"bestSeasons\":[],"
                    + "\"weatherTypes\":[]}"))
            .andExpect(status().isOk());

        AdminActivityLog log = allFor("PLACE_METADATA_UPSERT", place.getId()).get(0);
        assertEquals("PLACE", log.getTargetType(), "metadata has no independent lifecycle");
        assertEquals(place.getId(), log.getTargetId());
        assertEquals("metadata:absent", log.getBeforeState());
        assertEquals("metadata:present", log.getAfterState());

        mvc.perform(put("/api/admin/places/" + place.getId() + "/metadata")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"travelStyles\":[],\"bestVisitTimes\":[],\"bestSeasons\":[],"
                    + "\"weatherTypes\":[]}"))
            .andExpect(status().isOk());
        assertEquals("metadata:present",
            allFor("PLACE_METADATA_UPSERT", place.getId()).get(0).getBeforeState(),
            "the second upsert replaces an existing row and says so");
    }

    @Test
    void placeCreateIsAudited() throws Exception {
        long before = countOf("PLACE_CREATE");
        Place created = freshPlace(PlaceStatus.DRAFT);

        assertEquals(before + 1, countOf("PLACE_CREATE"), "one row for one creation");
        AdminActivityLog log = allFor("PLACE_CREATE", created.getId()).get(0);
        assertEquals("PLACE", log.getTargetType());
        assertEquals(created.getId(), log.getTargetId());
        assertEquals(adminUserId, log.getActorUserId());
        assertNull(log.getBeforeState(), "nothing existed before a creation");
        assertEquals("status:DRAFT", log.getAfterState());
    }

    @Test
    void placeUpdateIsAuditedAndNamesTheDestructiveReplace() throws Exception {
        Place place = freshPlace(PlaceStatus.DRAFT);
        Place template = placeRepo.findAll().get(0);
        long before = countOf("PLACE_UPDATE");

        mvc.perform(put("/api/admin/places/" + place.getId())
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(new PlaceRequest(
                    place.getName(), template.getCategory().getId(), null,
                    template.getAdministrativeUnit().getId(),
                    "2 Probe Road", null, 10.4, 107.1, "probe v2", "probe place v2",
                    1, null, false, false, null, List.of("beach"), List.of(), List.of()))))
            .andExpect(status().isOk());

        assertEquals(before + 1, countOf("PLACE_UPDATE"));
        AdminActivityLog log = allFor("PLACE_UPDATE", place.getId()).get(0);
        assertEquals("PLACE", log.getTargetType());
        assertEquals(adminUserId, log.getActorUserId());
        assertTrue(log.getDescription().contains("replaced"),
            "the wholesale replace of tags/hours/amenities must be named: "
                + log.getDescription());
        assertEquals("status:DRAFT", log.getBeforeState());
    }
}
