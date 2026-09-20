package com.example.planyourtrip;

import com.example.planyourtrip.config.DataInitializer;
import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.Profile;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * DB-03 — verifies the Flyway / SQL Server migration wiring WITHOUT booting a Spring
 * context or a database. It asserts, from classpath resources and reflection, that:
 *   - the initial migration exists at the standard Flyway location and is SQL-Server-safe;
 *   - Flyway is disabled in the default (dev/test H2) profile;
 *   - the prod profile enables Flyway, pins ddl-auto=validate, and uses NVARCHAR;
 *   - DataInitializer stays excluded from prod.
 * Purely static — it neither runs migrations nor requires SQL Server, so it is safe in
 * the H2 test suite.
 */
class FlywayMigrationConfigTest {

    private String readClasspath(String path) throws IOException {
        try (InputStream in = getClass().getResourceAsStream(path)) {
            assertNotNull(in, "classpath resource missing: " + path);
            return new String(in.readAllBytes(), StandardCharsets.UTF_8);
        }
    }

    @Test
    void initialMigrationExistsAtStandardLocation() throws IOException {
        String sql = readClasspath("/db/migration/V1__initial_schema.sql");
        // Core production tables from the audited entity model.
        assertTrue(sql.contains("create table users"), "users table missing");
        assertTrue(sql.contains("create table trip_plans"), "trip_plans table missing");
        assertTrue(sql.contains("create table trip_plan_expenses"), "trip_plan_expenses table missing");
        assertTrue(sql.contains("create table travel_wallet_items"), "travel_wallet_items table missing");
        assertTrue(sql.contains("create table user_interest_profiles"), "user_interest_profiles table missing");
        // Foreign keys are present.
        assertTrue(sql.contains("foreign key (user_id) references users"), "user FK missing");
    }

    @Test
    void migrationIsSqlServerSafe() throws IOException {
        String sql = readClasspath("/db/migration/V1__initial_schema.sql");
        // Vietnamese Unicode long-text columns use NVARCHAR(MAX), not the deprecated TEXT type.
        assertTrue(sql.contains("nvarchar(max)"), "expected nvarchar(max) long-text columns");
        // No DDL (non-comment) line may use the deprecated, non-Unicode SQL Server TEXT type.
        for (String line : sql.split("\\R")) {
            String trimmed = line.trim();
            if (trimmed.startsWith("--") || trimmed.isEmpty()) continue;
            assertFalse(trimmed.matches(".*\\bTEXT\\b.*"),
                    "deprecated TEXT type must not appear in DDL: " + trimmed);
        }
        // Nullable UNIQUE columns are SQL-Server-safe filtered unique indexes (multiple NULLs allowed).
        assertTrue(sql.contains("where booking_code is not null"),
                "expected filtered unique index for nullable booking_code");
        assertTrue(sql.contains("where idempotency_key is not null"),
                "expected filtered unique index for nullable idempotency_key");
    }

    /**
     * Phase A — V3 is additive and SQL-Server-shaped: the four account columns, the auth_tokens table
     * storing only a token hash, the deterministic backfill of existing accounts as verified, and no
     * destructive statement or touch on any property, room, rate or inventory table.
     */
    @Test
    void v3AccountLifecycleMigrationIsAdditiveAndSqlServerSafe() throws IOException {
        String sql = readClasspath("/db/migration/V3__account_lifecycle.sql");
        StringBuilder statements = new StringBuilder();
        for (String line : sql.split("\\R")) {
            if (!line.trim().startsWith("--")) statements.append(line).append('\n');
        }
        String ddl = statements.toString().toLowerCase();

        assertTrue(ddl.contains("alter table users add email_verified_at datetimeoffset(6)"));
        assertTrue(ddl.contains("alter table users add email_verification_required bit not null"));
        assertTrue(ddl.contains("alter table users add token_version int not null"));
        assertTrue(ddl.contains("alter table users add terms_accepted_at datetimeoffset(6)"));
        assertTrue(ddl.contains("alter table users add terms_version nvarchar(32)"));
        assertTrue(ddl.contains("set email_verified_at = coalesce(created_at, sysdatetimeoffset())"),
            "existing accounts are backfilled as verified, deterministically");

        assertTrue(ddl.contains("create table auth_tokens"));
        assertTrue(ddl.contains("token_hash nvarchar(64) not null"));
        assertTrue(ddl.contains("unique (token_hash)"));
        assertTrue(ddl.contains("foreign key (user_id) references users"));
        assertFalse(ddl.matches("(?s).*\\btoken\\s+nvarchar.*"), "no column for a raw token");

        for (String forbidden : new String[] {"drop ", "truncate ", "delete from", "rename ", "alter column"}) {
            assertFalse(ddl.contains(forbidden), "V3 must be additive; found: " + forbidden);
        }
        for (String untouched : new String[] {"places", "hotel_details", "hotel_rooms", "rate_plans", "room_inventory"}) {
            assertFalse(ddl.matches("(?s).*\\b(alter|update|create)\\s+table\\s+" + untouched + "\\b.*"),
                "V3 must not touch " + untouched);
        }
        for (String line : sql.split("\\R")) {
            String trimmed = line.trim();
            if (trimmed.startsWith("--") || trimmed.isEmpty()) continue;
            assertFalse(trimmed.matches(".*\\bTEXT\\b.*"), "deprecated TEXT type: " + trimmed);
        }
    }

    @Test
    void flywayDisabledInDefaultProfile() throws IOException {
        String base = readClasspath("/application.properties");
        assertTrue(base.contains("spring.flyway.enabled=false"),
                "Flyway must be disabled in the default (H2 dev/test) profile");
    }

    @Test
    void prodProfileEnablesFlywayValidateAndNvarchar() throws IOException {
        String prod = readClasspath("/application-prod.properties");
        assertTrue(prod.contains("spring.flyway.enabled=true"), "prod must enable Flyway");
        assertTrue(prod.contains("spring.flyway.locations=classpath:db/migration"),
                "prod must point Flyway at db/migration");
        assertTrue(prod.contains("spring.jpa.hibernate.ddl-auto=validate"),
                "prod must keep ddl-auto=validate (schema is migration-owned)");
        assertTrue(prod.contains("hibernate.use_nationalized_character_data=true"),
                "prod must map String columns to NVARCHAR");
    }

    @Test
    void dataInitializerRemainsExcludedFromProd() {
        Profile profile = DataInitializer.class.getAnnotation(Profile.class);
        assertNotNull(profile, "DataInitializer must be @Profile-guarded");
        boolean excludesProd = false;
        for (String p : profile.value()) {
            if (p.replace(" ", "").equals("!prod")) excludesProd = true;
        }
        assertTrue(excludesProd, "DataInitializer must remain @Profile(\"!prod\")");
    }
}
