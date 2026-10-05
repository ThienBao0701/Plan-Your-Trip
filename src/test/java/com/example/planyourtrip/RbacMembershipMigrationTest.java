package com.example.planyourtrip;

import com.example.planyourtrip.model.PartnerMemberGrant;
import com.example.planyourtrip.model.PartnerTeamMember;
import com.example.planyourtrip.model.PartnerTeamRole;
import com.example.planyourtrip.security.rbac.ScopeType;
import org.flywaydb.core.api.configuration.ClassicConfiguration;
import org.flywaydb.core.internal.parser.ParsingContext;
import org.flywaydb.core.internal.resource.StringResource;
import org.flywaydb.core.internal.sqlscript.SqlStatementIterator;
import org.flywaydb.database.sqlserver.SQLServerParser;
import org.hibernate.annotations.Check;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.*;

/**
 * R2 — the Flyway migrations V4–V6 as production will run them (RBAC V1.1 §28 M-1, M-2, M-4).
 *
 * <p>H2 never runs these files (Flyway is off in dev/test), so this class checks them statically, in the
 * style of {@code FlywayMigrationConfigTest}: the chain is contiguous and V1–V3 are untouched; Flyway's own
 * SQL Server parser cuts every file into one batch per statement, so no batch uses a column it adds itself
 * (SQL Server binds columns when it compiles a batch); every named constraint an entity declares for H2 is
 * declared with the identical expression in the migration; and the migrations are additive.
 *
 * <p>Executing V1–V6 against a real SQL Server remains the job of the environment-gated
 * {@code SqlServerProdChainVerificationTest}.
 */
class RbacMembershipMigrationTest {

    private static final String V4 = "/db/migration/V4__partner_membership_status.sql";
    private static final String V5 = "/db/migration/V5__partner_member_grants.sql";
    private static final String V6 = "/db/migration/V6__partner_activity_log_states.sql";

    /** SHA-256 of V1–V3 with line endings normalised — applied migrations are never edited. */
    private static final Map<String, String> APPLIED = Map.of(
        "/db/migration/V1__initial_schema.sql", "0b57f807bd94dc4a1b6552fcb8517c56802e8ad3cf25ec42c449df6be81e5994",
        "/db/migration/V2__admin_activity_log.sql", "c3c408985bb2695554edd1f8b318ee3496b94056734448a6c7061d65301a3740",
        "/db/migration/V3__account_lifecycle.sql", "b3a901e9df3bfe47b3b400948c297d18d0b22c9bf97975a361b6278dbdea6d18");

    // ── Chain ────────────────────────────────────────────────────────────────

    @Test
    void theChainIsContiguousAndR2AddsExactlyV4ToV6() throws IOException {
        Pattern name = Pattern.compile("V(\\d+)__([a-z0-9_]+)\\.sql");
        Map<Integer, String> versions = new TreeMap<>();
        for (Resource r : new PathMatchingResourcePatternResolver().getResources("classpath:db/migration/*.sql")) {
            Matcher m = name.matcher(r.getFilename());
            assertTrue(m.matches(), "unexpected migration file name " + r.getFilename());
            assertNull(versions.put(Integer.parseInt(m.group(1)), m.group(2)), "duplicate version " + m.group(1));
        }
        assertEquals(List.of(1, 2, 3, 4, 5, 6), List.copyOf(versions.keySet()));
        assertEquals("partner_membership_status", versions.get(4));
        assertEquals("partner_member_grants", versions.get(5));
        assertEquals("partner_activity_log_states", versions.get(6));
    }

    @Test
    void appliedMigrationsAreUntouched() throws Exception {
        for (Map.Entry<String, String> applied : APPLIED.entrySet()) {
            byte[] normalised = read(applied.getKey()).getBytes(StandardCharsets.UTF_8);
            String sha = HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(normalised));
            assertEquals(applied.getValue(), sha, applied.getKey() + " was edited; add a new migration instead");
        }
    }

    // ── Batches as Flyway runs them on SQL Server ────────────────────────────

    @Test
    void flywayRunsEveryR2StatementAsItsOwnBatch() throws IOException {
        Pattern addsColumn = Pattern.compile("(?s).*\\balter\\s+table\\s+\\w+\\s+add\\s+(?!constraint\\b)\\w+.*");
        Pattern dml = Pattern.compile("(?s).*\\b(update|insert\\s+into|delete\\s+from)\\b.*");
        for (String file : List.of(V4, V5, V6)) {
            String sql = read(file);
            List<String> batches = flywayBatches(sql);
            long goLines = sql.lines().filter(l -> l.trim().equalsIgnoreCase("go")).count();
            assertEquals(goLines, batches.size(), file + ": one batch per GO");
            for (String batch : batches) {
                String statements = withoutComments(batch).toLowerCase();
                assertFalse(addsColumn.matcher(statements).matches() && dml.matcher(statements).matches(),
                    file + ": a batch may not add a column and run DML (SQL Server binds columns at compile time):\n"
                        + statements);
            }
        }
    }

    // ── V4 (M-1) ─────────────────────────────────────────────────────────────

    @Test
    void v4DropsTheGeneratedRoleCheckAndRecreatesItNamedWithTheNineRoles() throws IOException {
        String ddl = ddl(V4);
        assertTrue(ddl.contains("from sys.check_constraints cc"));
        assertTrue(ddl.contains("c.column_id = cc.parent_column_id"));
        assertTrue(ddl.contains("cc.parent_object_id = object_id(n'partner_team_members')"));
        assertTrue(ddl.contains("and c.name = n'role'"));
        assertTrue(ddl.contains("drop constraint ' + quotename(@role_check)"));
        assertTrue(ddl.contains("exec sp_executesql @drop_role_check"));

        Matcher roles = Pattern.compile("add constraint ck_partner_team_members_role check \\(role in \\(([^)]*)\\)\\)")
            .matcher(ddl);
        assertTrue(roles.find(), "named role check");
        assertEquals(names(PartnerTeamRole.values()), quoted(roles.group(1)));
    }

    @Test
    void v4AddsMembershipStateAndMapsLegacyRowsWithoutLosingAny() throws IOException {
        String ddl = ddl(V4);
        assertTrue(ddl.contains("alter table partner_team_members add status nvarchar(20) not null "
            + "constraint df_partner_team_members_status default 'active'"));
        assertTrue(ddl.contains("alter table partner_team_members add status_reason nvarchar(255)"));
        assertTrue(ddl.contains("alter table partner_team_members add status_changed_at datetimeoffset(6)"));
        assertTrue(ddl.contains("alter table partner_team_members add status_changed_by bigint"));
        assertTrue(ddl.contains("alter table partner_team_members add pending_owner_confirmation bit not null "
            + "constraint df_partner_team_members_pending_owner_confirmation default 0"));
        assertTrue(ddl.contains("alter table partner_team_members add version bigint not null "
            + "constraint df_partner_team_members_version default 0"));

        // active rows stay ACTIVE through the default; inactive rows become SUSPENDED, marked as legacy
        assertTrue(ddl.contains("update partner_team_members set status = 'suspended', status_reason = '"
            + PartnerTeamMember.LEGACY_INACTIVE.toLowerCase() + "' where active = 0"));
        // the missing OWNER row of an approved registrant, by the ensureOwnerTeamMember rule
        assertTrue(ddl.contains("from partner_profiles p where p.verification_status = 'approved' and not exists "
            + "(select 1 from partner_team_members m where m.partner_profile_id = p.id and m.user_id = p.user_id)"));
        assertTrue(ddl.contains("'owner', 'active', 0, 0"));
        assertTrue(ddl.contains("create index idx_partner_team_members_user_status on partner_team_members (user_id, status)"));
    }

    // ── V5 (M-2) ─────────────────────────────────────────────────────────────

    @Test
    void v5CreatesTheGrantTablePinnedToItsMembershipsCompany() throws IOException {
        String ddl = ddl(V5);
        assertTrue(ddl.contains("create table partner_member_grants (id bigint identity not null, "
            + "created_at datetimeoffset(6) not null, created_by bigint, partner_profile_id bigint not null, "
            + "property_id bigint, scope_id bigint not null, team_member_id bigint not null, unit_id bigint, "
            + "role nvarchar(20) not null, scope_type nvarchar(20) not null, primary key (id) )"));
        assertTrue(ddl.contains("add constraint uk_partner_member_grant unique (team_member_id, role, scope_type, scope_id)"));
        assertTrue(ddl.contains("alter table partner_team_members add constraint uk_partner_team_members_id_company "
            + "unique (id, partner_profile_id)"));
        assertTrue(ddl.contains("add constraint fk_partner_member_grants_member foreign key (team_member_id, partner_profile_id) "
            + "references partner_team_members (id, partner_profile_id)"), "the composite key that pins a grant's company");
        assertTrue(ddl.contains("add constraint fk_partner_member_grants_company foreign key (partner_profile_id) references partner_profiles"));
        assertTrue(ddl.contains("add constraint fk_partner_member_grants_property foreign key (property_id) references places"));
        assertTrue(ddl.contains("add constraint fk_partner_member_grants_unit foreign key (unit_id) references hotel_rooms"));
        for (String index : List.of("idx_partner_member_grants_company on partner_member_grants (partner_profile_id)",
                "idx_partner_member_grants_property on partner_member_grants (property_id)",
                "idx_partner_member_grants_unit on partner_member_grants (unit_id)")) {
            assertTrue(ddl.contains("create index " + index), index);
        }
        // backfill: one COMPANY grant per membership that is not revoked, mirroring its role; the company id,
        // never a fake "all properties" id, is the company scope
        assertTrue(ddl.contains("select sysdatetimeoffset(), null, m.partner_profile_id, null, m.partner_profile_id, m.id, "
            + "null, m.role, 'company' from partner_team_members m where m.status <> 'revoked'"));
    }

    @Test
    void theStoredValuesMatchTheFrozenDecisions() {
        assertEquals(names(PartnerTeamRole.values()), quoted(PartnerMemberGrant.ROLE_VALUES));
        assertEquals(Set.of("OWNER", "MANAGER", "REVENUE", "RESERVATIONS", "FRONT_DESK", "FINANCE", "CONTENT",
            "HOUSEKEEPING", "VIEWER"), names(PartnerTeamRole.values()));
        assertEquals(Set.of("COMPANY", "PROPERTY", "UNIT"), names(ScopeType.values()), "UNIT is the room type (Q9)");
        assertTrue(PartnerMemberGrant.ROLE_SCOPE_CHECK.contains("(role in ('OWNER','FINANCE') and scope_type = 'COMPANY')"),
            "FINANCE and OWNER are company-only (Q10)");
        assertTrue(PartnerMemberGrant.ROLE_SCOPE_CHECK.contains("(role = 'HOUSEKEEPING' and scope_type in ('PROPERTY','UNIT'))"),
            "HOUSEKEEPING sits at a property or a room type (Q8)");
    }

    // ── Entity mirrors = production constraints ──────────────────────────────

    @Test
    void everyEntityCheckIsTheMigrationsConstraintVerbatim() throws IOException {
        String migrations = normalise(withoutComments(read(V4) + "\n" + read(V5)));
        Map<Class<?>, List<String>> expected = Map.of(
            PartnerTeamMember.class, List.of("ck_partner_team_members_status", "ck_partner_team_members_active_status"),
            PartnerMemberGrant.class, List.of("ck_partner_member_grants_role", "ck_partner_member_grants_scope_type",
                "ck_partner_member_grants_scope_id", "ck_partner_member_grants_scope_shape",
                "ck_partner_member_grants_role_scope"));
        for (Map.Entry<Class<?>, List<String>> entity : expected.entrySet()) {
            Check[] checks = entity.getKey().getAnnotationsByType(Check.class);
            assertEquals(Set.copyOf(entity.getValue()),
                Arrays.stream(checks).map(Check::name).collect(Collectors.toSet()), entity.getKey().getSimpleName());
            for (Check check : checks) {
                String declared = "add constraint " + check.name() + " check (" + normalise(check.constraints()) + ")";
                assertTrue(migrations.contains(declared), "migration differs from the entity for " + check.name()
                    + ":\n  entity:    " + declared);
            }
        }
    }

    @Test
    void nullableComparisonsInTheScopeShapeAreGuarded() {
        // a CHECK passes on unknown: every comparison of a nullable column is preceded by its own null test
        String shape = PartnerMemberGrant.SCOPE_SHAPE_CHECK;
        assertTrue(shape.contains("property_id is not null and property_id = scope_id"));
        assertTrue(shape.contains("unit_id is not null and unit_id = scope_id"));
    }

    // ── V6 (M-4) ─────────────────────────────────────────────────────────────

    @Test
    void v6AddsActivityLogSnapshotsAndBackfillsTheActorEmail() throws IOException {
        String ddl = ddl(V6);
        assertTrue(ddl.contains("alter table partner_activity_logs add actor_email nvarchar(255)"));
        assertTrue(ddl.contains("alter table partner_activity_logs add before_state nvarchar(500)"));
        assertTrue(ddl.contains("alter table partner_activity_logs add after_state nvarchar(500)"));
        assertTrue(ddl.contains("alter table partner_activity_logs add reason nvarchar(500)"));
        assertTrue(ddl.contains("set actor_email = coalesce(u.email, concat('user:', l.actor_user_id)), "
            + "reason = 'actor_email backfilled from users.email by v6'"));
        assertTrue(ddl.contains("left join users u on u.id = l.actor_user_id where l.actor_email is null"));
        assertTrue(ddl.contains("alter table partner_activity_logs alter column actor_email nvarchar(255) not null"));
    }

    // ── Additive and SQL Server shaped ───────────────────────────────────────

    @Test
    void r2MigrationsAreAdditive() throws IOException {
        for (String file : List.of(V4, V5, V6)) {
            String ddl = ddl(file);
            for (String forbidden : new String[] {"drop table", "drop column", "drop index", "truncate ", "delete from",
                    "sp_rename", "rename "}) {
                assertFalse(ddl.contains(forbidden), file + ": " + forbidden);
            }
            for (String untouched : new String[] {"users", "partner_profiles", "places", "hotel_details", "hotel_rooms",
                    "bookings", "rate_plans", "room_inventory"}) {
                assertFalse(ddl.matches("(?s).*\\b(alter|update|create)\\s+table\\s+" + untouched + "\\b.*"),
                    file + " must not change " + untouched);
                assertFalse(ddl.matches("(?s).*\\bupdate\\s+" + untouched + "\\b.*"), file + " must not update " + untouched);
            }
            for (String line : read(file).split("\n")) {
                String trimmed = line.trim();
                if (trimmed.startsWith("--") || trimmed.isEmpty()) continue;
                assertFalse(trimmed.matches("(?i).*\\b(TEXT|NTEXT|VARCHAR\\(MAX\\))\\b.*"), file + ": " + trimmed);
            }
        }
        // the only constraint dropped is V1's generated role check, through its looked-up name
        assertEquals(1, count(ddl(V4), "drop constraint"));
        assertEquals(0, count(ddl(V5) + ddl(V6), "drop constraint"));
        // the only column altered is the backfilled actor_email
        assertEquals(1, count(ddl(V6), "alter column"));
        assertEquals(0, count(ddl(V4) + ddl(V5), "alter column"));
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private static List<String> flywayBatches(String sql) {
        SQLServerParser parser = new SQLServerParser(new ClassicConfiguration(), new ParsingContext());
        List<String> batches = new ArrayList<>();
        try (SqlStatementIterator statements = parser.parse(new StringResource(sql))) {
            while (statements.hasNext()) batches.add(statements.next().getSql());
        }
        return batches;
    }

    /** The file with line endings normalised. */
    private String read(String path) throws IOException {
        try (InputStream in = getClass().getResourceAsStream(path)) {
            assertNotNull(in, "classpath resource missing: " + path);
            return new String(in.readAllBytes(), StandardCharsets.UTF_8).replace("\r\n", "\n");
        }
    }

    /** Statements only, lower case, whitespace collapsed, GO separators removed. */
    private String ddl(String path) throws IOException {
        StringBuilder statements = new StringBuilder();
        for (String line : withoutComments(read(path)).split("\n")) {
            if (!line.trim().equalsIgnoreCase("go")) statements.append(line).append('\n');
        }
        return normalise(statements.toString()).toLowerCase();
    }

    private static String withoutComments(String sql) {
        return Arrays.stream(sql.split("\n")).filter(l -> !l.trim().startsWith("--")).collect(Collectors.joining("\n"));
    }

    private static String normalise(String text) {
        return text.replaceAll("\\s+", " ").replace("( ", "(").trim();
    }

    private static Set<String> quoted(String list) {
        return Arrays.stream(list.split(",")).map(v -> v.trim().replace("'", "").toUpperCase()).collect(Collectors.toSet());
    }

    private static Set<String> names(Enum<?>[] values) {
        return Arrays.stream(values).map(Enum::name).collect(Collectors.toSet());
    }

    private static int count(String text, String needle) {
        int n = 0;
        for (int i = text.indexOf(needle); i >= 0; i = text.indexOf(needle, i + 1)) n++;
        return n;
    }
}
