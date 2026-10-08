package com.example.planyourtrip;

import com.example.planyourtrip.model.BusinessType;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.PartnerVerificationStatus;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

/**
 * R2 — the database refuses impossible memberships and grants (RBAC V1.1 §12.3, §11.3).
 *
 * <p>Tests run on H2 with the schema Hibernate builds from the entities; Flyway is off
 * ({@code spring.flyway.enabled=false}), so V4–V6 do not run here. The entities therefore declare the same
 * named CHECK expressions as the migrations ({@code RbacMembershipMigrationTest} proves the texts are
 * identical), and this class proves H2 enforces them. Two production constraints have no entity
 * equivalent and are covered elsewhere: the composite foreign key pinning a grant to its membership's company
 * (the entity's persist guard, {@code RbacMembershipFoundationTest}) and V4's re-created role CHECK (Hibernate
 * derives the same nine values from the enum).
 *
 * <p>Every test is transactional and rolls back; rows are written with plain SQL so the constraints, not
 * the entities, are what refuses them.
 */
@SpringBootTest
@Transactional
class RbacMembershipSchemaTest {

    private static final String GRANT_INSERT = "insert into partner_member_grants (created_at, partner_profile_id, "
        + "property_id, scope_id, team_member_id, unit_id, role, scope_type) values (?, ?, ?, ?, ?, ?, ?, ?)";

    @Autowired JdbcTemplate jdbc;
    @Autowired UserRepository users;
    @Autowired PartnerProfileRepository profiles;

    private Long company;
    private Long registrant;
    private Long member;
    private Long place;
    private Long room;
    private Long roomPlace;

    @BeforeEach
    void fixture() {
        User owner = user("PARTNER");
        company = approvedCompany(owner).getId();
        registrant = membership(company, owner.getId(), "OWNER", true);
        member = membership(company, user("PARTNER").getId(), "VIEWER", true);
        place = jdbc.queryForObject("select min(id) from places", Long.class);
        Map<String, Object> anyRoom = jdbc.queryForMap(
            "select r.id room_id, d.place_id place_id from hotel_rooms r join hotel_details d on d.id = r.hotel_detail_id "
                + "order by r.id limit 1");
        room = ((Number) anyRoom.get("room_id")).longValue();
        roomPlace = ((Number) anyRoom.get("place_id")).longValue();
    }

    @Test
    void wellFormedGrantsAreAccepted() {
        grant(company, null, company, member, null, "MANAGER", "COMPANY");
        grant(company, place, place, member, null, "MANAGER", "PROPERTY");
        grant(company, roomPlace, room, member, room, "HOUSEKEEPING", "UNIT");
        grant(company, place, place, member, null, "HOUSEKEEPING", "PROPERTY");
        grant(company, null, company, member, null, "FINANCE", "COMPANY");
        assertEquals(5, jdbc.queryForObject(
            "select count(*) from partner_member_grants where team_member_id = ?", Integer.class, member));
    }

    @Test
    void rolesSitOnlyAtTheirAllowedScopeTypes() {
        refused("ck_partner_member_grants_role_scope", company, place, place, member, null, "OWNER", "PROPERTY");
        refused("ck_partner_member_grants_role_scope", company, place, place, member, null, "FINANCE", "PROPERTY");
        refused("ck_partner_member_grants_role_scope", company, roomPlace, room, member, room, "FINANCE", "UNIT");
        refused("ck_partner_member_grants_role_scope", company, roomPlace, room, member, room, "MANAGER", "UNIT");
        refused("ck_partner_member_grants_role_scope", company, null, company, member, null, "HOUSEKEEPING", "COMPANY");
    }

    @Test
    void eachScopeTypeHasExactlyItsShape() {
        long otherCompany = approvedCompany(user("PARTNER")).getId();
        refused("ck_partner_member_grants_scope_shape", company, null, otherCompany, member, null, "VIEWER", "COMPANY");
        refused("ck_partner_member_grants_scope_shape", company, place, company, member, null, "VIEWER", "COMPANY");
        refused("ck_partner_member_grants_scope_shape", company, null, company, member, room, "VIEWER", "COMPANY");
        refused("ck_partner_member_grants_scope_shape", company, null, place, member, null, "VIEWER", "PROPERTY");
        refused("ck_partner_member_grants_scope_shape", company, place, place, member, room, "VIEWER", "PROPERTY");
        refused("ck_partner_member_grants_scope_shape", company, roomPlace, room, member, null, "HOUSEKEEPING", "UNIT");
        refused("ck_partner_member_grants_scope_shape", company, null, room, member, room, "HOUSEKEEPING", "UNIT");
    }

    @Test
    void allPropertiesIsNeverAFakeIdAndUnknownValuesFailClosed() {
        refused("ck_partner_member_grants_scope_id", company, null, 0L, member, null, "VIEWER", "PROPERTY");
        refused("ck_partner_member_grants_scope_id", company, null, -1L, member, null, "VIEWER", "COMPANY");
        refused(null, company, roomPlace, room, member, room, "HOUSEKEEPING", "ROOM");
        refused(null, company, null, company, member, null, "SUPER_OWNER", "COMPANY");
        refused(null, company, null, company, member, null, null, "COMPANY");
        refused(null, company, null, company, member, null, "VIEWER", null);
    }

    @Test
    void grantsReferenceOnlyExistingRowsAndAreUnique() {
        refused("Referential integrity", company, Long.MAX_VALUE, Long.MAX_VALUE, member, null, "VIEWER", "PROPERTY");
        refused("Referential integrity", company, roomPlace, Long.MAX_VALUE, member, Long.MAX_VALUE, "HOUSEKEEPING", "UNIT");
        refused("Referential integrity", company, null, company, Long.MAX_VALUE, null, "VIEWER", "COMPANY");
        grant(company, null, company, member, null, "VIEWER", "COMPANY");
        refused("uk_partner_member_grant", company, null, company, member, null, "VIEWER", "COMPANY");
        // a membership holding grants cannot be hard-deleted out from under them
        assertThrows(DataIntegrityViolationException.class,
            () -> jdbc.update("delete from partner_team_members where id = ?", member));
    }

    @Test
    void aMembershipsStatusAndActiveFlagAlwaysAgree() {
        refusedSql("ck_partner_team_members_active_status",
            "update partner_team_members set active = false where id = ?", member);
        refusedSql("ck_partner_team_members_active_status",
            "update partner_team_members set status = 'SUSPENDED' where id = ?", member);
        refusedSql("ck_partner_team_members_active_status",
            "update partner_team_members set status = 'REVOKED' where id = ?", member);
        refusedSql(null, "update partner_team_members set status = 'PENDING' where id = ?", member);
        refusedSql(null, "update partner_team_members set role = 'SUPER_OWNER' where id = ?", member);

        jdbc.update("update partner_team_members set active = false, status = 'SUSPENDED', status_reason = 'LEGACY_INACTIVE' "
            + "where id = ?", member);
        // RBAC R4 (V8): a revoked row carries its own id as revocation key, a live row 0 — never anything else
        refusedSql("ck_partner_team_members_revocation_key",
            "update partner_team_members set status = 'REVOKED' where id = ?", member);
        refusedSql("ck_partner_team_members_revocation_key",
            "update partner_team_members set revocation_key = id where id = ?", member);
        jdbc.update("update partner_team_members set status = 'REVOKED', revocation_key = id where id = ?", member);
        jdbc.update("update partner_team_members set role = 'HOUSEKEEPING' where id = ?", member);
    }

    @Test
    void anActivityLogEntryAlwaysCarriesItsActorsEmail() {
        Long actor = jdbc.queryForObject("select user_id from partner_team_members where id = ?", Long.class, registrant);
        refusedSql(null, "insert into partner_activity_logs (actor_user_id, partner_profile_id, action, created_at) "
            + "values (?, ?, 'TEST', current_timestamp)", actor, company);
        jdbc.update("insert into partner_activity_logs (actor_user_id, partner_profile_id, action, created_at, actor_email) "
            + "values (?, ?, 'TEST', current_timestamp, 'owner@test.com')", actor, company);
    }

    /** The M-0 audit is read-only, portable, and finds each documented case (§28 M-0). */
    @Test
    void theM0AuditFindsEachCase() throws IOException {
        User admin = user("ADMIN");
        User traveller = user("USER");
        User coOwner = user("PARTNER");
        User doubleMember = user("PARTNER");
        User secondRegistrant = user("PARTNER");
        Long secondCompany = approvedCompany(secondRegistrant).getId();   // approved, no OWNER row: G

        long adminRow = membership(company, admin.getId(), "VIEWER", true);                 // A, F
        long travellerRow = membership(company, traveller.getId(), "VIEWER", false);        // E, F
        long coOwnerRow = membership(company, coOwner.getId(), "OWNER", true);               // D
        long firstRow = membership(company, doubleMember.getId(), "VIEWER", true);          // C
        long secondRow = membership(secondCompany, doubleMember.getId(), "VIEWER", true);   // C
        long ownProfileRow = membership(company, secondRegistrant.getId(), "VIEWER", true); // B

        Set<String> found = new HashSet<>();
        for (Map<String, Object> row : jdbc.queryForList(auditSql())) {
            Object teamMember = row.get("team_member_id");
            found.add(row.get("finding") + ":" + row.get("user_id") + ":" + row.get("partner_profile_id") + ":"
                + (teamMember == null ? "-" : ((Number) teamMember).longValue()));
        }
        for (String expected : List.of(
                "A_ADMIN_MEMBER:" + admin.getId() + ":" + company + ":" + adminRow,
                "B_OWN_PROFILE_AND_MEMBERSHIP:" + secondRegistrant.getId() + ":" + company + ":" + ownProfileRow,
                "C_MULTIPLE_ACTIVE_MEMBERSHIPS:" + doubleMember.getId() + ":" + company + ":" + firstRow,
                "C_MULTIPLE_ACTIVE_MEMBERSHIPS:" + doubleMember.getId() + ":" + secondCompany + ":" + secondRow,
                "D_NON_REGISTRANT_OWNER:" + coOwner.getId() + ":" + company + ":" + coOwnerRow,
                "E_INACTIVE_MEMBERSHIP:" + traveller.getId() + ":" + company + ":" + travellerRow,
                "F_ACCOUNT_NOT_PARTNER:" + admin.getId() + ":" + company + ":" + adminRow,
                "F_ACCOUNT_NOT_PARTNER:" + traveller.getId() + ":" + company + ":" + travellerRow,
                "G_APPROVED_WITHOUT_OWNER_ROW:" + secondRegistrant.getId() + ":" + secondCompany + ":-")) {
            assertTrue(found.contains(expected), "audit missed " + expected);
        }
        // the registrant's own OWNER row is none of these
        assertTrue(found.stream().noneMatch(f -> f.endsWith(":" + registrant)), "registrant row flagged: " + found);
    }

    @Test
    void theM0AuditIsASingleReadOnlySelect() throws IOException {
        String sql = auditSql().toLowerCase();
        assertTrue(sql.startsWith("select "));
        assertFalse(sql.contains(";"), "one statement");
        for (String write : new String[] {"insert ", "update ", "delete ", "merge ", "drop ", "alter ", "create ",
                "truncate ", "exec ", " into ", "grant ", "revoke "}) {
            assertFalse(sql.contains(write), "the audit must not write: " + write);
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private void grant(Long companyId, Long propertyId, Long scopeId, Long memberId, Long unitId, String role,
                       String scopeType) {
        jdbc.update(GRANT_INSERT, Timestamp.from(Instant.now()), companyId, propertyId, scopeId, memberId, unitId, role,
            scopeType);
    }

    private void refused(String constraint, Long companyId, Long propertyId, Long scopeId, Long memberId, Long unitId,
                         String role, String scopeType) {
        DataIntegrityViolationException refused = assertThrows(DataIntegrityViolationException.class,
            () -> grant(companyId, propertyId, scopeId, memberId, unitId, role, scopeType),
            role + "@" + scopeType + " scope=" + scopeId + " property=" + propertyId + " unit=" + unitId);
        if (constraint != null) {
            assertTrue(refused.getMessage().toLowerCase().contains(constraint.toLowerCase()),
                "expected " + constraint + " but was: " + refused.getMessage());
        }
    }

    private void refusedSql(String constraint, String sql, Object... args) {
        DataIntegrityViolationException refused = assertThrows(DataIntegrityViolationException.class,
            () -> jdbc.update(sql, args), sql);
        if (constraint != null) {
            assertTrue(refused.getMessage().toLowerCase().contains(constraint.toLowerCase()),
                "expected " + constraint + " but was: " + refused.getMessage());
        }
    }

    private User user(String role) {
        User u = new User();
        u.setFullName("R2 Schema");
        u.setEmail("r2-schema-" + UUID.randomUUID() + "@test.com");
        u.setPasswordHash("x");
        u.setRole(role);
        return users.saveAndFlush(u);
    }

    private PartnerProfile approvedCompany(User owner) {
        PartnerProfile p = new PartnerProfile();
        p.setUser(owner);
        p.setBusinessName("R2 Schema Co");
        p.setBusinessType(BusinessType.HOTEL);
        p.setRepresentativeName("R2");
        p.setPhone("0900000000");
        p.setEmail("company@test.com");
        p.setAddress("1 Test Street");
        p.setVerificationStatus(PartnerVerificationStatus.APPROVED);
        return profiles.saveAndFlush(p);
    }

    private long membership(Long companyId, Long userId, String role, boolean active) {
        jdbc.update("insert into partner_team_members (active, status, pending_owner_confirmation, version, "
                + "partner_profile_id, user_id, role, created_at) values (?, ?, false, 0, ?, ?, ?, current_timestamp)",
            active, active ? "ACTIVE" : "SUSPENDED", companyId, userId, role);
        return jdbc.queryForObject("select id from partner_team_members where partner_profile_id = ? and user_id = ?",
            Long.class, companyId, userId);
    }

    /** The audit file exactly as shipped, without its comments and closing semicolon. */
    private static String auditSql() throws IOException {
        String file = Files.readString(Path.of("db/audit/R2_M0_partner_membership_audit.sql"), StandardCharsets.UTF_8);
        StringBuilder sql = new StringBuilder();
        for (String line : file.split("\\R")) {
            if (!line.trim().startsWith("--")) sql.append(line).append('\n');
        }
        String text = sql.toString().trim();
        return text.endsWith(";") ? text.substring(0, text.length() - 1) : text;
    }
}
