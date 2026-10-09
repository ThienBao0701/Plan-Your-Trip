package com.example.planyourtrip;

import com.example.planyourtrip.model.PartnerMembershipStatus;
import com.example.planyourtrip.model.PartnerTeamMember;
import com.example.planyourtrip.model.PartnerTeamRole;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.security.StepUpPolicy;
import com.example.planyourtrip.security.rbac.ScopeType;
import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * RBAC R4 — team administration: MANAGER delegation within authority and scope, anti-escalation, the membership
 * lifecycle, re-adding a removed member through a new membership, and concurrency (RBAC V1.1 §10.3, §11.4, §15–§19,
 * §31 Q3, I6–I9, I21).
 */
class RbacTeamAdministrationTest extends RbacTeamTestSupport {

    @org.springframework.beans.factory.annotation.Autowired
    com.example.planyourtrip.security.rbac.EndpointAuthorizationRegistry registry;

    /** A company with two properties, a room type at each, and managers at company and property scope. */
    private record Team(Company c, Long p1, Long p2, Long r1, Long r2, Member managerCompany, Member managerP1) {}

    private Team team() throws Exception {
        Company c = approvedCompany();
        Long p1 = createProperty(c);
        Long p2 = createProperty(c);
        Long r1 = createRoom(p1);
        Long r2 = createRoom(p2);
        return new Team(c, p1, p2, r1, r2, member(c, "MANAGER"), member(c, "MANAGER", ScopeType.PROPERTY, p1));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // §10.3 authority and delegation
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void ownersManageEveryRoleButThePrimaryOwner() throws Exception {
        Team t = team();
        Member viewer = member(t.c(), "VIEWER");
        for (String role : List.of("MANAGER", "FINANCE", "REVENUE", "HOUSEKEEPING")) {
            String scope = role.equals("HOUSEKEEPING") ? "PROPERTY:" + t.p1() : "COMPANY:" + t.c().id();
            send(json(put("/api/partner/team/" + viewer.rowId() + "/grants"), grantsBody(version(viewer.rowId()), role, scope)),
                t.c().token()).andExpect(status().isOk());
        }
        send(post("/api/partner/team/" + t.managerCompany().rowId() + "/suspend"), t.c().token()).andExpect(status().isOk());
        send(post("/api/partner/team/" + t.c().ownerRowId() + "/suspend"), member(t.c(), "OWNER").token())
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("OWNER_PROTECTED"));
    }

    @Test
    void aManagerManagesBelowManagerRolesWithinTheirScope() throws Exception {
        Team t = team();
        Member frontDesk = member(t.c(), "FRONT_DESK", ScopeType.PROPERTY, t.p1());
        String mgr = t.managerP1().token();

        // change role and scope inside P1, down to a room type of P1
        send(json(put("/api/partner/team/" + frontDesk.rowId() + "/grants"),
                grantsBody(version(frontDesk.rowId()), "CONTENT", "PROPERTY:" + t.p1())), mgr)
            .andExpect(status().isOk()).andExpect(jsonPath("$.role").value("CONTENT"));
        send(json(put("/api/partner/team/" + frontDesk.rowId() + "/grants"),
                grantsBody(version(frontDesk.rowId()), "HOUSEKEEPING", "UNIT:" + t.r1())), mgr)
            .andExpect(status().isOk());
        assertEquals(List.of("HOUSEKEEPING@UNIT:" + t.r1()), grants(frontDesk.rowId()));
        // suspend, reactivate, invite and remove — all inside P1
        send(post("/api/partner/team/" + frontDesk.rowId() + "/suspend"), mgr).andExpect(status().isOk());
        send(post("/api/partner/team/" + frontDesk.rowId() + "/reactivate"), mgr).andExpect(status().isOk());
        invite(mgr, partnerAccount(), "RESERVATIONS", "PROPERTY:" + t.p1()).andExpect(status().isAccepted());
        send(delete("/api/partner/team/" + frontDesk.rowId()), mgr).andExpect(status().isNoContent());
        assertEquals(PartnerMembershipStatus.REVOKED, teamMemberRepo.findById(frontDesk.rowId()).orElseThrow().getStatus());
        // the trail names the manager, by snapshot
        Map<String, Object> row = auditRows(t.c().id(), "TEAM_MEMBER_REMOVED").get(0);
        assertEquals(t.managerP1().email(), row.get("actor_email"));
        assertEquals(t.managerP1().userId(), ((Number) row.get("actor_user_id")).longValue());
    }

    @Test
    void aManagerNeverManagesOwnersManagersOrFinance() throws Exception {
        Team t = team();
        Member coOwner = member(t.c(), "OWNER");
        Member finance = member(t.c(), "FINANCE");
        Member viewer = member(t.c(), "VIEWER");
        String mgr = t.managerCompany().token();

        for (MockHttpServletRequestBuilder attempt : List.of(
                post("/api/partner/team/" + coOwner.rowId() + "/suspend"),
                delete("/api/partner/team/" + coOwner.rowId()),
                post("/api/partner/team/" + t.c().ownerRowId() + "/suspend"))) {
            send(attempt, mgr).andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("OWNER_PROTECTED"));
        }
        for (MockHttpServletRequestBuilder attempt : List.of(
                post("/api/partner/team/" + finance.rowId() + "/suspend"),
                post("/api/partner/team/" + t.managerP1().rowId() + "/suspend"),
                json(put("/api/partner/team/" + viewer.rowId() + "/grants"),
                    grantsBody(version(viewer.rowId()), "MANAGER", "PROPERTY:" + t.p1())),
                json(put("/api/partner/team/" + viewer.rowId() + "/grants"),
                    grantsBody(version(viewer.rowId()), "FINANCE", "COMPANY:" + t.c().id())),
                json(post("/api/partner/team/invitations"), invitationBody(partnerAccount(), "MANAGER", "PROPERTY:" + t.p1())),
                json(post("/api/partner/team/invitations"), invitationBody(partnerAccount(), "FINANCE", "COMPANY:" + t.c().id())))) {
            send(attempt, mgr).andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ROLE_NOT_DELEGABLE"));
        }
        send(json(put("/api/partner/team/" + viewer.rowId() + "/grants"),
                grantsBody(version(viewer.rowId()), "OWNER", "COMPANY:" + t.c().id())), mgr)
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("OWNER_PROTECTED"));
        invite(mgr, partnerAccount(), "OWNER", "COMPANY:" + t.c().id())
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("OWNER_PROTECTED"));
        assertEquals(List.of("VIEWER@COMPANY:" + t.c().id()), grants(viewer.rowId()));
        assertEquals(PartnerMembershipStatus.ACTIVE, teamMemberRepo.findById(finance.rowId()).orElseThrow().getStatus());
    }

    @Test
    void nobodyEscalatesThemselvesAndAScopedManagerNeverWidensAGrant() throws Exception {
        Team t = team();
        Member viewer = member(t.c(), "VIEWER");
        Member frontDesk = member(t.c(), "FRONT_DESK", ScopeType.PROPERTY, t.p1());
        Member unitKeeper = member(t.c(), "HOUSEKEEPING", ScopeType.UNIT, t.r1());

        // self-modification, for every role (I7)
        for (Member self : List.of(viewer, t.managerCompany(), t.managerP1())) {
            send(json(put("/api/partner/team/" + self.rowId() + "/grants"),
                    grantsBody(version(self.rowId()), "OWNER", "COMPANY:" + t.c().id())), self.token())
                .andExpect(status().isForbidden());
            send(json(patch("/api/partner/team/" + self.rowId()), "{\"role\":\"MANAGER\"}"), self.token())
                .andExpect(status().isForbidden());
        }
        send(json(put("/api/partner/team/" + t.managerP1().rowId() + "/grants"),
                grantsBody(version(t.managerP1().rowId()), "MANAGER", "COMPANY:" + t.c().id())), t.managerP1().token())
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("SELF_MODIFICATION_FORBIDDEN"));
        // a viewer holds no team permission at all: VIEWER -> OWNER / MANAGER is impossible
        invite(viewer.token(), partnerAccount(), "OWNER", "COMPANY:" + t.c().id())
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("PERMISSION_DENIED"));
        send(json(put("/api/partner/team/" + frontDesk.rowId() + "/grants"),
                grantsBody(version(frontDesk.rowId()), "MANAGER", "PROPERTY:" + t.p1())), viewer.token())
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("PERMISSION_DENIED"));

        // PROPERTY -> COMPANY and PROPERTY -> another property (I6)
        String mgr = t.managerP1().token();
        for (String scope : List.of("COMPANY:" + t.c().id(), "PROPERTY:" + t.p2(), "UNIT:" + t.r2())) {
            String role = scope.startsWith("UNIT") ? "HOUSEKEEPING" : "FRONT_DESK";
            send(json(put("/api/partner/team/" + frontDesk.rowId() + "/grants"),
                    grantsBody(version(frontDesk.rowId()), role, scope)), mgr)
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ROLE_NOT_DELEGABLE"));
            invite(mgr, partnerAccount(), role, scope)
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ROLE_NOT_DELEGABLE"));
        }
        // UNIT -> PROPERTY of another property, and a unit holder acts on nobody
        send(json(put("/api/partner/team/" + unitKeeper.rowId() + "/grants"),
                grantsBody(version(unitKeeper.rowId()), "HOUSEKEEPING", "PROPERTY:" + t.p2())), mgr)
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ROLE_NOT_DELEGABLE"));
        send(post("/api/partner/team/" + frontDesk.rowId() + "/suspend"), unitKeeper.token())
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("PERMISSION_DENIED"));
        assertEquals(List.of("FRONT_DESK@PROPERTY:" + t.p1()), grants(frontDesk.rowId()));
        assertEquals(List.of("HOUSEKEEPING@UNIT:" + t.r1()), grants(unitKeeper.rowId()));
        assertEquals(List.of("MANAGER@PROPERTY:" + t.p1()), grants(t.managerP1().rowId()));
    }

    @Test
    void aScopedManagerCannotSeeOrTouchMembersOutsideTheirScope() throws Exception {
        Team t = team();
        Member atP2 = member(t.c(), "FRONT_DESK", ScopeType.PROPERTY, t.p2());
        Member companyWide = member(t.c(), "VIEWER");
        Member mixed = member(t.c(), "FRONT_DESK", ScopeType.PROPERTY, t.p1());
        send(json(put("/api/partner/team/" + mixed.rowId() + "/grants"), """
                {"grants":[{"role":"FRONT_DESK","scope":"PROPERTY:%d"},{"role":"VIEWER","scope":"PROPERTY:%d"}],"version":%d}
                """.formatted(t.p1(), t.p2(), version(mixed.rowId()))), t.c().token()).andExpect(status().isOk());
        Company other = approvedCompany();
        Member foreign = member(other, "VIEWER");
        String mgr = t.managerP1().token();

        // 404, exactly as a missing id: the member is outside the manager's team view (E5)
        for (Long row : List.of(atP2.rowId(), companyWide.rowId(), mixed.rowId(), foreign.rowId(), t.c().ownerRowId())) {
            send(post("/api/partner/team/" + row + "/suspend"), mgr).andExpect(status().isNotFound());
            send(json(patch("/api/partner/team/" + row), "{\"active\":false}"), mgr).andExpect(status().isNotFound());
        }
        List<Long> visible = body(get("/api/partner/team"), mgr, 200).findValues("id").stream().map(JsonNode::asLong).toList();
        assertFalse(visible.contains(atP2.rowId()) || visible.contains(companyWide.rowId())
            || visible.contains(mixed.rowId()) || visible.contains(t.c().ownerRowId()), visible.toString());
        // a company-wide manager sees them; another company's member stays 404 for everyone
        send(post("/api/partner/team/" + atP2.rowId() + "/suspend"), t.managerCompany().token()).andExpect(status().isOk());
        send(post("/api/partner/team/" + foreign.rowId() + "/suspend"), t.c().token()).andExpect(status().isNotFound());
    }

    /**
     * R4 hardening — the invitation endpoint's contract (§13.1 step 1, §11.2, §11.4, PA-3): authorization is over the
     * invited grants (RESOURCE, body target), so a property-scoped manager invites inside their property while a
     * company-scoped one may invite company-wide; no invited grant is ever wider than the inviter's own; another
     * company's scopes and invitations do not exist for the caller. The legacy alias stays COMPANY-shaped (role at
     * company scope), so only a company-wide team holder can use it.
     */
    @Test
    void invitationsAreAuthorizedOverTheInvitedGrantsNeverWiderThanTheInviter() throws Exception {
        Team t = team();
        Company other = approvedCompany();
        Long foreignProperty = createProperty(other);
        String company = "COMPANY:" + t.c().id();

        // company scope: owner and company-wide manager
        invite(t.c().token(), partnerAccount(), "VIEWER", company).andExpect(status().isAccepted());
        invite(t.managerCompany().token(), partnerAccount(), "REVENUE", company).andExpect(status().isAccepted());
        invite(t.managerCompany().token(), partnerAccount(), "CONTENT", "PROPERTY:" + t.p2()).andExpect(status().isAccepted());
        // property scope: the P1 manager, inside P1 and its room types only
        String mgr = t.managerP1().token();
        invite(mgr, partnerAccount(), "RESERVATIONS", "PROPERTY:" + t.p1()).andExpect(status().isAccepted());
        invite(mgr, partnerAccount(), "HOUSEKEEPING", "UNIT:" + t.r1()).andExpect(status().isAccepted());
        // widening: property -> company, -> another property, -> another property's room type, mixed grants
        for (String body : List.of(
                invitationBody(partnerAccount(), "VIEWER", company),
                invitationBody(partnerAccount(), "VIEWER", "PROPERTY:" + t.p2()),
                invitationBody(partnerAccount(), "HOUSEKEEPING", "UNIT:" + t.r2()),
                "{\"email\":\"" + partnerAccount() + "\",\"grants\":[{\"role\":\"VIEWER\",\"scope\":\"PROPERTY:" + t.p1()
                    + "\"},{\"role\":\"VIEWER\",\"scope\":\"PROPERTY:" + t.p2() + "\"}]}")) {
            send(json(post("/api/partner/team/invitations"), body), mgr)
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ROLE_NOT_DELEGABLE"));
        }
        send(json(post("/api/partner/team"), "{\"email\":\"" + partnerAccount() + "\",\"role\":\"VIEWER\"}"), mgr)
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ROLE_NOT_DELEGABLE"));
        // cross-company targets: another company's scopes are invalid, its invitations missing
        for (String scope : List.of("COMPANY:" + other.id(), "PROPERTY:" + foreignProperty)) {
            invite(t.c().token(), partnerAccount(), "VIEWER", scope)
                .andExpect(status().isUnprocessableEntity()).andExpect(jsonPath("$.code").value("SCOPE_INVALID"));
        }
        String foreignEmail = partnerAccount();
        invite(other.token(), foreignEmail, "VIEWER", "COMPANY:" + other.id()).andExpect(status().isAccepted());
        Long foreignInvitation = invitationOf(other, foreignEmail).get("id").asLong();
        send(delete("/api/partner/team/invitations/" + foreignInvitation), t.c().token()).andExpect(status().isNotFound());
        send(delete("/api/partner/team/invitations/" + foreignInvitation), mgr).andExpect(status().isNotFound());
        // the P1 manager sees exactly the invitations inside P1
        JsonNode seen = body(get("/api/partner/team/invitations"), mgr, 200);
        assertEquals(2, seen.size(), seen.toString());
        seen.forEach(i -> i.get("grants").forEach(g -> assertTrue(
            g.get("scope").asText().equals("PROPERTY:" + t.p1()) || g.get("scope").asText().equals("UNIT:" + t.r1()), i.toString())));
    }

    /** The registry records the contract the services enforce (design erratum E-R4-1 in RBAC_TEAM_ADMINISTRATION.md). */
    @Test
    void theRegistryRecordsInvitationsAsResourcesOverTheirGrants() {
        var post = org.springframework.web.bind.annotation.RequestMethod.POST;
        var create = registry.partnerRule(post, "/api/partner/team/invitations").orElseThrow();
        assertEquals(com.example.planyourtrip.security.rbac.EndpointKind.RESOURCE, create.kind());
        assertEquals(com.example.planyourtrip.security.rbac.ResourceType.INVITATION, create.resourceType());
        assertEquals(List.of(com.example.planyourtrip.security.rbac.PartnerPermission.TEAM_INVITE,
            com.example.planyourtrip.security.rbac.PartnerPermission.TEAM_OWNER_MANAGE), create.permissions());
        for (String path : List.of("/api/partner/team/invitations/{id}/resend")) {
            assertEquals(com.example.planyourtrip.security.rbac.EndpointKind.RESOURCE, registry.partnerRule(post, path).orElseThrow().kind());
        }
        assertEquals(com.example.planyourtrip.security.rbac.EndpointKind.RESOURCE, registry.partnerRule(
            org.springframework.web.bind.annotation.RequestMethod.DELETE, "/api/partner/team/invitations/{id}").orElseThrow().kind());
        assertEquals(com.example.planyourtrip.security.rbac.EndpointKind.COLLECTION, registry.partnerRule(
            org.springframework.web.bind.annotation.RequestMethod.GET, "/api/partner/team/invitations").orElseThrow().kind());
        // the legacy alias always invites at company scope: it stays COMPANY
        assertEquals(com.example.planyourtrip.security.rbac.EndpointKind.COMPANY,
            registry.partnerRule(post, "/api/partner/team").orElseThrow().kind());
        // an invitation is seen, like a membership, through team view (P07) covering all of its grants (§11.2)
        assertEquals(com.example.planyourtrip.security.rbac.PartnerPermission.TEAM_VIEW,
            com.example.planyourtrip.security.rbac.ResourceType.INVITATION.viewPermission());
    }

    @Test
    void financeIsCompanyWideButHoldsNoTeamPower() throws Exception {
        Team t = team();
        Member finance = member(t.c(), "FINANCE");
        Member viewer = member(t.c(), "VIEWER");
        for (MockHttpServletRequestBuilder attempt : List.of(
                post("/api/partner/team/" + viewer.rowId() + "/suspend"),
                delete("/api/partner/team/" + viewer.rowId()),
                json(post("/api/partner/team/invitations"), invitationBody(partnerAccount(), "VIEWER", "COMPANY:" + t.c().id())),
                get("/api/partner/team"),
                get("/api/partner/team/invitations"))) {
            send(attempt, finance.token()).andExpect(status().isForbidden());
        }
    }

    @Test
    void aReactivationHandsBackOnlyGrantsTheActorCouldGrant() throws Exception {
        Team t = team();
        Member atP1 = member(t.c(), "RESERVATIONS", ScopeType.PROPERTY, t.p1());
        send(post("/api/partner/team/" + atP1.rowId() + "/suspend"), t.c().token()).andExpect(status().isOk());
        send(post("/api/partner/team/" + atP1.rowId() + "/reactivate"), t.managerP1().token()).andExpect(status().isOk());

        Member promoted = member(t.c(), "VIEWER");
        send(json(put("/api/partner/team/" + promoted.rowId() + "/grants"),
                grantsBody(version(promoted.rowId()), "MANAGER", "COMPANY:" + t.c().id())), t.c().token())
            .andExpect(status().isOk());
        send(post("/api/partner/team/" + promoted.rowId() + "/suspend"), t.c().token()).andExpect(status().isOk());
        send(post("/api/partner/team/" + promoted.rowId() + "/reactivate"), t.managerCompany().token())
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ROLE_NOT_DELEGABLE"));
        assertEquals(PartnerMembershipStatus.SUSPENDED, teamMemberRepo.findById(promoted.rowId()).orElseThrow().getStatus());
    }

    @Test
    void ownerProtectionsAndStepUpStillHoldForManagersAndOwners() throws Exception {
        Team t = team();
        Member coOwner = member(t.c(), "OWNER");
        // O-7: an owner change by an owner needs a fresh session
        send(post("/api/partner/team/" + coOwner.rowId() + "/suspend"), staleToken(t.c().userId()))
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value(StepUpPolicy.STEP_UP_REQUIRED));
        // LO-2: the last qualifying owner cannot leave once the registrant's account is disabled
        User registrant = userRepo.findById(t.c().userId()).orElseThrow();
        registrant.setEnabled(false);
        userRepo.save(registrant);
        send(post("/api/partner/team/leave"), coOwner.token())
            .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("LAST_OWNER_REQUIRED"));
        send(post("/api/partner/team/" + coOwner.rowId() + "/suspend"), t.managerCompany().token())
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("OWNER_PROTECTED"));
        assertEquals(PartnerMembershipStatus.ACTIVE, teamMemberRepo.findById(coOwner.rowId()).orElseThrow().getStatus());
    }

    @Test
    void securityNotificationsOfAManagersChangeReachEveryOwnerAndTheMember() throws Exception {
        Team t = team();
        Member coOwner = member(t.c(), "OWNER");
        Member target = member(t.c(), "FRONT_DESK", ScopeType.PROPERTY, t.p1());
        send(json(put("/api/partner/settings"), SETTINGS_ALL_OFF), t.managerCompany().token()).andExpect(status().isOk());

        send(post("/api/partner/team/" + target.rowId() + "/suspend"), t.managerP1().token()).andExpect(status().isOk());
        for (String token : List.of(t.c().token(), coOwner.token(), login(target.email()))) {
            assertTrue(titles(token).contains("Team member suspended"), "settings never silence a security event");
        }
        assertFalse(titles(t.managerP1().token()).contains("Team member suspended"), "only owners and the member");
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Lifecycle and re-add (§17, RV-2, I21)
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void aRemovedMemberRejoinsThroughANewMembershipAndTheOldOneStaysHistory() throws Exception {
        Team t = team();
        Member m = member(t.c(), "VIEWER");
        send(json(delete("/api/partner/team/" + m.rowId()), "{\"reason\":\"contract ended\"}"), t.c().token())
            .andExpect(status().isNoContent());
        PartnerTeamMember old = teamMemberRepo.findById(m.rowId()).orElseThrow();
        assertEquals(PartnerMembershipStatus.REVOKED, old.getStatus());
        assertEquals(m.rowId().longValue(), old.getRevocationKey());
        // mutations against the revoked row are 404 (it is history, not a member)
        for (MockHttpServletRequestBuilder attempt : List.of(
                post("/api/partner/team/" + m.rowId() + "/reactivate"),
                json(patch("/api/partner/team/" + m.rowId()), "{\"active\":true}"),
                json(put("/api/partner/team/" + m.rowId() + "/grants"), grantsBody(version(m.rowId()), "VIEWER", "COMPANY:" + t.c().id())),
                delete("/api/partner/team/" + m.rowId()))) {
            send(attempt, t.c().token()).andExpect(status().isNotFound());
        }
        send(get("/api/partner/settings"), m.token()).andExpect(status().isNotFound());

        // re-invited (fresh consent) and accepted: a NEW row, the old one untouched
        invite(t.managerCompany().token(), m.email(), "FRONT_DESK", "PROPERTY:" + t.p1()).andExpect(status().isAccepted());
        accept(login(m.email()), lastToken(m.email())).andExpect(status().isOk());
        List<PartnerTeamMember> rows = teamMemberRepo.findByPartnerProfileIdAndUserIdOrderByIdAsc(t.c().id(), m.userId());
        assertEquals(2, rows.size());
        assertEquals(m.rowId(), rows.get(0).getId());
        assertEquals(PartnerMembershipStatus.REVOKED, rows.get(0).getStatus());
        assertEquals("contract ended", rows.get(0).getStatusReason());
        assertTrue(grants(rows.get(0).getId()).isEmpty());
        PartnerTeamMember renewed = rows.get(1);
        assertNotEquals(m.rowId(), renewed.getId());
        assertEquals(PartnerMembershipStatus.ACTIVE, renewed.getStatus());
        assertEquals(0L, renewed.getRevocationKey());
        assertEquals(List.of("FRONT_DESK@PROPERTY:" + t.p1()), grants(renewed.getId()));
        assertTrue(teamIds(t.c()).contains(renewed.getId()) && !teamIds(t.c()).contains(m.rowId()));
        send(get("/api/partner/bookings"), login(m.email())).andExpect(status().isOk());
        // the trail keeps both lives of the membership
        assertEquals(m.rowId(), ((Number) auditRows(t.c().id(), "TEAM_MEMBER_REMOVED").get(0).get("entity_id")).longValue());
        assertFalse(auditRows(t.c().id(), "TEAM_INVITATION_ACCEPTED").isEmpty());
    }

    @Test
    void theDatabaseAllowsOneLiveMembershipPerCompanyAndAccount() throws Exception {
        Team t = team();
        Member m = member(t.c(), "VIEWER");
        PartnerTeamMember duplicate = new PartnerTeamMember();
        duplicate.setPartnerProfile(teamMemberRepo.findById(m.rowId()).orElseThrow().getPartnerProfile());
        duplicate.setUser(userRepo.getReferenceById(m.userId()));
        duplicate.setRole(PartnerTeamRole.VIEWER);
        assertThrows(DataIntegrityViolationException.class, () -> teamMemberRepo.saveAndFlush(duplicate));
        // a revoked row cannot pose as live, and a live row cannot carry a revocation key
        assertThrows(DataIntegrityViolationException.class, () -> jdbc.update(
            "update partner_team_members set status = 'REVOKED', active = false where id = ?", m.rowId()));
        assertThrows(DataIntegrityViolationException.class, () -> jdbc.update(
            "update partner_team_members set revocation_key = 7 where id = ?", m.rowId()));
    }

    @Test
    void leavingIsSelfServiceAuditedAndNotifiedAndTheAccountCanBeInvitedAgain() throws Exception {
        Team t = team();
        Member m = member(t.c(), "REVENUE");
        send(post("/api/partner/team/leave"), m.token()).andExpect(status().isNoContent());
        Map<String, Object> left = auditRows(t.c().id(), "TEAM_MEMBER_LEFT").get(0);
        assertEquals(m.email(), left.get("actor_email"));
        assertTrue(titles(t.c().token()).contains("Team member left"));
        send(post("/api/partner/team/leave"), t.c().token())
            .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("OWNER_PROTECTED"));

        invite(t.c().token(), m.email(), "VIEWER", "COMPANY:" + t.c().id()).andExpect(status().isAccepted());
        accept(login(m.email()), lastToken(m.email())).andExpect(status().isOk());
        assertEquals(2, teamMemberRepo.findByPartnerProfileIdAndUserIdOrderByIdAsc(t.c().id(), m.userId()).size());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Concurrency (§15 step 7, §19 LO-3)
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void twoGrantUpdatesFromTheSameVersionCannotBothWin() throws Exception {
        Team t = team();
        Member m = member(t.c(), "VIEWER");
        long read = version(m.rowId());
        List<Integer> statuses = concurrently(
            () -> send(json(put("/api/partner/team/" + m.rowId() + "/grants"),
                grantsBody(read, "FRONT_DESK", "COMPANY:" + t.c().id())), t.c().token()).andReturn().getResponse().getStatus(),
            () -> send(json(put("/api/partner/team/" + m.rowId() + "/grants"),
                grantsBody(read, "REVENUE", "COMPANY:" + t.c().id())), t.managerCompany().token()).andReturn().getResponse().getStatus());
        assertEquals(1, statuses.stream().filter(s -> s == 200).count(), statuses.toString());
        assertEquals(1, statuses.stream().filter(s -> s == 409).count(), statuses.toString());
        assertEquals(read + 1, version(m.rowId()), "exactly one applied change bumped the version");
        assertEquals(1, grants(m.rowId()).size());
    }

    @Test
    void simultaneousSuspensionsApplyOnceAndSuspendReactivateRacesStayConsistent() throws Exception {
        Team t = team();
        Member m = member(t.c(), "VIEWER");
        List<Integer> statuses = concurrently(
            () -> send(post("/api/partner/team/" + m.rowId() + "/suspend"), t.c().token()).andReturn().getResponse().getStatus(),
            () -> send(post("/api/partner/team/" + m.rowId() + "/suspend"), t.managerCompany().token()).andReturn().getResponse().getStatus());
        assertEquals(List.of(200, 200), statuses);
        assertEquals(1, auditRows(t.c().id(), "TEAM_MEMBER_SUSPENDED").size(), "the second suspension changed nothing");

        statuses = concurrently(
            () -> send(post("/api/partner/team/" + m.rowId() + "/reactivate"), t.c().token()).andReturn().getResponse().getStatus(),
            () -> send(post("/api/partner/team/" + m.rowId() + "/suspend"), t.managerCompany().token()).andReturn().getResponse().getStatus());
        assertEquals(List.of(200, 200), statuses);
        PartnerTeamMember row = teamMemberRepo.findById(m.rowId()).orElseThrow();
        List<String> trail = actions(t.c().id());
        String last = trail.stream().filter(a -> a.equals("TEAM_MEMBER_SUSPENDED") || a.equals("TEAM_MEMBER_REACTIVATED"))
            .reduce((a, b) -> b).orElseThrow();
        assertEquals(last.equals("TEAM_MEMBER_SUSPENDED") ? PartnerMembershipStatus.SUSPENDED : PartnerMembershipStatus.ACTIVE,
            row.getStatus(), "the final state is the last audited transition");
        assertEquals(row.isActive(), row.getStatus() == PartnerMembershipStatus.ACTIVE);
    }

    @Test
    void aRemovalRacingARejoinLeavesAtMostOneLiveMembership() throws Exception {
        Team t = team();
        String email = partnerAccount();
        invite(t.c().token(), email, "VIEWER", "COMPANY:" + t.c().id()).andExpect(status().isAccepted());
        String token = lastToken(email);
        // the account becomes a member another way before accepting (as a seeded membership would)
        Long live = seeder.seed(t.c().id(), email, PartnerTeamRole.VIEWER);
        String memberToken = login(email);

        List<Integer> statuses = concurrently(
            () -> send(delete("/api/partner/team/" + live), t.c().token()).andReturn().getResponse().getStatus(),
            () -> accept(memberToken, token).andReturn().getResponse().getStatus());
        assertEquals(204, statuses.get(0));
        assertTrue(statuses.get(1) == 200 || statuses.get(1) == 409, statuses.toString());
        Long userId = userRepo.findByEmail(email).orElseThrow().getId();
        long liveRows = teamMemberRepo.findByPartnerProfileIdAndUserIdOrderByIdAsc(t.c().id(), userId).stream()
            .filter(r -> r.getStatus() != PartnerMembershipStatus.REVOKED).count();
        assertEquals(statuses.get(1) == 200 ? 1 : 0, liveRows, statuses.toString());
        assertEquals(PartnerMembershipStatus.REVOKED, teamMemberRepo.findById(live).orElseThrow().getStatus());
    }

    @Test
    void twoOwnersRemovingEachOtherCannotLeaveTheCompanyOwnerless() throws Exception {
        Team t = team();
        Member a = member(t.c(), "OWNER");
        Member b = member(t.c(), "OWNER");
        User registrant = userRepo.findById(t.c().userId()).orElseThrow();
        registrant.setEnabled(false);
        userRepo.save(registrant);

        List<Integer> statuses = concurrently(
            () -> send(delete("/api/partner/team/" + b.rowId()), a.token()).andReturn().getResponse().getStatus(),
            () -> send(delete("/api/partner/team/" + a.rowId()), b.token()).andReturn().getResponse().getStatus());
        // the loser either meets LAST_OWNER_REQUIRED or no longer exists as an actor
        assertEquals(1, statuses.stream().filter(s -> s == 204).count(), statuses.toString());
        long activeOwners = List.of(a.rowId(), b.rowId()).stream()
            .map(id -> teamMemberRepo.findById(id).orElseThrow())
            .filter(m -> m.getStatus() == PartnerMembershipStatus.ACTIVE).count();
        assertEquals(1, activeOwners, "the company keeps one active owner");
    }
}
