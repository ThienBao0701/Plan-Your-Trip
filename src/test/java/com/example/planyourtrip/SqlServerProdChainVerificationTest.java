package com.example.planyourtrip;

import com.example.planyourtrip.repository.LoyaltyRedemptionPolicyRepository;
import com.example.planyourtrip.repository.ReferralCampaignRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

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
}
