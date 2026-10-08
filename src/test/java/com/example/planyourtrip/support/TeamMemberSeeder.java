package com.example.planyourtrip.support;

import com.example.planyourtrip.model.PartnerMembershipStatus;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.PartnerTeamMember;
import com.example.planyourtrip.model.PartnerTeamRole;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.PartnerTeamMemberRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.security.rbac.ScopeRef;
import com.example.planyourtrip.security.rbac.ScopeType;
import com.example.planyourtrip.service.PartnerMembershipService;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

/**
 * Test fixture — puts an existing PARTNER account into a company's team.
 *
 * <p>Since RBAC R4 members join only by accepting an invitation, and legacy {@code POST /api/partner/team} is an
 * alias of the invitation endpoint (§29). Tests whose subject is not the invitation flow use this seeder instead;
 * it calls {@link PartnerMembershipService#createMembership}, the method invitation acceptance itself uses, so the
 * resulting membership and grants are exactly what an accepted invitation produces. The invitation flow is
 * covered end to end by {@code RbacTeamInvitationTest}.
 */
@Component
public class TeamMemberSeeder {

    private final PartnerMembershipService memberships;
    private final PartnerProfileRepository profiles;
    private final PartnerTeamMemberRepository members;
    private final UserRepository users;

    public TeamMemberSeeder(PartnerMembershipService memberships, PartnerProfileRepository profiles,
                            PartnerTeamMemberRepository members, UserRepository users) {
        this.memberships = memberships;
        this.profiles = profiles;
        this.members = members;
        this.users = users;
    }

    /** {@code role} at company scope, ACTIVE. Returns the membership id. */
    @Transactional
    public Long seed(Long companyId, String email, PartnerTeamRole role) {
        return seed(companyId, email, List.of(Map.entry(role, new ScopeRef(ScopeType.COMPANY, companyId))), true);
    }

    /** {@code role} at company scope, ACTIVE or SUSPENDED. Returns the membership id. */
    @Transactional
    public Long seed(Long companyId, String email, PartnerTeamRole role, boolean active) {
        return seed(companyId, email, List.of(Map.entry(role, new ScopeRef(ScopeType.COMPANY, companyId))), active);
    }

    /** The given grants, ACTIVE or SUSPENDED. Returns the membership id. */
    @Transactional
    public Long seed(Long companyId, String email, List<Map.Entry<PartnerTeamRole, ScopeRef>> grants, boolean active) {
        PartnerProfile company = profiles.findById(companyId).orElseThrow();
        User user = users.findByEmail(email.trim().toLowerCase()).orElseThrow();
        PartnerTeamMember member = memberships.createMembership(company, user, grants, company.getUser().getId(), null);
        if (!active) {
            member.changeStatus(PartnerMembershipStatus.SUSPENDED, null, company.getUser().getId());
            members.saveAndFlush(member);
        }
        return member.getId();
    }
}
