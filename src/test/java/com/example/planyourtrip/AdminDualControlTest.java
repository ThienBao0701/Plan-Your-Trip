package com.example.planyourtrip;

import com.example.planyourtrip.model.AdminProfileAssignment;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.AdminProfileAssignmentRepository;
import com.example.planyourtrip.security.StepUpPolicy;
import com.example.planyourtrip.security.rbac.AdminProfile;
import com.example.planyourtrip.security.rbac.ScopeType;
import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;

/**
 * RBAC R6 — dual control for A16 (RBAC V1.1 §22.6, AP-5): moving a property to another company is a request one
 * platform owner submits and a different, eligible one approves; the move runs only then, in the approval's
 * transaction. Every request goes through the real HTTP stack and commits, so the row locks, the live unique key and
 * the CHECK constraints are real. Extends the R4 fixture for companies, properties and the spied partner audit
 * (used to make an execution fail mid-way).
 */
class AdminDualControlTest extends RbacTeamTestSupport {

    private static final String ADMIN_PASSWORD = "R6-dual-control-Pw1";
    private static final String REQUESTS = "/api/admin/dual-control/requests";

    @Autowired PasswordEncoder encoder;
    @Autowired AdminProfileAssignmentRepository assignments;

    record Admin(String token, Long id, String email) {}

    // ── 1, 2 · Submission ───────────────────────────────────────────────────

    @Test
    void submittingNeedsA16AFreshSessionAndAnActiveAccount() throws Exception {
        Company a = company(), b = company();
        Long place = property(a);
        String body = assign(b);

        refused(json(post(assignPath(place)), body), admin(AdminProfile.PARTNER_OPERATIONS).token(), 403,
            "PERMISSION_DENIED");
        refused(json(post(assignPath(place)), body), a.token(), 403, null);                 // a partner
        Admin owner = admin(AdminProfile.PLATFORM_OWNER);
        refused(json(post(assignPath(place)), body), stale(owner), 403, StepUpPolicy.STEP_UP_REQUIRED);
        disable(owner);
        assertEquals(401, status(json(post(assignPath(place)), body), owner.token()), "a disabled account");
        assertEquals(0, requestsFor(place), "nothing was stored");

        // the move is validated as the direct endpoint always did
        Admin requester = admin(AdminProfile.PLATFORM_OWNER);
        assertEquals(404, status(json(post("/api/admin/hotels/987654321/assign-owner"), body), requester.token()));
        assertEquals(404, status(json(post(assignPath(place)), "{\"partnerProfileId\":987654321}"), requester.token()));
        refused(json(post(assignPath(place)), "{\"partnerProfileId\":" + b.id() + ",\"reason\":\"password=hunter2\"}"),
            requester.token(), 400, "VALIDATION_FAILED");
        assertEquals(0, requestsFor(place));
    }

    @Test
    void theAssignEndpointAnswers202AndMovesNothing() throws Exception {
        Company a = company(), b = company();
        Long place = property(a);
        Admin requester = admin(AdminProfile.PLATFORM_OWNER), reviewer = admin(AdminProfile.PLATFORM_OWNER);

        JsonNode request = body(json(post(assignPath(place)),
            "{\"partnerProfileId\":" + b.id() + ",\"reason\":\"Contract signed\"}"), requester.token(), 202);
        assertEquals("PENDING", request.get("status").asText());
        assertEquals(Duration.ofHours(24), Duration.between(Instant.parse(request.get("requestedAt").asText()),
            Instant.parse(request.get("expiresAt").asText())));
        assertEquals("admin.place.owner.assign", request.get("permission").asText());
        assertEquals(a.id(), ownerOf(place), "nothing moves before an approval");
        assertEquals(0, audits("HOTEL_ASSIGN_OWNER", "PLACE", place));
        assertEquals(1, audits("DUAL_CONTROL_REQUEST", "DUAL_CONTROL_REQUEST", request.get("id").asLong()));

        // the reviewer sees exactly what will run, and whose request it is
        JsonNode reviewed = body(get(REQUESTS + "/" + request.get("id").asLong()), reviewer.token(), 200);
        JsonNode proposal = reviewed.get("proposal");
        assertEquals(place, proposal.get("placeId").asLong());
        assertEquals(a.id(), proposal.get("expectedOwnerProfileId").asLong());
        assertEquals(b.id(), proposal.get("proposedOwnerProfileId").asLong());
        assertEquals(requester.id(), reviewed.get("requestedBy").asLong());
        assertEquals("Contract signed", reviewed.get("reason").asText());
        assertFalse(reviewed.get("mine").asBoolean());
        assertTrue(body(get(REQUESTS + "/" + request.get("id").asLong()), requester.token(), 200).get("mine").asBoolean());
        assertTrue(ids(body(get(REQUESTS).param("status", "PENDING").param("size", "100"), reviewer.token(), 200))
            .contains(request.get("id").asLong()));
    }

    // ── 3 · Approval ────────────────────────────────────────────────────────

    @Test
    void anApprovalExecutesTheMoveExactlyOnceWithItsAudits() throws Exception {
        Company a = company(), b = company();
        Long place = property(a);
        Admin requester = admin(AdminProfile.PLATFORM_OWNER), approver = admin(AdminProfile.PLATFORM_OWNER);
        long id = submit(requester, place, b.id());

        JsonNode approved = body(post(REQUESTS + "/" + id + "/approve"), approver.token(), 200);
        assertEquals("APPROVED", approved.get("request").get("status").asText());
        assertEquals(approver.id(), approved.get("request").get("decidedBy").asLong());
        assertEquals(b.id(), approved.get("result").get("ownerProfileId").asLong());
        assertEquals(b.id(), ownerOf(place));
        assertEquals(1, audits("HOTEL_ASSIGN_OWNER", "PLACE", place));
        assertEquals(1, audits("DUAL_CONTROL_APPROVE", "DUAL_CONTROL_REQUEST", id));
        assertEquals(approver.id(), auditActor("HOTEL_ASSIGN_OWNER", "PLACE", place), "the approver executes");

        // a closed request never runs again, whoever asks
        refused(post(REQUESTS + "/" + id + "/approve"), admin(AdminProfile.PLATFORM_OWNER).token(), 409,
            "DUAL_CONTROL_NOT_PENDING");
        refused(json(post(REQUESTS + "/" + id + "/reject"), "{\"reason\":\"late\"}"), approver.token(), 409,
            "DUAL_CONTROL_NOT_PENDING");
        refused(post(REQUESTS + "/" + id + "/cancel"), requester.token(), 409, "DUAL_CONTROL_NOT_PENDING");
        assertEquals(1, audits("HOTEL_ASSIGN_OWNER", "PLACE", place));

        // the live key is free again: the property can be the subject of a new request
        submit(requester, place, a.id());
    }

    // ── 4, 5, 7 · Who may decide ─────────────────────────────────────────────

    @Test
    void nobodyDecidesTheirOwnRequest() throws Exception {
        Company a = company(), b = company();
        Long place = property(a);
        Admin requester = admin(AdminProfile.PLATFORM_OWNER);
        long id = submit(requester, place, b.id());

        refused(post(REQUESTS + "/" + id + "/approve"), requester.token(), 403, "SELF_APPROVAL_FORBIDDEN");
        refused(json(post(REQUESTS + "/" + id + "/reject"), "{\"reason\":\"never mind\"}"), requester.token(), 403,
            "SELF_APPROVAL_FORBIDDEN");
        assertEquals("PENDING", statusOf(id));
        assertEquals(a.id(), ownerOf(place));
    }

    @Test
    void onlyAnotherEligiblePlatformOwnerWithAFreshSessionMayDecideOrEvenSee() throws Exception {
        Company a = company(), b = company();
        Long place = property(a);
        long id = submit(admin(AdminProfile.PLATFORM_OWNER), place, b.id());

        for (AdminProfile profile : List.of(AdminProfile.PARTNER_OPERATIONS, AdminProfile.CONTENT_CATALOGUE,
                AdminProfile.BOOKING_SUPPORT, AdminProfile.TECH_SUPPORT)) {
            String t = admin(profile).token();
            refused(post(REQUESTS + "/" + id + "/approve"), t, 403, "PERMISSION_DENIED");
            refused(json(post(REQUESTS + "/" + id + "/reject"), "{\"reason\":\"no\"}"), t, 403, "PERMISSION_DENIED");
            refused(get(REQUESTS + "/" + id), t, 403, "PERMISSION_DENIED");
            refused(get(REQUESTS), t, 403, "PERMISSION_DENIED");
        }
        assertEquals(403, status(get(REQUESTS + "/" + id), a.token()), "a partner never reads the queue");
        assertEquals(403, status(get(REQUESTS), admin().token()), "an ADMIN without a profile holds nothing");

        Admin approver = admin(AdminProfile.PLATFORM_OWNER);
        refused(post(REQUESTS + "/" + id + "/approve"), stale(approver), 403, StepUpPolicy.STEP_UP_REQUIRED);
        assertEquals("PENDING", statusOf(id));
        assertEquals(a.id(), ownerOf(place));
        assertEquals(0, audits("HOTEL_ASSIGN_OWNER", "PLACE", place));
    }

    // ── 6 · Requester eligibility at execution time ─────────────────────────

    @Test
    void aRequesterWhoLostA16OrWasDisabledCannotHaveTheMoveExecuted() throws Exception {
        Company a = company(), b = company();
        Admin approver = admin(AdminProfile.PLATFORM_OWNER);

        Long first = property(a);
        Admin narrowed = admin(AdminProfile.PLATFORM_OWNER);
        long revoked = submit(narrowed, first, b.id());
        body(json(put("/api/admin/access/admins/" + narrowed.id() + "/profiles"), "{\"profiles\":[\"ANALYTICS\"]}"),
            approver.token(), 200);
        refused(post(REQUESTS + "/" + revoked + "/approve"), approver.token(), 409, "DUAL_CONTROL_STALE");
        assertEquals("STALE", statusOf(revoked));
        assertEquals("REQUESTER_NOT_ELIGIBLE", decisionReasonOf(revoked));
        assertEquals(1, audits("DUAL_CONTROL_STALE", "DUAL_CONTROL_REQUEST", revoked));
        assertEquals(a.id(), ownerOf(first));

        Long second = property(a);
        Admin leaving = admin(AdminProfile.PLATFORM_OWNER);
        long disabled = submit(leaving, second, b.id());
        disable(leaving);
        refused(post(REQUESTS + "/" + disabled + "/approve"), approver.token(), 409, "DUAL_CONTROL_STALE");
        assertEquals("REQUESTER_NOT_ELIGIBLE", decisionReasonOf(disabled));
        assertEquals(a.id(), ownerOf(second));
        assertEquals(0, audits("HOTEL_ASSIGN_OWNER", "PLACE", second));
    }

    // ── 8 · Reject and cancel ───────────────────────────────────────────────

    @Test
    void rejectionAndCancellationAreDistinctTerminalStates() throws Exception {
        Company a = company(), b = company();
        Long place = property(a);
        Admin requester = admin(AdminProfile.PLATFORM_OWNER), other = admin(AdminProfile.PLATFORM_OWNER);

        long rejected = submit(requester, place, b.id());
        refused(json(post(REQUESTS + "/" + rejected + "/reject"), "{\"reason\":\"  \"}"), other.token(), 400, null);
        JsonNode r = body(json(post(REQUESTS + "/" + rejected + "/reject"), "{\"reason\":\"Ownership disputed\"}"),
            other.token(), 200);
        assertEquals("REJECTED", r.get("status").asText());
        assertEquals("Ownership disputed", r.get("decisionReason").asText());
        assertEquals(other.id(), r.get("decidedBy").asLong());
        assertEquals(1, audits("DUAL_CONTROL_REJECT", "DUAL_CONTROL_REQUEST", rejected));
        assertEquals(0, audits("DUAL_CONTROL_CANCEL", "DUAL_CONTROL_REQUEST", rejected));

        long cancelled = submit(requester, place, b.id());
        refused(post(REQUESTS + "/" + cancelled + "/cancel"), other.token(), 403, "PERMISSION_DENIED");
        JsonNode c = body(post(REQUESTS + "/" + cancelled + "/cancel"), requester.token(), 200);
        assertEquals("CANCELLED", c.get("status").asText());
        assertEquals(1, audits("DUAL_CONTROL_CANCEL", "DUAL_CONTROL_REQUEST", cancelled));
        assertEquals(0, audits("DUAL_CONTROL_REJECT", "DUAL_CONTROL_REQUEST", cancelled));
        refused(post(REQUESTS + "/" + cancelled + "/approve"), other.token(), 409, "DUAL_CONTROL_NOT_PENDING");

        assertEquals(a.id(), ownerOf(place));
        assertEquals(0, audits("HOTEL_ASSIGN_OWNER", "PLACE", place));
        assertTrue(ids(body(get(REQUESTS).param("status", "REJECTED").param("size", "100"), other.token(), 200))
            .contains(rejected));
    }

    // ── 9 · Expiry ──────────────────────────────────────────────────────────

    @Test
    void anExpiredRequestNeverRunsAndItsExpiryIsPersistedAndAudited() throws Exception {
        Company a = company(), b = company();
        Long place = property(a);
        Admin requester = admin(AdminProfile.PLATFORM_OWNER), approver = admin(AdminProfile.PLATFORM_OWNER);
        long id = submit(requester, place, b.id());
        overdue(id);

        // readers see it as expired before anyone writes it
        assertEquals("EXPIRED", body(get(REQUESTS + "/" + id), approver.token(), 200).get("status").asText());
        assertTrue(ids(body(get(REQUESTS).param("status", "EXPIRED").param("size", "100"), approver.token(), 200))
            .contains(id));
        assertFalse(ids(body(get(REQUESTS).param("status", "PENDING").param("size", "100"), approver.token(), 200))
            .contains(id));
        assertEquals("PENDING", statusOf(id), "reading never writes");

        refused(post(REQUESTS + "/" + id + "/approve"), approver.token(), 409, "DUAL_CONTROL_EXPIRED");
        assertEquals("EXPIRED", statusOf(id), "the expiry survived the 409");
        assertEquals(1, audits("DUAL_CONTROL_EXPIRE", "DUAL_CONTROL_REQUEST", id));
        assertNull(auditActor("DUAL_CONTROL_EXPIRE", "DUAL_CONTROL_REQUEST", id), "a system event");
        assertEquals(a.id(), ownerOf(place));
        refused(post(REQUESTS + "/" + id + "/approve"), approver.token(), 409, "DUAL_CONTROL_NOT_PENDING");
        assertEquals(1, audits("DUAL_CONTROL_EXPIRE", "DUAL_CONTROL_REQUEST", id), "expired once");

        // an overdue request does not block a new one: submitting closes it first
        long overdueAgain = submit(requester, place, b.id());
        overdue(overdueAgain);
        long fresh = submit(requester, place, b.id());
        assertEquals("EXPIRED", statusOf(overdueAgain));
        assertEquals(1, audits("DUAL_CONTROL_EXPIRE", "DUAL_CONTROL_REQUEST", overdueAgain));
        assertEquals("PENDING", statusOf(fresh));
    }

    // ── 10, 11 · Stale target, immutable payload ─────────────────────────────

    @Test
    void aChangedOwnerOrAnUnapprovedCompanyMakesTheRequestStale() throws Exception {
        Company a = company(), b = company(), c = company();
        Admin requester = admin(AdminProfile.PLATFORM_OWNER), approver = admin(AdminProfile.PLATFORM_OWNER);

        Long moved = property(a);
        long ownerChanged = submit(requester, moved, b.id());
        jdbc.update("UPDATE places SET owner_partner_profile_id = ? WHERE id = ?", c.id(), moved);
        refused(post(REQUESTS + "/" + ownerChanged + "/approve"), approver.token(), 409, "DUAL_CONTROL_STALE");
        assertEquals("STALE", statusOf(ownerChanged));
        assertEquals("OWNER_CHANGED", decisionReasonOf(ownerChanged));
        assertEquals(1, audits("DUAL_CONTROL_STALE", "DUAL_CONTROL_REQUEST", ownerChanged));
        assertEquals(c.id(), ownerOf(moved), "the approval moved nothing");

        Long kept = property(a);
        long suspended = submit(requester, kept, b.id());
        send(json(post("/api/admin/partners/" + b.id() + "/suspend"), "{\"reason\":\"review\"}"), adminToken())
            .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isOk());
        refused(post(REQUESTS + "/" + suspended + "/approve"), approver.token(), 409, "DUAL_CONTROL_STALE");
        assertEquals("PROPOSED_OWNER_NOT_APPROVED", decisionReasonOf(suspended));
        assertEquals(a.id(), ownerOf(kept));
        assertEquals(0, audits("HOTEL_ASSIGN_OWNER", "PLACE", kept));
    }

    @Test
    void theApproverCannotChangeWhatRunsAndAStoredPayloadIsCheckedAgainstItsDigest() throws Exception {
        Company a = company(), b = company(), c = company();
        Admin requester = admin(AdminProfile.PLATFORM_OWNER), approver = admin(AdminProfile.PLATFORM_OWNER);

        Long place = property(a), other = property(a);
        long id = submit(requester, place, b.id());
        JsonNode approved = body(json(post(REQUESTS + "/" + id + "/approve"),
            "{\"partnerProfileId\":" + c.id() + ",\"placeId\":" + other + ",\"proposedOwnerProfileId\":" + c.id() + "}"),
            approver.token(), 200);
        assertEquals(b.id(), approved.get("result").get("ownerProfileId").asLong(), "the stored proposal ran");
        assertEquals(b.id(), ownerOf(place));
        assertEquals(a.id(), ownerOf(other), "the body named another place; it was ignored");

        Long tampered = property(a);
        long forged = submit(requester, tampered, b.id());
        jdbc.update("UPDATE admin_dual_control_requests SET payload = REPLACE(payload, ?, ?) WHERE id = ?",
            "\"proposedOwnerProfileId\":" + b.id(), "\"proposedOwnerProfileId\":" + c.id(), forged);
        refused(post(REQUESTS + "/" + forged + "/approve"), approver.token(), 409, "DUAL_CONTROL_STALE");
        assertEquals("PAYLOAD_DIGEST_MISMATCH", decisionReasonOf(forged));
        assertEquals(a.id(), ownerOf(tampered));
    }

    // ── 12, 13, 14 · Duplicates and races ────────────────────────────────────

    @Test
    void onlyOneOpenRequestPerPropertyEvenWhenSubmissionsRace() throws Exception {
        Company a = company(), b = company(), c = company();
        Admin requester = admin(AdminProfile.PLATFORM_OWNER), other = admin(AdminProfile.PLATFORM_OWNER);

        Long place = property(a);
        submit(requester, place, b.id());
        refused(json(post(assignPath(place)), assign(c)), other.token(), 409, "DUAL_CONTROL_PENDING_EXISTS");
        refused(json(post(assignPath(place)), assign(b)), requester.token(), 409, "DUAL_CONTROL_PENDING_EXISTS");

        Long raced = property(a);
        List<Integer> results = concurrently(
            () -> status(json(post(assignPath(raced)), assign(b)), requester.token()),
            () -> status(json(post(assignPath(raced)), assign(c)), other.token()));
        assertEquals(1, results.stream().filter(s -> s == 202).count(), results.toString());
        assertEquals(1, results.stream().filter(s -> s == 409).count(), results.toString());
        assertEquals(1, requestsFor(raced));
    }

    @Test
    void competingApprovalsExecuteTheMoveOnce() throws Exception {
        Company a = company(), b = company();
        Long place = property(a);
        long id = submit(admin(AdminProfile.PLATFORM_OWNER), place, b.id());
        Admin first = admin(AdminProfile.PLATFORM_OWNER), second = admin(AdminProfile.PLATFORM_OWNER);

        List<Integer> results = concurrently(
            () -> status(post(REQUESTS + "/" + id + "/approve"), first.token()),
            () -> status(post(REQUESTS + "/" + id + "/approve"), second.token()));
        assertEquals(1, results.stream().filter(s -> s == 200).count(), results.toString());
        assertEquals(1, results.stream().filter(s -> s == 409).count(), results.toString());
        assertEquals(b.id(), ownerOf(place));
        assertEquals(1, audits("HOTEL_ASSIGN_OWNER", "PLACE", place));
        assertEquals(1, audits("DUAL_CONTROL_APPROVE", "DUAL_CONTROL_REQUEST", id));
    }

    @Test
    void anApprovalRacingTheRequestersCancellationEndsInOneTerminalState() throws Exception {
        Company a = company(), b = company();
        Long place = property(a);
        Admin requester = admin(AdminProfile.PLATFORM_OWNER), approver = admin(AdminProfile.PLATFORM_OWNER);
        long id = submit(requester, place, b.id());

        List<Integer> results = concurrently(
            () -> status(post(REQUESTS + "/" + id + "/approve"), approver.token()),
            () -> status(post(REQUESTS + "/" + id + "/cancel"), requester.token()));
        assertEquals(1, results.stream().filter(s -> s == 200).count(), results.toString());
        assertEquals(1, results.stream().filter(s -> s == 409).count(), results.toString());
        String status = statusOf(id);
        if (status.equals("APPROVED")) {
            assertEquals(b.id(), ownerOf(place));
            assertEquals(1, audits("HOTEL_ASSIGN_OWNER", "PLACE", place));
            assertEquals(0, audits("DUAL_CONTROL_CANCEL", "DUAL_CONTROL_REQUEST", id));
        } else {
            assertEquals("CANCELLED", status);
            assertEquals(a.id(), ownerOf(place));
            assertEquals(0, audits("HOTEL_ASSIGN_OWNER", "PLACE", place));
            assertEquals(0, audits("DUAL_CONTROL_APPROVE", "DUAL_CONTROL_REQUEST", id));
        }
    }

    // ── 15 · A failed execution rolls everything back ────────────────────────

    @Test
    void aFailedMoveRollsBackTheApprovalAndItsAudits() throws Exception {
        Company a = company(), b = company();
        Long place = property(a);
        Member frontDesk = member(a, "FRONT_DESK", ScopeType.PROPERTY, place);   // PA-4 revokes this grant on a move
        Admin requester = admin(AdminProfile.PLATFORM_OWNER), approver = admin(AdminProfile.PLATFORM_OWNER);
        long id = submit(requester, place, b.id());
        long grantsBefore = grantRepo.count();

        Mockito.doThrow(new IllegalStateException("audit store unavailable")).when(activityLog)
            .audit(any(), any(), eq("TEAM_MEMBER_SCOPE_REVOKED"), any(), any(), any(), any(), any(), any());
        try {
            assertEquals(500, status(post(REQUESTS + "/" + id + "/approve"), approver.token()));
        } finally {
            Mockito.reset(activityLog);
        }
        assertEquals("PENDING", statusOf(id), "no approval without its move");
        assertEquals(a.id(), ownerOf(place), "no partial move");
        assertEquals(grantsBefore, grantRepo.count(), "the PA-4 grant revocation rolled back too");
        assertEquals(0, audits("HOTEL_ASSIGN_OWNER", "PLACE", place));
        assertEquals(0, audits("DUAL_CONTROL_APPROVE", "DUAL_CONTROL_REQUEST", id));

        // still pending, so a retry once the failure is gone succeeds
        body(post(REQUESTS + "/" + id + "/approve"), approver.token(), 200);
        assertEquals(b.id(), ownerOf(place));
        assertNotNull(frontDesk);
    }

    // ── Helpers ─────────────────────────────────────────────────────────────

    /**
     * An approved company of this test. Named and placed apart from the shared R4 fixtures ("R4 Co …" in Vũng Tàu):
     * other suites search the newest partners and places by name or address prefix in the same in-memory database,
     * so this test's many rows must not crowd their seed rows off a first page.
     */
    private Company company() throws Exception {
        String email = registerUser();
        String token = login(email);
        Long id = body(json(post("/api/partner/profile"), """
            {"businessName":"DualCtl-%s","businessType":"HOTEL","representativeName":"DualCtl Owner",
             "phone":"0901234567","email":"contact@example.com","address":"8 Tran Phu, Hai Chau"}
            """.formatted(UUID.randomUUID().toString().substring(0, 8))), token, 200).get("id").asLong();
        send(post("/api/partner/profile/submit"), token)
            .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isOk());
        send(post("/api/admin/partners/" + id + "/approve"), adminToken())
            .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isOk());
        Long userId = userRepo.findByEmail(email).orElseThrow().getId();
        Long ownerRow = teamMemberRepo.findByPartnerProfileIdAndUserId(id, userId).orElseThrow().getId();
        return new Company(login(email), id, userId, email, ownerRow);
    }

    /** A draft property of {@code company}, created by its owner. */
    private Long property(Company company) throws Exception {
        java.util.Map<String, Object> body = new java.util.LinkedHashMap<>();
        body.put("name", "DualCtl Stay " + UUID.randomUUID().toString().substring(0, 8));
        body.put("categoryId", categoryRepo.findBySlug("accommodation").orElseThrow().getId());
        body.put("subcategoryId", categoryRepo.findBySlug("hotel").orElseThrow().getId());
        body.put("administrativeUnitId", locationRepo.findByCode("DNG").orElseThrow().getId());
        body.put("address", "8 Tran Phu, Hai Chau");
        body.put("starRating", 3);
        body.put("checkIn", "14:00:00");
        body.put("checkOut", "12:00:00");
        return body(json(post("/api/partner/hotels"), mapper.writeValueAsString(body)), company.token(), 201)
            .get("id").asLong();
    }

    /** A fresh ADMIN account holding exactly {@code profiles}, signed in now (a step-up fresh session). */
    private Admin admin(AdminProfile... profiles) throws Exception {
        User u = new User();
        u.setFullName("R6 Dual Control Admin");
        u.setEmail("r6-dc-" + UUID.randomUUID().toString().substring(0, 12) + "@test.com");
        u.setPasswordHash(encoder.encode(ADMIN_PASSWORD));
        u.setRole("ADMIN");
        u.setEmailVerifiedAt(Instant.now());
        userRepo.save(u);
        for (AdminProfile profile : profiles) {
            assignments.save(AdminProfileAssignment.systemGrant(u, profile, Instant.now()));
        }
        return new Admin(login(u.getEmail(), ADMIN_PASSWORD), u.getId(), u.getEmail());
    }

    /** A valid token of {@code admin} issued just outside the 15-minute step-up window. */
    private String stale(Admin admin) {
        User u = userRepo.findById(admin.id()).orElseThrow();
        return jwt.createToken(u.getId(), u.getEmail(), u.getTokenVersion(),
            Instant.now().minus(StepUpPolicy.FRESHNESS).minusSeconds(60));
    }

    private void disable(Admin admin) {
        User u = userRepo.findById(admin.id()).orElseThrow();
        u.setEnabled(false);
        userRepo.save(u);
    }

    private long submit(Admin requester, Long place, Long partnerProfileId) throws Exception {
        return body(json(post(assignPath(place)), "{\"partnerProfileId\":" + partnerProfileId + "}"),
            requester.token(), 202).get("id").asLong();
    }

    private static String assignPath(Long place) {
        return "/api/admin/hotels/" + place + "/assign-owner";
    }

    private static String assign(Company company) {
        return "{\"partnerProfileId\":" + company.id() + "}";
    }

    private void overdue(long requestId) {
        jdbc.update("UPDATE admin_dual_control_requests SET expires_at = ? WHERE id = ?",
            java.sql.Timestamp.from(Instant.now().minusSeconds(60)), requestId);
    }

    private int status(MockHttpServletRequestBuilder request, String token) throws Exception {
        return send(request, token).andReturn().getResponse().getStatus();
    }

    /** Asserts the status and, when given, the error code; the probe's own values are never echoed. */
    private void refused(MockHttpServletRequestBuilder request, String token, int status, String code)
            throws Exception {
        MvcResult r = send(request, token).andReturn();
        assertEquals(status, r.getResponse().getStatus(), r.getResponse().getContentAsString());
        if (code != null) assertEquals(code, mapper.readTree(r.getResponse().getContentAsString()).get("code").asText());
    }

    private static List<Long> ids(JsonNode page) {
        List<Long> ids = new java.util.ArrayList<>();
        page.get("content").forEach(n -> ids.add(n.get("id").asLong()));
        return ids;
    }

    private Long ownerOf(Long placeId) {
        return jdbc.queryForObject("SELECT owner_partner_profile_id FROM places WHERE id = ?", Long.class, placeId);
    }

    private String statusOf(long requestId) {
        return jdbc.queryForObject("SELECT status FROM admin_dual_control_requests WHERE id = ?", String.class,
            requestId);
    }

    private String decisionReasonOf(long requestId) {
        return jdbc.queryForObject("SELECT decision_reason FROM admin_dual_control_requests WHERE id = ?",
            String.class, requestId);
    }

    private int requestsFor(Long placeId) {
        return jdbc.queryForObject("SELECT COUNT(*) FROM admin_dual_control_requests WHERE target_id = ?",
            Integer.class, placeId);
    }

    private int audits(String action, String targetType, Long targetId) {
        return jdbc.queryForObject("SELECT COUNT(*) FROM admin_activity_logs WHERE action = ? AND target_type = ? "
            + "AND target_id = ?", Integer.class, action, targetType, targetId);
    }

    private Long auditActor(String action, String targetType, Long targetId) {
        return jdbc.queryForObject("SELECT actor_user_id FROM admin_activity_logs WHERE action = ? AND target_type = ? "
            + "AND target_id = ?", Long.class, action, targetType, targetId);
    }
}
