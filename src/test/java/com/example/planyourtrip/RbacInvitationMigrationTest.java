package com.example.planyourtrip;

import com.example.planyourtrip.model.PartnerInvitation;
import com.example.planyourtrip.model.PartnerInvitationGrant;
import com.example.planyourtrip.model.PartnerTeamMember;
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
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.*;

/**
 * RBAC R4 — V8 (M-3: partner invitations; re-addable memberships), checked statically like the R2 migrations
 * ({@code RbacMembershipMigrationTest}): H2 never runs Flyway, so the file is parsed with Flyway's own SQL Server
 * parser and compared with the entities that build the H2 schema. Running V1–V8 on a real SQL Server stays the job
 * of the environment-gated {@code SqlServerProdChainVerificationTest}.
 */
class RbacInvitationMigrationTest {

    private static final String V8 = "/db/migration/V8__partner_invitations.sql";

    /** V4–V7 are applied in production with R2/R3a: SHA-256 with line endings normalised. They are never edited. */
    private static final Map<String, String> APPLIED = Map.of(
        "/db/migration/V4__partner_membership_status.sql", "4f18ad3d9f8b050768651113be9c778c2526d9462f6e53d67c28df434ade559a",
        "/db/migration/V5__partner_member_grants.sql", "d29703a9eec8976334dfc2dc81dbddb7f9690d76444443d0107288cddafa454b",
        "/db/migration/V6__partner_activity_log_states.sql", "cb3ba5460d3974803ef9451350ed700fd270c700603029c938d08cca479ecf92",
        "/db/migration/V7__partner_membership_remediation.sql", "9d2af2a43838bb91f564a78cb87120dffd4a940d5b5fda6b7623574c916ffecd");

    @Test
    void v4ToV7AreUntouched() throws Exception {
        for (Map.Entry<String, String> applied : APPLIED.entrySet()) {
            byte[] normalised = read(applied.getKey()).getBytes(StandardCharsets.UTF_8);
            String sha = HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(normalised));
            assertEquals(applied.getValue(), sha, applied.getKey() + " was edited; add a new migration instead");
        }
    }

    @Test
    void flywayRunsEveryV8StatementAsItsOwnBatch() throws IOException {
        Pattern addsColumn = Pattern.compile("(?s).*\\balter\\s+table\\s+\\w+\\s+add\\s+(?!constraint\\b)\\w+.*");
        Pattern dml = Pattern.compile("(?s).*\\b(update|insert\\s+into|delete\\s+from)\\b.*");
        String sql = read(V8);
        List<String> batches = flywayBatches(sql);
        long goLines = sql.lines().filter(l -> l.trim().equalsIgnoreCase("go")).count();
        assertEquals(goLines, batches.size(), "one batch per GO");
        for (String batch : batches) {
            String statement = withoutComments(batch).toLowerCase();
            assertFalse(addsColumn.matcher(statement).matches() && dml.matcher(statement).matches(),
                "a batch may not add a column and run DML (SQL Server binds columns at compile time):\n" + statement);
        }
    }

    /**
     * The only destructive statement is the swap of V1's (company, account) unique key for the live-membership key;
     * nothing is dropped otherwise, no existing table but partner_team_members is altered, and no row changes but
     * the backfill of revoked rows' key.
     */
    @Test
    void v8IsAdditiveExceptTheLiveMembershipKeySwap() throws IOException {
        String ddl = ddl(V8);
        assertEquals(1, count(ddl, "drop constraint"));
        assertTrue(ddl.contains("alter table partner_team_members drop constraint uk_partner_team_member_profile_user"));
        assertTrue(ddl.contains("add constraint uk_partner_team_members_live unique (partner_profile_id, user_id, revocation_key)"));
        for (String forbidden : new String[] {"drop table", "drop column", "drop index", "truncate ", "delete from",
                "sp_rename", "alter column", "insert into"}) {
            assertFalse(ddl.contains(forbidden), forbidden);
        }
        assertEquals(1, count(ddl, "update "), "only the revocation-key backfill writes rows");
        assertTrue(ddl.contains("update partner_team_members set revocation_key = id where status = 'revoked'"));
        for (String untouched : new String[] {"users", "partner_profiles", "partner_member_grants", "places",
                "hotel_rooms", "bookings", "partner_activity_logs"}) {
            assertFalse(ddl.matches("(?s).*\\balter\\s+table\\s+" + untouched + "\\b.*"), "V8 must not alter " + untouched);
        }
        for (String line : read(V8).split("\n")) {
            String trimmed = line.trim();
            if (trimmed.startsWith("--") || trimmed.isEmpty()) continue;
            assertFalse(trimmed.matches("(?i).*\\b(TEXT|NTEXT|VARCHAR\\(MAX\\))\\b.*"), trimmed);
        }
    }

    /** IN-7: the token is never a column — only its SHA-256, unique. */
    @Test
    void invitationsStoreOnlyATokenHash() throws IOException {
        String ddl = ddl(V8);
        assertTrue(ddl.contains("token_hash nvarchar(64) not null"));
        assertTrue(ddl.contains("add constraint uk_partner_invitations_token_hash unique (token_hash)"));
        assertFalse(ddl.matches("(?s).*\\btoken\\s+nvarchar.*"), "no raw token column");
        assertTrue(ddl.contains("add constraint uk_partner_invitations_pending unique (partner_profile_id, email, closed_key)"));
        assertTrue(ddl.contains("check (resend_count between 0 and 5)"));
    }

    @Test
    void everyEntityCheckIsTheMigrationsConstraintVerbatim() throws IOException {
        String migration = normalise(withoutComments(read(V8)));
        Map<Class<?>, List<String>> expected = Map.of(
            PartnerInvitation.class, List.of("ck_partner_invitations_status", "ck_partner_invitations_delivery_status",
                "ck_partner_invitations_resend_count", "ck_partner_invitations_closed_key"),
            PartnerInvitationGrant.class, List.of("ck_partner_invitation_grants_role", "ck_partner_invitation_grants_scope_type",
                "ck_partner_invitation_grants_scope_id", "ck_partner_invitation_grants_role_scope"));
        for (Map.Entry<Class<?>, List<String>> entity : expected.entrySet()) {
            Check[] checks = entity.getKey().getAnnotationsByType(Check.class);
            assertEquals(Set.copyOf(entity.getValue()),
                Arrays.stream(checks).map(Check::name).collect(Collectors.toSet()), entity.getKey().getSimpleName());
            for (Check check : checks) {
                String declared = "add constraint " + check.name() + " check (" + normalise(check.constraints()) + ")";
                assertTrue(migration.contains(declared), "V8 differs from the entity for " + check.name()
                    + ":\n  entity:    " + declared);
            }
        }
        String revocation = "add constraint ck_partner_team_members_revocation_key check ("
            + normalise(PartnerTeamMember.REVOCATION_KEY_CHECK) + ")";
        assertTrue(migration.contains(revocation), revocation);
    }

    // ── Helpers (as RbacMembershipMigrationTest) ─────────────────────────────

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
