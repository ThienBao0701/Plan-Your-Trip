package com.example.planyourtrip.service;

import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.PartnerTeamMember;
import com.example.planyourtrip.model.PartnerVerificationStatus;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.PartnerTeamMemberRepository;
import com.example.planyourtrip.security.rbac.AuthorizationDecision;
import com.example.planyourtrip.security.rbac.LegacyPartnerBundles;
import com.example.planyourtrip.security.rbac.PartnerAccessContext;
import com.example.planyourtrip.security.rbac.PartnerAuthorization;
import com.example.planyourtrip.security.rbac.PartnerGrant;
import com.example.planyourtrip.security.rbac.PartnerPermission;
import com.example.planyourtrip.security.rbac.ResourceType;
import com.example.planyourtrip.security.rbac.ScopePath;
import com.example.planyourtrip.security.rbac.ScopeSet;
import org.hibernate.Hibernate;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

/**
 * The partner authorization kernel's entry point (RBAC V1.1 §24 B1): resolves the caller's workspace from
 * stored data and turns evaluator decisions into the API's responses.
 *
 * <p>It replaces the thirteen copies of {@code myApprovedProfileOrThrow} and
 * {@code PartnerSettingsService.resolveAccess}. Phase R1 is behaviour-preserving, so it keeps their exact
 * rules and messages:
 * <ul>
 *   <li>{@link #requireRegistrantWorkspace} — every operational partner endpoint: the company the caller
 *       registered, or 404 {@code Partner profile not found}; a company that is not approved is a 403,
 *       now with the stable code {@code PARTNER_NOT_APPROVED}. Team members still get the 404 here: R1 grants
 *       them no operational access.</li>
 *   <li>{@link #requireTeamWorkspace} — settings, payout account and team: the registrant's own company,
 *       else the caller's active membership, carrying the {@link LegacyPartnerBundles legacy bundle} of the
 *       member's role.</li>
 * </ul>
 *
 * <p>{@link #requireResource} and {@link #requireCollection} implement the §4.5 {@code RESOURCE} and
 * {@code COLLECTION} decisions for the phase that enforces the V1.1 matrix (R3b).
 */
@Service
public class PartnerAccessService {

    public static final String PARTNER_NOT_APPROVED = "PARTNER_NOT_APPROVED";
    public static final String PERMISSION_DENIED = "PERMISSION_DENIED";

    static final String PROFILE_NOT_FOUND_MESSAGE = "Partner profile not found";
    static final String NOT_APPROVED_MESSAGE = "Partner profile is not approved";
    static final String ACCESS_DENIED_MESSAGE = "Access denied";

    private final PartnerProfileRepository partnerProfiles;
    private final PartnerTeamMemberRepository teamMembers;
    private final PartnerResourceTargetResolver targets;

    public PartnerAccessService(PartnerProfileRepository partnerProfiles,
                                PartnerTeamMemberRepository teamMembers,
                                PartnerResourceTargetResolver targets) {
        this.partnerProfiles = partnerProfiles;
        this.teamMembers = teamMembers;
        this.targets = targets;
    }

    // ── Workspace resolution ─────────────────────────────────────────────────

    /**
     * The approved company the caller registered, with every partner permission over it. The rule every
     * operational partner service used before R1.
     */
    public PartnerAccessContext requireRegistrantWorkspace(Long userId) {
        PartnerProfile profile = partnerProfiles.findByUserId(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, PROFILE_NOT_FOUND_MESSAGE));
        requireApproved(profile);
        return registrantContext(profile, userId);
    }

    /**
     * The caller's own approved company if they registered one — even if they are also a member elsewhere
     * — otherwise the company of their active membership with the legacy bundle of its role. The rule of
     * {@code PartnerSettingsService.resolveAccess} before R1.
     *
     * <p>Runs in its own read-only transaction (joining the caller's when there is one) because the
     * membership's company is loaded lazily; the returned context carries the loaded company, so it stays
     * usable after this call returns.
     */
    @Transactional(readOnly = true)
    public PartnerAccessContext requireTeamWorkspace(Long userId) {
        Optional<PartnerProfile> own = partnerProfiles.findByUserId(userId);
        if (own.isPresent()) {
            requireApproved(own.get());
            return registrantContext(own.get(), userId);
        }
        PartnerTeamMember membership = teamMembers.findByUserIdAndActiveTrue(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, PROFILE_NOT_FOUND_MESSAGE));
        PartnerProfile company = Hibernate.unproxy(membership.getPartnerProfile(), PartnerProfile.class);
        requireApproved(company);
        PartnerGrant grant = new PartnerGrant(LegacyPartnerBundles.member(membership.getRole()),
            ScopePath.company(company.getId()));
        return new PartnerAccessContext(company, userId, false, List.of(grant));
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
        PartnerGrant grant = new PartnerGrant(LegacyPartnerBundles.registrant(), ScopePath.company(profile.getId()));
        return new PartnerAccessContext(profile, userId, true, List.of(grant));
    }

    private static void requireApproved(PartnerProfile profile) {
        if (profile.getVerificationStatus() != PartnerVerificationStatus.APPROVED) {
            throw new ApiException(HttpStatus.FORBIDDEN, PARTNER_NOT_APPROVED, NOT_APPROVED_MESSAGE);
        }
    }
}
