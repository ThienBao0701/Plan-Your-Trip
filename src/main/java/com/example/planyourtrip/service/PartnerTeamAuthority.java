package com.example.planyourtrip.service;

import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.PartnerTeamRole;
import com.example.planyourtrip.security.StepUpPolicy;
import com.example.planyourtrip.security.rbac.AuthorizationDecision;
import com.example.planyourtrip.security.rbac.PartnerAccessContext;
import com.example.planyourtrip.security.rbac.PartnerAuthorization;
import com.example.planyourtrip.security.rbac.PartnerPermission;
import com.example.planyourtrip.security.rbac.PartnerRoleBundles;
import com.example.planyourtrip.security.rbac.ScopePath;
import com.example.planyourtrip.security.rbac.ScopeSet;
import com.example.planyourtrip.security.rbac.ScopeType;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collection;
import java.util.Set;

/**
 * RBAC R4 — who may act on whom in the team, and what they may hand out (RBAC V1.1 §10.3, §11.4, §18, I6–I8).
 * Shared by team mutations ({@link PartnerTeamService}) and invitations ({@link PartnerInvitationService}), so
 * both apply one rule set, always through the R1/R3b kernel ({@link PartnerAuthorization}) and never through a
 * role-name shortcut.
 *
 * <ul>
 *   <li><b>Visibility.</b> A membership or invitation is a resource whose scope is the set of its grants; a team
 *       holder sees it only when their team view (P07) covers <em>every</em> grant (§11.2, §11.4). Anything else is
 *       answered 404, exactly like a missing id — a property-scoped manager learns nothing about the rest of the
 *       team.</li>
 *   <li><b>Authority (§10.3).</b> Owners manage everyone but the primary owner (O-1). A non-owner never touches a
 *       membership or grant involving OWNER (403 {@code OWNER_PROTECTED}) nor one involving MANAGER or FINANCE
 *       (403 {@code ROLE_NOT_DELEGABLE}): a membership is held at its highest-authority role.</li>
 *   <li><b>Delegation (I6).</b> Each new grant must be covered by the action permission, and every permission the
 *       grant would carry at its scope type (its role bundle, cut by floors) must be held by the actor at a scope
 *       covering the grant's scope — so a grant is never wider than the actor's own (a {@code PROPERTY:123}
 *       manager cannot assign {@code COMPANY} or {@code PROPERTY:124}; 403 {@code ROLE_NOT_DELEGABLE}).</li>
 *   <li><b>Owner management (O-2, O-7).</b> Anything that adds, confirms or removes an owner needs P12 — held only
 *       by confirmed owners — and a fresh session.</li>
 * </ul>
 */
@Component
public class PartnerTeamAuthority {

    private static final Logger log = LoggerFactory.getLogger(PartnerTeamAuthority.class);

    /** Roles only an owner may manage (§10.3 columns OWNER, MANAGER, FINANCE). */
    private static final Set<PartnerTeamRole> OWNER_MANAGED =
        Set.of(PartnerTeamRole.OWNER, PartnerTeamRole.MANAGER, PartnerTeamRole.FINANCE);

    /** The acting user in their workspace, and whether they are a confirmed owner of it. */
    public record Actor(PartnerAccessContext ctx, boolean owner) {
        public Long userId() { return ctx.userId(); }
        public Long companyId() { return ctx.companyId(); }
    }

    private final PartnerMembershipService memberships;
    private final StepUpPolicy stepUp;

    public PartnerTeamAuthority(PartnerMembershipService memberships, StepUpPolicy stepUp) {
        this.memberships = memberships;
        this.stepUp = stepUp;
    }

    @Transactional(readOnly = true)
    public Actor actor(PartnerAccessContext ctx) {
        return new Actor(ctx, isOwner(ctx));
    }

    /** The registrant, or an ACTIVE member of this company holding a confirmed {@code OWNER@COMPANY} grant. */
    @Transactional(readOnly = true)
    public boolean isOwner(PartnerAccessContext ctx) {
        if (ctx.registrant()) return true;
        return memberships.activeTeamMembership(ctx.userId())
            .filter(m -> m.getPartnerProfile().getId().equals(ctx.companyId()))
            .map(memberships::holdsConfirmedOwner).orElse(false);
    }

    /** 403 {@code PERMISSION_DENIED} when the actor holds the team permission nowhere (§26 E7). */
    public void requireSomewhere(Actor actor, PartnerPermission permission) {
        if (PartnerAuthorization.effectiveScopes(actor.ctx(), permission).isEmpty()) {
            log.warn("Team action refused for user {}: {} held nowhere", actor.userId(), permission.key());
            throw new ApiException(HttpStatus.FORBIDDEN, PartnerAccessService.PERMISSION_DENIED,
                "Your role cannot manage team members");
        }
    }

    /**
     * Whether the actor's team view covers a membership or invitation whose grants resolve to {@code scopes}. A
     * company-wide team view sees everything in the company; a narrower one sees only items with at least one grant,
     * all of them inside it.
     */
    public boolean sees(Actor actor, Collection<ScopePath> scopes) {
        ScopeSet view = PartnerAuthorization.collection(actor.ctx(), PartnerPermission.TEAM_VIEW);
        if (view.companyWide()) return true;
        return !scopes.isEmpty() && scopes.stream().allMatch(view::permits);
    }

    /** Whether {@code permission} is held at scopes covering every one of {@code scopes} (all of a member's grants). */
    public boolean covers(Actor actor, PartnerPermission permission, Collection<ScopePath> scopes) {
        Set<ScopePath> held = PartnerAuthorization.effectiveScopes(actor.ctx(), permission);
        if (scopes.isEmpty()) return held.stream().anyMatch(s -> s.type() == ScopeType.COMPANY);
        return scopes.stream().allMatch(target -> held.stream().anyMatch(s -> s.covers(target)));
    }

    /** §10.3 authority over memberships or grants holding {@code roles}; {@code pendingOwner} counts as OWNER (O-9). */
    public void requireAuthorityOver(Actor actor, Set<PartnerTeamRole> roles, boolean pendingOwner) {
        if (actor.owner()) return;
        if (pendingOwner || roles.contains(PartnerTeamRole.OWNER)) {
            throw refused(actor, OWNER_PROTECTED, "Only an owner can manage an owner");
        }
        if (roles.stream().anyMatch(OWNER_MANAGED::contains)) {
            throw refused(actor, ROLE_NOT_DELEGABLE, "Your role cannot manage this member");
        }
    }

    /**
     * I6 delegation for one new grant of {@code role} at {@code target}: the action permission covers the target,
     * and every permission the grant would carry there is held by the actor at a covering scope.
     */
    public void requireDelegable(Actor actor, PartnerPermission action, PartnerTeamRole role, ScopePath target) {
        Set<ScopePath> actionScopes = PartnerAuthorization.effectiveScopes(actor.ctx(), action);
        boolean allowed = actionScopes.stream().anyMatch(s -> s.covers(target));
        if (allowed) {
            for (PartnerPermission carried : PartnerRoleBundles.effective(role)) {
                if (!carried.floor().admits(target.type())) continue; // ineffective at this scope type anyway
                if (PartnerAuthorization.effectiveScopes(actor.ctx(), carried).stream().noneMatch(s -> s.covers(target))) {
                    allowed = false;
                    break;
                }
            }
        }
        if (!allowed) {
            throw refused(actor, ROLE_NOT_DELEGABLE, "You cannot grant this role at this scope");
        }
    }

    /** O-2 and O-7: {@code team.owner.manage} (owners only, non-delegable) and a fresh session. */
    public void requireOwnerManagement(Actor actor) {
        if (!actor.owner()
                || PartnerAuthorization.company(actor.ctx(), PartnerPermission.TEAM_OWNER_MANAGE) != AuthorizationDecision.ALLOW) {
            log.warn("Owner management refused for user {} (P12 not held)", actor.userId());
            throw new ApiException(HttpStatus.FORBIDDEN, OWNER_PROTECTED, "Only an owner can manage owners");
        }
        if (!stepUp.isFresh()) log.warn("Owner management refused for user {}: step-up required", actor.userId());
        stepUp.requireFresh();
    }

    private static final String OWNER_PROTECTED = PartnerTeamService.OWNER_PROTECTED;
    private static final String ROLE_NOT_DELEGABLE = PartnerTeamService.ROLE_NOT_DELEGABLE;

    /** §22.4: a refused team action is logged at WARN with ids only — it is not a business event. */
    private static ApiException refused(Actor actor, String code, String message) {
        log.warn("Team action refused ({}): actor {} in company {}", code, actor.userId(), actor.companyId());
        return new ApiException(HttpStatus.FORBIDDEN, code, message);
    }
}
