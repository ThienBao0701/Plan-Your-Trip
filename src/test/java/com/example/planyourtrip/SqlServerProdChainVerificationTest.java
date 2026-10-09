package com.example.planyourtrip;

import com.example.planyourtrip.repository.LoyaltyRedemptionPolicyRepository;
import com.example.planyourtrip.repository.ReferralCampaignRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * DB-05 — end-to-end production chain verification against a REAL Microsoft SQL Server.
 *
 * <p><b>Disabled by default.</b> This test only runs when {@code DB05_SQLSERVER_VERIFY=true} is set
 * in the environment, so it never affects the normal H2 {@code ./mvnw test} run. It is the documented,
 * reusable mechanism for verifying the live chain when a TCP-reachable SQL Server is available — it is
 * NOT an H2 test masquerading as SQL Server.
 *
 * <p>To run it against a disposable SQL Server verification database (never a production database):
 * <pre>
 *   set DB05_SQLSERVER_VERIFY=true
 *   set SPRING_PROFILES_ACTIVE=prod
 *   set SPRING_DATASOURCE_URL=jdbc:sqlserver://HOST:1433;databaseName=PYT_DB05_VERIFY;encrypt=true;trustServerCertificate=false;sendStringParametersAsUnicode=true
 *   set SPRING_DATASOURCE_USERNAME=...        (a login scoped to the verification DB)
 *   set SPRING_DATASOURCE_PASSWORD=...        (supplied via env only; never committed)
 *   set VOUCHER_SIGNING_SECRET=...            (>=32 chars; surefire also injects one for tests)
 *   ./mvnw -Dtest=SqlServerProdChainVerificationTest test
 * </pre>
 *
 * <p>A successful context start under the {@code prod} profile already proves that Flyway applied the
 * migration-owned schema and that Hibernate {@code ddl-auto=validate} passed against it (an invalid
 * schema would fail context startup). The assertions then confirm the Flyway history and that
 * {@link com.example.planyourtrip.config.ProductionBootstrap} seeded the required reference rows.
 */
@SpringBootTest
@ActiveProfiles("prod")
@EnabledIfEnvironmentVariable(named = "DB05_SQLSERVER_VERIFY", matches = "(?i)true")
class SqlServerProdChainVerificationTest {

    @Autowired JdbcTemplate jdbc;
    @Autowired ReferralCampaignRepository referralCampaigns;
    @Autowired LoyaltyRedemptionPolicyRepository redemptionPolicies;

    @Test
    void flywayAppliedHibernateValidatedAndBootstrapSeeded() {
        // Context started under prod → Flyway migrated + Hibernate ddl-auto=validate passed.
        Integer applied = jdbc.queryForObject(
                "SELECT COUNT(*) FROM flyway_schema_history WHERE success = 1 AND version = '1'", Integer.class);
        assertTrue(applied != null && applied >= 1, "Flyway V1 migration must be recorded as applied");

        // ProductionBootstrap must have seeded the required system reference data.
        assertTrue(referralCampaigns.findByCodeIgnoreCase("DEFAULT_REFERRAL").isPresent(),
                "DEFAULT_REFERRAL campaign must exist after prod bootstrap");
        assertTrue(redemptionPolicies.findByPolicyCodeIgnoreCase("DEFAULT_LOYALTY_REDEMPTION").isPresent(),
                "DEFAULT_LOYALTY_REDEMPTION policy must exist after prod bootstrap");
    }

    /**
     * RBAC R2/R3a — V4–V7 applied on SQL Server: every named constraint exists (CHECK constraints are invisible
     * to {@code ddl-auto=validate}), V1's generated role check is gone, and the backfills hold.
     */
    @Test
    void rbacR2MembershipMigrationsAppliedWithTheirConstraints() {
        for (String version : List.of("4", "5", "6", "7")) {
            Integer applied = jdbc.queryForObject(
                    "SELECT COUNT(*) FROM flyway_schema_history WHERE success = 1 AND version = ?", Integer.class, version);
            assertEquals(1, applied, "Flyway V" + version + " must be recorded as applied");
        }
        for (String check : List.of("ck_partner_team_members_role", "ck_partner_team_members_status",
                "ck_partner_team_members_active_status", "ck_partner_member_grants_role",
                "ck_partner_member_grants_scope_type", "ck_partner_member_grants_scope_id",
                "ck_partner_member_grants_scope_shape", "ck_partner_member_grants_role_scope")) {
            assertEquals(1, jdbc.queryForObject("SELECT COUNT(*) FROM sys.check_constraints WHERE name = ?",
                    Integer.class, check), check);
        }
        assertEquals(1, jdbc.queryForObject("SELECT COUNT(*) FROM sys.check_constraints cc "
                + "JOIN sys.columns c ON c.object_id = cc.parent_object_id AND c.column_id = cc.parent_column_id "
                + "WHERE cc.parent_object_id = OBJECT_ID('partner_team_members') AND c.name = 'role'", Integer.class),
                "only the named role check remains");
        assertEquals(2, jdbc.queryForObject("SELECT COUNT(*) FROM sys.foreign_key_columns fkc "
                + "JOIN sys.foreign_keys fk ON fk.object_id = fkc.constraint_object_id "
                + "WHERE fk.name = 'fk_partner_member_grants_member'", Integer.class),
                "the composite membership/company foreign key");
        assertEquals(0, jdbc.queryForObject("SELECT COUNT(*) FROM partner_team_members m WHERE m.status <> 'REVOKED' "
                + "AND NOT EXISTS (SELECT 1 FROM partner_member_grants g WHERE g.team_member_id = m.id "
                + "AND g.scope_type = 'COMPANY' AND g.role = m.role)", Integer.class),
                "every membership that is not revoked holds a company grant mirroring its role");
        assertEquals(0, jdbc.queryForObject("SELECT COUNT(*) FROM partner_activity_logs WHERE actor_email IS NULL",
                Integer.class));
        // RBAC R3a / V7 (M-6): no administrator remains a member, no legacy co-owner keeps OWNER unconfirmed
        assertEquals(0, jdbc.queryForObject("SELECT COUNT(*) FROM partner_team_members m JOIN users u ON u.id = m.user_id "
                + "JOIN partner_profiles p ON p.id = m.partner_profile_id "
                + "WHERE u.role = 'ADMIN' AND m.status <> 'REVOKED' AND p.user_id <> m.user_id", Integer.class));
        assertEquals(0, jdbc.queryForObject("SELECT COUNT(*) FROM partner_member_grants g "
                + "JOIN partner_team_members m ON m.id = g.team_member_id "
                + "WHERE g.role = 'OWNER' AND m.pending_owner_confirmation = 1", Integer.class));
    }

    /**
     * RBAC R4 — V8 applied on SQL Server: the invitation tables and their named constraints exist, V1's (company,
     * account) unique key is replaced by the live-membership key, and every revoked row carries its own revocation key.
     */
    @Test
    void rbacR4InvitationMigrationAppliedWithItsConstraints() {
        assertEquals(1, jdbc.queryForObject(
                "SELECT COUNT(*) FROM flyway_schema_history WHERE success = 1 AND version = '8'", Integer.class));
        for (String check : List.of("ck_partner_team_members_revocation_key", "ck_partner_invitations_status",
                "ck_partner_invitations_delivery_status", "ck_partner_invitations_resend_count",
                "ck_partner_invitations_closed_key", "ck_partner_invitation_grants_role",
                "ck_partner_invitation_grants_scope_type", "ck_partner_invitation_grants_scope_id",
                "ck_partner_invitation_grants_role_scope")) {
            assertEquals(1, jdbc.queryForObject("SELECT COUNT(*) FROM sys.check_constraints WHERE name = ?",
                    Integer.class, check), check);
        }
        for (String key : List.of("uk_partner_team_members_live", "uk_partner_invitations_token_hash",
                "uk_partner_invitations_pending", "uk_partner_invitation_grant")) {
            assertEquals(1, jdbc.queryForObject("SELECT COUNT(*) FROM sys.key_constraints WHERE name = ?",
                    Integer.class, key), key);
        }
        assertEquals(0, jdbc.queryForObject("SELECT COUNT(*) FROM sys.key_constraints WHERE name = "
                + "'uk_partner_team_member_profile_user'", Integer.class), "V1's key is replaced");
        assertEquals(0, jdbc.queryForObject("SELECT COUNT(*) FROM partner_team_members WHERE "
                + "(status = 'REVOKED' AND revocation_key <> id) OR (status <> 'REVOKED' AND revocation_key <> 0)",
                Integer.class));
    }

    /**
     * RBAC R6 — V9 (M-5) applied on SQL Server: the admin profile table and its named constraints exist, and every
     * ADMIN account holds an active PLATFORM_OWNER grant (the AP-4 backfill, or the bootstrap's system grant).
     */
    @Test
    void rbacR6AdminProfileMigrationAppliedWithItsConstraints() {
        assertEquals(1, jdbc.queryForObject(
                "SELECT COUNT(*) FROM flyway_schema_history WHERE success = 1 AND version = '9'", Integer.class));
        for (String check : List.of("ck_admin_profile_assignments_profile", "ck_admin_profile_assignments_revocation")) {
            assertEquals(1, jdbc.queryForObject("SELECT COUNT(*) FROM sys.check_constraints WHERE name = ?",
                    Integer.class, check), check);
        }
        assertEquals(1, jdbc.queryForObject("SELECT COUNT(*) FROM sys.key_constraints WHERE name = "
                + "'uk_admin_profile_assignments_live'", Integer.class));
        assertEquals(3, jdbc.queryForObject("SELECT COUNT(*) FROM sys.foreign_keys WHERE name IN "
                + "('fk_admin_profile_assignments_user', 'fk_admin_profile_assignments_granted_by', "
                + "'fk_admin_profile_assignments_revoked_by')", Integer.class));
        assertEquals(0, jdbc.queryForObject("SELECT COUNT(*) FROM users u WHERE u.role = 'ADMIN' AND NOT EXISTS ("
                + "SELECT 1 FROM admin_profile_assignments a WHERE a.user_id = u.id "
                + "AND a.profile = 'PLATFORM_OWNER' AND a.revoked_at IS NULL)", Integer.class),
                "every ADMIN is a PLATFORM_OWNER until profiles are narrowed (AP-4)");
    }

    /**
     * RBAC R6 — V10 (A16 dual control) applied on SQL Server: the request table with every named CHECK (invisible to
     * {@code ddl-auto=validate}), the live unique key that allows one open request per action and target, the three
     * foreign keys and the queue index. V10 writes no row.
     */
    @Test
    void rbacR6DualControlMigrationAppliedWithItsConstraints() {
        assertEquals(1, jdbc.queryForObject(
                "SELECT COUNT(*) FROM flyway_schema_history WHERE success = 1 AND version = '10'", Integer.class));
        for (String check : List.of("ck_admin_dual_control_requests_permission",
                "ck_admin_dual_control_requests_target_type", "ck_admin_dual_control_requests_status",
                "ck_admin_dual_control_requests_live", "ck_admin_dual_control_requests_decision")) {
            assertEquals(1, jdbc.queryForObject("SELECT COUNT(*) FROM sys.check_constraints WHERE name = ?",
                    Integer.class, check), check);
        }
        assertEquals(1, jdbc.queryForObject("SELECT COUNT(*) FROM sys.key_constraints WHERE name = "
                + "'uk_admin_dual_control_requests_live'", Integer.class));
        assertEquals(3, jdbc.queryForObject("SELECT COUNT(*) FROM sys.foreign_keys WHERE name IN "
                + "('fk_admin_dual_control_requests_requested_by', 'fk_admin_dual_control_requests_approved_by', "
                + "'fk_admin_dual_control_requests_rejected_by')", Integer.class));
        assertEquals(1, jdbc.queryForObject("SELECT COUNT(*) FROM sys.indexes WHERE name = "
                + "'idx_admin_dual_control_requests_status'", Integer.class));
    }
}
