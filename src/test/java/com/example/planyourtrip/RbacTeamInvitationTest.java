package com.example.planyourtrip;

import com.example.planyourtrip.model.PartnerInvitation;
import com.example.planyourtrip.model.PartnerMembershipStatus;
import com.example.planyourtrip.model.PartnerTeamMember;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.security.StepUpPolicy;
import com.example.planyourtrip.security.rbac.ScopeType;
import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mockito;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Callable;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * RBAC R4 — the partner invitation lifecycle (RBAC V1.1 §13, §14, §16 PA-4, §22, §26 E16–E21, §31 Q16).
 */
@ExtendWith(OutputCaptureExtension.class)
class RbacTeamInvitationTest extends RbacTeamTestSupport {

    // ═══════════════════════════════════════════════════════════════════════
    // Create, accept, decline (§13.1, §14)
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void anInvitationIsCreatedSentAfterCommitAndAcceptedIntoANewMembership() throws Exception {
        Company c = approvedCompany();
        String email = partnerAccount();

        invite(c.token(), email, "FRONT_DESK", "COMPANY:" + c.id())
            .andExpect(status().isAccepted())
            .andExpect(jsonPath("$.status").value("REQUESTED"))
            .andExpect(jsonPath("$.id").doesNotExist());
        JsonNode listed = invitationOf(c, email);
        assertEquals("PENDING", listed.get("status").asText());
        assertEquals("SENT", listed.get("deliveryStatus").asText());
        assertEquals(0, listed.get("resendCount").asInt());
        // 7-day lifetime, measured on the server's own timestamps (both set from one instant at creation)
        Instant created = Instant.parse(listed.get("createdAt").asText());
        Instant expires = Instant.parse(listed.get("expiresAt").asText());
        assertEquals(Duration.ofDays(7), Duration.between(created, expires), created + " -> " + expires);

        String token = lastToken(email);
        String memberToken = login(email);
        send(get("/api/me/partner-invitations"), memberToken).andExpect(status().isOk())
            .andExpect(jsonPath("$[0].companyId").value(c.id()))
            .andExpect(jsonPath("$[0].grants[0].role").value("FRONT_DESK"))
            .andExpect(jsonPath("$[0].grants[0].scopeType").value("COMPANY"));

        JsonNode doc = mapper.readTree(accept(memberToken, token)
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertEquals(c.id().longValue(), doc.get("workspace").get("companyId").asLong());
        assertEquals("ACTIVE", doc.get("membership").get("status").asText());
        assertTrue(doc.get("permissions").get("company").toString().contains("partner.booking.arrival.operate"));

        Long userId = userRepo.findByEmail(email).orElseThrow().getId();
        PartnerTeamMember row = teamMemberRepo.findByPartnerProfileIdAndUserId(c.id(), userId).orElseThrow();
        assertEquals(List.of("FRONT_DESK@COMPANY:" + c.id()), grants(row.getId()));
        assertEquals("PARTNER", userRepo.findById(userId).orElseThrow().getRole(), "no system role is written (I1)");
        send(get("/api/partner/bookings"), memberToken).andExpect(status().isOk());
        assertEquals("ACCEPTED", invitationOf(c, email).get("status").asText());
        assertTrue(send(get("/api/me/partner-invitations"), memberToken).andReturn().getResponse()
            .getContentAsString().equals("[]"), "an accepted invitation is no longer offered");

        // one-time: the same link never works twice (§14 step 1)
        accept(memberToken, token).andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.code").value("INVITATION_INVALID"));
        // audit and owner notification
        assertTrue(actions(c.id()).containsAll(List.of("TEAM_MEMBER_INVITED", "TEAM_INVITATION_ACCEPTED")));
        Map<String, Object> accepted = auditRows(c.id(), "TEAM_INVITATION_ACCEPTED").get(0);
        assertEquals(email, accepted.get("actor_email"));
        assertEquals("FRONT_DESK@COMPANY:" + c.id() + "|PENDING", accepted.get("before_state"));
        assertTrue(titles(c.token()).containsAll(List.of("Team member invited", "Invitation accepted")));
        assertTrue(titles(memberToken).contains("Invitation accepted"), "the member is told too (O-8)");
    }

    @Test
    void invalidInputIsRefusedBeforeAnythingIsCreated() throws Exception {
        Company c = approvedCompany();
        Company other = approvedCompany();
        Long foreign = createProperty(other);
        long before = invitationRepo.count();

        send(json(post("/api/partner/team/invitations"), "{\"grants\":[{\"role\":\"VIEWER\",\"scope\":\"COMPANY:" + c.id() + "\"}]}"), c.token())
            .andExpect(status().isBadRequest());
        send(json(post("/api/partner/team/invitations"), invitationBody("not-an-email", "VIEWER", "COMPANY:" + c.id())), c.token())
            .andExpect(status().isBadRequest());
        send(json(post("/api/partner/team/invitations"), "{\"email\":\"" + uniqueEmail("x") + "\",\"grants\":[]}"), c.token())
            .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
        invite(c.token(), uniqueEmail("x"), "SUPER_OWNER", "COMPANY:" + c.id()).andExpect(status().isBadRequest());
        for (String scope : List.of("company:" + c.id(), "ROOM:1", "PROPERTY:0", "PROPERTY:abc", "")) {
            invite(c.token(), uniqueEmail("x"), "VIEWER", scope)
                .andExpect(status().isUnprocessableEntity()).andExpect(jsonPath("$.code").value("SCOPE_INVALID"));
        }
        // roles outside their scope types (§11.3) and scopes of another company (E9)
        invite(c.token(), uniqueEmail("x"), "HOUSEKEEPING", "COMPANY:" + c.id())
            .andExpect(status().isUnprocessableEntity()).andExpect(jsonPath("$.code").value("SCOPE_INVALID"));
        invite(c.token(), uniqueEmail("x"), "FINANCE", "PROPERTY:" + createProperty(c))
            .andExpect(status().isUnprocessableEntity()).andExpect(jsonPath("$.code").value("SCOPE_INVALID"));
        invite(c.token(), uniqueEmail("x"), "VIEWER", "PROPERTY:" + foreign)
            .andExpect(status().isUnprocessableEntity()).andExpect(jsonPath("$.code").value("SCOPE_INVALID"));
        invite(c.token(), uniqueEmail("x"), "VIEWER", "COMPANY:" + other.id())
            .andExpect(status().isUnprocessableEntity()).andExpect(jsonPath("$.code").value("SCOPE_INVALID"));
        assertEquals(before, invitationRepo.count(), "nothing was created");
    }

    @Test
    void anyoneHoldingTheLinkMayDeclineIt() throws Exception {
        Company c = approvedCompany();
        String email = partnerAccount();
        invite(c.token(), email, "VIEWER", "COMPANY:" + c.id()).andExpect(status().isAccepted());
        String token = lastToken(email);

        String stranger = login(registerUser()); // a traveller account: decline needs no Partner account (AC-1)
        send(json(post("/api/me/partner-invitations/decline"), "{\"token\":\"" + token + "\"}"), stranger)
            .andExpect(status().isNoContent());
        assertEquals("DECLINED", invitationOf(c, email).get("status").asText());
        accept(login(email), token).andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.code").value("INVITATION_INVALID"));
        assertTrue(actions(c.id()).contains("TEAM_INVITATION_DECLINED"));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Token lifecycle: expiry, revocation, supersession, rotation (§13.2, §13.3, IN-6–IN-8)
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void anExpiredInvitationCannotBeAcceptedOrResent() throws Exception {
        Company c = approvedCompany();
        String email = partnerAccount();
        invite(c.token(), email, "VIEWER", "COMPANY:" + c.id()).andExpect(status().isAccepted());
        String token = lastToken(email);
        Long id = invitationOf(c, email).get("id").asLong();
        jdbc.update("update partner_invitations set expires_at = ? where id = ?",
            Timestamp.from(Instant.now().minusSeconds(1)), id);

        accept(login(email), token).andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.code").value("INVITATION_EXPIRED"));
        assertEquals("EXPIRED", invitationOf(c, email).get("status").asText());
        cooldownPassed(id);
        send(post("/api/partner/team/invitations/" + id + "/resend"), c.token())
            .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("INVITATION_NOT_PENDING"));
        // a new invitation replaces it
        invite(c.token(), email, "VIEWER", "COMPANY:" + c.id()).andExpect(status().isAccepted());
        accept(login(email), lastToken(email)).andExpect(status().isOk());
    }

    @Test
    void aRevokedInvitationCanNeverBeAccepted() throws Exception {
        Company c = approvedCompany();
        String email = partnerAccount();
        invite(c.token(), email, "VIEWER", "COMPANY:" + c.id()).andExpect(status().isAccepted());
        String token = lastToken(email);
        Long id = invitationOf(c, email).get("id").asLong();

        send(json(delete("/api/partner/team/invitations/" + id), "{\"reason\":\"sent by mistake\"}"), c.token())
            .andExpect(status().isNoContent());
        accept(login(email), token).andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.code").value("INVITATION_INVALID"));
        send(delete("/api/partner/team/invitations/" + id), c.token())
            .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("INVITATION_NOT_PENDING"));
        Map<String, Object> row = auditRows(c.id(), "TEAM_INVITATION_REVOKED").get(0);
        assertEquals("sent by mistake", row.get("reason"));
        assertEquals(c.email(), row.get("actor_email"));
        assertTrue(titles(c.token()).contains("Team invitation revoked"));
    }

    @Test
    void aNewInvitationSupersedesThePendingOneAndItsLink() throws Exception {
        Company c = approvedCompany();
        String email = partnerAccount();
        invite(c.token(), email, "VIEWER", "COMPANY:" + c.id()).andExpect(status().isAccepted());
        String first = lastToken(email);
        Long firstId = invitationOf(c, email).get("id").asLong();
        cooldownPassed(firstId);

        invite(c.token(), email, "FRONT_DESK", "COMPANY:" + c.id()).andExpect(status().isAccepted());
        PartnerInvitation old = invitationRepo.findById(firstId).orElseThrow();
        assertEquals("REVOKED", old.getStatus().name());
        assertEquals("SUPERSEDED", old.getStatusReason());
        accept(login(email), first).andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.code").value("INVITATION_INVALID"));
        accept(login(email), lastToken(email)).andExpect(status().isOk());
        Long userId = userRepo.findByEmail(email).orElseThrow().getId();
        assertEquals(List.of("FRONT_DESK@COMPANY:" + c.id()),
            grants(teamMemberRepo.findByPartnerProfileIdAndUserId(c.id(), userId).orElseThrow().getId()));
    }

    @Test
    void aResendRotatesTheTokenAndIsLimited() throws Exception {
        Company c = approvedCompany();
        String email = partnerAccount();
        invite(c.token(), email, "VIEWER", "COMPANY:" + c.id()).andExpect(status().isAccepted());
        String first = lastToken(email);
        Long id = invitationOf(c, email).get("id").asLong();

        // 60 s cooldown, for a resend and for a second invitation to the address (429)
        send(post("/api/partner/team/invitations/" + id + "/resend"), c.token())
            .andExpect(status().isTooManyRequests()).andExpect(jsonPath("$.code").value("INVITATION_RATE_LIMITED"));
        invite(c.token(), email, "VIEWER", "COMPANY:" + c.id())
            .andExpect(status().isTooManyRequests()).andExpect(jsonPath("$.code").value("INVITATION_RATE_LIMITED"));

        cooldownPassed(id);
        send(post("/api/partner/team/invitations/" + id + "/resend"), c.token())
            .andExpect(status().isAccepted()).andExpect(jsonPath("$.status").value("REQUESTED"));
        String second = lastToken(email);
        assertNotEquals(first, second, "the token rotates");
        JsonNode listed = invitationOf(c, email);
        assertEquals(1, listed.get("resendCount").asInt());
        assertEquals("SENT", listed.get("deliveryStatus").asText());
        assertTrue(actions(c.id()).contains("TEAM_INVITATION_RESENT"));
        assertTrue(titles(c.token()).contains("Team invitation resent"));

        // at most 5 resends (§31 Q16)
        jdbc.update("update partner_invitations set resend_count = 5 where id = ?", id);
        cooldownPassed(id);
        send(post("/api/partner/team/invitations/" + id + "/resend"), c.token())
            .andExpect(status().isTooManyRequests()).andExpect(jsonPath("$.code").value("INVITATION_RATE_LIMITED"));

        // the old link stopped working the moment it was replaced; the current one works once
        String memberToken = login(email);
        accept(memberToken, first).andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("INVITATION_INVALID"));
        accept(memberToken, second).andExpect(status().isOk());
    }

    @Test
    void aCompanyHoldsAtMostTwentyPendingInvitations() throws Exception {
        Company c = approvedCompany();
        for (int i = 0; i < 20; i++) {
            invite(c.token(), uniqueEmail("bulk"), "VIEWER", "COMPANY:" + c.id()).andExpect(status().isAccepted());
        }
        invite(c.token(), uniqueEmail("bulk"), "VIEWER", "COMPANY:" + c.id())
            .andExpect(status().isTooManyRequests()).andExpect(jsonPath("$.code").value("INVITATION_RATE_LIMITED"));
        // revoking one frees a slot
        Long one = body(get("/api/partner/team/invitations"), c.token(), 200).get(0).get("id").asLong();
        send(delete("/api/partner/team/invitations/" + one), c.token()).andExpect(status().isNoContent());
        invite(c.token(), uniqueEmail("bulk"), "VIEWER", "COMPANY:" + c.id()).andExpect(status().isAccepted());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Email availability and delivery (IN-5, §13.1 steps 5 and 7)
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void anUnavailableEmailServiceAnswers503AndCreatesNothing() throws Exception {
        Company c = approvedCompany();
        long before = invitationRepo.count();
        List<String> trailBefore = actions(c.id());
        Mockito.doReturn(false).when(emailSender).isAvailable();
        try {
            invite(c.token(), uniqueEmail("x"), "VIEWER", "COMPANY:" + c.id())
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.code").value("EMAIL_DELIVERY_UNAVAILABLE"));
            send(json(post("/api/partner/team"), "{\"email\":\"" + uniqueEmail("x") + "\",\"role\":\"VIEWER\"}"), c.token())
                .andExpect(status().isServiceUnavailable());
        } finally {
            Mockito.reset(emailSender);
        }
        assertEquals(before, invitationRepo.count());
        assertEquals(trailBefore, actions(c.id()), "nothing audited, nothing notified");
    }

    @Test
    void aFailedSendLeavesTheInvitationPendingToBeResent() throws Exception {
        Company c = approvedCompany();
        String email = partnerAccount();
        Mockito.doThrow(new IllegalStateException("smtp down")).when(emailSender).send(any());
        try {
            invite(c.token(), email, "VIEWER", "COMPANY:" + c.id()).andExpect(status().isAccepted());
        } finally {
            Mockito.reset(emailSender);
        }
        JsonNode listed = invitationOf(c, email);
        assertEquals("PENDING", listed.get("status").asText());
        assertEquals("FAILED", listed.get("deliveryStatus").asText(), "no pretending the email went out");

        cooldownPassed(listed.get("id").asLong());
        send(post("/api/partner/team/invitations/" + listed.get("id").asLong() + "/resend"), c.token())
            .andExpect(status().isAccepted());
        assertEquals("SENT", invitationOf(c, email).get("deliveryStatus").asText());
        accept(login(email), lastToken(email)).andExpect(status().isOk());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Token hygiene (IN-7, I23) and no enumeration (IN-1, IN-3)
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void onlyTheTokensHashIsStoredAndTheTokenIsNeverReturnedOrLogged(CapturedOutput output) throws Exception {
        Company c = approvedCompany();
        String email = partnerAccount();
        // replace delivery so the development sender does not print the link (its documented local mechanism)
        List<String> links = new ArrayList<>();
        Mockito.doAnswer(call -> { links.add(((com.example.planyourtrip.service.mail.AccountEmail) call.getArgument(0)).actionUrl()); return null; })
            .when(emailSender).send(any());
        String token;
        String listed;
        String mine;
        try {
            String created = invite(c.token(), email, "VIEWER", "COMPANY:" + c.id())
                .andExpect(status().isAccepted()).andReturn().getResponse().getContentAsString();
            String link = links.get(links.size() - 1);
            assertTrue(link.contains("/accept-invitation#token="), "the token travels in the fragment, not a query");
            assertFalse(link.contains("?"));
            token = link.substring(link.indexOf("#token=") + 7);
            listed = send(get("/api/partner/team/invitations"), c.token()).andReturn().getResponse().getContentAsString();
            mine = send(get("/api/me/partner-invitations"), login(email)).andReturn().getResponse().getContentAsString();
            assertFalse(created.contains(token));
        } finally {
            Mockito.reset(emailSender);
        }
        String hash = HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.UTF_8)));
        Long id = invitationOf(c, email).get("id").asLong();
        assertEquals(hash, invitationRepo.findById(id).orElseThrow().getTokenHash());
        assertEquals(0, jdbc.queryForObject("select count(*) from partner_invitations where token_hash = ?", Integer.class, token));
        for (String response : List.of(listed, mine)) {
            assertFalse(response.contains(token), "token in a response");
            assertFalse(response.contains(hash), "hash in a response");
            assertFalse(response.contains("tokenHash"));
        }
        assertFalse(output.getAll().contains(token), "the token reached the log");
        String audit = String.valueOf(jdbc.queryForList("select * from partner_activity_logs where partner_profile_id = ?", c.id()));
        assertFalse(audit.contains(token) || audit.contains(hash), "the token reached the audit trail");
        // the accept endpoint takes the token only in its body
        send(post("/api/me/partner-invitations/accept?token=" + token), login(email)).andExpect(status().isBadRequest());
        accept(login(email), token).andExpect(status().isOk());
    }

    @Test
    void theAnswerNeverRevealsWhoTheAddressBelongsTo() throws Exception {
        Company c = approvedCompany();
        Company other = approvedCompany();
        Member memberElsewhere = member(other, "VIEWER");
        String traveller = registerUser();

        List<String> bodies = new ArrayList<>();
        for (String email : List.of(uniqueEmail("nobody"), traveller, "admin@planyourtrip.com", other.email(),
                memberElsewhere.email(), partnerAccount())) {
            bodies.add(invite(c.token(), email, "VIEWER", "COMPANY:" + c.id())
                .andExpect(status().isAccepted()).andReturn().getResponse().getContentAsString());
        }
        assertEquals(1, bodies.stream().distinct().count(), "one uniform body: " + bodies);
        assertEquals("USER", userRepo.findByEmail(traveller).orElseThrow().getRole(), "inviting never promotes (IN-2)");
        assertEquals("ADMIN", userRepo.findByEmail("admin@planyourtrip.com").orElseThrow().getRole());
    }

    @Test
    void anExistingMemberIsAConflictOnlyForWhoCanSeeThem() throws Exception {
        Company c = approvedCompany();
        Long p1 = createProperty(c);
        Member visible = member(c, "VIEWER");
        Member outside = member(c, "VIEWER"); // company-wide: outside a property manager's view
        Member manager = member(c, "MANAGER", ScopeType.PROPERTY, p1);
        Member inside = member(c, "FRONT_DESK", ScopeType.PROPERTY, p1);

        invite(c.token(), visible.email(), "VIEWER", "COMPANY:" + c.id())
            .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("ALREADY_MEMBER"));
        invite(manager.token(), inside.email(), "VIEWER", "PROPERTY:" + p1)
            .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("ALREADY_MEMBER"));
        // IN-3: the scoped manager learns nothing about a member outside their scope — the uniform 202, nothing made
        long before = invitationRepo.count();
        invite(manager.token(), outside.email(), "VIEWER", "PROPERTY:" + p1)
            .andExpect(status().isAccepted()).andExpect(jsonPath("$.status").value("REQUESTED"));
        invite(manager.token(), c.email(), "VIEWER", "PROPERTY:" + p1).andExpect(status().isAccepted());
        assertEquals(before, invitationRepo.count());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Accepting: account, workspace, company and authority checks (§14, WS-3, AC-3, AC-4)
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void onlyAVerifiedPartnerAccountWithTheInvitedAddressCanAccept() throws Exception {
        Company c = approvedCompany();
        String traveller = registerUser();
        invite(c.token(), traveller, "VIEWER", "COMPANY:" + c.id()).andExpect(status().isAccepted());
        String travellerToken = lastToken(traveller);
        accept(login(traveller), travellerToken).andExpect(status().isForbidden())
            .andExpect(jsonPath("$.code").value("PARTNER_ACCOUNT_REQUIRED"));
        assertEquals("USER", userRepo.findByEmail(traveller).orElseThrow().getRole(), "a traveller is never promoted");
        send(get("/api/me/partner-invitations"), login(traveller)).andExpect(status().isForbidden())
            .andExpect(jsonPath("$.code").value("PARTNER_ACCOUNT_REQUIRED"));

        invite(c.token(), "admin@planyourtrip.com", "VIEWER", "COMPANY:" + c.id()).andExpect(status().isAccepted());
        accept(adminToken(), lastToken("admin@planyourtrip.com")).andExpect(status().isForbidden())
            .andExpect(jsonPath("$.code").value("PARTNER_ACCOUNT_REQUIRED"));

        // a session that outlives the account's verification requirement (sign-in itself refuses unverified accounts)
        String unverified = partnerAccount();
        String unverifiedSession = login(unverified);
        User u = userRepo.findByEmail(unverified).orElseThrow();
        u.setEmailVerificationRequired(true);
        u.setEmailVerifiedAt(null);
        userRepo.save(u);
        invite(c.token(), unverified, "VIEWER", "COMPANY:" + c.id()).andExpect(status().isAccepted());
        accept(unverifiedSession, lastToken(unverified)).andExpect(status().isForbidden())
            .andExpect(jsonPath("$.code").value("PARTNER_ACCOUNT_REQUIRED"));

        // another Partner account holding the link: refused, the invited address is not echoed
        String invited = partnerAccount();
        invite(c.token(), invited, "VIEWER", "COMPANY:" + c.id()).andExpect(status().isAccepted());
        String wrongHolder = login(partnerAccount());
        String answer = accept(wrongHolder, lastToken(invited)).andExpect(status().isForbidden())
            .andExpect(jsonPath("$.code").value("INVITATION_ACCOUNT_MISMATCH"))
            .andReturn().getResponse().getContentAsString();
        assertFalse(answer.contains(invited));
        accept(login(invited), lastToken(invited)).andExpect(status().isOk());
    }

    @Test
    void acceptanceNeverCreatesASecondWorkspace() throws Exception {
        Company a = approvedCompany();
        Company b = approvedCompany();
        Member memberOfB = member(b, "VIEWER");

        // WS-3: an own company of any status blocks acceptance
        invite(a.token(), b.email(), "VIEWER", "COMPANY:" + a.id()).andExpect(status().isAccepted());
        accept(b.token(), lastToken(b.email())).andExpect(status().isConflict())
            .andExpect(jsonPath("$.code").value("WORKSPACE_CONFLICT"))
            .andExpect(jsonPath("$.reason").value("OWN_PROFILE_EXISTS"));
        String draftOwner = partnerAccount();
        send(json(post("/api/partner/profile"), """
            {"businessName":"R4 Draft","businessType":"HOTEL","representativeName":"R4",
             "phone":"0901234567","email":"contact@example.com","address":"1 Le Loi"}"""), login(draftOwner))
            .andExpect(status().isOk());
        invite(a.token(), draftOwner, "VIEWER", "COMPANY:" + a.id()).andExpect(status().isAccepted());
        accept(login(draftOwner), lastToken(draftOwner)).andExpect(status().isConflict())
            .andExpect(jsonPath("$.reason").value("OWN_PROFILE_EXISTS"));
        // an ACTIVE membership elsewhere blocks it too
        invite(a.token(), memberOfB.email(), "VIEWER", "COMPANY:" + a.id()).andExpect(status().isAccepted());
        accept(memberOfB.token(), lastToken(memberOfB.email())).andExpect(status().isConflict())
            .andExpect(jsonPath("$.reason").value("MEMBERSHIP_EXISTS"));
        assertTrue(teamMemberRepo.findByPartnerProfileIdAndUserId(a.id(), memberOfB.userId()).isEmpty());
        assertTrue(teamMemberRepo.findByPartnerProfileIdAndUserId(a.id(), b.userId()).isEmpty());
        // the invitations stay pending: the person may resolve the conflict and come back
        assertEquals("PENDING", invitationOf(a, memberOfB.email()).get("status").asText());
    }

    @Test
    void anInvitationGoesStaleWhenTheInviterLosesAuthorityOrTheCompanyIsSuspended() throws Exception {
        Company c = approvedCompany();
        Member manager = member(c, "MANAGER");
        String email = partnerAccount();
        invite(manager.token(), email, "VIEWER", "COMPANY:" + c.id()).andExpect(status().isAccepted());
        String token = lastToken(email);
        send(post("/api/partner/team/" + manager.rowId() + "/suspend"), c.token()).andExpect(status().isOk());
        accept(login(email), token).andExpect(status().isConflict())
            .andExpect(jsonPath("$.code").value("INVITATION_STALE"));
        send(post("/api/partner/team/" + manager.rowId() + "/reactivate"), c.token()).andExpect(status().isOk());
        accept(login(email), token).andExpect(status().isOk());

        String later = partnerAccount();
        invite(c.token(), later, "VIEWER", "COMPANY:" + c.id()).andExpect(status().isAccepted());
        send(json(post("/api/admin/partners/" + c.id() + "/suspend"), "{\"reason\":\"review\"}"), adminToken())
            .andExpect(status().isOk());
        accept(login(later), lastToken(later)).andExpect(status().isConflict())
            .andExpect(jsonPath("$.code").value("WORKSPACE_UNAVAILABLE"));
    }

    @Test
    void anotherCompanysInvitationIsNotFound() throws Exception {
        Company a = approvedCompany();
        Company b = approvedCompany();
        String email = partnerAccount();
        invite(a.token(), email, "VIEWER", "COMPANY:" + a.id()).andExpect(status().isAccepted());
        Long id = invitationOf(a, email).get("id").asLong();
        cooldownPassed(id);

        send(post("/api/partner/team/invitations/" + id + "/resend"), b.token()).andExpect(status().isNotFound());
        send(delete("/api/partner/team/invitations/" + id), b.token()).andExpect(status().isNotFound());
        send(post("/api/partner/team/invitations/" + Long.MAX_VALUE + "/resend"), a.token()).andExpect(status().isNotFound());
        assertEquals("[]", send(get("/api/partner/team/invitations"), b.token()).andReturn().getResponse().getContentAsString());
        assertEquals("PENDING", invitationOf(a, email).get("status").asText());
        // an invitation token is no key to anything else: a forged or random value is invalid
        accept(login(email), "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA").andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.code").value("INVITATION_INVALID"));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Owner invitations (O-2, O-7) and PA-4
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void anOwnerInvitationNeedsAnOwnerAndAFreshSession() throws Exception {
        Company c = approvedCompany();
        Member manager = member(c, "MANAGER");
        String email = partnerAccount();

        invite(manager.token(), email, "OWNER", "COMPANY:" + c.id())
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("OWNER_PROTECTED"));
        invite(staleToken(c.userId()), email, "OWNER", "COMPANY:" + c.id())
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value(StepUpPolicy.STEP_UP_REQUIRED));
        invite(c.token(), email, "OWNER", "COMPANY:" + c.id()).andExpect(status().isAccepted());
        // the manager cannot revoke or resend it either
        Long id = invitationOf(c, email).get("id").asLong();
        send(delete("/api/partner/team/invitations/" + id), manager.token())
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("OWNER_PROTECTED"));

        String memberToken = login(email);
        accept(memberToken, lastToken(email)).andExpect(status().isOk());
        Long userId = userRepo.findByEmail(email).orElseThrow().getId();
        PartnerTeamMember row = teamMemberRepo.findByPartnerProfileIdAndUserId(c.id(), userId).orElseThrow();
        assertEquals(List.of("OWNER@COMPANY:" + c.id()), grants(row.getId()));
        assertFalse(row.isPendingOwnerConfirmation());
        assertTrue(actions(c.id()).contains("OWNER_GRANTED"));
        send(get("/api/partner/team"), memberToken).andExpect(status().isOk());
    }

    @Test
    void aMovedPropertyRevokesThePreviousCompanysPendingInvitationsOnIt() throws Exception {
        Company a = approvedCompany();
        Company b = approvedCompany();
        Long property = createProperty(a);
        String scoped = partnerAccount();
        String companyWide = partnerAccount();
        invite(a.token(), scoped, "FRONT_DESK", "PROPERTY:" + property).andExpect(status().isAccepted());
        invite(a.token(), companyWide, "VIEWER", "COMPANY:" + a.id()).andExpect(status().isAccepted());

        send(json(post("/api/admin/hotels/" + property + "/assign-owner"), "{\"partnerProfileId\":" + b.id() + "}"),
            adminToken()).andExpect(status().isOk());

        PartnerInvitation moved = invitationRepo.findById(invitationOf(a, scoped).get("id").asLong()).orElseThrow();
        assertEquals("REVOKED", moved.getStatus().name());
        assertEquals("PROPERTY_MOVED", moved.getStatusReason());
        assertEquals("PENDING", invitationOf(a, companyWide).get("status").asText(), "company grants follow the company");
        accept(login(scoped), lastToken(scoped)).andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.code").value("INVITATION_INVALID"));
        assertTrue(auditRows(a.id(), "TEAM_INVITATION_REVOKED").stream()
            .anyMatch(r -> "PROPERTY_MOVED".equals(r.get("reason"))));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Concurrency (§19 LO-3 style: the company row lock serializes every invitation write)
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void twoAcceptancesOfOneInvitationCannotBothSucceed() throws Exception {
        Company c = approvedCompany();
        String email = partnerAccount();
        invite(c.token(), email, "VIEWER", "COMPANY:" + c.id()).andExpect(status().isAccepted());
        String token = lastToken(email);
        String memberToken = login(email);

        List<Integer> statuses = concurrently(
            () -> accept(memberToken, token).andReturn().getResponse().getStatus(),
            () -> accept(memberToken, token).andReturn().getResponse().getStatus());
        assertEquals(1, statuses.stream().filter(s -> s == 200).count(), statuses.toString());
        assertEquals(1, statuses.stream().filter(s -> s == 400).count(), statuses.toString());
        Long userId = userRepo.findByEmail(email).orElseThrow().getId();
        assertEquals(1, teamMemberRepo.findByPartnerProfileIdAndUserIdOrderByIdAsc(c.id(), userId).size());
    }

    @Test
    void concurrentInvitationsNearTheLimitNeverExceedTwenty() throws Exception {
        Company c = approvedCompany();
        for (int i = 0; i < 18; i++) {
            invite(c.token(), uniqueEmail("near"), "VIEWER", "COMPANY:" + c.id()).andExpect(status().isAccepted());
        }
        List<Callable<Integer>> calls = new ArrayList<>();
        for (int i = 0; i < 6; i++) {
            String email = uniqueEmail("race");
            calls.add(() -> invite(c.token(), email, "VIEWER", "COMPANY:" + c.id()).andReturn().getResponse().getStatus());
        }
        @SuppressWarnings("unchecked")
        List<Integer> statuses = concurrently(calls.toArray(new Callable[0]));
        assertEquals(2, statuses.stream().filter(s -> s == 202).count(), statuses.toString());
        assertEquals(4, statuses.stream().filter(s -> s == 429).count(), statuses.toString());
        assertEquals(20L, jdbc.queryForObject(
            "select count(*) from partner_invitations where partner_profile_id = ? and status = 'PENDING'", Long.class, c.id()));
    }

    @Test
    void concurrentResendsRotateTheTokenOnce() throws Exception {
        Company c = approvedCompany();
        String email = partnerAccount();
        invite(c.token(), email, "VIEWER", "COMPANY:" + c.id()).andExpect(status().isAccepted());
        Long id = invitationOf(c, email).get("id").asLong();
        cooldownPassed(id);

        List<Integer> statuses = concurrently(
            () -> send(post("/api/partner/team/invitations/" + id + "/resend"), c.token()).andReturn().getResponse().getStatus(),
            () -> send(post("/api/partner/team/invitations/" + id + "/resend"), c.token()).andReturn().getResponse().getStatus());
        assertEquals(1, statuses.stream().filter(s -> s == 202).count(), statuses.toString());
        assertEquals(1, statuses.stream().filter(s -> s == 429).count(), statuses.toString());
        assertEquals(1, invitationRepo.findById(id).orElseThrow().getResendCount());
        accept(login(email), lastToken(email)).andExpect(status().isOk());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Audit (§22.1 AU-1): written in the transaction and failing closed
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * R4 hardening: a reason the audit guard would refuse is a structured 400 before anything starts — not a failed
     * audit write and a 500 — and is never echoed or logged. Ordinary reasons keep working.
     */
    @Test
    void aCredentialLikeReasonIsAValidationErrorAndChangesNothing(CapturedOutput output) throws Exception {
        Company c = approvedCompany();
        String email = partnerAccount();
        invite(c.token(), email, "VIEWER", "COMPANY:" + c.id()).andExpect(status().isAccepted());
        Long id = invitationOf(c, email).get("id").asLong();
        Member m = member(c, "VIEWER");
        List<String> before = actions(c.id());
        long versionBefore = version(m.rowId());

        for (var attempt : List.of(
                json(delete("/api/partner/team/invitations/" + id), "{\"reason\":\"my password is hunter2\"}"),
                json(post("/api/partner/team/" + m.rowId() + "/suspend"), "{\"reason\":\"shared secret hunter2\"}"),
                json(delete("/api/partner/team/" + m.rowId()), "{\"reason\":\"api_key hunter2\"}"),
                json(put("/api/partner/team/" + m.rowId() + "/grants"), "{\"grants\":[{\"role\":\"FRONT_DESK\",\"scope\":\"COMPANY:"
                    + c.id() + "\"}],\"reason\":\"bearer hunter2\",\"version\":" + versionBefore + "}"))) {
            String body = send(attempt, c.token())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.fieldErrors[0].field").value("reason"))
                .andReturn().getResponse().getContentAsString();
            assertFalse(body.contains("hunter2"), "the rejected value is not echoed");
        }
        assertEquals("PENDING", invitationOf(c, email).get("status").asText());
        assertEquals(PartnerMembershipStatus.ACTIVE, teamMemberRepo.findById(m.rowId()).orElseThrow().getStatus());
        assertEquals(versionBefore, version(m.rowId()));
        assertEquals(List.of("VIEWER@COMPANY:" + c.id()), grants(m.rowId()));
        assertEquals(before, actions(c.id()), "nothing audited");
        assertFalse(output.getAll().contains("hunter2"), "the rejected value is not logged");

        // every other caller of the services gets the same 400, before any lock or change
        com.example.planyourtrip.exception.ApiException refused = assertThrows(com.example.planyourtrip.exception.ApiException.class,
            () -> teamService.suspend(c.userId(), m.rowId(), "the password is hunter2"));
        assertEquals("VALIDATION_FAILED", refused.code());
        assertEquals("reason", refused.field());
        assertThrows(com.example.planyourtrip.exception.ApiException.class,
            () -> invitationService.revoke(c.userId(), id, "secret hunter2"));
        assertEquals(PartnerMembershipStatus.ACTIVE, teamMemberRepo.findById(m.rowId()).orElseThrow().getStatus());

        // ordinary reasons are recorded as given; an address merely containing such a word is invited normally
        send(json(post("/api/partner/team/" + m.rowId() + "/suspend"), "{\"reason\":\"on leave until March\"}"), c.token())
            .andExpect(status().isOk());
        send(json(delete("/api/partner/team/invitations/" + id), "{\"reason\":\"sent to the wrong address\"}"), c.token())
            .andExpect(status().isNoContent());
        assertEquals("on leave until March", auditRows(c.id(), "TEAM_MEMBER_SUSPENDED").get(0).get("reason"));
        assertEquals("sent to the wrong address", auditRows(c.id(), "TEAM_INVITATION_REVOKED").get(0).get("reason"));
        invite(c.token(), "secretary-" + uniqueEmail("x"), "VIEWER", "COMPANY:" + c.id()).andExpect(status().isAccepted());
    }

    /** AU-1: when the strict audit write itself fails, the mutation it records never commits — and nothing is sent. */
    @Test
    void anAuditWriteFailureRollsTheMutationBack() throws Exception {
        Company c = approvedCompany();
        String pendingEmail = partnerAccount();
        invite(c.token(), pendingEmail, "VIEWER", "COMPANY:" + c.id()).andExpect(status().isAccepted());
        Long pending = invitationOf(c, pendingEmail).get("id").asLong();
        Member m = member(c, "VIEWER");
        String newcomer = partnerAccount();
        List<String> before = actions(c.id());
        long invitationsBefore = invitationRepo.count();
        Mockito.clearInvocations(emailSender);

        Mockito.doThrow(new IllegalStateException("audit store unavailable")).when(activityLog)
            .audit(Mockito.anyLong(), Mockito.anyLong(), Mockito.anyString(), any(), any(), any(), any(), any(), any());
        try {
            send(post("/api/partner/team/" + m.rowId() + "/suspend"), c.token()).andExpect(status().isInternalServerError());
            send(delete("/api/partner/team/invitations/" + pending), c.token()).andExpect(status().isInternalServerError());
            invite(c.token(), newcomer, "VIEWER", "COMPANY:" + c.id()).andExpect(status().isInternalServerError());
        } finally {
            Mockito.reset(activityLog);
        }
        assertEquals(PartnerMembershipStatus.ACTIVE, teamMemberRepo.findById(m.rowId()).orElseThrow().getStatus());
        assertEquals("PENDING", invitationOf(c, pendingEmail).get("status").asText());
        assertEquals(invitationsBefore, invitationRepo.count(), "no invitation without its audit row");
        Mockito.verify(emailSender, Mockito.never()).send(any());
        assertEquals(before, actions(c.id()));
        assertFalse(titles(login(m.email())).contains("Team member suspended"), "no notification of a rolled-back change");
    }

    /**
     * Item-3 hardening: outside the dev-only sender, no path logs a link — a failing provider whose exception message
     * carries the link is logged by class only, and {@code AccountEmail} never prints its link.
     */
    @Test
    void aFailingSendNeverLogsTheLinkAndAccountEmailRedactsIt(CapturedOutput output) throws Exception {
        Company c = approvedCompany();
        String email = partnerAccount();
        List<String> links = new ArrayList<>();
        Mockito.doAnswer(call -> {
            com.example.planyourtrip.service.mail.AccountEmail sent = call.getArgument(0);
            links.add(sent.actionUrl());
            throw new IllegalStateException("provider rejected " + sent.actionUrl() + " / " + sent);
        }).when(emailSender).send(any());
        try {
            invite(c.token(), email, "VIEWER", "COMPANY:" + c.id()).andExpect(status().isAccepted());
        } finally {
            Mockito.reset(emailSender);
        }
        String token = links.get(0).substring(links.get(0).indexOf("#token=") + 7);
        assertFalse(output.getAll().contains(token), "the token reached a log");
        assertEquals("FAILED", invitationOf(c, email).get("deliveryStatus").asText());

        var mail = new com.example.planyourtrip.service.mail.AccountEmail("a@test.com",
            com.example.planyourtrip.service.mail.AccountEmail.Kind.PARTNER_INVITATION, "https://p/accept-invitation#token=SECRET123");
        assertFalse(mail.toString().contains("SECRET123"));
        assertEquals("https://p/accept-invitation#token=SECRET123", mail.actionUrl());
        // the development sender is never active in production, and the production sender prints nothing
        assertTrue(java.util.Arrays.asList(com.example.planyourtrip.service.mail.DevelopmentLogEmailSender.class
            .getAnnotation(org.springframework.context.annotation.Profile.class).value()).contains("!prod"));
        assertTrue(java.util.Arrays.asList(com.example.planyourtrip.service.mail.UnconfiguredEmailSender.class
            .getAnnotation(org.springframework.context.annotation.Profile.class).value()).contains("prod"));
        IllegalStateException unconfigured = assertThrows(IllegalStateException.class,
            () -> new com.example.planyourtrip.service.mail.UnconfiguredEmailSender().send(mail));
        assertFalse(unconfigured.getMessage().contains("SECRET123"));
        assertFalse(output.getAll().contains("SECRET123"));
    }

    /** Whatever ran before in this database: every revoked row keeps its own key, every live row 0 (RV-2). */
    @Test
    void noMembershipRowEverBreaksTheRevocationKeyInvariant() {
        assertEquals(0, jdbc.queryForObject(
            "select count(*) from partner_team_members where status = 'REVOKED' and revocation_key <> id", Integer.class));
        assertEquals(0, jdbc.queryForObject(
            "select count(*) from partner_team_members where status <> 'REVOKED' and revocation_key <> 0", Integer.class));
        assertEquals(List.of("ACTIVE", "SUSPENDED", "REVOKED"),
            java.util.Arrays.stream(PartnerMembershipStatus.values()).map(Enum::name).toList(), "no new state");
    }
}
