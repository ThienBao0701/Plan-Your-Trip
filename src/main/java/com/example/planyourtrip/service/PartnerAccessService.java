package com.example.planyourtrip.service;

import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.PartnerMembershipStatus;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.Place;
import com.example.planyourtrip.model.PartnerTeamMember;
import com.example.planyourtrip.model.PartnerTeamRole;
import com.example.planyourtrip.model.PartnerVerificationStatus;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.PartnerTeamMemberRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.security.rbac.AuthorizationDecision;
import com.example.planyourtrip.security.rbac.PartnerAccessContext;
import com.example.planyourtrip.security.rbac.PartnerAuthorization;
import com.example.planyourtrip.security.rbac.PartnerGrant;
import com.example.planyourtrip.security.rbac.PartnerPermission;
import com.example.planyourtrip.security.rbac.PartnerRoleBundles;
import com.example.planyourtrip.security.rbac.ResourceType;
import com.example.planyourtrip.security.rbac.ScopePath;
import com.example.planyourtrip.security.rbac.ScopeSet;
import org.hibernate.Hibernate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

/**
 * The partner authorization kernel's entry point (RBAC V1.1 §24 B1): resolves the caller's workspace from
 * stored data and turns evaluator decisions into the API's responses.
 *
 * <p>RBAC R3b — every partner endpoint resolves the same workspace ({@link #requireWorkspace}, §4.5 W and G):
 * <ul>
 *   <li>the company the caller registered, any status, else the company of their single ACTIVE membership,
 *       else 404 {@code Partner profile not found};</li>
 *   <li>a company that is not APPROVED is 403 {@code PARTNER_NOT_APPROVED} (B4);</li>
 *   <li>the registrant holds {@code OWNER@COMPANY} (every permission); a member holds the grants of their
 *       ACTIVE membership, each carrying its role's V1.1 bundle ({@link PartnerRoleBundles#effective}) at its
 *       scope as resolved from stored ownership today — a grant whose property moved away carries nothing.</li>
 * </ul>
 * Services then decide with {@link #requireResource}, {@link #requireCollection} and
 * {@link #requireCompanyPermission} (§4.5 RESOURCE / COLLECTION / COMPANY), and filter queries by the permitted
 * property set ({@link #propertyIds}, B5). Nothing is cached across requests (B13).
 */
@Service
public class PartnerAccessService {

    public static final String PARTNER_NOT_APPROVED = "PARTNER_NOT_APPROVED";
    public static final String PERMISSION_DENIED = "PERMISSION_DENIED";

    private static final Logger log = LoggerFactory.getLogger(PartnerAccessService.class);

    static final String PROFILE_NOT_FOUND_MESSAGE = "Partner profile not found";
    static final String NOT_APPROVED_MESSAGE = "Partner profile is not approved";
    static final String ACCESS_DENIED_MESSAGE = "Access denied";

    private final PartnerProfileRepository partnerProfiles;
    private final PartnerTeamMemberRepository teamMembers;
    private final PartnerMembershipService memberships;
    private final PartnerResourceTargetResolver targets;
    private final PlaceRepository places;

    public PartnerAccessService(PartnerProfileRepository partnerProfiles,
                                PartnerTeamMemberRepository teamMembers,
                                PartnerMembershipService memberships,
                                PartnerResourceTargetResolver targets,
                                PlaceRepository places) {
        this.partnerProfiles = partnerProfiles;
        this.teamMembers = teamMembers;
        this.memberships = memberships;
        this.targets = targets;
        this.places = places;
    }

    // ── Workspace resolution ─────────────────────────────────────────────────

    /**
     * §4.5 W(user) and G(user): the caller's approved workspace with their effective grants.
     *
     * <p>Runs in its own read-only transaction (joining the caller's when there is one) because the
     * membership's company and grants are loaded lazily; the returned context carries everything it needs.
     */
    @Transactional(readOnly = true)
    public PartnerAccessContext requireWorkspace(Long userId) {
        Optional<PartnerProfile> own = partnerProfiles.findByUserId(userId);
        if (own.isPresent()) {
            requireApproved(own.get());
            return registrantContext(own.get(), userId);
        }
        // One ACTIVE membership or none (§11.6 WS-1). Two — legacy data until M-6 — is refused, not guessed.
        List<PartnerTeamMember> active = teamMembers.findByUserIdAndStatusIn(userId, List.of(PartnerMembershipStatus.ACTIVE));
        if (active.size() != 1) {
            if (active.size() > 1) log.warn("User {} holds {} active partner memberships; refusing the workspace", userId, active.size());
            throw new ApiException(HttpStatus.NOT_FOUND, PROFILE_NOT_FOUND_MESSAGE);
        }
        PartnerTeamMember membership = active.get(0);
        PartnerProfile company = Hibernate.unproxy(membership.getPartnerProfile(), PartnerProfile.class);
        requireApproved(company);
        return new PartnerAccessContext(company, userId, false,
            memberships.kernelGrants(membership, PartnerRoleBundles::effective));
    }

    /** Settings, payout account and team resolve the same workspace as every other endpoint (R3b). */
    @Transactional(readOnly = true)
    public PartnerAccessContext requireTeamWorkspace(Long userId) {
        return requireWorkspace(userId);
    }

    /**
     * The approved company the caller registered, with every partner permission over it — for the
     * registrant-only self endpoints (business profile, §25.1 Profile rows).
     */
    public PartnerAccessContext requireRegistrantWorkspace(Long userId) {
        PartnerProfile profile = partnerProfiles.findByUserId(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, PROFILE_NOT_FOUND_MESSAGE));
        requireApproved(profile);
        return registrantContext(profile, userId);
    }

    // ── Scope helpers (B5: filter in the query) ──────────────────────────────

    /**
     * The properties of the caller's company that the scope set covers, read from current ownership: every
     * property of the company for a company-wide set, otherwise the granted properties the company still owns.
     */
    @Transactional(readOnly = true)
    public List<Long> propertyIds(PartnerAccessContext ctx, ScopeSet scope) {
        List<Long> owned = places.findAllByOwnerId(ctx.companyId()).stream().map(Place::getId).toList();
        if (scope.companyWide()) return owned;
        return owned.stream().filter(scope.propertyIds()::contains).toList();
    }

    /**
     * The properties over which {@code permission} is held, read like {@link #propertyIds}; empty when it is held
     * nowhere. For field-level filters, e.g. a guest search that may only match where the guest's name or contact
     * would be shown. Unit grants contribute no property, exactly as a unit grant never covers a property target.
     */
    @Transactional(readOnly = true)
    public List<Long> propertyIdsHolding(PartnerAccessContext ctx, PartnerPermission permission) {
        ScopeSet scope = PartnerAuthorization.collection(ctx, permission);
        return scope.isEmpty() ? List.of() : propertyIds(ctx, scope);
    }

    /**
     * The property list a filtered collection or report runs over: all of {@link #propertyIds} without a filter,
     * otherwise just the filtered property — which must lie inside the scope set, else 404 like a missing id
     * (§4.5 COLLECTION step 4).
     */
    @Transactional(readOnly = true)
    public List<Long> propertyIds(PartnerAccessContext ctx, ScopeSet scope, Long hotelIdFilter) {
        List<Long> permitted = propertyIds(ctx, scope);
        if (hotelIdFilter == null) return permitted;
        if (!permitted.contains(hotelIdFilter))
            throw new ApiException(HttpStatus.NOT_FOUND, "Hotel not found: " + hotelIdFilter);
        return List.of(hotelIdFilter);
    }

    /** Where a promotion target named in a request body lives (§11.2: a HOTEL target is a hotel_details id). */
    public ScopePath promotionTarget(com.example.planyourtrip.model.PromotionTargetType type, Long targetId) {
        return targets.resolvePromotionTarget(type, targetId).orElse(null);
    }

    /** Where the booking with {@code bookingCode} lives (voucher and code-based check-in/out), or null. */
    public ScopePath bookingCodeTarget(String bookingCode) {
        return targets.resolveBookingCode(bookingCode).orElse(null);
    }

    /** Where a resource lives, read from the database (§11.2), or null — the resolver's answer, nothing else. */
    public ScopePath target(ResourceType type, Long id) {
        return targets.resolve(type, id).orElse(null);
    }

    /** Whether {@code permission} is held at a scope covering {@code target} (field-level checks, §21.2). */
    public boolean holds(PartnerAccessContext ctx, PartnerPermission permission, ScopePath target) {
        return target != null && PartnerAuthorization.effectiveScopes(ctx, permission).stream()
            .anyMatch(scope -> scope.covers(target));
    }

    /** Whether {@code permission} is held anywhere in the workspace (menu, home blocks). */
    public boolean holdsAnywhere(PartnerAccessContext ctx, PartnerPermission permission) {
        return !PartnerAuthorization.effectiveScopes(ctx, permission).isEmpty();
    }

    /** Whether {@code permission} is held over every property of {@code propertyIds} (aggregate blocks). */
    public boolean holdsOver(PartnerAccessContext ctx, PartnerPermission permission, List<Long> propertyIds) {
        return propertyIds.stream().allMatch(id -> holds(ctx, permission, ScopePath.property(ctx.companyId(), id)));
    }

    // ── Decisions ────────────────────────────────────────────────────────────

    /**
     * {@code COMPANY} endpoints: refuses with 403 {@code PERMISSION_DENIED} unless the permission is held at
     * company scope. {@code deniedMessage} keeps each endpoint's existing wording.
     */
    public void requireCompanyPermission(PartnerAccessContext ctx, PartnerPermission permission,
                                         String deniedMessage) {
        if (PartnerAuthorization.company(ctx, permission) != AuthorizationDecision.ALLOW) {
            throw new ApiException(HttpStatus.FORBIDDEN, PERMISSION_DENIED,
                deniedMessage == null ? ACCESS_DENIED_MESSAGE : deniedMessage);
        }
    }

    /**
     * {@code RESOURCE} endpoints: resolves where the resource lives from the database and decides. Returns
     * the resolved target when allowed; otherwise 403 {@code PERMISSION_DENIED} or the endpoint's own 404
     * message — the same answer a missing id gets.
     */
    public ScopePath requireResource(PartnerAccessContext ctx, PartnerPermission permission,
                                     ResourceType type, Long id, String notFoundMessage) {
        ScopePath target = targets.resolve(type, id).orElse(null);
        return decide(ctx, permission, type, target, notFoundMessage);
    }

    /** As {@link #requireResource}, for a target the caller already resolved through the resolver. */
    public ScopePath decide(PartnerAccessContext ctx, PartnerPermission permission, ResourceType type,
                            ScopePath target, String notFoundMessage) {
        return switch (PartnerAuthorization.resource(ctx, permission, type, target)) {
            case ALLOW -> target;
            case FORBIDDEN -> throw new ApiException(HttpStatus.FORBIDDEN, PERMISSION_DENIED, ACCESS_DENIED_MESSAGE);
            case NOT_FOUND -> throw new ApiException(HttpStatus.NOT_FOUND, notFoundMessage);
        };
    }

    /**
     * A {@code RESOURCE} endpoint whose path names one type and whose decision uses another — e.g.
     * {@code /rooms/{roomId}/rate-plans}: the target is resolved through the room, the view permission is the
     * rate plan's (§25.1 "RESOURCE (rate plan, via room)").
     */
    public ScopePath requireResourceVia(PartnerAccessContext ctx, PartnerPermission permission, ResourceType type,
                                        ResourceType resolveAs, Long id, String notFoundMessage) {
        ScopePath target = targets.resolve(resolveAs, id).orElse(null);
        return decide(ctx, permission, type, target, notFoundMessage);
    }

    /**
     * A mutation that needs several permissions on one target (B9 field-diff): every permission must be held at a
     * scope covering it. Decided completely before anything is written, so a refusal never leaves a partial change.
     * The answer for a refusal is the first refusal's: 404 when the caller cannot even view the target, else 403.
     */
    public ScopePath requireAll(PartnerAccessContext ctx, java.util.Collection<PartnerPermission> permissions,
                                ResourceType type, ScopePath target, String notFoundMessage) {
        if (permissions.isEmpty()) throw new IllegalArgumentException("At least one permission is required");
        for (PartnerPermission permission : permissions) decide(ctx, permission, type, target, notFoundMessage);
        return target;
    }

    /**
     * A mutation that changes nothing still needs the right to make it: any one of {@code permissions} at a scope
     * covering the target suffices; otherwise the decision of the first permission is returned.
     */
    public ScopePath requireAny(PartnerAccessContext ctx, java.util.Collection<PartnerPermission> permissions,
                                ResourceType type, ScopePath target, String notFoundMessage) {
        for (PartnerPermission permission : permissions) {
            if (PartnerAuthorization.resource(ctx, permission, type, target) == AuthorizationDecision.ALLOW) return target;
        }
        return decide(ctx, permissions.iterator().next(), type, target, notFoundMessage);
    }

    /**
     * {@code COLLECTION} endpoints: the scope set to filter and aggregate over, or 403
     * {@code PERMISSION_DENIED} when the permission is held nowhere.
     */
    public ScopeSet requireCollection(PartnerAccessContext ctx, PartnerPermission permission) {
        ScopeSet scopeSet = PartnerAuthorization.collection(ctx, permission);
        if (scopeSet.isEmpty()) {
            throw new ApiException(HttpStatus.FORBIDDEN, PERMISSION_DENIED, ACCESS_DENIED_MESSAGE);
        }
        return scopeSet;
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private static PartnerAccessContext registrantContext(PartnerProfile profile, Long userId) {
        // §4.5 G(user): the primary owner holds OWNER@COMPANY — every partner permission.
        PartnerGrant grant = new PartnerGrant(PartnerRoleBundles.of(PartnerTeamRole.OWNER), ScopePath.company(profile.getId()));
        return new PartnerAccessContext(profile, userId, true, List.of(grant));
    }

    private static void requireApproved(PartnerProfile profile) {
        if (profile.getVerificationStatus() != PartnerVerificationStatus.APPROVED) {
            throw new ApiException(HttpStatus.FORBIDDEN, PARTNER_NOT_APPROVED, NOT_APPROVED_MESSAGE);
        }
    }
}
