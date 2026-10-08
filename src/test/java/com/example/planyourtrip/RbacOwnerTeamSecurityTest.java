package com.example.planyourtrip;

import com.example.planyourtrip.model.PartnerMembershipStatus;
import com.example.planyourtrip.model.PartnerTeamMember;
import com.example.planyourtrip.model.PartnerTeamRole;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.CategoryRepository;
import com.example.planyourtrip.repository.PartnerActivityLogRepository;
import com.example.planyourtrip.repository.PartnerMemberGrantRepository;
import com.example.planyourtrip.repository.PartnerTeamMemberRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.security.JwtService;
import com.example.planyourtrip.security.StepUpPolicy;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.repository.CrudRepository;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.lang.reflect.Method;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * R3a — owner and team security (RBAC V1.1 §10.3, §15, §17, §18, §19, §22, §25.3, §25.6, §29).
 *
 * <p>Every scenario provisions its own companies through the public API and the class is not
 * {@code @Transactional}, so each request commits as in production and the company row lock is real.
 */
@SpringBootTest
@AutoConfigureMockMvc
class RbacOwnerTeamSecurityTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired JdbcTemplate jdbc;
    @Autowired JwtService jwt;
    @Autowired UserRepository userRepo;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired PartnerTeamMemberRepository teamMemberRepo;
    @Autowired PartnerMemberGrantRepository grantRepo;
    @Autowired com.example.planyourtrip.support.TeamMemberSeeder seeder;

    private static final AtomicInteger counter = new AtomicInteger(1);
    private static final String PASSWORD = "password123";
    private static final String SETTINGS_ALL_OFF = """
        {"defaultLanguage":"en","timezone":"Asia/Ho_Chi_Minh",
         "notificationEmailEnabled":false,"notificationSmsEnabled":false,"notificationInAppEnabled":false,
         "bookingNotificationEnabled":false,"paymentNotificationEnabled":false,
         "reviewNotificationEnabled":false,"promotionNotificationEnabled":false}
        """;
    private static final String PAYOUT_BODY = """
        {"accountHolderName":"R3a Holder","bankName":"R3a Bank","bankAccountNumber":"%s","payoutMethod":"BANK_TRANSFER"}
        """;

    private String adminToken;

    private record Partner(String token, Long companyId, Long userId, String email, Long ownerRowId) {}
    private record Member(String token, Long userId, String email, Long rowId) {}

    // ═══════════════════════════════════════════════════════════════════════
    // Owner protection (§18)
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void thePrimaryOwnerCannotBeReplacedRemovedOrSuspended() throws Exception {
        Partner p = approvedPartner();
        Member coOwner = member(p, "OWNER");

        for (MockHttpServletRequestBuilder attempt : List.of(
                delete("/api/partner/team/" + p.ownerRowId()),
                post("/api/partner/team/" + p.ownerRowId() + "/suspend"),
                json(patch("/api/partner/team/" + p.ownerRowId()), "{\"role\":\"MANAGER\"}"),
                json(patch("/api/partner/team/" + p.ownerRowId()), "{\"active\":false}"),
                json(put("/api/partner/team/" + p.ownerRowId() + "/grants"),
                    grantsBody(version(p.ownerRowId()), "VIEWER", "COMPANY:" + p.companyId())))) {
            send(attempt, coOwner.token()).andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("OWNER_PROTECTED"));
        }
        // the primary owner cannot change or leave their own membership either
        send(json(patch("/api/partner/team/" + p.ownerRowId()), "{\"role\":\"VIEWER\"}"), p.token())
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("SELF_MODIFICATION_FORBIDDEN"));
        send(post("/api/partner/team/leave"), p.token())
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("OWNER_PROTECTED"));

        PartnerTeamMember primary = teamMemberRepo.findById(p.ownerRowId()).orElseThrow();
        assertEquals(PartnerTeamRole.OWNER, primary.getRole());
        assertEquals(PartnerMembershipStatus.ACTIVE, primary.getStatus());
        assertEquals(List.of("OWNER@COMPANY"), grants(p.ownerRowId()));
    }

    @Test
    void theLastQualifyingOwnerCannotLeave() throws Exception {
        Partner p = approvedPartner();
        Member a = member(p, "OWNER");
        Member b = member(p, "OWNER");
        setEnabled(p.userId(), false); // the primary owner's account becomes unusable (LO-1)

        send(delete("/api/partner/team/" + b.rowId()), a.token()).andExpect(status().isNoContent());
        send(post("/api/partner/team/leave"), a.token())
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.code").value("LAST_OWNER_REQUIRED"));
        assertEquals(PartnerMembershipStatus.ACTIVE, teamMemberRepo.findById(a.rowId()).orElseThrow().getStatus());
    }

    @Test
    void concurrentLastOwnerDeparturesCannotBothSucceed() throws Exception {
        Partner p = approvedPartner();
        Member a = member(p, "OWNER");
        Member b = member(p, "OWNER");
        setEnabled(p.userId(), false);

        List<Integer> statuses = concurrently(
            () -> send(post("/api/partner/team/leave"), a.token()).andReturn().getResponse().getStatus(),
            () -> send(post("/api/partner/team/leave"), b.token()).andReturn().getResponse().getStatus());

        assertEquals(1, statuses.stream().filter(s -> s == 204).count(), "exactly one departure succeeds: " + statuses);
        assertEquals(1, statuses.stream().filter(s -> s == 409).count(), "the other is refused: " + statuses);
        long activeOwners = List.of(a.rowId(), b.rowId()).stream()
            .map(id -> teamMemberRepo.findById(id).orElseThrow())
            .filter(m -> m.getStatus() == PartnerMembershipStatus.ACTIVE).count();
        assertEquals(1, activeOwners, "the company keeps one active owner");
    }

    @Test
    void ownerChangesNeedAFreshSessionAndStepUpRestoresIt() throws Exception {
        Partner p = approvedPartner();
        String stale = staleToken(p.userId());
        Member viewer = member(p, "VIEWER");
        String target = partnerAccount();

        send(json(post("/api/partner/team"), "{\"email\":\"" + target + "\",\"role\":\"OWNER\"}"), stale)
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value(StepUpPolicy.STEP_UP_REQUIRED));
        send(json(put("/api/partner/team/" + viewer.rowId() + "/grants"),
                grantsBody(version(viewer.rowId()), "OWNER", "COMPANY:" + p.companyId())), stale)
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value(StepUpPolicy.STEP_UP_REQUIRED));
        send(json(put("/api/partner/payout-account"), PAYOUT_BODY.formatted("1234567890")), stale)
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value(StepUpPolicy.STEP_UP_REQUIRED));
        // a non-owner change needs no step-up
        send(json(put("/api/partner/team/" + viewer.rowId() + "/grants"),
                grantsBody(version(viewer.rowId()), "FRONT_DESK", "COMPANY:" + p.companyId())), stale)
            .andExpect(status().isOk());

        String fresh = stepUp(stale, PASSWORD);
        send(json(put("/api/partner/team/" + viewer.rowId() + "/grants"),
                grantsBody(version(viewer.rowId()), "OWNER", "COMPANY:" + p.companyId())), fresh)
            .andExpect(status().isOk()).andExpect(jsonPath("$.role").value("OWNER"));
        assertTrue(actions(p.companyId()).contains("OWNER_GRANTED"));
        // the stale token still works for everything that does not need freshness (step-up rotates nothing)
        send(get("/api/partner/team"), stale).andExpect(status().isOk());
    }

    @Test
    void stepUpChecksThePasswordAndIsRateLimited() throws Exception {
        Partner p = approvedPartner();
        mvc.perform(json(post("/api/me/step-up"), "{\"currentPassword\":\"wrong-password\"}")
                .header("Authorization", "Bearer " + p.token()))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.code").value("CURRENT_PASSWORD_INCORRECT"))
            .andExpect(jsonPath("$.fieldErrors[0].field").value("currentPassword"));
        for (int i = 0; i < 4; i++) stepUp(p.token(), PASSWORD);
        mvc.perform(json(post("/api/me/step-up"), "{\"currentPassword\":\"" + PASSWORD + "\"}")
                .header("Authorization", "Bearer " + p.token()))
            .andExpect(status().isTooManyRequests())
            .andExpect(jsonPath("$.code").value("STEP_UP_RATE_LIMITED"));
        mvc.perform(json(post("/api/me/step-up"), "{\"currentPassword\":\"" + PASSWORD + "\"}"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void anAdministratorsStepUpIsAudited() throws Exception {
        long ok = adminActions("ADMIN_STEP_UP");
        long failed = adminActions("ADMIN_STEP_UP_FAILED");
        String admin = adminToken();
        mvc.perform(json(post("/api/me/step-up"), "{\"currentPassword\":\"not-the-password\"}")
                .header("Authorization", "Bearer " + admin)).andExpect(status().isBadRequest());
        mvc.perform(json(post("/api/me/step-up"), "{\"currentPassword\":\"admin123456\"}")
                .header("Authorization", "Bearer " + admin)).andExpect(status().isOk());
        assertEquals(ok + 1, adminActions("ADMIN_STEP_UP"));
        assertEquals(failed + 1, adminActions("ADMIN_STEP_UP_FAILED"));
    }

    private long adminActions(String action) {
        return jdbc.queryForObject("select count(*) from admin_activity_logs where action = ?", Long.class, action);
    }

    @Test
    void aLegacyCoOwnerPendingConfirmationHoldsOnlyManagerUntilThePrimaryOwnerConfirms() throws Exception {
        Partner p = approvedPartner();
        Member legacy = member(p, "MANAGER");
        markPendingCoOwner(legacy.rowId()); // the state M-6 (V7) leaves a legacy co-owner in

        String other = partnerAccount();
        // RBAC R4: a pending co-owner holds MANAGER's rights only - those now include inviting below-manager roles
        // (§31 Q3), never an owner, and never the payout account
        send(json(post("/api/partner/team"), "{\"email\":\"" + other + "\",\"role\":\"VIEWER\"}"), legacy.token())
            .andExpect(status().isAccepted());
        send(json(post("/api/partner/team"), "{\"email\":\"" + partnerAccount() + "\",\"role\":\"OWNER\"}"), legacy.token())
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("OWNER_PROTECTED"));
        send(json(put("/api/partner/payout-account"), PAYOUT_BODY.formatted("1234567890")), legacy.token())
            .andExpect(status().isForbidden());

        send(json(put("/api/partner/team/" + legacy.rowId() + "/grants"),
                grantsBody(version(legacy.rowId()), "OWNER", "COMPANY:" + p.companyId())), p.token())
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.pendingOwnerConfirmation").value(false))
            .andExpect(jsonPath("$.role").value("OWNER"));
        assertTrue(actions(p.companyId()).contains("OWNER_GRANTED"));
        // confirmed: owner-level invitations become possible (with a fresh session)
        send(json(post("/api/partner/team"), "{\"email\":\"" + partnerAccount() + "\",\"role\":\"OWNER\"}"),
                login(legacy.email(), PASSWORD))
            .andExpect(status().isAccepted());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Authority, delegation and self-modification (§10.3)
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void rolesWithoutTeamPermissionsCannotChangeAnyMembership() throws Exception {
        Partner p = approvedPartner();
        Member manager = member(p, "MANAGER");
        Member finance = member(p, "FINANCE");
        Member viewer = member(p, "VIEWER");

        // RBAC R4: MANAGER holds the team permissions (§31 Q3, see RbacTeamAdministrationTest); FINANCE and VIEWER
        // hold none - FINANCE being company-wide gives it no team power (§10.4)
        for (Member actor : List.of(finance, viewer)) {
            for (MockHttpServletRequestBuilder attempt : List.of(
                    json(patch("/api/partner/team/" + viewer.rowId()), "{\"role\":\"FRONT_DESK\"}"),
                    json(put("/api/partner/team/" + viewer.rowId() + "/grants"),
                        grantsBody(version(viewer.rowId()), "FRONT_DESK", "COMPANY:" + p.companyId())),
                    post("/api/partner/team/" + viewer.rowId() + "/suspend"),
                    post("/api/partner/team/" + viewer.rowId() + "/reactivate"),
                    delete("/api/partner/team/" + viewer.rowId()),
                    json(post("/api/partner/team"), "{\"email\":\"" + partnerAccount() + "\",\"role\":\"VIEWER\"}"))) {
                send(attempt, actor.token()).andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.code").value("PERMISSION_DENIED"));
            }
        }
        assertEquals(List.of("VIEWER@COMPANY"), grants(viewer.rowId()));
        assertEquals(PartnerMembershipStatus.ACTIVE, teamMemberRepo.findById(viewer.rowId()).orElseThrow().getStatus());
        // the manager may manage the viewer, but never the finance member (§10.3)
        send(json(patch("/api/partner/team/" + viewer.rowId()), "{\"role\":\"FRONT_DESK\"}"), manager.token())
            .andExpect(status().isOk());
        send(post("/api/partner/team/" + finance.rowId() + "/suspend"), manager.token())
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ROLE_NOT_DELEGABLE"));
    }

    @Test
    void aManagerCannotEscalateThemselvesOrAnyoneToOwner() throws Exception {
        Partner p = approvedPartner();
        Member manager = member(p, "MANAGER");
        Member viewer = member(p, "VIEWER");

        send(json(patch("/api/partner/team/" + manager.rowId()), "{\"role\":\"OWNER\"}"), manager.token())
            .andExpect(status().isForbidden());
        send(json(put("/api/partner/team/" + manager.rowId() + "/grants"),
                grantsBody(version(manager.rowId()), "OWNER", "COMPANY:" + p.companyId())), manager.token())
            .andExpect(status().isForbidden());
        send(json(patch("/api/partner/team/" + viewer.rowId()), "{\"role\":\"OWNER\"}"), manager.token())
            .andExpect(status().isForbidden());
        send(json(post("/api/partner/team"), "{\"email\":\"" + partnerAccount() + "\",\"role\":\"OWNER\"}"), manager.token())
            .andExpect(status().isForbidden());
        assertEquals(List.of("MANAGER@COMPANY"), grants(manager.rowId()));
        assertEquals(List.of("VIEWER@COMPANY"), grants(viewer.rowId()));

        // an owner cannot change their own membership either
        Member coOwner = member(p, "OWNER");
        send(json(put("/api/partner/team/" + coOwner.rowId() + "/grants"),
                grantsBody(version(coOwner.rowId()), "MANAGER", "COMPANY:" + p.companyId())), coOwner.token())
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("SELF_MODIFICATION_FORBIDDEN"));
        send(post("/api/partner/team/" + coOwner.rowId() + "/suspend"), coOwner.token())
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("SELF_MODIFICATION_FORBIDDEN"));
    }

    @Test
    void financeAndOwnerKeepTheirBoundaries() throws Exception {
        Partner p = approvedPartner();
        Long property = createProperty(p);
        Member finance = member(p, "FINANCE");
        Member manager = member(p, "MANAGER");

        send(json(put("/api/partner/payout-account"), PAYOUT_BODY.formatted("1111222233")), finance.token())
            .andExpect(status().isOk());
        send(json(put("/api/partner/payout-account"), PAYOUT_BODY.formatted("1111222233")), manager.token())
            .andExpect(status().isForbidden());
        send(json(put("/api/partner/payout-account"), PAYOUT_BODY.formatted("1111222233")), staleToken(finance.userId()))
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value(StepUpPolicy.STEP_UP_REQUIRED));
        // FINANCE and OWNER are company-only (§11.3, Q10)
        for (String role : List.of("FINANCE", "OWNER")) {
            send(json(put("/api/partner/team/" + manager.rowId() + "/grants"),
                    grantsBody(version(manager.rowId()), role, "PROPERTY:" + property)), p.token())
                .andExpect(status().isUnprocessableEntity()).andExpect(jsonPath("$.code").value("SCOPE_INVALID"));
        }
        // FINANCE cannot touch the team
        send(post("/api/partner/team/" + manager.rowId() + "/suspend"), finance.token())
            .andExpect(status().isForbidden());
    }

    @Test
    void anotherCompanysMembershipIsNotFound() throws Exception {
        Partner a = approvedPartner();
        Partner b = approvedPartner();
        Long foreignProperty = createProperty(b);
        Member memberOfB = member(b, "VIEWER");
        Member memberOfA = member(a, "VIEWER");

        for (MockHttpServletRequestBuilder attempt : List.of(
                json(patch("/api/partner/team/" + memberOfB.rowId()), "{\"role\":\"MANAGER\"}"),
                json(put("/api/partner/team/" + memberOfB.rowId() + "/grants"),
                    grantsBody(version(memberOfB.rowId()), "MANAGER", "COMPANY:" + a.companyId())),
                post("/api/partner/team/" + memberOfB.rowId() + "/suspend"),
                post("/api/partner/team/" + memberOfB.rowId() + "/reactivate"),
                delete("/api/partner/team/" + memberOfB.rowId()),
                delete("/api/partner/team/" + b.ownerRowId()))) {
            send(attempt, a.token()).andExpect(status().isNotFound());
        }
        // a grant into another company is refused without saying whether the scope exists
        send(json(put("/api/partner/team/" + memberOfA.rowId() + "/grants"),
                grantsBody(version(memberOfA.rowId()), "MANAGER", "PROPERTY:" + foreignProperty)), a.token())
            .andExpect(status().isUnprocessableEntity()).andExpect(jsonPath("$.code").value("SCOPE_INVALID"));
        send(json(put("/api/partner/team/" + memberOfA.rowId() + "/grants"),
                grantsBody(version(memberOfA.rowId()), "MANAGER", "COMPANY:" + b.companyId())), a.token())
            .andExpect(status().isUnprocessableEntity()).andExpect(jsonPath("$.code").value("SCOPE_INVALID"));
        assertEquals(List.of("VIEWER@COMPANY"), grants(memberOfB.rowId()));
        assertEquals(PartnerMembershipStatus.ACTIVE, teamMemberRepo.findById(memberOfB.rowId()).orElseThrow().getStatus());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Membership states (§17)
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void suspensionEndsAccessKeepsGrantsAndReactivationRestoresThem() throws Exception {
        Partner p = approvedPartner();
        Member m = member(p, "MANAGER");

        send(json(post("/api/partner/team/" + m.rowId() + "/suspend"), "{\"reason\":\"on leave\"}"), p.token())
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("SUSPENDED"))
            .andExpect(jsonPath("$.active").value(false));
        send(get("/api/partner/settings"), m.token()).andExpect(status().isNotFound());
        assertEquals(List.of("MANAGER@COMPANY"), grants(m.rowId()));
        JsonNode listed = teamEntry(p, m.rowId());
        assertEquals("SUSPENDED", listed.get("status").asText());
        assertEquals("on leave", teamMemberRepo.findById(m.rowId()).orElseThrow().getStatusReason());

        // suspending again changes nothing and records nothing
        int before = actions(p.companyId()).size();
        send(post("/api/partner/team/" + m.rowId() + "/suspend"), p.token()).andExpect(status().isOk());
        assertEquals(before, actions(p.companyId()).size());

        send(post("/api/partner/team/" + m.rowId() + "/reactivate"), p.token())
            .andExpect(status().isOk()).andExpect(jsonPath("$.status").value("ACTIVE"));
        send(get("/api/partner/settings"), m.token()).andExpect(status().isOk());
        assertEquals(List.of("MANAGER@COMPANY"), grants(m.rowId()));
    }

    @Test
    void removalIsASoftRevokeThatCanNeverBeUndone() throws Exception {
        Partner p = approvedPartner();
        Member m = member(p, "VIEWER");

        send(json(delete("/api/partner/team/" + m.rowId()), "{\"reason\":\"left the company\"}"), p.token())
            .andExpect(status().isNoContent());
        PartnerTeamMember row = teamMemberRepo.findById(m.rowId()).orElseThrow();
        assertEquals(PartnerMembershipStatus.REVOKED, row.getStatus());
        assertTrue(grants(m.rowId()).isEmpty());
        assertEquals("PARTNER", userRepo.findById(m.userId()).orElseThrow().getRole(), "RV-1: users.role is untouched");
        send(get("/api/partner/settings"), m.token()).andExpect(status().isNotFound());
        assertTrue(teamIds(p).stream().noneMatch(id -> id.equals(m.rowId())), "a revoked member is not listed");

        for (MockHttpServletRequestBuilder attempt : List.of(
                post("/api/partner/team/" + m.rowId() + "/reactivate"),
                json(patch("/api/partner/team/" + m.rowId()), "{\"active\":true}"),
                post("/api/partner/team/" + m.rowId() + "/suspend"),
                delete("/api/partner/team/" + m.rowId()))) {
            send(attempt, p.token()).andExpect(status().isNotFound());
        }
        // RBAC R4 (RV-2): the person is re-invited - a new invitation, and on acceptance a NEW membership; the
        // revoked row is never revived (RbacTeamAdministrationTest covers the acceptance)
        send(json(post("/api/partner/team"), "{\"email\":\"" + m.email() + "\",\"role\":\"VIEWER\"}"), p.token())
            .andExpect(status().isAccepted());
        assertEquals(PartnerMembershipStatus.REVOKED, teamMemberRepo.findById(m.rowId()).orElseThrow().getStatus());
    }

    @Test
    void oneCompanyPerAccountStillHoldsAndLeavingFreesTheAccount() throws Exception {
        Partner a = approvedPartner();
        Partner b = approvedPartner();
        Member m = member(a, "VIEWER");

        // suspended in B while active in A, then B tries to reactivate (WS-5)
        long rowInB = seeder.seed(b.companyId(), m.email(), PartnerTeamRole.VIEWER, false);
        send(post("/api/partner/team/" + rowInB + "/reactivate"), b.token())
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.code").value("WORKSPACE_CONFLICT"))
            .andExpect(jsonPath("$.reason").value("MEMBERSHIP_EXISTS"));

        // a member cannot register a company until they leave (WS-2)
        send(json(post("/api/partner/profile"), profileBody()), m.token())
            .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("WORKSPACE_CONFLICT"));
        send(delete("/api/partner/team/" + rowInB), b.token()).andExpect(status().isNoContent());
        send(post("/api/partner/team/leave"), m.token()).andExpect(status().isNoContent());
        assertEquals(PartnerMembershipStatus.REVOKED, teamMemberRepo.findById(m.rowId()).orElseThrow().getStatus());
        assertTrue(actions(a.companyId()).contains("TEAM_MEMBER_LEFT"));
        send(json(post("/api/partner/profile"), profileBody()), m.token()).andExpect(status().isOk());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Strict audit (§22) and mandatory notifications (§18 O-8)
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void everyTeamMutationIsAuditedWithActorSnapshotBeforeAfterAndReason() throws Exception {
        Partner p = approvedPartner();
        Long property = createProperty(p);
        Member m = member(p, "VIEWER");

        send(json(put("/api/partner/team/" + m.rowId() + "/grants"), """
                {"grants":[{"role":"MANAGER","scope":"COMPANY:%d"},{"role":"CONTENT","scope":"PROPERTY:%d"}],
                 "reason":"promotion","version":%d}
                """.formatted(p.companyId(), property, version(m.rowId()))), p.token())
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.role").value("MANAGER"))
            .andExpect(jsonPath("$.grants.length()").value(2));
        send(post("/api/partner/team/" + m.rowId() + "/suspend"), p.token()).andExpect(status().isOk());
        send(post("/api/partner/team/" + m.rowId() + "/reactivate"), p.token()).andExpect(status().isOk());
        send(json(put("/api/partner/team/" + m.rowId() + "/grants"),
                grantsBody(version(m.rowId()), "OWNER", "COMPANY:" + p.companyId())), p.token())
            .andExpect(status().isOk());
        Member owner2 = member(p, "OWNER");
        send(json(patch("/api/partner/team/" + owner2.rowId()), "{\"role\":\"MANAGER\"}"), p.token())
            .andExpect(status().isOk());
        send(delete("/api/partner/team/" + m.rowId()), p.token()).andExpect(status().isNoContent());

        List<Map<String, Object>> rows = auditRows(p.companyId());
        Map<String, Map<String, Object>> byAction = new LinkedHashMap<>();
        rows.forEach(r -> byAction.putIfAbsent((String) r.get("action"), r));
        // RBAC R4: members join through invitations (TEAM_MEMBER_INVITED / TEAM_INVITATION_ACCEPTED, covered in
        // RbacTeamInvitationTest); TEAM_MEMBER_ADDED is no longer written (§22.2)
        for (String action : List.of("TEAM_MEMBER_ROLE_CHANGED", "TEAM_MEMBER_SUSPENDED",
                "TEAM_MEMBER_REACTIVATED", "OWNER_GRANTED", "OWNER_REVOKED", "TEAM_MEMBER_REMOVED")) {
            Map<String, Object> row = byAction.get(action);
            assertNotNull(row, "missing audit " + action + " in " + byAction.keySet());
            assertEquals(p.userId(), ((Number) row.get("actor_user_id")).longValue(), action);
            assertEquals(p.email(), row.get("actor_email"), action);
        }
        Map<String, Object> changed = byAction.get("TEAM_MEMBER_ROLE_CHANGED");
        assertEquals("VIEWER@COMPANY:" + p.companyId() + "|ACTIVE", changed.get("before_state"));
        assertEquals("CONTENT@PROPERTY:" + property + ",MANAGER@COMPANY:" + p.companyId() + "|ACTIVE",
            changed.get("after_state"));
        assertEquals("promotion", changed.get("reason"));
        assertEquals("OWNER@COMPANY:" + p.companyId() + "|ACTIVE", byAction.get("OWNER_REVOKED").get("before_state"));
        assertTrue(((String) byAction.get("TEAM_MEMBER_REMOVED").get("after_state")).endsWith("|REVOKED"));
    }

    @Test
    void theActorEmailIsASnapshotNeverReResolved() throws Exception {
        Partner p = approvedPartner();
        Member m = member(p, "VIEWER");
        send(post("/api/partner/team/" + m.rowId() + "/suspend"), p.token()).andExpect(status().isOk());

        User owner = userRepo.findById(p.userId()).orElseThrow();
        owner.setEmail("renamed-" + UUID.randomUUID() + "@test.com");
        userRepo.save(owner);

        Map<String, Object> row = auditRows(p.companyId()).stream()
            .filter(r -> "TEAM_MEMBER_SUSPENDED".equals(r.get("action"))).findFirst().orElseThrow();
        assertEquals(p.email(), row.get("actor_email"));
    }

    @Test
    void thePartnerTrailIsAppendOnly() {
        assertFalse(CrudRepository.class.isAssignableFrom(PartnerActivityLogRepository.class));
        for (Method method : PartnerActivityLogRepository.class.getMethods()) {
            String name = method.getName().toLowerCase();
            assertFalse(name.startsWith("delete") || name.startsWith("update") || name.startsWith("remove"),
                "the partner trail exposes " + method.getName());
        }
        assertEquals(List.of("findByPartnerProfileIdOrderByCreatedAtDesc", "findByPartnerProfileIdOrderByCreatedAtDescIdDesc", "save"),
            Arrays.stream(PartnerActivityLogRepository.class.getDeclaredMethods()).map(Method::getName).sorted().toList());
    }

    @Test
    void securityNotificationsReachEveryOwnerAndTheMemberAndCannotBeSwitchedOff() throws Exception {
        Partner p = approvedPartner();
        Member coOwner = member(p, "OWNER");
        Member m = member(p, "VIEWER");
        // every operational notification setting off, by the owner
        send(json(put("/api/partner/settings"), SETTINGS_ALL_OFF), p.token()).andExpect(status().isOk());

        send(json(patch("/api/partner/team/" + m.rowId()), "{\"role\":\"FRONT_DESK\"}"), p.token())
            .andExpect(status().isOk());
        for (String token : List.of(p.token(), coOwner.token(), m.token())) {
            assertTrue(titles(token).contains("Team member role changed"), "role change not notified");
        }
        send(json(put("/api/partner/payout-account"), PAYOUT_BODY.formatted("5555666677")), p.token())
            .andExpect(status().isOk());
        assertTrue(titles(coOwner.token()).contains("Payout account updated"), "every owner hears of a payout change");
        assertFalse(titles(m.token()).contains("Payout account updated"));
        Map<String, Object> payout = auditRows(p.companyId()).stream()
            .filter(r -> "PAYOUT_ACCOUNT_UPDATED".equals(r.get("action"))).findFirst().orElseThrow();
        assertEquals("none", payout.get("before_state"));
        assertEquals("****6677", payout.get("after_state"));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Contract: optimistic version, validation, legacy endpoint
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void aStaleVersionIsRefused() throws Exception {
        Partner p = approvedPartner();
        Member m = member(p, "VIEWER");
        long read = version(m.rowId());

        send(json(put("/api/partner/team/" + m.rowId() + "/grants"),
                grantsBody(read, "FRONT_DESK", "COMPANY:" + p.companyId())), p.token())
            .andExpect(status().isOk()).andExpect(jsonPath("$.version").value(read + 1));
        send(json(put("/api/partner/team/" + m.rowId() + "/grants"),
                grantsBody(read, "MANAGER", "COMPANY:" + p.companyId())), p.token())
            .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("CONCURRENT_MODIFICATION"));
        assertEquals(List.of("FRONT_DESK@COMPANY"), grants(m.rowId()));
    }

    @Test
    void malformedGrantsAndUnknownRolesFailClosed() throws Exception {
        Partner p = approvedPartner();
        Member m = member(p, "VIEWER");
        String path = "/api/partner/team/" + m.rowId() + "/grants";
        long v = version(m.rowId());

        send(json(put(path), "{\"grants\":[{\"role\":\"SUPER_OWNER\",\"scope\":\"COMPANY:" + p.companyId() + "\"}],\"version\":" + v + "}"), p.token())
            .andExpect(status().isBadRequest());
        send(json(put(path), "{\"grants\":[],\"version\":" + v + "}"), p.token())
            .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
        send(json(put(path), "{\"grants\":[{\"role\":\"VIEWER\",\"scope\":\"COMPANY:" + p.companyId() + "\"}]}"), p.token())
            .andExpect(status().isBadRequest()).andExpect(jsonPath("$.fieldErrors[0].field").value("version"));
        for (String scope : List.of("company:1", "ROOM:1", "PROPERTY:0", "PROPERTY:abc", "")) {
            send(json(put(path), "{\"grants\":[{\"role\":\"VIEWER\",\"scope\":\"" + scope + "\"}],\"version\":" + v + "}"), p.token())
                .andExpect(status().isUnprocessableEntity()).andExpect(jsonPath("$.code").value("SCOPE_INVALID"));
        }
        send(json(put(path), grantsBody(v, "HOUSEKEEPING", "COMPANY:" + p.companyId())), p.token())
            .andExpect(status().isUnprocessableEntity()).andExpect(jsonPath("$.code").value("SCOPE_INVALID"));
        assertEquals(List.of("VIEWER@COMPANY"), grants(m.rowId()));
    }

    @Test
    void theLegacyAddIsAnInvitationAliasAndPromotesNobody() throws Exception {
        Partner p = approvedPartner();
        Partner other = approvedPartner();
        String traveller = registerUser();
        Member existing = member(p, "VIEWER");

        // RBAC R4 (§29): POST /team invites - one uniform 202 for an unknown address, a traveller, an administrator
        // and another company's registrant (IN-1); nobody is attached or promoted (IN-2)
        String uniform = null;
        for (String email : List.of("nobody-" + UUID.randomUUID() + "@test.com", traveller,
                "admin@planyourtrip.com", other.email())) {
            String body = send(json(post("/api/partner/team"), "{\"email\":\"" + email + "\",\"role\":\"VIEWER\"}"), p.token())
                .andExpect(status().isAccepted())
                .andReturn().getResponse().getContentAsString();
            if (uniform == null) uniform = body;
            assertEquals(uniform, body, "the answer never depends on the address");
        }
        assertEquals(2, teamIds(p).size(), "nobody joined: the owner and the existing viewer only");
        assertEquals("USER", userRepo.findByEmail(traveller).orElseThrow().getRole(), "no USER -> PARTNER promotion");
        send(json(post("/api/partner/team"), "{\"email\":\"" + existing.email() + "\",\"role\":\"VIEWER\"}"), p.token())
            .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("ALREADY_MEMBER"));

        JsonNode self = teamEntry(p, p.ownerRowId());
        assertTrue(self.get("primaryOwner").asBoolean());
        assertTrue(self.get("isSelf").asBoolean());
        assertEquals("OWNER", self.get("grants").get(0).get("role").asText());
        assertEquals("COMPANY:" + p.companyId(), self.get("grants").get(0).get("scope").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Nothing of R3b is activated
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void scopedAndNewRoleGrantsActivateExactlyTheirScopedBundles() throws Exception {
        Partner p = approvedPartner();
        Long property = createProperty(p);
        Member m = member(p, "VIEWER");

        send(json(put("/api/partner/team/" + m.rowId() + "/grants"), """
                {"grants":[{"role":"MANAGER","scope":"PROPERTY:%d"},{"role":"REVENUE","scope":"COMPANY:%d"},
                           {"role":"HOUSEKEEPING","scope":"PROPERTY:%d"}],"version":%d}
                """.formatted(property, p.companyId(), property, version(m.rowId()))), p.token())
            .andExpect(status().isOk()).andExpect(jsonPath("$.role").value("MANAGER"));

        // R3b: a MANAGER@PROPERTY grant is never company-wide MANAGER (floor C stays out of reach)…
        send(json(put("/api/partner/settings"), SETTINGS_ALL_OFF), m.token()).andExpect(status().isForbidden());
        send(get("/api/partner/finance/settlements"), m.token()).andExpect(status().isForbidden());
        // …while REVENUE@COMPANY and MANAGER@PROPERTY give exactly their bundles
        send(get("/api/partner/settings"), m.token()).andExpect(status().isOk());
        for (String path : List.of("/api/partner/hotels", "/api/partner/hotels/" + property, "/api/partner/bookings",
                "/api/partner/finance/overview")) {
            send(get(path), m.token()).andExpect(status().isOk());
        }
        // a confirmed co-owner operates company-wide
        Member coOwner = member(p, "OWNER");
        send(get("/api/partner/hotels"), coOwner.token()).andExpect(status().isOk());
        send(get("/api/partner/team"), coOwner.token()).andExpect(status().isOk());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Helpers
    // ═══════════════════════════════════════════════════════════════════════

    private ResultActions send(MockHttpServletRequestBuilder request, String token) throws Exception {
        return mvc.perform(request.header("Authorization", "Bearer " + token));
    }

    private static MockHttpServletRequestBuilder json(MockHttpServletRequestBuilder request, String body) {
        return request.contentType(MediaType.APPLICATION_JSON).content(body);
    }

    private static String grantsBody(long version, String role, String scope) {
        return "{\"grants\":[{\"role\":\"" + role + "\",\"scope\":\"" + scope + "\"}],\"version\":" + version + "}";
    }

    private long version(Long rowId) {
        return teamMemberRepo.findById(rowId).orElseThrow().getVersion();
    }

    private List<String> grants(Long rowId) {
        return grantRepo.findByTeamMemberIdOrderByIdAsc(rowId).stream()
            .map(g -> g.getRole().name() + "@" + g.getScopeType().name()).sorted().toList();
    }

    private List<String> actions(Long companyId) {
        return jdbc.queryForList("select action from partner_activity_logs where partner_profile_id = ? order by id",
            String.class, companyId);
    }

    private List<Map<String, Object>> auditRows(Long companyId) {
        return jdbc.queryForList("select action, actor_user_id, actor_email, before_state, after_state, reason "
            + "from partner_activity_logs where partner_profile_id = ? order by id", companyId);
    }

    private List<String> titles(String token) throws Exception {
        JsonNode list = mapper.readTree(send(get("/api/me/notifications"), token)
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
        List<String> titles = new ArrayList<>();
        list.forEach(n -> titles.add(n.get("title").asText()));
        return titles;
    }

    private JsonNode teamEntry(Partner p, Long rowId) throws Exception {
        JsonNode list = mapper.readTree(send(get("/api/partner/team"), p.token())
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
        for (JsonNode n : list) if (n.get("id").asLong() == rowId) return n;
        throw new AssertionError("member " + rowId + " not listed");
    }

    private List<Long> teamIds(Partner p) throws Exception {
        JsonNode list = mapper.readTree(send(get("/api/partner/team"), p.token())
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
        List<Long> ids = new ArrayList<>();
        list.forEach(n -> ids.add(n.get("id").asLong()));
        return ids;
    }

    private void setEnabled(Long userId, boolean enabled) {
        User u = userRepo.findById(userId).orElseThrow();
        u.setEnabled(enabled);
        userRepo.save(u);
    }

    /** The state V7 (M-6 d) leaves a legacy co-owner in: MANAGER@COMPANY pending the primary owner's confirmation. */
    private void markPendingCoOwner(Long rowId) {
        jdbc.update("update partner_team_members set pending_owner_confirmation = true where id = ?", rowId);
    }

    private String staleToken(Long userId) {
        User u = userRepo.findById(userId).orElseThrow();
        return jwt.createToken(u.getId(), u.getEmail(), u.getTokenVersion(),
            Instant.now().minus(StepUpPolicy.FRESHNESS).minusSeconds(60));
    }

    private String stepUp(String token, String password) throws Exception {
        String body = mvc.perform(json(post("/api/me/step-up"), "{\"currentPassword\":\"" + password + "\"}")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    @SafeVarargs
    private static List<Integer> concurrently(Callable<Integer>... calls) throws Exception {
        ExecutorService pool = Executors.newFixedThreadPool(calls.length);
        CountDownLatch start = new CountDownLatch(1);
        try {
            List<Future<Integer>> futures = new ArrayList<>();
            for (Callable<Integer> call : calls) {
                futures.add(pool.submit(() -> { start.await(); return call.call(); }));
            }
            start.countDown();
            List<Integer> results = new ArrayList<>();
            for (Future<Integer> f : futures) results.add(f.get(30, TimeUnit.SECONDS));
            return results;
        } finally {
            pool.shutdownNow();
        }
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
        return "r3a-" + prefix + "-" + counter.getAndIncrement() + "-"
            + UUID.randomUUID().toString().substring(0, 8) + "@test.com";
    }

    private String registerUser() throws Exception {
        String email = uniqueEmail("user");
        mvc.perform(json(post("/api/auth/register"),
                "{\"fullName\":\"R3a Tester\",\"email\":\"" + email + "\",\"password\":\"" + PASSWORD + "\"}"))
            .andExpect(status().isCreated());
        return email;
    }

    /** An existing PARTNER account without a company, as a self-registered Partner would be. */
    private String partnerAccount() throws Exception {
        String email = registerUser();
        User u = userRepo.findByEmail(email).orElseThrow();
        u.setRole("PARTNER");
        userRepo.save(u);
        return email;
    }

    private static String profileBody() {
        return """
            {"businessName":"R3a Co %s","businessType":"HOTEL","representativeName":"R3a Tester",
             "phone":"0901234567","email":"contact@example.com","address":"1 Le Loi, Da Nang"}
            """.formatted(UUID.randomUUID().toString().substring(0, 8));
    }

    private Partner approvedPartner() throws Exception {
        String email = registerUser();
        String token = login(email, PASSWORD);
        Long companyId = mapper.readTree(send(json(post("/api/partner/profile"), profileBody()), token)
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString()).get("id").asLong();
        send(post("/api/partner/profile/submit"), token).andExpect(status().isOk());
        send(post("/api/admin/partners/" + companyId + "/approve"), adminToken()).andExpect(status().isOk());
        Long userId = userRepo.findByEmail(email).orElseThrow().getId();
        Long ownerRow = teamMemberRepo.findByPartnerProfileIdAndUserId(companyId, userId).orElseThrow().getId();
        return new Partner(token, companyId, userId, email, ownerRow);
    }

    /**
     * A Partner account in the team with {@code role} at company scope. RBAC R4: members join through accepted
     * invitations; the seeder creates exactly that membership (the invitation flow is RbacTeamInvitationTest's).
     */
    private Member member(Partner owner, String role) throws Exception {
        String email = partnerAccount();
        Long rowId = seeder.seed(owner.companyId(), email, PartnerTeamRole.valueOf(role));
        return new Member(login(email, PASSWORD), userRepo.findByEmail(email).orElseThrow().getId(), email, rowId);
    }

    private Long createProperty(Partner partner) throws Exception {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("name", "R3a Stay " + UUID.randomUUID().toString().substring(0, 8));
        body.put("categoryId", categoryRepo.findBySlug("accommodation").orElseThrow().getId());
        body.put("subcategoryId", categoryRepo.findBySlug("hotel").orElseThrow().getId());
        body.put("administrativeUnitId", locationRepo.findByCode("VT").orElseThrow().getId());
        body.put("address", "15 Thuy Van, Vung Tau");
        body.put("starRating", 3);
        body.put("checkIn", "14:00:00");
        body.put("checkOut", "12:00:00");
        String response = send(json(post("/api/partner/hotels"), mapper.writeValueAsString(body)), partner.token())
            .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        return mapper.readTree(response).get("id").asLong();
    }
}
