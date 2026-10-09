package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PartnerSettingsDto.PartnerTeamGrantItem;
import com.example.planyourtrip.dto.PartnerSettingsDto.PartnerTeamGrantView;
import com.example.planyourtrip.dto.PartnerSettingsDto.PartnerTeamGrantsRequest;
import com.example.planyourtrip.dto.PartnerSettingsDto.PartnerTeamMemberRequest;
import com.example.planyourtrip.dto.PartnerSettingsDto.PartnerTeamMemberResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.PartnerMemberGrant;
import com.example.planyourtrip.model.PartnerMembershipStatus;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.PartnerTeamMember;
import com.example.planyourtrip.model.PartnerTeamRole;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.PartnerTeamMemberRepository;
import com.example.planyourtrip.security.rbac.PartnerAccessContext;
import com.example.planyourtrip.security.rbac.PartnerPermission;
import com.example.planyourtrip.security.rbac.ScopePath;
import com.example.planyourtrip.security.rbac.ScopeRef;
import com.example.planyourtrip.security.rbac.ScopeSet;
import com.example.planyourtrip.security.rbac.ScopeType;
import jakarta.persistence.EntityManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.stream.Collectors;

import static com.example.planyourtrip.security.rbac.PartnerPermission.TEAM_REMOVE;
import static com.example.planyourtrip.security.rbac.PartnerPermission.TEAM_ROLE_ASSIGN;
import static com.example.planyourtrip.security.rbac.PartnerPermission.TEAM_SUSPEND;
import static com.example.planyourtrip.security.rbac.PartnerPermission.TEAM_VIEW;

/**
 * RBAC R3a/R4 — team administration (RBAC V1.1 §10.3, §15, §17, §18, §19, §22, §29).
 *
 * <p>Every team mutation, legacy or new, goes through {@link #apply} in this order:
 * <ol>
 *   <li>the endpoint permission (P09–P11) held somewhere in the caller's workspace (403 {@code PERMISSION_DENIED});
 *       since R4 MANAGER holds them too (§31 Q3), bounded by the rules below;</li>
 *   <li>the company row is locked ({@code SELECT … FOR UPDATE}, §19 LO-3) and the target membership is read
 *       under the lock — a target outside the company, or revoked, is 404;</li>
 *   <li>no one modifies their own membership (403 {@code SELF_MODIFICATION_FORBIDDEN}, I7) — leaving is the
 *       one self-service action;</li>
 *   <li>the caller's team view (P07) must cover every grant of the target — otherwise 404, as if missing, so a
 *       scoped manager learns nothing about members outside their scope (§11.2, §26 E5);</li>
 *   <li>the primary owner is immutable inside the workspace (403 {@code OWNER_PROTECTED}, O-1);</li>
 *   <li>authority over the target's current grants and over the new ones (§10.3, {@link PartnerTeamAuthority}):
 *       only owners touch OWNER (403 {@code OWNER_PROTECTED}), MANAGER and FINANCE (403
 *       {@code ROLE_NOT_DELEGABLE}); the action permission must cover every current grant;</li>
 *   <li>every new grant is valid for its scope type and inside the company (422 {@code SCOPE_INVALID}) and
 *       delegable by the caller — never wider than the caller's own grant (403 {@code ROLE_NOT_DELEGABLE}, I6); a
 *       reactivation re-checks the retained grants the same way;</li>
 *   <li>a change that involves an owner — adding, confirming, revoking, suspending, reactivating or removing
 *       one — needs {@code team.owner.manage} (P12) and a fresh session (403 {@code STEP_UP_REQUIRED}, O-7);</li>
 *   <li>the version the client read (409 {@code CONCURRENT_MODIFICATION});</li>
 *   <li>reactivation re-checks one workspace per account (409 {@code WORKSPACE_CONFLICT}, WS-5);</li>
 *   <li>the company keeps at least one active, enabled, confirmed owner (409 {@code LAST_OWNER_REQUIRED}, LO-2),
 *       counted under the lock;</li>
 *   <li>the change, a strict audit row per event (fail closed, AU-1) and the mandatory security notification
 *       to every owner and the member (O-8) — all in one transaction.</li>
 * </ol>
 *
 * <p>Removing a member is a soft revoke: {@code REVOKED}, grants removed, row kept (§17); a revoked membership
 * is never revived (RV-2) — the person is re-invited and joins through a new membership
 * ({@link PartnerInvitationService}). No team action writes {@code users.role} (RV-1, I1). Members are added only
 * through invitations since R4: legacy {@code POST /api/partner/team} is an alias of
 * {@code POST /api/partner/team/invitations} (§29).
 */
@Service
public class PartnerTeamService {

    public static final String OWNER_PROTECTED = "OWNER_PROTECTED";
    public static final String SELF_MODIFICATION_FORBIDDEN = "SELF_MODIFICATION_FORBIDDEN";
    public static final String ROLE_NOT_DELEGABLE = "ROLE_NOT_DELEGABLE";
    public static final String LAST_OWNER_REQUIRED = "LAST_OWNER_REQUIRED";
    public static final String CONCURRENT_MODIFICATION = "CONCURRENT_MODIFICATION";
    public static final String ALREADY_MEMBER = "ALREADY_MEMBER";

    private static final String ENTITY = "TEAM_MEMBER";
    private static final Logger log = LoggerFactory.getLogger(PartnerTeamService.class);

    /** One grant: a role at a scope written {@code TYPE:id}. */
    record GrantSpec(PartnerTeamRole role, ScopeRef scope) {
        String label() { return role.name() + "@" + scope; }
    }

    private final PartnerAccessService access;
    private final PartnerMembershipService memberships;
    private final PartnerTeamAuthority authority;
    private final PartnerTeamMemberRepository members;
    private final PartnerProfileRepository profiles;
    private final PartnerActivityLogService audit;
    private final PartnerSecurityNotifier securityNotifier;
    private final EntityManager entityManager;

    public PartnerTeamService(PartnerAccessService access, PartnerMembershipService memberships,
                              PartnerTeamAuthority authority, PartnerTeamMemberRepository members,
                              PartnerProfileRepository profiles, PartnerActivityLogService audit,
                              PartnerSecurityNotifier securityNotifier, EntityManager entityManager) {
        this.access = access;
        this.memberships = memberships;
        this.authority = authority;
        this.members = members;
        this.profiles = profiles;
        this.audit = audit;
        this.securityNotifier = securityNotifier;
        this.entityManager = entityManager;
    }

    // ── Reads ────────────────────────────────────────────────────────────────

    /**
     * The company's members (not revoked) with their status and grants (§25.3, additive). RBAC R3b — a COLLECTION
     * over team view's scope set (P07): a company holder sees every member; a property holder sees only members all
     * of whose grants lie inside their properties (§11.4), never the owners.
     */
    @Transactional(readOnly = true)
    public List<PartnerTeamMemberResponse> list(Long userId) {
        PartnerAccessContext ctx = access.requireTeamWorkspace(userId);
        ScopeSet scope = access.requireCollection(ctx, TEAM_VIEW);
        return members.findByPartnerProfileIdOrderByCreatedAtAsc(ctx.companyId()).stream()
            .filter(m -> m.getStatus() != PartnerMembershipStatus.REVOKED)
            .filter(m -> scope.companyWide() || within(scope, m))
            .map(m -> toResponse(m, userId)).toList();
    }

    /** Every grant of the membership, as resolved today, lies inside the scope set; a membership with none does not. */
    private boolean within(ScopeSet scope, PartnerTeamMember member) {
        if (memberships.isPrimaryOwner(member)) return false;
        List<ScopePath> grants = memberships.scopesOf(member);
        return !grants.isEmpty() && grants.stream().allMatch(scope::permits);
    }

    /** Administrative read: every membership of the company, revoked history included. */
    @Transactional(readOnly = true)
    public List<PartnerTeamMemberResponse> adminList(Long companyId) {
        return members.findByPartnerProfileIdOrderByCreatedAtAsc(companyId).stream()
            .map(m -> toResponse(m, null)).toList();
    }

    // ── Legacy endpoint (R3a semantics + R4 delegation, §29) ─────────────────

    /**
     * {@code PATCH /api/partner/team/{id}} with {@code role} and/or {@code active}: the same rules as the new
     * endpoints. A role change replaces the company-wide grant and keeps property and unit grants.
     */
    @Transactional
    public PartnerTeamMemberResponse updateLegacy(Long userId, Long memberId, PartnerTeamMemberRequest req) {
        PartnerTeamAuthority.Actor actor = authority.actor(access.requireTeamWorkspace(userId));
        // A role change needs P09, an active change P10; a request carrying neither is judged as a role change.
        PartnerPermission action = req.role() == null && req.active() != null ? TEAM_SUSPEND : TEAM_ROLE_ASSIGN;
        authority.requireSomewhere(actor, action);
        if (req.role() != null && req.active() != null) authority.requireSomewhere(actor, TEAM_SUSPEND);

        PartnerProfile company = lockCompany(actor.companyId());
        PartnerTeamMember member = targetIn(company, memberId);
        List<GrantSpec> newGrants = null;
        if (req.role() != null) {
            newGrants = new ArrayList<>(currentGrants(member).stream()
                .filter(g -> g.scope().type() != ScopeType.COMPANY).toList());
            newGrants.add(new GrantSpec(req.role(), new ScopeRef(ScopeType.COMPANY, company.getId())));
        }
        PartnerMembershipStatus newStatus = req.active() == null ? null
            : req.active() ? PartnerMembershipStatus.ACTIVE : PartnerMembershipStatus.SUSPENDED;
        apply(actor, action, company, member, newGrants, newStatus, null, null);
        return toResponse(member, userId);
    }

    // ── New endpoints (§25.3) ────────────────────────────────────────────────

    /** {@code PUT /api/partner/team/{memberId}/grants} (§15). */
    @Transactional
    public PartnerTeamMemberResponse replaceGrants(Long userId, Long memberId, PartnerTeamGrantsRequest req) {
        requireAuditableReason(req.reason());
        PartnerTeamAuthority.Actor actor = authority.actor(access.requireTeamWorkspace(userId));
        authority.requireSomewhere(actor, TEAM_ROLE_ASSIGN);
        if (req.grants() == null || req.grants().isEmpty())
            throw invalid("grants", "must contain at least one grant (suspend or remove the member instead)");
        if (req.version() == null) throw invalid("version", "is required");
        List<GrantSpec> specs = parseGrants(req.grants());
        PartnerProfile company = lockCompany(actor.companyId());
        PartnerTeamMember member = targetIn(company, memberId);
        apply(actor, TEAM_ROLE_ASSIGN, company, member, specs, null, req.reason(), req.version());
        return toResponse(member, userId);
    }

    /** {@code POST /api/partner/team/{memberId}/suspend} (§17). */
    @Transactional
    public PartnerTeamMemberResponse suspend(Long userId, Long memberId, String reason) {
        return changeStatus(userId, memberId, PartnerMembershipStatus.SUSPENDED, TEAM_SUSPEND, reason);
    }

    /** {@code POST /api/partner/team/{memberId}/reactivate} (§17): same grants, re-checked (§10.3, WS-1). */
    @Transactional
    public PartnerTeamMemberResponse reactivate(Long userId, Long memberId) {
        return changeStatus(userId, memberId, PartnerMembershipStatus.ACTIVE, TEAM_SUSPEND, null);
    }

    /** {@code DELETE /api/partner/team/{memberId}} (§17): soft revoke — {@code REVOKED}, grants removed, row kept. */
    @Transactional
    public void remove(Long userId, Long memberId, String reason) {
        changeStatus(userId, memberId, PartnerMembershipStatus.REVOKED, TEAM_REMOVE, reason);
    }

    /**
     * {@code POST /api/partner/team/leave} (§17, SELF): the caller revokes their own membership. The primary owner
     * cannot leave (O-1, LO-4: 403 {@code OWNER_PROTECTED}); the last qualifying owner cannot either (409).
     */
    @Transactional
    public void leave(Long userId) {
        List<PartnerTeamMember> candidates = memberships.membershipsOf(userId).stream()
            .filter(m -> !memberships.isPrimaryOwner(m)).toList();
        List<PartnerTeamMember> activeOnes = candidates.stream()
            .filter(m -> m.getStatus() == PartnerMembershipStatus.ACTIVE).toList();
        PartnerTeamMember chosen = activeOnes.size() == 1 ? activeOnes.get(0)
            : activeOnes.isEmpty() && candidates.size() == 1 ? candidates.get(0) : null;
        if (chosen == null) {
            if (candidates.size() > 1) {
                throw new ApiException(HttpStatus.CONFLICT, PartnerMembershipService.WORKSPACE_CONFLICT, null,
                    "This account holds more than one membership; ask an owner to remove the one to leave",
                    PartnerMembershipService.REASON_MEMBERSHIP_EXISTS);
            }
            if (profiles.findByUserId(userId).isPresent()) {
                throw new ApiException(HttpStatus.FORBIDDEN, OWNER_PROTECTED,
                    "The primary owner cannot leave the company; ownership must be transferred first");
            }
            throw new ApiException(HttpStatus.NOT_FOUND, "Partner profile not found");
        }
        PartnerProfile company = lockCompany(chosen.getPartnerProfile().getId());
        PartnerTeamMember member = refreshed(chosen);
        if (member.getStatus() == PartnerMembershipStatus.REVOKED) throw new ApiException(HttpStatus.NOT_FOUND, "Partner profile not found");
        apply(null, null, company, member, null, PartnerMembershipStatus.REVOKED, null, null);
    }

    // ── The single mutation path ─────────────────────────────────────────────

    private PartnerTeamMemberResponse changeStatus(Long userId, Long memberId, PartnerMembershipStatus status,
                                                   PartnerPermission permission, String reason) {
        requireAuditableReason(reason);
        PartnerTeamAuthority.Actor actor = authority.actor(access.requireTeamWorkspace(userId));
        authority.requireSomewhere(actor, permission);
        PartnerProfile company = lockCompany(actor.companyId());
        PartnerTeamMember member = targetIn(company, memberId);
        apply(actor, permission, company, member, null, status, reason, null);
        return toResponse(member, userId);
    }

    /**
     * Applies a change to one membership under the company lock, after every check of §10.3/§15/§17/§18/§19. A
     * change that changes nothing is accepted and writes nothing.
     *
     * @param actor     the acting team holder, or null when the member is leaving (the only self-service change)
     * @param action    the team permission the endpoint requires (P09–P11); null when leaving
     * @param newGrants the full new grant list, or null to keep the grants
     * @param newStatus the new status, or null to keep it
     * @param expectedVersion the version the client read, or null (legacy endpoints carry none)
     */
    private void apply(PartnerTeamAuthority.Actor actor, PartnerPermission action, PartnerProfile company,
                       PartnerTeamMember member, List<GrantSpec> newGrants, PartnerMembershipStatus newStatus,
                       String reason, Long expectedVersion) {
        boolean leaving = actor == null;
        Long actorUserId = leaving ? member.getUser().getId() : actor.userId();
        List<GrantSpec> current = currentGrants(member);

        if (!leaving) {
            if (member.getUser().getId().equals(actorUserId)) {
                throw denied(HttpStatus.FORBIDDEN, SELF_MODIFICATION_FORBIDDEN,
                    "You cannot change your own membership", actorUserId, member);
            }
            List<ScopePath> currentScopes = memberships.scopesOf(member);
            if (!authority.sees(actor, currentScopes)) throw notFound(member.getId());
            if (memberships.isPrimaryOwner(member)) {
                throw denied(HttpStatus.FORBIDDEN, OWNER_PROTECTED,
                    "The primary owner cannot be changed from inside the workspace", actorUserId, member);
            }
            authority.requireAuthorityOver(actor, rolesOf(current), member.isPendingOwnerConfirmation());
            if (!authority.covers(actor, action, currentScopes)) {
                throw denied(HttpStatus.FORBIDDEN, ROLE_NOT_DELEGABLE,
                    "Your role cannot manage this member", actorUserId, member);
            }
            if (newGrants != null) {
                authority.requireAuthorityOver(actor, rolesOf(newGrants), false);
                for (GrantSpec g : newGrants) {
                    ScopePath path = memberships.validateGrant(company.getId(), g.role(), g.scope());
                    authority.requireDelegable(actor, action, g.role(), path);
                }
            } else if (newStatus == PartnerMembershipStatus.ACTIVE
                    && member.getStatus() == PartnerMembershipStatus.SUSPENDED) {
                // reactivation hands the retained grants back: they must still be delegable by this actor
                for (PartnerMembershipService.ResolvedGrant g : memberships.resolveGrants(member)) {
                    authority.requireDelegable(actor, action, g.role(), g.scope());
                }
            }
        }

        PartnerMembershipStatus statusBefore = member.getStatus();
        PartnerMembershipStatus statusAfter = newStatus == null ? statusBefore : newStatus;
        boolean grantsChanged = newGrants != null
            && (!labels(current).equals(labels(newGrants)) || member.isPendingOwnerConfirmation());
        boolean statusChanged = statusAfter != statusBefore;
        if (!grantsChanged && !statusChanged) return;

        boolean ownerBefore = memberships.holdsConfirmedOwner(member);
        boolean ownerAfter = statusAfter != PartnerMembershipStatus.REVOKED
            && (newGrants != null ? rolesOf(newGrants).contains(PartnerTeamRole.OWNER) : ownerBefore);
        boolean ownerInvolved = ownerBefore || ownerAfter || (grantsChanged && member.isPendingOwnerConfirmation());
        if (!leaving && ownerInvolved) authority.requireOwnerManagement(actor);

        if (expectedVersion != null && !expectedVersion.equals(member.getVersion())) {
            throw new ApiException(HttpStatus.CONFLICT, CONCURRENT_MODIFICATION,
                "The membership changed since it was read; reload and try again");
        }
        if (statusAfter == PartnerMembershipStatus.ACTIVE && statusBefore == PartnerMembershipStatus.SUSPENDED) {
            memberships.requireCanReactivate(member);
        }

        boolean enabled = member.getUser().isEnabled();
        boolean qualifiedBefore = ownerBefore && statusBefore == PartnerMembershipStatus.ACTIVE && enabled;
        boolean qualifiedAfter = ownerAfter && statusAfter == PartnerMembershipStatus.ACTIVE && enabled;
        if (qualifiedBefore && !qualifiedAfter) {
            Set<Long> remaining = new LinkedHashSet<>(memberships.qualifyingOwnerUserIds(company));
            remaining.remove(member.getUser().getId());
            if (remaining.isEmpty()) {
                throw denied(HttpStatus.CONFLICT, LAST_OWNER_REQUIRED,
                    "The company must keep at least one active owner", actorUserId, member);
            }
        }

        String before = describe(current, member);
        if (grantsChanged) {
            memberships.replaceGrants(member, newGrants.stream()
                .map(g -> Map.entry(g.role(), g.scope())).toList(), actorUserId);
            member.setRole(PartnerMembershipService.highestRole(rolesOf(newGrants)));
            member.setPendingOwnerConfirmation(false);
        }
        if (statusChanged) {
            member.changeStatus(statusAfter, reason, actorUserId);
            if (statusAfter == PartnerMembershipStatus.REVOKED) memberships.deleteGrants(member);
        }
        // Every applied change moves the optimistic version, including a grants-only change (§15 step 7).
        member.setUpdatedAt(Instant.now());
        members.saveAndFlush(member);
        String after = describe(statusAfter == PartnerMembershipStatus.REVOKED ? List.of()
            : grantsChanged ? newGrants : current, member);

        List<String> events = new ArrayList<>();
        if (grantsChanged) {
            events.add(ownerAfter && !ownerBefore ? "OWNER_GRANTED"
                : ownerBefore && !ownerAfter ? "OWNER_REVOKED" : "TEAM_MEMBER_ROLE_CHANGED");
        }
        if (statusChanged) {
            events.add(switch (statusAfter) {
                case SUSPENDED -> "TEAM_MEMBER_SUSPENDED";
                case ACTIVE -> "TEAM_MEMBER_REACTIVATED";
                case REVOKED -> leaving ? "TEAM_MEMBER_LEFT" : "TEAM_MEMBER_REMOVED";
            });
        }
        for (String event : events) {
            audit.audit(company.getId(), actorUserId, event, ENTITY, member.getId(),
                describeEvent(event, member.getId()), before, after, reason);
        }
        securityNotifier.notifyOwners(company, member.getUser().getId(), titleOf(events.get(0)),
            member.getUser().getEmail() + ": " + before + " -> " + after);
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    /** Parses and de-duplicates {@code role}/{@code TYPE:id} items; a malformed scope is 422 {@code SCOPE_INVALID}. */
    static List<GrantSpec> parseGrants(List<PartnerTeamGrantItem> items) {
        List<GrantSpec> specs = new ArrayList<>();
        Set<String> seen = new LinkedHashSet<>();
        for (PartnerTeamGrantItem item : items) {
            if (item == null || item.role() == null) throw invalid("grants", "every grant needs a role");
            ScopeRef scope = ScopeRef.parse(item.scope()).orElseThrow(() -> new ApiException(
                HttpStatus.UNPROCESSABLE_ENTITY, PartnerMembershipService.SCOPE_INVALID, "scope", "The scope is not valid"));
            GrantSpec spec = new GrantSpec(item.role(), scope);
            if (seen.add(spec.label())) specs.add(spec);
        }
        return specs;
    }

    private PartnerProfile lockCompany(Long companyId) {
        return profiles.findByIdForUpdate(companyId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Partner profile not found"));
    }

    /** The membership as the database holds it now, read after the company lock. */
    private PartnerTeamMember targetIn(PartnerProfile company, Long memberId) {
        return members.findById(memberId)
            .filter(m -> m.getPartnerProfile().getId().equals(company.getId()))
            .map(this::refreshed)
            .filter(m -> m.getStatus() != PartnerMembershipStatus.REVOKED)
            .orElseThrow(() -> notFound(memberId));
    }

    private PartnerTeamMember refreshed(PartnerTeamMember member) {
        entityManager.refresh(member);
        return member;
    }

    private static ApiException notFound(Long memberId) {
        return new ApiException(HttpStatus.NOT_FOUND, "Team member not found: " + memberId);
    }

    /**
     * RBAC R4 hardening — a reason is written verbatim to the strict audit trail, whose guard refuses
     * credential-looking text and would fail the whole mutation (fail closed). Checked first, before the workspace
     * is resolved or the company locked, so such input is a plain 400 and nothing starts. The value is never echoed
     * or logged. Requests are already refused by {@code @NoCredentialText}; this covers every other caller.
     */
    static void requireAuditableReason(String reason) {
        if (AdminActivityLogService.looksLikeCredential(reason)) {
            throw invalid("reason", "must not contain passwords, secrets, keys, tokens or card or account numbers");
        }
    }

    static ApiException invalid(String field, String message) {
        return new ApiException(HttpStatus.BAD_REQUEST, "VALIDATION_FAILED", field, message);
    }

    /** §22.4: a refused team mutation is logged at WARN with ids only — it is not a business event. */
    private static ApiException denied(HttpStatus status, String code, String message, Long actorUserId,
                                       PartnerTeamMember member) {
        log.warn("Team mutation refused ({}): actor {} target member {}", code, actorUserId, member.getId());
        return new ApiException(status, code, message);
    }

    // ── Rendering ────────────────────────────────────────────────────────────

    private List<GrantSpec> currentGrants(PartnerTeamMember member) {
        List<GrantSpec> specs = new ArrayList<>();
        for (PartnerMemberGrant g : memberships.grantsOf(member)) {
            specs.add(new GrantSpec(g.getRole(), new ScopeRef(g.getScopeType(), g.getScopeId())));
        }
        return specs;
    }

    private static Set<PartnerTeamRole> rolesOf(List<GrantSpec> specs) {
        return specs.stream().map(GrantSpec::role).collect(Collectors.toSet());
    }

    static Set<String> labels(List<GrantSpec> specs) {
        return specs.stream().map(GrantSpec::label).collect(Collectors.toCollection(TreeSet::new));
    }

    /** A safe scalar for the audit trail, e.g. {@code FRONT_DESK@PROPERTY:123,MANAGER@COMPANY:456|ACTIVE}. */
    private static String describe(List<GrantSpec> grants, PartnerTeamMember member) {
        String state = String.join(",", labels(grants)) + "|" + member.getStatus().name();
        return member.isPendingOwnerConfirmation() ? state + "|PENDING_OWNER_CONFIRMATION" : state;
    }

    private static String describeEvent(String event, Long memberId) {
        return switch (event) {
            case "OWNER_GRANTED" -> "Owner granted to team member #" + memberId;
            case "OWNER_REVOKED" -> "Owner revoked from team member #" + memberId;
            case "TEAM_MEMBER_ROLE_CHANGED" -> "Grants of team member #" + memberId + " changed";
            case "TEAM_MEMBER_SUSPENDED" -> "Team member #" + memberId + " suspended";
            case "TEAM_MEMBER_REACTIVATED" -> "Team member #" + memberId + " reactivated";
            case "TEAM_MEMBER_REMOVED" -> "Team member #" + memberId + " removed";
            case "TEAM_MEMBER_LEFT" -> "Team member #" + memberId + " left the team";
            default -> event;
        };
    }

    private static String titleOf(String event) {
        return switch (event) {
            case "OWNER_GRANTED" -> "Owner granted";
            case "OWNER_REVOKED" -> "Owner revoked";
            case "TEAM_MEMBER_ROLE_CHANGED" -> "Team member role changed";
            case "TEAM_MEMBER_SUSPENDED" -> "Team member suspended";
            case "TEAM_MEMBER_REACTIVATED" -> "Team member reactivated";
            case "TEAM_MEMBER_REMOVED" -> "Team member removed";
            case "TEAM_MEMBER_LEFT" -> "Team member left";
            default -> "Team security event";
        };
    }

    private PartnerTeamMemberResponse toResponse(PartnerTeamMember m, Long viewerUserId) {
        List<PartnerTeamGrantView> grants = memberships.grantsOf(m).stream()
            .map(g -> new PartnerTeamGrantView(g.getRole().name(), g.getScopeType().name() + ":" + g.getScopeId()))
            .toList();
        return new PartnerTeamMemberResponse(
            m.getId(), m.getPartnerProfile().getId(),
            m.getUser().getId(), m.getUser().getFullName(), m.getUser().getEmail(),
            m.getRole().name(), m.isActive(),
            m.getInvitedAt(), m.getJoinedAt(), m.getCreatedAt(), m.getUpdatedAt(),
            m.getStatus().name(), grants, memberships.isPrimaryOwner(m), m.isPendingOwnerConfirmation(),
            viewerUserId != null && viewerUserId.equals(m.getUser().getId()), m.getVersion());
    }
}
