package com.example.planyourtrip;

import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.PartnerActivityLog;
import com.example.planyourtrip.model.PartnerMemberGrant;
import com.example.planyourtrip.model.PartnerMembershipStatus;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.PartnerTeamMember;
import com.example.planyourtrip.model.PartnerTeamRole;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.CategoryRepository;
import com.example.planyourtrip.repository.PartnerActivityLogRepository;
import com.example.planyourtrip.repository.PartnerMemberGrantRepository;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.PartnerTeamMemberRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.security.rbac.AuthorizationDecision;
import com.example.planyourtrip.security.rbac.LegacyPartnerBundles;
import com.example.planyourtrip.security.rbac.PartnerAccessContext;
import com.example.planyourtrip.security.rbac.PartnerAuthorization;
import com.example.planyourtrip.security.rbac.PartnerGrant;
import com.example.planyourtrip.security.rbac.PartnerPermission;
import com.example.planyourtrip.security.rbac.PartnerRoleScopes;
import com.example.planyourtrip.security.rbac.ResourceType;
import com.example.planyourtrip.security.rbac.ScopePath;
import com.example.planyourtrip.security.rbac.ScopeRef;
import com.example.planyourtrip.security.rbac.ScopeSet;
import com.example.planyourtrip.security.rbac.ScopeType;
import com.example.planyourtrip.service.PartnerAccessService;
import com.example.planyourtrip.service.PartnerMembershipService;
import com.example.planyourtrip.service.PartnerMembershipService.ResolvedGrant;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.time.Instant;
import java.util.EnumSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.Function;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * R2 — the persistent membership and scope foundation (RBAC V1.1 §11, §12.3, §28 M-1/M-2/M-4).
 *
 * <p>Memberships carry a status, grants carry an explicit company, property or room-type scope, every scope
 * is resolved from stored ownership, and one Partner account belongs to one company. Nothing here widens
 * anyone's rights: the R1 kernel still decides with the legacy bundles, and the grants written in R2 are
 * read by nothing that answers a request.
 *
 * <p>Like {@code RbacKernelHttpTest}, every scenario provisions its own partners through the public API and
 * the class is not {@code @Transactional}, so each request commits as in production.
 */
@SpringBootTest
@AutoConfigureMockMvc
class RbacMembershipFoundationTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired JdbcTemplate jdbc;
    @Autowired UserRepository userRepo;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired PartnerProfileRepository profileRepo;
    @Autowired PartnerTeamMemberRepository teamMemberRepo;
    @Autowired PartnerMemberGrantRepository grantRepo;
    @Autowired PartnerActivityLogRepository activityLogRepo;
    @Autowired PartnerMembershipService memberships;
    @Autowired PartnerAccessService partnerAccess;

    private static final AtomicInteger counter = new AtomicInteger(1);
    private static final String SETTINGS_BODY = """
        {"defaultLanguage":"en","timezone":"Asia/Ho_Chi_Minh",
         "notificationEmailEnabled":true,"notificationSmsEnabled":false,"notificationInAppEnabled":true,
         "bookingNotificationEnabled":true,"paymentNotificationEnabled":true,
         "reviewNotificationEnabled":true,"promotionNotificationEnabled":true}
        """;
    /** A bundle used only to exercise scope evaluation on R2 data; no production path uses it in R2. */
    private static final Function<PartnerTeamRole, Set<PartnerPermission>> PROBE_BUNDLE = role -> EnumSet.of(
        PartnerPermission.WORKSPACE_ACCESS, PartnerPermission.PROPERTY_VIEW, PartnerPermission.ROOM_VIEW,
        PartnerPermission.SETTINGS_EDIT);

    private String adminToken;

    private record Partner(String token, Long profileId, Long userId, String email) {}
    private record Account(String token, Long userId, String email) {}

    // ═══════════════════════════════════════════════════════════════════════
    // Memberships
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void approvalPersistsTheRegistrantsOwnerMembershipWithAMirroredCompanyGrant() throws Exception {
        Partner partner = approvedPartner();
        PartnerTeamMember owner = membership(partner.profileId(), partner.userId());

        assertEquals(PartnerTeamRole.OWNER, owner.getRole());
        assertEquals(PartnerMembershipStatus.ACTIVE, owner.getStatus());
        assertTrue(owner.isActive());
        assertFalse(owner.isPendingOwnerConfirmation());
        assertNotNull(owner.getVersion());

        List<PartnerMemberGrant> grants = grantRepo.findByTeamMemberIdOrderByIdAsc(owner.getId());
        assertEquals(1, grants.size());
        PartnerMemberGrant grant = grants.get(0);
        assertEquals(PartnerTeamRole.OWNER, grant.getRole());
        assertEquals(ScopeType.COMPANY, grant.getScopeType());
        assertEquals(partner.profileId(), grant.getScopeId(), "a company grant stores the company id, never null");
        assertNull(grant.getProperty());
        assertNull(grant.getUnit());
        assertNotNull(grant.getCreatedAt());

        // approving again neither duplicates the membership nor its grant
        mvc.perform(auth(post("/api/admin/partners/" + partner.profileId() + "/approve"), adminToken()));
        assertEquals(1, teamMemberRepo.findByPartnerProfileIdOrderByCreatedAtAsc(partner.profileId()).size());
        assertEquals(1, grantRepo.findByTeamMemberIdOrderByIdAsc(owner.getId()).size());
    }

    @Test
    void oneMembershipPerCompanyAndUserAndOneGrantPerRoleAndScope() throws Exception {
        Partner partner = approvedPartner();
        Account member = memberAccount(partner, "VIEWER");
        PartnerTeamMember row = membership(partner.profileId(), member.userId());

        PartnerTeamMember duplicate = new PartnerTeamMember();
        duplicate.setPartnerProfile(profileRepo.getReferenceById(partner.profileId()));
        duplicate.setUser(userRepo.getReferenceById(member.userId()));
        duplicate.setRole(PartnerTeamRole.MANAGER);
        assertThrows(DataIntegrityViolationException.class, () -> teamMemberRepo.saveAndFlush(duplicate));

        PartnerMemberGrant first = memberships.grant(row, PartnerTeamRole.VIEWER,
            new ScopeRef(ScopeType.COMPANY, partner.profileId()), partner.userId());
        PartnerMemberGrant again = memberships.grant(row, PartnerTeamRole.VIEWER,
            new ScopeRef(ScopeType.COMPANY, partner.profileId()), partner.userId());
        assertEquals(first.getId(), again.getId(), "granting what is already held returns the existing grant");
        assertEquals(1, grantRepo.findByTeamMemberIdOrderByIdAsc(row.getId()).size());

        assertThrows(DataIntegrityViolationException.class, () -> grantRepo.saveAndFlush(
            PartnerMemberGrant.company(row, PartnerTeamRole.VIEWER, null)));
    }

    @Test
    void suspensionKeepsGrantsButASuspendedMembershipHoldsNothing() throws Exception {
        Partner partner = approvedPartner();
        Long propertyId = createProperty(partner);
        Account member = memberAccount(partner, "MANAGER");
        Long memberRowId = membership(partner.profileId(), member.userId()).getId();
        memberships.grant(membership(partner.profileId(), member.userId()), PartnerTeamRole.CONTENT,
            new ScopeRef(ScopeType.PROPERTY, propertyId), partner.userId());

        patchMember(partner, memberRowId, "{\"active\":false}", HttpStatus.OK);
        PartnerTeamMember suspended = membership(partner.profileId(), member.userId());
        assertEquals(PartnerMembershipStatus.SUSPENDED, suspended.getStatus());
        assertFalse(suspended.isActive());
        assertEquals(partner.userId(), suspended.getStatusChangedBy(), "the legacy endpoint records who suspended");
        assertNotNull(suspended.getStatusChangedAt());
        assertEquals(2, grantRepo.findByTeamMemberIdOrderByIdAsc(memberRowId).size(), "grants survive suspension");
        assertTrue(memberships.kernelGrants(suspended, PROBE_BUNDLE).isEmpty(), "a suspended membership holds nothing");
        assertTrue(memberships.activeTeamMembership(member.userId()).isEmpty());
        // the legacy workspace refuses a suspended member exactly as before
        mvc.perform(auth(get("/api/partner/settings"), member.token())).andExpect(status().isNotFound());

        patchMember(partner, memberRowId, "{\"active\":true}", HttpStatus.OK);
        PartnerTeamMember reactivated = membership(partner.profileId(), member.userId());
        assertEquals(PartnerMembershipStatus.ACTIVE, reactivated.getStatus());
        assertTrue(reactivated.isActive());
        assertEquals(2, memberships.kernelGrants(reactivated, PROBE_BUNDLE).size());
        mvc.perform(auth(get("/api/partner/settings"), member.token())).andExpect(status().isOk());
    }

    @Test
    void aRevokedMembershipIsNeverRevived() {
        PartnerTeamMember row = new PartnerTeamMember();
        row.changeStatus(PartnerMembershipStatus.REVOKED, "test", 1L);
        assertFalse(row.isActive());
        assertThrows(IllegalStateException.class, () -> row.setActive(true));
        assertThrows(IllegalStateException.class, () -> row.changeStatus(PartnerMembershipStatus.ACTIVE, null, null));
        row.setActive(false);
        assertEquals(PartnerMembershipStatus.REVOKED, row.getStatus());
    }

    @Test
    void theCompanyOfAMembershipComesFromStoredData() throws Exception {
        Partner partner = approvedPartner();
        Account member = memberAccount(partner, "FRONT_DESK");

        PartnerTeamMember resolved = memberships.activeTeamMembership(member.userId()).orElseThrow();
        assertEquals(partner.profileId(), memberships.companyOf(resolved).getId());
        assertEquals(1, memberships.membershipsOf(member.userId()).size());
        // the registrant's own row is their company, not a team membership elsewhere
        assertTrue(memberships.activeTeamMembership(partner.userId()).isEmpty());
        assertEquals(1, memberships.membershipsOf(partner.userId()).size());
        assertTrue(memberships.membershipsOf(null).isEmpty());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Grants and containment
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void companyPropertyAndUnitGrantsResolveToTheirStoredScope() throws Exception {
        Partner partner = approvedPartner();
        Long propertyId = createProperty(partner);
        Long roomId = createRoom(propertyId);
        PartnerTeamMember row = membership(partner.profileId(), memberAccount(partner, "MANAGER").userId());

        PartnerMemberGrant property = memberships.grant(row, PartnerTeamRole.REVENUE,
            new ScopeRef(ScopeType.PROPERTY, propertyId), partner.userId());
        assertEquals(propertyId, property.getScopeId());
        assertEquals(propertyId, property.getProperty().getId());
        assertNull(property.getUnit());

        PartnerMemberGrant unit = memberships.grant(row, PartnerTeamRole.HOUSEKEEPING,
            new ScopeRef(ScopeType.UNIT, roomId), partner.userId());
        assertEquals(roomId, unit.getScopeId());
        assertEquals(roomId, unit.getUnit().getId());
        assertEquals(propertyId, unit.getProperty().getId(), "a unit grant records its room type's property");

        assertEquals(Set.of(
                ScopePath.company(partner.profileId()),
                ScopePath.property(partner.profileId(), propertyId),
                ScopePath.unit(partner.profileId(), propertyId, roomId)),
            scopesOf(memberships.resolveGrants(row)));
    }

    @Test
    void containmentIsDecidedByCurrentOwnership() throws Exception {
        Partner a = approvedPartner();
        Partner b = approvedPartner();
        Long propertyA = createProperty(a);
        Long otherPropertyA = createProperty(a);
        Long propertyB = createProperty(b);
        Long roomA = createRoom(propertyA);
        Long roomB = createRoom(propertyB);

        assertTrue(memberships.propertyBelongsToCompany(propertyA, a.profileId()));
        assertFalse(memberships.propertyBelongsToCompany(propertyB, a.profileId()));
        assertFalse(memberships.propertyBelongsToCompany(Long.MAX_VALUE, a.profileId()));
        assertFalse(memberships.propertyBelongsToCompany(propertyA, null));

        assertTrue(memberships.unitBelongsToProperty(roomA, propertyA));
        assertFalse(memberships.unitBelongsToProperty(roomA, otherPropertyA));
        assertFalse(memberships.unitBelongsToProperty(roomB, propertyA));
        assertFalse(memberships.unitBelongsToProperty(roomA, null));

        assertTrue(memberships.unitBelongsToCompany(roomA, a.profileId()));
        assertFalse(memberships.unitBelongsToCompany(roomB, a.profileId()));
        assertFalse(memberships.unitBelongsToCompany(Long.MAX_VALUE, a.profileId()));

        // ownership is read from Place.owner each time: move the property and containment follows it
        jdbc.update("update places set owner_partner_profile_id = ? where id = ?", b.profileId(), propertyA);
        assertFalse(memberships.propertyBelongsToCompany(propertyA, a.profileId()));
        assertTrue(memberships.propertyBelongsToCompany(propertyA, b.profileId()));
        assertTrue(memberships.unitBelongsToCompany(roomA, b.profileId()));
    }

    @Test
    void aGrantIntoAnotherCompanyIsRefusedWithoutRevealingIt() throws Exception {
        Partner a = approvedPartner();
        Partner b = approvedPartner();
        Long propertyB = createProperty(b);
        Long roomB = createRoom(propertyB);
        PartnerTeamMember row = membership(a.profileId(), memberAccount(a, "MANAGER").userId());

        for (ScopeRef foreign : List.of(new ScopeRef(ScopeType.COMPANY, b.profileId()),
                new ScopeRef(ScopeType.PROPERTY, propertyB), new ScopeRef(ScopeType.UNIT, roomB),
                new ScopeRef(ScopeType.PROPERTY, Long.MAX_VALUE), new ScopeRef(ScopeType.UNIT, Long.MAX_VALUE))) {
            PartnerTeamRole role = foreign.type() == ScopeType.UNIT ? PartnerTeamRole.HOUSEKEEPING : PartnerTeamRole.MANAGER;
            ApiException refused = assertThrows(ApiException.class,
                () -> memberships.grant(row, role, foreign, a.userId()), foreign.toString());
            assertEquals(HttpStatus.UNPROCESSABLE_ENTITY, refused.status());
            assertEquals("SCOPE_INVALID", refused.code());
            assertEquals("scope", refused.field());
            // another company's id and a missing id get the same answer
            assertEquals("The scope does not belong to this company", refused.getMessage());
        }
        assertEquals(1, grantRepo.findByTeamMemberIdOrderByIdAsc(row.getId()).size(), "only the mirrored grant");
    }

    @Test
    void aUnitGrantRecordedUnderAnotherPropertyResolvesToNothing() throws Exception {
        Partner partner = approvedPartner();
        Long propertyOne = createProperty(partner);
        Long propertyTwo = createProperty(partner);
        Long roomOfTwo = createRoom(propertyTwo);
        PartnerTeamMember row = membership(partner.profileId(), memberAccount(partner, "VIEWER").userId());

        // A row no server path can write (grant() derives the property from the room type): stored directly.
        jdbc.update("insert into partner_member_grants (created_at, partner_profile_id, property_id, scope_id, "
                + "team_member_id, unit_id, role, scope_type) values (?, ?, ?, ?, ?, ?, 'HOUSEKEEPING', 'UNIT')",
            java.sql.Timestamp.from(Instant.now()), partner.profileId(), propertyOne, roomOfTwo, row.getId(), roomOfTwo);

        assertEquals(2, grantRepo.findByTeamMemberIdOrderByIdAsc(row.getId()).size());
        assertEquals(Set.of(ScopePath.company(partner.profileId())), scopesOf(memberships.resolveGrants(row)),
            "the mismatched unit grant is dropped, never re-pointed at either property");
    }

    @Test
    void aUnitGrantNeverActsAsItsProperty() throws Exception {
        Partner partner = approvedPartner();
        Long propertyId = createProperty(partner);
        Long room = createRoom(propertyId);
        Long siblingRoom = createRoom(propertyId);
        PartnerTeamMember row = membership(partner.profileId(), memberAccount(partner, "VIEWER").userId());
        deleteGrants(row);
        memberships.grant(row, PartnerTeamRole.HOUSEKEEPING, new ScopeRef(ScopeType.UNIT, room), partner.userId());

        PartnerAccessContext ctx = context(partner.profileId(), row, PROBE_BUNDLE);
        assertTrue(PartnerAuthorization.isGranted(ctx, "partner.room.view", ScopePath.unit(partner.profileId(), propertyId, room)));
        assertFalse(PartnerAuthorization.isGranted(ctx, "partner.room.view",
            ScopePath.unit(partner.profileId(), propertyId, siblingRoom)), "a unit grant does not reach sibling room types");
        assertFalse(PartnerAuthorization.isGranted(ctx, "partner.room.view", ScopePath.property(partner.profileId(), propertyId)));
        // PROPERTY_VIEW's floor is PROPERTY: a unit grant below the floor contributes nothing, never rounded up
        assertTrue(PartnerAuthorization.effectiveScopes(ctx, PartnerPermission.PROPERTY_VIEW).isEmpty());
        assertEquals(AuthorizationDecision.NOT_FOUND, PartnerAuthorization.resource(ctx, PartnerPermission.PROPERTY_VIEW,
            ResourceType.PROPERTY, ScopePath.property(partner.profileId(), propertyId)));
    }

    @Test
    void aPropertyGrantNeverActsAsTheCompany() throws Exception {
        Partner partner = approvedPartner();
        Long propertyId = createProperty(partner);
        Long otherProperty = createProperty(partner);
        PartnerTeamMember row = membership(partner.profileId(), memberAccount(partner, "VIEWER").userId());
        deleteGrants(row);
        memberships.grant(row, PartnerTeamRole.MANAGER, new ScopeRef(ScopeType.PROPERTY, propertyId), partner.userId());

        PartnerAccessContext ctx = context(partner.profileId(), row, PROBE_BUNDLE);
        assertEquals(AuthorizationDecision.ALLOW, PartnerAuthorization.resource(ctx, PartnerPermission.PROPERTY_VIEW,
            ResourceType.PROPERTY, ScopePath.property(partner.profileId(), propertyId)));
        assertEquals(AuthorizationDecision.NOT_FOUND, PartnerAuthorization.resource(ctx, PartnerPermission.PROPERTY_VIEW,
            ResourceType.PROPERTY, ScopePath.property(partner.profileId(), otherProperty)));
        // SETTINGS_EDIT is a company-level permission: a property grant never satisfies it
        assertEquals(AuthorizationDecision.FORBIDDEN, PartnerAuthorization.company(ctx, PartnerPermission.SETTINGS_EDIT));
        ScopeSet collection = PartnerAuthorization.collection(ctx, PartnerPermission.PROPERTY_VIEW);
        assertFalse(collection.companyWide());
        assertEquals(Set.of(propertyId), collection.propertyIds());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Frozen role decisions (§11.3, Q8, Q9, Q10)
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void housekeepingSitsAtAPropertyOrARoomTypeOnly() throws Exception {
        Partner partner = approvedPartner();
        Long propertyId = createProperty(partner);
        Long roomId = createRoom(propertyId);
        PartnerTeamMember row = membership(partner.profileId(), memberAccount(partner, "VIEWER").userId());

        assertEquals(EnumSet.of(ScopeType.PROPERTY, ScopeType.UNIT), PartnerRoleScopes.allowed(PartnerTeamRole.HOUSEKEEPING));
        memberships.grant(row, PartnerTeamRole.HOUSEKEEPING, new ScopeRef(ScopeType.PROPERTY, propertyId), partner.userId());
        memberships.grant(row, PartnerTeamRole.HOUSEKEEPING, new ScopeRef(ScopeType.UNIT, roomId), partner.userId());
        assertScopeInvalid(() -> memberships.grant(row, PartnerTeamRole.HOUSEKEEPING,
            new ScopeRef(ScopeType.COMPANY, partner.profileId()), partner.userId()));

        // the role exists but carries no runtime capability yet, and the legacy endpoints cannot assign it
        assertTrue(LegacyPartnerBundles.member(PartnerTeamRole.HOUSEKEEPING).isEmpty());
        mvc.perform(auth(json(post("/api/partner/team"),
                "{\"email\":\"" + registerPlainUser().email() + "\",\"role\":\"HOUSEKEEPING\"}"), partner.token()))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.code").value("VALIDATION_FAILED"))
            .andExpect(jsonPath("$.fieldErrors[0].field").value("role"));
    }

    @Test
    void financeIsCompanyOnlyAndOwnerToo() throws Exception {
        Partner partner = approvedPartner();
        Long propertyId = createProperty(partner);
        Long roomId = createRoom(propertyId);
        PartnerTeamMember row = membership(partner.profileId(), memberAccount(partner, "VIEWER").userId());

        assertEquals(EnumSet.of(ScopeType.COMPANY), PartnerRoleScopes.allowed(PartnerTeamRole.FINANCE));
        assertEquals(EnumSet.of(ScopeType.COMPANY), PartnerRoleScopes.allowed(PartnerTeamRole.OWNER));
        for (PartnerTeamRole role : List.of(PartnerTeamRole.FINANCE, PartnerTeamRole.OWNER)) {
            assertScopeInvalid(() -> memberships.grant(row, role, new ScopeRef(ScopeType.PROPERTY, propertyId), partner.userId()));
            assertScopeInvalid(() -> memberships.grant(row, role, new ScopeRef(ScopeType.UNIT, roomId), partner.userId()));
        }
        memberships.grant(row, PartnerTeamRole.FINANCE, new ScopeRef(ScopeType.COMPANY, partner.profileId()), partner.userId());
        for (PartnerTeamRole role : List.of(PartnerTeamRole.MANAGER, PartnerTeamRole.REVENUE, PartnerTeamRole.RESERVATIONS,
                PartnerTeamRole.FRONT_DESK, PartnerTeamRole.CONTENT, PartnerTeamRole.VIEWER)) {
            assertEquals(EnumSet.of(ScopeType.COMPANY, ScopeType.PROPERTY), PartnerRoleScopes.allowed(role), role.name());
            assertScopeInvalid(() -> memberships.grant(row, role, new ScopeRef(ScopeType.UNIT, roomId), partner.userId()));
        }
        assertTrue(PartnerRoleScopes.allowed(null).isEmpty());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Fail closed
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void anUnknownOrInvalidScopeFailsClosed() throws Exception {
        Partner partner = approvedPartner();
        PartnerTeamMember row = membership(partner.profileId(), memberAccount(partner, "VIEWER").userId());

        for (String raw : new String[] {null, "", "company:1", "COMPANY", "COMPANY:", "COMPANY:0", "COMPANY:-1",
                "COMPANY:01", " PROPERTY:1", "ROOM:1", "ALL:1", "PROPERTY:*", "UNIT:99999999999999999999"}) {
            assertTrue(ScopeRef.parse(raw).isEmpty(), String.valueOf(raw));
        }
        assertThrows(IllegalArgumentException.class, () -> new ScopeRef(ScopeType.PROPERTY, 0));
        assertThrows(IllegalArgumentException.class, () -> new ScopeRef(null, 1));
        assertScopeInvalid(() -> memberships.grant(row, PartnerTeamRole.VIEWER, null, partner.userId()));
        assertScopeInvalid(() -> memberships.grant(row, null, new ScopeRef(ScopeType.COMPANY, partner.profileId()), partner.userId()));
        assertThrows(IllegalArgumentException.class, () -> memberships.grant(new PartnerTeamMember(), PartnerTeamRole.VIEWER,
            new ScopeRef(ScopeType.COMPANY, partner.profileId()), partner.userId()));
    }

    @Test
    void aStaleOrMalformedStoredGrantFailsClosed() throws Exception {
        Partner a = approvedPartner();
        Partner b = approvedPartner();
        Long property = createProperty(a);
        Long room = createRoom(property);
        PartnerTeamMember row = membership(a.profileId(), memberAccount(a, "VIEWER").userId());
        memberships.grant(row, PartnerTeamRole.MANAGER, new ScopeRef(ScopeType.PROPERTY, property), a.userId());
        memberships.grant(row, PartnerTeamRole.HOUSEKEEPING, new ScopeRef(ScopeType.UNIT, room), a.userId());
        assertEquals(3, memberships.resolveGrants(row).size());

        // the property changes hands: its grants in company A resolve to nothing; the company grant survives
        jdbc.update("update places set owner_partner_profile_id = ? where id = ?", b.profileId(), property);
        assertEquals(Set.of(ScopePath.company(a.profileId())), scopesOf(memberships.resolveGrants(row)));
        // and the same scope cannot be granted again inside A
        assertScopeInvalid(() -> memberships.grant(row, PartnerTeamRole.VIEWER, new ScopeRef(ScopeType.PROPERTY, property), a.userId()));

        // a property without an owning company is outside every company
        jdbc.update("update places set owner_partner_profile_id = null where id = ?", property);
        assertEquals(Set.of(ScopePath.company(a.profileId())), scopesOf(memberships.resolveGrants(row)));
    }

    @Test
    void aGrantCannotBelongToAnotherCompanyThanItsMembership() throws Exception {
        Partner a = approvedPartner();
        Partner b = approvedPartner();
        PartnerTeamMember row = membership(a.profileId(), memberAccount(a, "VIEWER").userId());

        // the factories take the company from the membership; the only way to differ is to forge the row
        PartnerMemberGrant grant = PartnerMemberGrant.company(row, PartnerTeamRole.VIEWER, null);
        assertEquals(a.profileId(), grant.getPartnerProfile().getId());
        PartnerProfile foreign = profileRepo.findById(b.profileId()).orElseThrow();
        org.springframework.test.util.ReflectionTestUtils.setField(grant, "partnerProfile", foreign);
        org.springframework.test.util.ReflectionTestUtils.setField(grant, "scopeId", b.profileId());
        // V5 refuses it with the composite foreign key; entity-built schemas (H2) through the persist guard
        Exception refused = assertThrows(Exception.class, () -> grantRepo.saveAndFlush(grant));
        assertTrue(causes(refused).contains("A grant must belong to its membership's company"), causes(refused));
        assertEquals(1, grantRepo.findByTeamMemberIdOrderByIdAsc(row.getId()).size());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // The R1 kernel on R2 data
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void theR1EvaluatorDecidesOnResolvedR2Grants() throws Exception {
        Partner a = approvedPartner();
        Partner b = approvedPartner();
        Long property = createProperty(a);
        Long foreign = createProperty(b);
        PartnerTeamMember row = membership(a.profileId(), memberAccount(a, "FINANCE").userId());

        List<PartnerGrant> legacy = memberships.kernelGrants(row, LegacyPartnerBundles::member);
        assertEquals(List.of(new PartnerGrant(LegacyPartnerBundles.member(PartnerTeamRole.FINANCE),
            ScopePath.company(a.profileId()))), legacy, "the mirrored grant carries exactly the legacy bundle");

        PartnerAccessContext ctx = context(a.profileId(), row, PROBE_BUNDLE);
        assertEquals(AuthorizationDecision.ALLOW, PartnerAuthorization.resource(ctx, PartnerPermission.PROPERTY_VIEW,
            ResourceType.PROPERTY, ScopePath.property(a.profileId(), property)));
        assertEquals(AuthorizationDecision.NOT_FOUND, PartnerAuthorization.resource(ctx, PartnerPermission.PROPERTY_VIEW,
            ResourceType.PROPERTY, ScopePath.property(b.profileId(), foreign)), "another company is never covered");
        assertEquals(AuthorizationDecision.ALLOW, PartnerAuthorization.company(ctx, PartnerPermission.SETTINGS_EDIT));

        // suspended: the same stored grants evaluate to nothing
        row.changeStatus(PartnerMembershipStatus.SUSPENDED, "test", a.userId());
        PartnerAccessContext suspended = context(a.profileId(), row, PROBE_BUNDLE);
        assertEquals(AuthorizationDecision.NOT_FOUND, PartnerAuthorization.resource(suspended, PartnerPermission.PROPERTY_VIEW,
            ResourceType.PROPERTY, ScopePath.property(a.profileId(), property)));
        assertEquals(AuthorizationDecision.FORBIDDEN, PartnerAuthorization.company(suspended, PartnerPermission.WORKSPACE_ACCESS));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // One company per Partner account (§11.6, Q1)
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void aTeamMemberCannotRegisterASecondCompany() throws Exception {
        Partner a = approvedPartner();
        Account member = memberAccount(a, "VIEWER");

        mvc.perform(auth(json(post("/api/partner/profile"), profileBody()), member.token()))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.code").value("WORKSPACE_CONFLICT"))
            .andExpect(jsonPath("$.reason").value("MEMBERSHIP_EXISTS"));
        assertTrue(profileRepo.findByUserId(member.userId()).isEmpty(), "nothing is created");

        // a suspended membership still counts; only leaving (R3a) frees the account
        patchMember(a, membership(a.profileId(), member.userId()).getId(), "{\"active\":false}", HttpStatus.OK);
        mvc.perform(auth(json(post("/api/partner/profile"), profileBody()), member.token()))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.code").value("WORKSPACE_CONFLICT"));
        assertTrue(profileRepo.findByUserId(member.userId()).isEmpty());

        // an account without a membership still registers a company and edits its own draft, as before
        Account newcomer = registerPlainUser();
        mvc.perform(auth(json(post("/api/partner/profile"), profileBody()), newcomer.token())).andExpect(status().isOk());
        mvc.perform(auth(json(post("/api/partner/profile"), profileBody()), newcomer.token())).andExpect(status().isOk());
        assertTrue(profileRepo.findByUserId(newcomer.userId()).isPresent());
        // and other errors keep their exact shape
        mvc.perform(auth(get("/api/partner/hotels/" + Long.MAX_VALUE), a.token()))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.reason").doesNotExist());
    }

    @Test
    void aRegistrantOrAnActiveMemberElsewhereCannotBeAddedToAnotherTeam() throws Exception {
        Partner a = approvedPartner();
        Partner b = approvedPartner();
        Account memberOfA = memberAccount(a, "FRONT_DESK");

        // the registrant of B cannot join A, and an active member of A cannot join B: one uniform answer
        for (Object[] attempt : new Object[][] {{a, b.email()}, {b, memberOfA.email()}}) {
            Partner owner = (Partner) attempt[0];
            mvc.perform(auth(json(post("/api/partner/team"),
                    "{\"email\":\"" + attempt[1] + "\",\"role\":\"VIEWER\"}"), owner.token()))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("MEMBER_NOT_ADDABLE"))
                .andExpect(jsonPath("$.message").value("This account cannot be added to the team"))
                .andExpect(jsonPath("$.reason").doesNotExist());
        }
        assertTrue(teamMemberRepo.findByPartnerProfileIdAndUserId(a.profileId(), b.userId()).isEmpty());
        assertTrue(teamMemberRepo.findByPartnerProfileIdAndUserId(b.profileId(), memberOfA.userId()).isEmpty());

        // an inactive membership elsewhere may exist, as before; reactivating it re-checks the invariant (WS-5)
        String body = mvc.perform(auth(json(post("/api/partner/team"),
                "{\"email\":\"" + memberOfA.email() + "\",\"role\":\"VIEWER\",\"active\":false}"), b.token()))
            .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        long inactiveRow = mapper.readTree(body).get("id").asLong();
        mvc.perform(auth(json(patch("/api/partner/team/" + inactiveRow), "{\"active\":true}"), b.token()))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.code").value("WORKSPACE_CONFLICT"))
            .andExpect(jsonPath("$.reason").value("MEMBERSHIP_EXISTS"));
        assertFalse(teamMemberRepo.findById(inactiveRow).orElseThrow().isActive());
        assertEquals(a.profileId(), memberships.activeTeamMembership(memberOfA.userId()).orElseThrow().getPartnerProfile().getId());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Compatibility: registrant, legacy roles, legacy endpoints
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void theRegistrantKeepsEveryPower() throws Exception {
        Partner partner = approvedPartner();
        Long propertyId = createProperty(partner);
        PartnerAccessContext ctx = partnerAccess.requireRegistrantWorkspace(partner.userId());
        assertTrue(ctx.registrant());
        assertEquals(LegacyPartnerBundles.registrant(), ctx.grants().get(0).permissions());

        for (String path : new String[] {"/api/partner/hotels", "/api/partner/hotels/" + propertyId,
                "/api/partner/settings", "/api/partner/team", "/api/partner/finance/overview"}) {
            mvc.perform(auth(get(path), partner.token())).andExpect(status().isOk());
        }
        mvc.perform(auth(json(put("/api/partner/settings"), SETTINGS_BODY), partner.token())).andExpect(status().isOk());
    }

    @Test
    void storedGrantsGiveATeamMemberNothingInR2() throws Exception {
        Partner partner = approvedPartner();
        Long propertyId = createProperty(partner);
        Account viewer = memberAccount(partner, "VIEWER");
        PartnerTeamMember row = membership(partner.profileId(), viewer.userId());
        // grants that R3b will honour — stored now, read by no request path yet
        memberships.grant(row, PartnerTeamRole.MANAGER, new ScopeRef(ScopeType.PROPERTY, propertyId), partner.userId());
        memberships.grant(row, PartnerTeamRole.CONTENT, new ScopeRef(ScopeType.COMPANY, partner.profileId()), partner.userId());

        for (String path : new String[] {"/api/partner/hotels", "/api/partner/hotels/" + propertyId,
                "/api/partner/bookings", "/api/partner/extranet/home"}) {
            mvc.perform(auth(get(path), viewer.token()))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Partner profile not found"));
        }
        mvc.perform(auth(json(put("/api/partner/settings"), SETTINGS_BODY), viewer.token()))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.code").value("PERMISSION_DENIED"));
        mvc.perform(auth(get("/api/partner/settings"), viewer.token())).andExpect(status().isOk());

        PartnerAccessContext legacy = partnerAccess.requireTeamWorkspace(viewer.userId());
        assertEquals(List.of(new PartnerGrant(LegacyPartnerBundles.member(PartnerTeamRole.VIEWER),
            ScopePath.company(partner.profileId()))), legacy.grants(), "the workspace still carries the legacy bundle only");
    }

    @Test
    void theLegacyTeamEndpointsKeepTheCompanyGrantInStep() throws Exception {
        Partner partner = approvedPartner();
        Long propertyId = createProperty(partner);
        Account member = memberAccount(partner, "FRONT_DESK");
        PartnerTeamMember row = membership(partner.profileId(), member.userId());
        assertEquals(List.of("FRONT_DESK@COMPANY"), describe(row.getId()));

        memberships.grant(row, PartnerTeamRole.CONTENT, new ScopeRef(ScopeType.PROPERTY, propertyId), partner.userId());
        patchMember(partner, row.getId(), "{\"role\":\"MANAGER\"}", HttpStatus.OK);
        assertEquals(List.of("CONTENT@PROPERTY", "MANAGER@COMPANY"), describe(row.getId()).stream().sorted().toList(),
            "the company grant follows the role; scoped grants are left alone");

        // the R2 roles cannot be assigned through the legacy endpoints
        for (String role : new String[] {"REVENUE", "RESERVATIONS", "CONTENT", "HOUSEKEEPING"}) {
            mvc.perform(auth(json(patch("/api/partner/team/" + row.getId()), "{\"role\":\"" + role + "\"}"), partner.token()))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.fieldErrors[0].field").value("role"));
        }
        assertEquals(PartnerTeamRole.MANAGER, membership(partner.profileId(), member.userId()).getRole());

        mvc.perform(auth(delete("/api/partner/team/" + row.getId()), partner.token())).andExpect(status().isNoContent());
        assertTrue(teamMemberRepo.findById(row.getId()).isEmpty());
        assertTrue(grantRepo.findByTeamMemberIdOrderByIdAsc(row.getId()).isEmpty(), "no orphaned grant remains");
    }

    @Test
    void partnerActivityRecordsTheActorsEmail() throws Exception {
        Partner partner = approvedPartner();
        memberAccount(partner, "VIEWER");
        List<PartnerActivityLog> entries = activityLogRepo.findByPartnerProfileIdOrderByCreatedAtDesc(partner.profileId());
        assertFalse(entries.isEmpty());
        PartnerActivityLog added = entries.stream().filter(e -> "TEAM_MEMBER_ADDED".equals(e.getAction()))
            .findFirst().orElseThrow();
        assertEquals(partner.email(), added.getActorEmail());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Helpers
    // ═══════════════════════════════════════════════════════════════════════

    private PartnerTeamMember membership(Long companyId, Long userId) {
        return teamMemberRepo.findByPartnerProfileIdAndUserId(companyId, userId).orElseThrow();
    }

    private void deleteGrants(PartnerTeamMember row) {
        memberships.deleteGrants(row);
    }

    private List<String> describe(Long memberRowId) {
        return grantRepo.findByTeamMemberIdOrderByIdAsc(memberRowId).stream()
            .map(g -> g.getRole().name() + "@" + g.getScopeType().name()).toList();
    }

    private static Set<ScopePath> scopesOf(List<ResolvedGrant> grants) {
        return Set.copyOf(grants.stream().map(ResolvedGrant::scope).toList());
    }

    private PartnerAccessContext context(Long companyId, PartnerTeamMember row,
                                         Function<PartnerTeamRole, Set<PartnerPermission>> bundles) {
        return new PartnerAccessContext(profileRepo.findById(companyId).orElseThrow(), row.getUser().getId(), false,
            memberships.kernelGrants(row, bundles));
    }

    private static String causes(Throwable failure) {
        StringBuilder messages = new StringBuilder();
        for (Throwable t = failure; t != null; t = t.getCause()) messages.append(t.getMessage()).append(" | ");
        return messages.toString();
    }

    private static void assertScopeInvalid(org.junit.jupiter.api.function.Executable call) {
        ApiException refused = assertThrows(ApiException.class, call);
        assertEquals(HttpStatus.UNPROCESSABLE_ENTITY, refused.status());
        assertEquals("SCOPE_INVALID", refused.code());
    }

    private void patchMember(Partner owner, Long memberRowId, String body, HttpStatus expected) throws Exception {
        mvc.perform(auth(json(patch("/api/partner/team/" + memberRowId), body), owner.token()))
            .andExpect(status().is(expected.value()));
    }

    private static MockHttpServletRequestBuilder auth(MockHttpServletRequestBuilder request, String token) {
        return request.header("Authorization", "Bearer " + token);
    }

    private static MockHttpServletRequestBuilder json(MockHttpServletRequestBuilder request, String body) {
        return request.contentType(MediaType.APPLICATION_JSON).content(body);
    }

    private String adminToken() throws Exception {
        if (adminToken == null) adminToken = login("admin@planyourtrip.com", "admin123456");
        return adminToken;
    }

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(json(post("/api/auth/login"),
                "{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private static String uniqueEmail(String prefix) {
        return "r2-" + prefix + "-" + counter.getAndIncrement() + "-"
            + UUID.randomUUID().toString().substring(0, 8) + "@test.com";
    }

    private String registerAndLogin(String email) throws Exception {
        String body = mvc.perform(json(post("/api/auth/register"),
                "{\"fullName\":\"R2 Tester\",\"email\":\"" + email + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private Account registerPlainUser() throws Exception {
        String email = uniqueEmail("member");
        String token = registerAndLogin(email);
        return new Account(token, userRepo.findByEmail(email).orElseThrow().getId(), email);
    }

    private static String profileBody() {
        return """
            {"businessName":"R2 Co %s","businessType":"HOTEL","representativeName":"R2 Tester",
             "phone":"0901234567","email":"contact@example.com","address":"1 Le Loi, Da Nang"}
            """.formatted(UUID.randomUUID().toString().substring(0, 8));
    }

    private Partner approvedPartner() throws Exception {
        String email = uniqueEmail("partner");
        String token = registerAndLogin(email);
        Long profileId = mapper.readTree(mvc.perform(auth(json(post("/api/partner/profile"), profileBody()), token))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString()).get("id").asLong();
        mvc.perform(auth(post("/api/partner/profile/submit"), token)).andExpect(status().isOk());
        mvc.perform(auth(post("/api/admin/partners/" + profileId + "/approve"), adminToken()))
            .andExpect(status().isOk());
        return new Partner(token, profileId, userRepo.findByEmail(email).orElseThrow().getId(), email);
    }

    private Account memberAccount(Partner owner, String role) throws Exception {
        Account account = registerPlainUser();
        mvc.perform(auth(json(post("/api/partner/team"),
                "{\"email\":\"" + account.email() + "\",\"role\":\"" + role + "\"}"), owner.token()))
            .andExpect(status().isCreated());
        return new Account(login(account.email(), "password123"), account.userId(), account.email());
    }

    private Long createProperty(Partner partner) throws Exception {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("name", "R2 Stay " + UUID.randomUUID().toString().substring(0, 8));
        body.put("categoryId", categoryRepo.findBySlug("accommodation").orElseThrow().getId());
        body.put("subcategoryId", categoryRepo.findBySlug("hotel").orElseThrow().getId());
        body.put("administrativeUnitId", locationRepo.findByCode("VT").orElseThrow().getId());
        body.put("address", "15 Thuy Van, Vung Tau");
        body.put("starRating", 3);
        body.put("checkIn", "14:00:00");
        body.put("checkOut", "12:00:00");
        String response = mvc.perform(auth(json(post("/api/partner/hotels"), mapper.writeValueAsString(body)),
                partner.token()))
            .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        return mapper.readTree(response).get("id").asLong();
    }

    private Long createRoom(Long placeId) throws Exception {
        String body = """
            {"placeId":%d,"roomName":"R2 Room","roomCode":"R2-%s","roomType":"STANDARD","bedType":"DOUBLE",
             "bedCount":1,"maxAdults":2,"maxChildren":0,"maxGuests":2,"priceFrom":100.00,"originalPrice":120.00,
             "quantity":5,"availableQuantity":5}
            """.formatted(placeId, UUID.randomUUID().toString().substring(0, 6));
        JsonNode room = mapper.readTree(mvc.perform(auth(json(post("/api/admin/rooms"), body), adminToken()))
            .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString());
        return room.get("id").asLong();
    }
}
