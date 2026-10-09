package com.example.planyourtrip;

import com.example.planyourtrip.model.AdminDualControlRequest;
import com.example.planyourtrip.model.DualControlStatus;
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
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.*;

/**
 * RBAC R6 — V10 (A16 dual-control requests), checked statically like V8 and V9: H2 never runs Flyway, so the file is
 * parsed with Flyway's own SQL Server parser and compared with the entity that builds the H2 schema. Running V1–V10 on
 * a real SQL Server stays the job of the environment-gated {@code SqlServerProdChainVerificationTest}.
 */
class RbacDualControlMigrationTest {

    private static final String V9 = "/db/migration/V9__admin_profile_assignments.sql";
    private static final String V10 = "/db/migration/V10__admin_dual_control_requests.sql";

    /** V9 as verified on a disposable SQL Server in R6: SHA-256 with line endings normalised. */
    private static final String V9_SHA = "c6aa0575e2bf43e07ea16c15e9559b33794b36fb12135857828da31eac5d6987";

    @Test
    void v9IsUntouched() throws Exception {
        String sha = HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
            .digest(read(V9).getBytes(StandardCharsets.UTF_8)));
        assertEquals(V9_SHA, sha, "V9 was edited; add a new migration instead");
    }

    @Test
    void flywayRunsEveryV10StatementAsItsOwnBatch() throws IOException {
        String sql = read(V10);
        List<String> batches = flywayBatches(sql);
        long goLines = sql.lines().filter(l -> l.trim().equalsIgnoreCase("go")).count();
        assertEquals(goLines, batches.size(), "one batch per GO");
        assertEquals(11, batches.size(), "table, unique key, 5 checks, 3 foreign keys, index - and nothing else");
        for (String batch : batches) {
            String statement = withoutComments(batch).trim().toLowerCase();
            assertTrue(statement.startsWith("create table admin_dual_control_requests")
                || statement.startsWith("alter table admin_dual_control_requests add constraint ")
                || statement.startsWith("create index idx_admin_dual_control_requests_status"), statement);
        }
    }

    /** Additive: one new table with its constraints and index; no existing table or row changes. */
    @Test
    void v10IsAdditiveAndWritesNoRow() throws IOException {
        String ddl = ddl(V10);
        for (String forbidden : new String[] {"drop ", "truncate ", "delete from", "sp_rename", "alter column",
                "update ", "insert into"}) {
            assertFalse(ddl.contains(forbidden), forbidden);
        }
        assertFalse(ddl.matches("(?s).*\\balter\\s+table\\s+(?!admin_dual_control_requests\\b)\\w+.*"),
            "V10 alters only its own table");
        assertEquals(1, count(ddl, "create table "));
        assertTrue(ddl.contains("add constraint uk_admin_dual_control_requests_live "
            + "unique (permission, target_type, target_id, live_key)"), ddl);
        for (String fk : List.of("requested_by", "approved_by", "rejected_by")) {
            assertTrue(ddl.contains("add constraint fk_admin_dual_control_requests_" + fk + " foreign key (" + fk
                + ") references users"), fk);
        }
        assertFalse(ddl.contains(" where "), "no filtered index: the live key gives the guarantee on H2 too");
        for (String line : read(V10).split("\n")) {
            String trimmed = line.trim();
            if (trimmed.startsWith("--") || trimmed.isEmpty()) continue;
            assertFalse(trimmed.matches("(?i).*\\b(TEXT|NTEXT|VARCHAR\\(MAX\\))\\b.*"), trimmed);
        }
    }

    @Test
    void everyEntityCheckIsTheMigrationsConstraintVerbatim() throws IOException {
        String migration = normalise(withoutComments(read(V10)));
        Check[] checks = AdminDualControlRequest.class.getAnnotationsByType(Check.class);
        assertEquals(Set.of("ck_admin_dual_control_requests_permission", "ck_admin_dual_control_requests_target_type",
                "ck_admin_dual_control_requests_status", "ck_admin_dual_control_requests_live",
                "ck_admin_dual_control_requests_decision"),
            Arrays.stream(checks).map(Check::name).collect(Collectors.toSet()));
        for (Check check : checks) {
            String declared = "add constraint " + check.name() + " check (" + normalise(check.constraints()) + ")";
            assertTrue(migration.contains(declared), "V10 differs from the entity for " + check.name()
                + ":\n  entity:    " + declared);
        }
        for (DualControlStatus status : DualControlStatus.values()) {
            assertTrue(DualControlStatus.CHECK.contains("'" + status.name() + "'"), status.name());
        }
        assertEquals(DualControlStatus.values().length, count(DualControlStatus.CHECK, "'") / 2, "exactly six states");
        assertEquals("permission in ('admin.place.owner.assign')", AdminDualControlRequest.PERMISSION_CHECK,
            "R6 dual-controls A16 only; A11 (R8) and the R7 thresholds widen this in a later migration");
    }

    // ── Helpers (as RbacAdminProfileMigrationTest) ───────────────────────────

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
        for (int at = haystack.indexOf(needle); at >= 0; at = haystack.indexOf(needle, at + needle.length())) n++;
        return n;
    }
}
