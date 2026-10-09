package com.example.planyourtrip;

import com.example.planyourtrip.model.AdminProfileAssignment;
import com.example.planyourtrip.security.rbac.AdminProfile;
import org.flywaydb.core.api.configuration.ClassicConfiguration;
import org.flywaydb.core.internal.parser.ParsingContext;
import org.flywaydb.core.internal.resource.StringResource;
import org.flywaydb.core.internal.sqlscript.SqlStatementIterator;
import org.flywaydb.database.sqlserver.SQLServerParser;
import org.hibernate.annotations.Check;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HexFormat;
import java.util.List;
import java.util.Set;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.*;

/**
 * RBAC R6 — V9 (M-5: admin profile assignments), checked statically like V8 ({@code RbacInvitationMigrationTest}):
 * H2 never runs Flyway, so the file is parsed with Flyway's own SQL Server parser and compared with the entity that
 * builds the H2 schema. Running V1–V9 on a real SQL Server stays the job of the environment-gated
 * {@code SqlServerProdChainVerificationTest}.
 */
class RbacAdminProfileMigrationTest {

    private static final String V8 = "/db/migration/V8__partner_invitations.sql";
    private static final String V9 = "/db/migration/V9__admin_profile_assignments.sql";

    /** V8 shipped with R4 and was verified on SQL Server in DB-07: SHA-256 with line endings normalised. */
    private static final String V8_SHA = "4e5dc7b8643489f09a41d460e25bf7874efd7fb78c3e697e342a60a1adc55cee";

    @Test
    void v8IsUntouched() throws Exception {
        String sha = HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
            .digest(read(V8).getBytes(StandardCharsets.UTF_8)));
        assertEquals(V8_SHA, sha, "V8 was edited; add a new migration instead");
    }

    @Test
    void flywayRunsEveryV9StatementAsItsOwnBatch() throws IOException {
        Pattern addsColumn = Pattern.compile("(?s).*\\balter\\s+table\\s+\\w+\\s+add\\s+(?!constraint\\b)\\w+.*");
        Pattern dml = Pattern.compile("(?s).*\\b(update|insert\\s+into|delete\\s+from)\\b.*");
        String sql = read(V9);
        List<String> batches = flywayBatches(sql);
        long goLines = sql.lines().filter(l -> l.trim().equalsIgnoreCase("go")).count();
        assertEquals(goLines, batches.size(), "one batch per GO");
        assertEquals(9, batches.size(), "table, unique key, 2 checks, 3 foreign keys, index, backfill");
        for (String batch : batches) {
            String statement = withoutComments(batch).toLowerCase();
            assertFalse(addsColumn.matcher(statement).matches() && dml.matcher(statement).matches(), statement);
            assertFalse(statement.contains("create table") && dml.matcher(statement).matches(),
                "the backfill must run in a later batch than the table it fills:\n" + statement);
        }
    }

    /** Additive: one new table, its constraints and index, and the AP-4 backfill; no existing table changes. */
    @Test
    void v9IsAdditiveAndBackfillsEveryAdministratorAsPlatformOwner() throws IOException {
        String ddl = ddl(V9);
        for (String forbidden : new String[] {"drop ", "truncate ", "delete from", "sp_rename", "alter column",
                "update "}) {
            assertFalse(ddl.contains(forbidden), forbidden);
        }
        assertFalse(ddl.matches("(?s).*\\balter\\s+table\\s+(?!admin_profile_assignments\\b)\\w+.*"),
            "V9 alters only its own table");
        assertEquals(1, count(ddl, "create table "));
        assertTrue(ddl.contains("add constraint uk_admin_profile_assignments_live unique (user_id, profile, revocation_key)"));
        assertEquals(1, count(ddl, "insert into"), "only the AP-4 backfill writes rows");
        assertTrue(ddl.contains("select id, 'platform_owner', null, sysdatetimeoffset(), null, null, 0, 0 from users "
            + "where role = 'admin'"), ddl);
        for (String line : read(V9).split("\n")) {
            String trimmed = line.trim();
            if (trimmed.startsWith("--") || trimmed.isEmpty()) continue;
            assertFalse(trimmed.matches("(?i).*\\b(TEXT|NTEXT|VARCHAR\\(MAX\\))\\b.*"), trimmed);
        }
    }

    @Test
    void everyEntityCheckIsTheMigrationsConstraintVerbatim() throws IOException {
        String migration = normalise(withoutComments(read(V9)));
        Check[] checks = AdminProfileAssignment.class.getAnnotationsByType(Check.class);
        assertEquals(Set.of("ck_admin_profile_assignments_profile", "ck_admin_profile_assignments_revocation"),
            Arrays.stream(checks).map(Check::name).collect(Collectors.toSet()));
        for (Check check : checks) {
            String declared = "add constraint " + check.name() + " check (" + normalise(check.constraints()) + ")";
            assertTrue(migration.contains(declared), "V9 differs from the entity for " + check.name()
                + ":\n  entity:    " + declared);
        }
        for (AdminProfile profile : AdminProfile.values()) {
            assertTrue(AdminProfile.CHECK.contains("'" + profile.name() + "'"), profile.name());
        }
        assertEquals(AdminProfile.values().length, count(AdminProfile.CHECK, "'") / 2, "exactly the 11 profiles");
    }

    // ── Helpers (as RbacInvitationMigrationTest) ─────────────────────────────

    private static List<String> flywayBatches(String sql) {
        SQLServerParser parser = new SQLServerParser(new ClassicConfiguration(), new ParsingContext());
        List<String> batches = new ArrayList<>();
        try (SqlStatementIterator statements = parser.parse(new StringResource(sql))) {
            while (statements.hasNext()) batches.add(statements.next().getSql());
        }
        return batches;
    }

    private String read(String path) throws IOException {
        try (InputStream in = getClass().getResourceAsStream(path)) {
            assertNotNull(in, "classpath resource missing: " + path);
            return new String(in.readAllBytes(), StandardCharsets.UTF_8).replace("\r\n", "\n");
        }
    }

    private String ddl(String path) throws IOException {
        StringBuilder statements = new StringBuilder();
        for (String line : withoutComments(read(path)).split("\n")) {
            if (!line.trim().equalsIgnoreCase("go")) statements.append(line).append('\n');
        }
        return normalise(statements.toString()).toLowerCase();
    }

    private static String withoutComments(String sql) {
        return Arrays.stream(sql.split("\n")).map(l -> {
            int at = l.indexOf("--");
            return at < 0 ? l : l.substring(0, at);
        }).collect(Collectors.joining("\n"));
    }

    private static String normalise(String sql) {
        return sql.replaceAll("\\s+", " ").replace("( ", "(").trim();
    }

    private static int count(String haystack, String needle) {
        int n = 0;
        for (int at = haystack.indexOf(needle); at >= 0; at = haystack.indexOf(needle, at + 1)) n++;
        return n;
    }
}
