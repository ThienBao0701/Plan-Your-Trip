package com.example.planyourtrip.service;

import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.PartnerMemberGrant;
import com.example.planyourtrip.model.PartnerMembershipStatus;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.PartnerTeamMember;
import com.example.planyourtrip.model.PartnerTeamRole;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PartnerMemberGrantRepository;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.PartnerTeamMemberRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.security.rbac.PartnerGrant;
import com.example.planyourtrip.security.rbac.PartnerPermission;
import com.example.planyourtrip.security.rbac.PartnerRoleScopes;
import com.example.planyourtrip.security.rbac.ResourceType;
import com.example.planyourtrip.security.rbac.ScopePath;
import com.example.planyourtrip.security.rbac.ScopeRef;
import com.example.planyourtrip.security.rbac.ScopeType;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.EnumSet;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.function.Function;

/**
 * RBAC R2 — the persistent membership and scope foundation (RBAC V1.1 §11, §12.3, §28 M-1/M-2).
 *
 * <p>Answers, from stored data only: which memberships a user has, which company a membership belongs to,
 * which grants it holds and which company, property or room type each grant covers. It also writes grants
 * and enforces the one-workspace-per-account invariant (§11.6, I21).
 *
 * <p>Since RBAC R3b the stored grants decide every request ({@link #kernelGrants}); since R4 memberships are also
 * created here from accepted invitations ({@link #createMembership}).
 *
 * <p>Every read fails closed: a grant whose property or room no longer belongs to the membership's company,
 * or whose stored shape does not match the design, resolves to nothing.
 */
@Service
public class PartnerMembershipService {

    public static final String WORKSPACE_CONFLICT = "WORKSPACE_CONFLICT";
    public static final String MEMBER_NOT_ADDABLE = "MEMBER_NOT_ADDABLE";
    public static final String SCOPE_INVALID = "SCOPE_INVALID";
    public static final String REASON_MEMBERSHIP_EXISTS = "MEMBERSHIP_EXISTS";
    public static final String REASON_OWN_PROFILE_EXISTS = "OWN_PROFILE_EXISTS";

    private static final Logger log = LoggerFactory.getLogger(PartnerMembershipService.class);
    private static final Set<PartnerMembershipStatus> NOT_REVOKED =
        EnumSet.of(PartnerMembershipStatus.ACTIVE, PartnerMembershipStatus.SUSPENDED);

    /** A stored grant whose scope the server has resolved against current ownership. */
    public record ResolvedGrant(Long grantId, PartnerTeamRole role, ScopePath scope) {}

    /** Highest authority first (§10.3); the legacy {@code role} column shows the highest grant. */
    public static final List<PartnerTeamRole> AUTHORITY_ORDER = List.of(
        PartnerTeamRole.OWNER, PartnerTeamRole.MANAGER, PartnerTeamRole.FINANCE, PartnerTeamRole.REVENUE,
        PartnerTeamRole.RESERVATIONS, PartnerTeamRole.FRONT_DESK, PartnerTeamRole.CONTENT,
        PartnerTeamRole.HOUSEKEEPING, PartnerTeamRole.VIEWER);

    /** The highest-authority role among {@code roles} (§10.3: a membership is held at its highest role). */
    public static PartnerTeamRole highestRole(java.util.Collection<PartnerTeamRole> roles) {
        return roles.stream().min(java.util.Comparator.comparingInt(AUTHORITY_ORDER::indexOf))
            .orElseThrow(() -> new IllegalArgumentException("A membership needs at least one grant"));
    }

    private final PartnerTeamMemberRepository members;
    private final PartnerMemberGrantRepository grants;
    private final PartnerProfileRepository profiles;
    private final PlaceRepository places;
    private final HotelRoomRepository rooms;
    private final PartnerResourceTargetResolver targets;

    public PartnerMembershipService(PartnerTeamMemberRepository members,
                                    PartnerMemberGrantRepository grants,
                                    PartnerProfileRepository profiles,
                                    PlaceRepository places,
                                    HotelRoomRepository rooms,
                                    PartnerResourceTargetResolver targets) {
        this.members = members;
        this.grants = grants;
        this.profiles = profiles;
        this.places = places;
        this.rooms = rooms;
        this.targets = targets;
    }

    // ── Memberships ──────────────────────────────────────────────────────────

    /** Every membership of the user that is not revoked, in any company — including their own company's row. */
    @Transactional(readOnly = true)
    public List<PartnerTeamMember> membershipsOf(Long userId) {
        if (userId == null) return List.of();
        return members.findByUserIdAndStatusIn(userId, NOT_REVOKED);
    }

    /**
     * The user's single active membership of a company they did not register, or empty. Two or more such
     * memberships break the one-workspace invariant; rather than guess which one counts (today the legacy
     * lookup throws), this fails closed and returns nothing.
     */
    @Transactional(readOnly = true)
    public Optional<PartnerTeamMember> activeTeamMembership(Long userId) {
        List<PartnerTeamMember> active = membershipsOf(userId).stream()
            .filter(m -> m.getStatus() == PartnerMembershipStatus.ACTIVE)
            .filter(m -> !isRegistrantRow(m))
            .toList();
        if (active.size() > 1) {
            log.warn("User {} holds {} active partner memberships; refusing to choose one (WS-1)", userId, active.size());
            return Optional.empty();
        }
        return active.stream().findFirst();
    }

    /** The company a membership belongs to. */
    public PartnerProfile companyOf(PartnerTeamMember membership) {
        return membership.getPartnerProfile();
    }

    // ── One workspace per account (§11.6 WS-1, WS-2, WS-5) ───────────────────

    /**
     * Why the user may not register a company of their own, or empty. A user who holds a non-revoked
     * membership of another company must leave it first (WS-2).
     */
    @Transactional(readOnly = true)
    public Optional<String> companyCreationConflict(Long userId) {
        boolean memberElsewhere = membershipsOf(userId).stream().anyMatch(m -> !isRegistrantRow(m));
        return memberElsewhere ? Optional.of(REASON_MEMBERSHIP_EXISTS) : Optional.empty();
    }

    /** {@code 409 WORKSPACE_CONFLICT} with its {@code reason} when {@link #companyCreationConflict} finds one. */
    @Transactional(readOnly = true)
    public void requireCanCreateCompany(Long userId) {
        companyCreationConflict(userId).ifPresent(reason -> {
            throw new ApiException(HttpStatus.CONFLICT, WORKSPACE_CONFLICT, null,
                "This account already belongs to a partner team and cannot register another company", reason);
        });
    }

    /**
     * Why the user may not hold a membership of {@code companyId} in the given state, or empty: they
     * registered another company (WS-1), or the membership would be a second active one (WS-1).
     */
    @Transactional(readOnly = true)
    public Optional<String> joinConflict(Long userId, Long companyId, boolean active) {
        Optional<PartnerProfile> own = profiles.findByUserId(userId);
        if (own.isPresent() && !own.get().getId().equals(companyId)) return Optional.of(REASON_OWN_PROFILE_EXISTS);
        if (!active) return Optional.empty();
        boolean activeElsewhere = membershipsOf(userId).stream()
            .filter(m -> m.getStatus() == PartnerMembershipStatus.ACTIVE)
            .filter(m -> !isRegistrantRow(m))
            .anyMatch(m -> !m.getPartnerProfile().getId().equals(companyId));
        return activeElsewhere ? Optional.of(REASON_MEMBERSHIP_EXISTS) : Optional.empty();
    }

    /** For adding a member: {@code 422 MEMBER_NOT_ADDABLE}, the same answer whatever the conflict is. */
    @Transactional(readOnly = true)
    public void requireCanJoin(Long userId, Long companyId, boolean active) {
        if (joinConflict(userId, companyId, active).isPresent()) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, MEMBER_NOT_ADDABLE,
                "This account cannot be added to the team");
        }
    }

    /** For reactivating a suspended membership (WS-5): {@code 409 WORKSPACE_CONFLICT} with its {@code reason}. */
    @Transactional(readOnly = true)
    public void requireCanReactivate(PartnerTeamMember membership) {
        joinConflict(membership.getUser().getId(), membership.getPartnerProfile().getId(), true)
            .ifPresent(reason -> {
                throw new ApiException(HttpStatus.CONFLICT, WORKSPACE_CONFLICT, null,
                    "This member already belongs to another partner workspace", reason);
            });
    }

    // ── Memberships: writing (RBAC R4) ───────────────────────────────────────

    /**
     * RBAC R4 — creates a NEW live membership with exactly {@code newGrants} (§14 step 7). Never revives a revoked
     * row (RV-2): the account's revoked memberships of the company stay as history, and the database key
     * {@code uk_partner_team_members_live} refuses a second live membership of the same company and account. The
     * caller has validated the grants, the one-workspace rule and its authority, under the company lock.
     */
    @Transactional
    public PartnerTeamMember createMembership(PartnerProfile company, com.example.planyourtrip.model.User user,
                                              List<Map.Entry<PartnerTeamRole, ScopeRef>> newGrants,
                                              Long actorUserId, java.time.Instant invitedAt) {
        if (newGrants == null || newGrants.isEmpty()) throw new IllegalArgumentException("A membership needs a grant");
        PartnerTeamMember member = new PartnerTeamMember();
        member.setPartnerProfile(company);
        member.setUser(user);
        member.setRole(highestRole(newGrants.stream().map(Map.Entry::getKey).toList()));
        member.setActive(true, actorUserId);
        java.time.Instant now = java.time.Instant.now();
        member.setInvitedAt(invitedAt == null ? now : invitedAt);
        member.setJoinedAt(now);
        PartnerTeamMember saved = members.saveAndFlush(member);
        for (Map.Entry<PartnerTeamRole, ScopeRef> g : newGrants) grant(saved, g.getKey(), g.getValue(), actorUserId);
        grants.flush();
        return saved;
    }

    // ── Grants: writing ──────────────────────────────────────────────────────

    /**
     * Grants {@code role} at {@code scope} to a membership. The scope is resolved against the membership's
     * company from stored data — the company id, property or room type named by the caller is a claim, not
     * a fact — and refused with {@code 422 SCOPE_INVALID} when the role may not sit at that scope type or the
     * scope lies outside the company. The answer never says whether the scope exists elsewhere. Granting
     * what the membership already holds returns the existing grant.
     */
    @Transactional
    public PartnerMemberGrant grant(PartnerTeamMember membership, PartnerTeamRole role, ScopeRef scope,
                                    Long createdBy) {
        if (membership == null || membership.getId() == null)
            throw new IllegalArgumentException("Grants belong to a stored membership");
        if (membership.getStatus() == PartnerMembershipStatus.REVOKED)
            throw new IllegalStateException("A revoked membership cannot receive grants");
        if (scope == null || !PartnerRoleScopes.allows(role, scope.type()))
            throw scopeInvalid("This role cannot be granted at this scope");

        Long companyId = membership.getPartnerProfile().getId();
        ScopePath path = targets.resolveGrantScope(companyId, scope)
            .orElseThrow(() -> scopeInvalid("The scope does not belong to this company"));

        Optional<PartnerMemberGrant> existing = grants.findByTeamMemberIdAndRoleAndScopeTypeAndScopeId(
            membership.getId(), role, scope.type(), scope.id());
        if (existing.isPresent()) return existing.get();

        PartnerMemberGrant grant = switch (scope.type()) {
            case COMPANY -> PartnerMemberGrant.company(membership, role, createdBy);
            case PROPERTY -> PartnerMemberGrant.property(membership, role,
                places.getReferenceById(path.propertyId()), createdBy);
            case UNIT -> PartnerMemberGrant.unit(membership, role, places.getReferenceById(path.propertyId()),
                rooms.getReferenceById(path.unitId()), createdBy);
        };
        return grants.save(grant);
    }

    /**
     * Keeps the membership's company-wide grant equal to its legacy role (§28 M-2: "mirroring role
     * exactly"). Called whenever the legacy team endpoints or partner approval create a membership or change
     * its role. Property and unit grants are left alone.
     */
    @Transactional
    public void syncLegacyCompanyGrant(PartnerTeamMember membership, Long actorUserId) {
        if (membership.getStatus() == PartnerMembershipStatus.REVOKED) return;
        List<PartnerMemberGrant> companyGrants =
            grants.findByTeamMemberIdAndScopeType(membership.getId(), ScopeType.COMPANY);
        boolean mirrored = false;
        for (PartnerMemberGrant grant : companyGrants) {
            if (grant.getRole() == membership.getRole()) {
                mirrored = true;
            } else {
                grants.delete(grant);
            }
        }
        grants.flush();
        if (!mirrored) {
            grant(membership, membership.getRole(),
                new ScopeRef(ScopeType.COMPANY, membership.getPartnerProfile().getId()), actorUserId);
        }
    }

    /** Removes every grant of a membership; required before the legacy hard delete of the membership. */
    @Transactional
    public void deleteGrants(PartnerTeamMember membership) {
        grants.deleteByTeamMemberId(membership.getId());
        grants.flush();
    }

    // ── Grants: reading ──────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<PartnerMemberGrant> grantsOf(PartnerTeamMember membership) {
        return grants.findByTeamMemberIdOrderByIdAsc(membership.getId());
    }

    /**
     * The membership's grants with their scope resolved against current ownership. A grant is dropped —
     * never widened — when its company is not the membership's, its role may not sit at its scope type, its
     * property or room type no longer belongs to the company, or a unit grant's recorded property is not the
     * room type's property.
     */
    @Transactional(readOnly = true)
    public List<ResolvedGrant> resolveGrants(PartnerTeamMember membership) {
        Long companyId = membership.getPartnerProfile().getId();
        List<ResolvedGrant> resolved = new ArrayList<>();
        for (PartnerMemberGrant grant : grantsOf(membership)) {
            resolveStored(grant, companyId).ifPresentOrElse(
                path -> resolved.add(new ResolvedGrant(grant.getId(), grant.getRole(), path)),
                () -> log.warn("Ignoring partner grant {}: its scope does not resolve inside company {}",
                    grant.getId(), companyId));
        }
        return resolved;
    }

    /** RBAC R4 — the scopes of a membership's grants as they resolve today (its scope as a team resource, §11.2). */
    @Transactional(readOnly = true)
    public List<ScopePath> scopesOf(PartnerTeamMember membership) {
        return resolveGrants(membership).stream().map(ResolvedGrant::scope).toList();
    }

    /**
     * The R1 kernel's view of a membership's stored grants: each resolved grant becomes a
     * {@link PartnerGrant} carrying the bundle {@code bundles} gives its role. A membership that is not
     * active holds nothing. R2 does not use this to decide any request.
     */
    @Transactional(readOnly = true)
    public List<PartnerGrant> kernelGrants(PartnerTeamMember membership,
                                           Function<PartnerTeamRole, Set<PartnerPermission>> bundles) {
        if (membership.getStatus() != PartnerMembershipStatus.ACTIVE) return List.of();
        return resolveGrants(membership).stream()
            .map(g -> new PartnerGrant(bundles.apply(g.role()), g.scope()))
            .toList();
    }

    /**
     * RBAC R3a — validates one grant for a company without writing it: the role may sit at the scope type
     * (§11.3) and the scope resolves inside the company from stored ownership; 422 {@code SCOPE_INVALID}
     * otherwise, with the same answer for another company's id and a missing id.
     */
    @Transactional(readOnly = true)
    public ScopePath validateGrant(Long companyId, PartnerTeamRole role, ScopeRef scope) {
        if (scope == null || !PartnerRoleScopes.allows(role, scope.type()))
            throw scopeInvalid("This role cannot be granted at this scope");
        return targets.resolveGrantScope(companyId, scope)
            .orElseThrow(() -> scopeInvalid("The scope does not belong to this company"));
    }

    /** RBAC R3a — replaces every grant of a membership (§15 step 8). The caller has validated them. */
    @Transactional
    public void replaceGrants(PartnerTeamMember membership, List<Map.Entry<PartnerTeamRole, ScopeRef>> newGrants,
                              Long actorUserId) {
        deleteGrants(membership);
        for (Map.Entry<PartnerTeamRole, ScopeRef> g : newGrants) grant(membership, g.getKey(), g.getValue(), actorUserId);
    }

    // ── Owners (RBAC R3a, §18, §19) ──────────────────────────────────────────

    /** The registrant's own row: the primary owner, immutable inside the workspace (§18 O-1). */
    public boolean isPrimaryOwner(PartnerTeamMember membership) {
        return isRegistrantRow(membership);
    }

    /** Holds a confirmed {@code OWNER@COMPANY} grant; a co-owner pending confirmation does not (§18 O-9). */
    @Transactional(readOnly = true)
    public boolean holdsConfirmedOwner(PartnerTeamMember membership) {
        return !membership.isPendingOwnerConfirmation()
            && grants.existsByTeamMemberIdAndRoleAndScopeType(membership.getId(), PartnerTeamRole.OWNER, ScopeType.COMPANY);
    }

    /**
     * Every owner of the company who must receive security notifications (§18 O-8): the primary owner and the
     * ACTIVE confirmed co-owners.
     */
    @Transactional(readOnly = true)
    public Set<Long> activeOwnerUserIds(PartnerProfile company) {
        Set<Long> owners = new LinkedHashSet<>();
        owners.add(company.getUser().getId());
        for (PartnerTeamMember m : grants.findMembersHolding(company.getId(), PartnerTeamRole.OWNER, ScopeType.COMPANY,
                PartnerMembershipStatus.ACTIVE)) {
            owners.add(m.getUser().getId());
        }
        return owners;
    }

    /**
     * The owners that keep a company reachable (§19 LO-1): ACTIVE, confirmed, account enabled. The primary owner
     * counts while their account is enabled — O-1 makes their ownership implicit and unremovable in the workspace.
     */
    @Transactional(readOnly = true)
    public Set<Long> qualifyingOwnerUserIds(PartnerProfile company) {
        Set<Long> owners = new LinkedHashSet<>();
        if (company.getUser().isEnabled()) owners.add(company.getUser().getId());
        for (PartnerTeamMember m : grants.findMembersHolding(company.getId(), PartnerTeamRole.OWNER, ScopeType.COMPANY,
                PartnerMembershipStatus.ACTIVE)) {
            if (m.getUser().isEnabled()) owners.add(m.getUser().getId());
        }
        return owners;
    }

    // ── Containment ──────────────────────────────────────────────────────────

    /** Whether the property is owned by the company today. */
    @Transactional(readOnly = true)
    public boolean propertyBelongsToCompany(Long propertyId, Long companyId) {
        return companyId != null && targets.resolve(ResourceType.PROPERTY, propertyId)
            .map(p -> p.companyId().equals(companyId)).orElse(false);
    }

    /** Whether the room type belongs to the property. */
    @Transactional(readOnly = true)
    public boolean unitBelongsToProperty(Long unitId, Long propertyId) {
        return propertyId != null && targets.resolve(ResourceType.ROOM, unitId)
            .map(u -> propertyId.equals(u.propertyId())).orElse(false);
    }

    /** Whether the room type belongs to a property the company owns today. */
    @Transactional(readOnly = true)
    public boolean unitBelongsToCompany(Long unitId, Long companyId) {
        return companyId != null && targets.resolve(ResourceType.ROOM, unitId)
            .map(u -> u.companyId().equals(companyId)).orElse(false);
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private Optional<ScopePath> resolveStored(PartnerMemberGrant grant, Long companyId) {
        if (!companyId.equals(grant.getPartnerProfile().getId())) return Optional.empty();
        if (!PartnerRoleScopes.allows(grant.getRole(), grant.getScopeType())) return Optional.empty();
        if (grant.getScopeId() == null || grant.getScopeId() <= 0) return Optional.empty();
        ScopeRef ref = new ScopeRef(grant.getScopeType(), grant.getScopeId());
        Optional<ScopePath> path = targets.resolveGrantScope(companyId, ref);
        if (grant.getScopeType() == ScopeType.UNIT) {
            Long recordedProperty = grant.getProperty() == null ? null : grant.getProperty().getId();
            path = path.filter(p -> p.propertyId().equals(recordedProperty));
        }
        return path;
    }

    /** The registrant's own row in the company they registered — not a membership "elsewhere". */
    private static boolean isRegistrantRow(PartnerTeamMember membership) {
        return membership.getPartnerProfile().getUser().getId().equals(membership.getUser().getId());
    }

    private static ApiException scopeInvalid(String message) {
        return new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, SCOPE_INVALID, "scope", message);
    }
}
