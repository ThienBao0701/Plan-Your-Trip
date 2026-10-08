package com.example.planyourtrip.service;

import com.example.planyourtrip.config.AuthProperties;
import com.example.planyourtrip.dto.PartnerInvitationDto.InvitationRequest;
import com.example.planyourtrip.dto.PartnerInvitationDto.InvitationRequestResult;
import com.example.planyourtrip.dto.PartnerInvitationDto.InvitationView;
import com.example.planyourtrip.dto.PartnerInvitationDto.MyInvitationGrant;
import com.example.planyourtrip.dto.PartnerInvitationDto.MyInvitationView;
import com.example.planyourtrip.dto.PartnerSettingsDto.PartnerTeamGrantItem;
import com.example.planyourtrip.dto.PartnerSettingsDto.PartnerTeamGrantView;
import com.example.planyourtrip.dto.PartnerSettingsDto.PartnerTeamMemberRequest;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.PartnerInvitation;
import com.example.planyourtrip.model.PartnerInvitationDeliveryStatus;
import com.example.planyourtrip.model.PartnerInvitationGrant;
import com.example.planyourtrip.model.PartnerInvitationStatus;
import com.example.planyourtrip.model.PartnerMembershipStatus;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.PartnerTeamMember;
import com.example.planyourtrip.model.PartnerTeamRole;
import com.example.planyourtrip.model.PartnerVerificationStatus;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PartnerInvitationGrantRepository;
import com.example.planyourtrip.repository.PartnerInvitationRepository;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.PartnerTeamMemberRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.security.rbac.AuthorizationDecision;
import com.example.planyourtrip.security.rbac.PartnerAccessContext;
import com.example.planyourtrip.security.rbac.PartnerAuthorization;
import com.example.planyourtrip.security.rbac.PartnerPermission;
import com.example.planyourtrip.security.rbac.ScopePath;
import com.example.planyourtrip.security.rbac.ScopeRef;
import com.example.planyourtrip.security.rbac.ScopeType;
import com.example.planyourtrip.service.PartnerTeamService.GrantSpec;
import com.example.planyourtrip.service.mail.AccountEmail;
import com.example.planyourtrip.service.mail.EmailSender;
import com.example.planyourtrip.util.AccountEmails;
import jakarta.persistence.EntityManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

import static com.example.planyourtrip.security.rbac.PartnerPermission.TEAM_INVITE;
import static com.example.planyourtrip.security.rbac.PartnerPermission.TEAM_VIEW;

/**
 * RBAC R4 — the partner invitation lifecycle (RBAC V1.1 §13, §14, §16 PA-4, §22, §25.3, §31 Q16).
 *
 * <p><b>Create</b> ({@link #invite}) and <b>resend</b> ({@link #resend}) run their checks and writes in one
 * transaction under the company row lock, and send the email only <em>after</em> commit:
 * <ol>
 *   <li>team invite (P08) held somewhere; authority (§10.3) and delegation (I6) over every invited grant, each
 *       valid inside the company (422 {@code SCOPE_INVALID}); an {@code OWNER} grant needs P12 and step-up;</li>
 *   <li>the address is normalised like every account email; an existing membership the caller can see is
 *       409 {@code ALREADY_MEMBER}, one they cannot see answers the uniform 202 and creates nothing (IN-3);</li>
 *   <li>limits (IN-4): at most {@value #MAX_PENDING} pending invitations per company, {@code 60 s} between two
 *       invitations to one address and between two sends, at most {@value #MAX_RESENDS} resends —
 *       429 {@code INVITATION_RATE_LIMITED};</li>
 *   <li>{@code EmailSender.isAvailable()} is checked before anything is written: 503
 *       {@code EMAIL_DELIVERY_UNAVAILABLE} and nothing changes (IN-5);</li>
 *   <li>a pending invitation to the same address is superseded; the new one stores only the SHA-256 of a
 *       32-byte random token and expires after 7 days; a resend rotates the token so the old link stops working;</li>
 *   <li>strict audit ({@code TEAM_MEMBER_INVITED}, {@code TEAM_INVITATION_RESENT}) and the mandatory owner
 *       notification, in the same transaction;</li>
 *   <li>after commit the link {@code <partner app>/accept-invitation#token=…} is sent; a failed send marks the
 *       delivery {@code FAILED} and leaves the invitation {@code PENDING} to be resent.</li>
 * </ol>
 * The response is the same 202 whatever the address is (IN-1); no account is created or promoted (IN-2).
 *
 * <p><b>Accept</b> ({@link #accept}) consumes the one-time token under the company lock, checks the account
 * (PARTNER, enabled, verified when required, same address), one workspace per account (WS-3), that the company is
 * still approved and that every grant is still valid and still within the inviter's authority, then creates a
 * NEW membership with exactly the invited grants — a revoked membership is never revived (RV-2).
 */
@Service
public class PartnerInvitationService {

    public static final String INVITATION_RATE_LIMITED = "INVITATION_RATE_LIMITED";
    public static final String INVITATION_NOT_PENDING = "INVITATION_NOT_PENDING";
    public static final String INVITATION_INVALID = "INVITATION_INVALID";
    public static final String INVITATION_EXPIRED = "INVITATION_EXPIRED";
    public static final String INVITATION_STALE = "INVITATION_STALE";
    public static final String INVITATION_ACCOUNT_MISMATCH = "INVITATION_ACCOUNT_MISMATCH";
    public static final String PARTNER_ACCOUNT_REQUIRED = "PARTNER_ACCOUNT_REQUIRED";
    public static final String WORKSPACE_UNAVAILABLE = "WORKSPACE_UNAVAILABLE";
    public static final String EMAIL_DELIVERY_UNAVAILABLE = "EMAIL_DELIVERY_UNAVAILABLE";

    public static final Duration LIFETIME = Duration.ofDays(7);
    public static final Duration COOLDOWN = Duration.ofSeconds(60);
    public static final int MAX_PENDING = 20;
    public static final int MAX_RESENDS = 5;

    static final String REASON_SUPERSEDED = "SUPERSEDED";
    static final String REASON_REVOKED = "REVOKED_BY_TEAM";
    static final String REASON_PROPERTY_MOVED = "PROPERTY_MOVED";

    private static final String ENTITY = "TEAM_INVITATION";
    private static final Logger log = LoggerFactory.getLogger(PartnerInvitationService.class);

    /** A token handed to the email sender after commit. {@code rawToken} goes into the link and nowhere else. */
    private record Issued(Long invitationId, String email, String rawToken) {}

    private final PartnerAccessService access;
    private final PartnerMembershipService memberships;
    private final PartnerTeamAuthority authority;
    private final PartnerInvitationRepository invitations;
    private final PartnerInvitationGrantRepository invitationGrants;
    private final PartnerProfileRepository profiles;
    private final PartnerTeamMemberRepository members;
    private final UserRepository users;
    private final PlaceRepository places;
    private final HotelRoomRepository rooms;
    private final PartnerResourceTargetResolver targets;
    private final PartnerActivityLogService audit;
    private final PartnerSecurityNotifier securityNotifier;
    private final EmailSender emailSender;
    private final AuthProperties properties;
    private final Clock clock;
    private final EntityManager entityManager;
    private final TransactionTemplate tx;

    public PartnerInvitationService(PartnerAccessService access, PartnerMembershipService memberships,
                                    PartnerTeamAuthority authority, PartnerInvitationRepository invitations,
                                    PartnerInvitationGrantRepository invitationGrants, PartnerProfileRepository profiles,
                                    PartnerTeamMemberRepository members, UserRepository users, PlaceRepository places,
                                    HotelRoomRepository rooms, PartnerResourceTargetResolver targets,
                                    PartnerActivityLogService audit, PartnerSecurityNotifier securityNotifier,
                                    EmailSender emailSender, AuthProperties properties, Clock clock,
                                    EntityManager entityManager, PlatformTransactionManager transactionManager) {
        this.access = access;
        this.memberships = memberships;
        this.authority = authority;
        this.invitations = invitations;
        this.invitationGrants = invitationGrants;
        this.profiles = profiles;
        this.members = members;
        this.users = users;
        this.places = places;
        this.rooms = rooms;
        this.targets = targets;
        this.audit = audit;
        this.securityNotifier = securityNotifier;
        this.emailSender = emailSender;
        this.properties = properties;
        this.clock = clock;
        this.entityManager = entityManager;
        this.tx = new TransactionTemplate(transactionManager);
    }

    // ── Create (§13.1) ───────────────────────────────────────────────────────

    /** {@code POST /api/partner/team/invitations}: checks and writes in one transaction, the email after commit. */
    public InvitationRequestResult invite(Long userId, InvitationRequest req) {
        Optional<Issued> issued = tx.execute(status -> create(userId, req));
        issued.ifPresent(this::deliver);
        return InvitationRequestResult.requested();
    }

    /**
     * {@code POST /api/partner/team} since R4 (§29): an alias of {@link #invite} for the legacy body
     * {@code {email, role, active}} — {@code role} at company scope; {@code active} is ignored, since an accepted
     * invitation always creates an active membership.
     */
    public InvitationRequestResult inviteLegacy(Long userId, PartnerTeamMemberRequest req) {
        if (req.role() == null) throw PartnerTeamService.invalid("role", "is required");
        Long companyId = access.requireTeamWorkspace(userId).companyId();
        return invite(userId, new InvitationRequest(req.email(),
            List.of(new PartnerTeamGrantItem(req.role(), ScopeType.COMPANY.name() + ":" + companyId))));
    }

    private Optional<Issued> create(Long userId, InvitationRequest req) {
        PartnerTeamAuthority.Actor actor = authority.actor(access.requireTeamWorkspace(userId));
        authority.requireSomewhere(actor, TEAM_INVITE);
        String email = AccountEmails.normalize(req.email());
        if (email == null || email.isBlank()) throw PartnerTeamService.invalid("email", "is required");
        if (email.length() > AccountEmails.MAX_LENGTH) throw PartnerTeamService.invalid("email", "is too long");
        if (req.grants() == null || req.grants().isEmpty())
            throw PartnerTeamService.invalid("grants", "must contain at least one grant");
        List<GrantSpec> grants = PartnerTeamService.parseGrants(req.grants());

        PartnerProfile company = lockCompany(actor.companyId());
        requireInvitable(actor, company, grants);
        Instant now = clock.instant();

        // IN-3: an existing live membership of that address — 409 when the caller can see it, silence otherwise
        Optional<User> account = users.findByEmail(email);
        if (account.isPresent()) {
            Optional<PartnerTeamMember> existing = members.findByPartnerProfileIdAndUserId(company.getId(), account.get().getId());
            if (existing.isPresent()) {
                if (authority.sees(actor, memberships.scopesOf(existing.get()))) {
                    throw new ApiException(HttpStatus.CONFLICT, PartnerTeamService.ALREADY_MEMBER,
                        "This address already belongs to a team member");
                }
                return Optional.empty();
            }
        }

        Optional<PartnerInvitation> pending = invitations.findByPartnerProfileIdAndEmailAndStatus(
            company.getId(), email, PartnerInvitationStatus.PENDING);
        if (pending.isPresent()) {
            // a pending invitation the caller cannot see is somebody else's business: nothing is created (IN-3)
            if (!authority.sees(actor, scopesOf(pending.get()))) return Optional.empty();
            authority.requireAuthorityOver(actor, rolesOf(pending.get()), false);
        }
        invitations.findFirstByPartnerProfileIdAndEmailOrderByCreatedAtDescIdDesc(company.getId(), email)
            .filter(latest -> authority.sees(actor, scopesOf(latest)))
            .filter(latest -> sentWithinCooldown(latest, now))
            .ifPresent(latest -> { throw rateLimited("Please wait a minute before inviting this address again"); });
        long open = invitations.countOpen(company.getId(), now)
            - pending.filter(p -> p.isOpenAt(now)).map(p -> 1L).orElse(0L);
        if (open >= MAX_PENDING) throw rateLimited("This company already has " + MAX_PENDING + " pending invitations");
        requireEmailDelivery();

        pending.ifPresent(old -> closeAndAudit(company, actor.userId(), old,
            old.isOpenAt(now) ? PartnerInvitationStatus.REVOKED : PartnerInvitationStatus.EXPIRED,
            REASON_SUPERSEDED, "Invitation #" + old.getId() + " superseded by a new invitation", now));

        String raw = AuthTokenService.newRawToken();
        PartnerInvitation invitation = new PartnerInvitation();
        invitation.setPartnerProfile(company);
        invitation.setEmail(email);
        invitation.setTokenHash(AuthTokenService.hash(raw));
        invitation.setExpiresAt(now.plus(LIFETIME));
        invitation.setLastSentAt(now);
        invitation.setCreatedAt(now);
        invitation.setInvitedBy(users.getReferenceById(actor.userId()));
        PartnerInvitation saved = invitations.saveAndFlush(invitation);
        for (GrantSpec g : grants) invitationGrants.save(new PartnerInvitationGrant(saved, g.role(), g.scope()));
        invitationGrants.flush();

        String after = describe(grants, PartnerInvitationStatus.PENDING);
        audit.audit(company.getId(), actor.userId(), "TEAM_MEMBER_INVITED", ENTITY, saved.getId(),
            "Invitation #" + saved.getId() + " created", null, after, null);
        securityNotifier.notifyOwners(company, null, "Team member invited", email + " was invited: " + after);
        return Optional.of(new Issued(saved.getId(), email, raw));
    }

    /**
     * Authority and delegation over every invited grant (§10.3, I6), each valid inside the company (§11.3, 422);
     * owner invitations need P12 and a fresh session (O-2, O-7).
     */
    private void requireInvitable(PartnerTeamAuthority.Actor actor, PartnerProfile company, List<GrantSpec> grants) {
        Set<PartnerTeamRole> roles = grants.stream().map(GrantSpec::role).collect(Collectors.toSet());
        authority.requireAuthorityOver(actor, roles, false);
        for (GrantSpec g : grants) {
            ScopePath path = memberships.validateGrant(company.getId(), g.role(), g.scope());
            authority.requireDelegable(actor, TEAM_INVITE, g.role(), path);
        }
        if (roles.contains(PartnerTeamRole.OWNER)) authority.requireOwnerManagement(actor);
    }

    // ── Resend (§13.2) ───────────────────────────────────────────────────────

    /** {@code POST /api/partner/team/invitations/{id}/resend}: rotates the token; the old link stops working. */
    public InvitationRequestResult resend(Long userId, Long invitationId) {
        Issued issued = tx.execute(status -> rotate(userId, invitationId));
        deliver(issued);
        return InvitationRequestResult.requested();
    }

    private Issued rotate(Long userId, Long invitationId) {
        PartnerTeamAuthority.Actor actor = authority.actor(access.requireTeamWorkspace(userId));
        authority.requireSomewhere(actor, TEAM_INVITE);
        PartnerProfile company = lockCompany(actor.companyId());
        PartnerInvitation invitation = visibleInvitation(actor, company, invitationId);
        Instant now = clock.instant();
        List<GrantSpec> grants = grantsOf(invitation);
        authority.requireAuthorityOver(actor, rolesOf(invitation), false);
        if (!invitation.isOpenAt(now)) {
            throw new ApiException(HttpStatus.CONFLICT, INVITATION_NOT_PENDING,
                "This invitation is no longer pending; create a new invitation instead");
        }
        try {
            requireInvitable(actor, company, grants);
        } catch (ApiException e) {
            if (!PartnerMembershipService.SCOPE_INVALID.equals(e.code())) throw e;
            throw new ApiException(HttpStatus.CONFLICT, INVITATION_STALE,
                "A scope of this invitation no longer belongs to the company; revoke it and invite again");
        }
        if (invitation.getResendCount() >= MAX_RESENDS) throw rateLimited("This invitation cannot be resent again");
        if (sentWithinCooldown(invitation, now)) throw rateLimited("Please wait a minute before resending");
        requireEmailDelivery();

        String raw = AuthTokenService.newRawToken();
        invitation.setTokenHash(AuthTokenService.hash(raw));
        invitation.setExpiresAt(now.plus(LIFETIME));
        invitation.setResendCount(invitation.getResendCount() + 1);
        invitation.setLastSentAt(now);
        invitation.setDeliveryStatus(PartnerInvitationDeliveryStatus.QUEUED);
        invitations.saveAndFlush(invitation);

        String state = describe(grants, PartnerInvitationStatus.PENDING);
        audit.audit(company.getId(), actor.userId(), "TEAM_INVITATION_RESENT", ENTITY, invitation.getId(),
            "Invitation #" + invitation.getId() + " resent (" + invitation.getResendCount() + "/" + MAX_RESENDS
                + "); the previous link no longer works", state, state, null);
        securityNotifier.notifyOwners(company, null, "Team invitation resent",
            invitation.getEmail() + " was sent a new invitation link: " + state);
        return new Issued(invitation.getId(), invitation.getEmail(), raw);
    }

    // ── Revoke (IN-6) ────────────────────────────────────────────────────────

    /** {@code DELETE /api/partner/team/invitations/{id}}: the invitation can never be accepted afterwards. */
    @Transactional
    public void revoke(Long userId, Long invitationId, String reason) {
        PartnerTeamAuthority.Actor actor = authority.actor(access.requireTeamWorkspace(userId));
        authority.requireSomewhere(actor, TEAM_INVITE);
        PartnerProfile company = lockCompany(actor.companyId());
        PartnerInvitation invitation = visibleInvitation(actor, company, invitationId);
        authority.requireAuthorityOver(actor, rolesOf(invitation), false);
        if (!authority.covers(actor, TEAM_INVITE, scopesOf(invitation))) {
            throw new ApiException(HttpStatus.FORBIDDEN, PartnerTeamService.ROLE_NOT_DELEGABLE,
                "Your role cannot manage this invitation");
        }
        if (invitation.getStatus() != PartnerInvitationStatus.PENDING) {
            throw new ApiException(HttpStatus.CONFLICT, INVITATION_NOT_PENDING, "This invitation is no longer pending");
        }
        closeAndAudit(company, actor.userId(), invitation, PartnerInvitationStatus.REVOKED, REASON_REVOKED,
            "Invitation #" + invitation.getId() + " revoked", clock.instant(), reason);
    }

    // ── Team read (§25.3) ────────────────────────────────────────────────────

    /** {@code GET /api/partner/team/invitations}: COLLECTION over team view (P07) — only invitations it fully covers. */
    @Transactional(readOnly = true)
    public List<InvitationView> list(Long userId) {
        PartnerAccessContext ctx = access.requireTeamWorkspace(userId);
        access.requireCollection(ctx, TEAM_VIEW);
        PartnerTeamAuthority.Actor actor = authority.actor(ctx);
        Instant now = clock.instant();
        return invitations.findByPartnerProfileIdOrderByCreatedAtDescIdDesc(ctx.companyId()).stream()
            .filter(i -> authority.sees(actor, scopesOf(i)))
            .map(i -> toView(i, now)).toList();
    }

    // ── Invitee side (§14) ───────────────────────────────────────────────────

    /** {@code GET /api/me/partner-invitations}: open invitations addressed to the caller's own address (AC-5). */
    @Transactional(readOnly = true)
    public List<MyInvitationView> mine(Long userId) {
        User user = users.findById(userId).orElseThrow(PartnerInvitationService::partnerAccountRequired);
        requirePartnerAccount(user);
        Instant now = clock.instant();
        return invitations.findOpenFor(AccountEmails.normalize(user.getEmail()), now).stream()
            .map(i -> new MyInvitationView(i.getId(), i.getPartnerProfile().getId(),
                i.getPartnerProfile().getBusinessName(), myGrants(i), i.getExpiresAt()))
            .toList();
    }

    /**
     * {@code POST /api/me/partner-invitations/accept} (§14 steps 1–7): consumes the token and creates the
     * membership. Returns the company joined; the controller answers with the caller's access document (step 8).
     */
    @Transactional
    public Long accept(Long userId, String rawToken) {
        PartnerInvitation found = byToken(rawToken);
        Instant now = clock.instant();
        if (!found.getExpiresAt().isAfter(now)) throw expired();

        User user = users.findById(userId).orElseThrow(PartnerInvitationService::partnerAccountRequired);
        requirePartnerAccount(user);
        if (!found.getEmail().equals(AccountEmails.normalize(user.getEmail()))) {
            throw new ApiException(HttpStatus.FORBIDDEN, INVITATION_ACCOUNT_MISMATCH,
                "This invitation was sent to a different address; sign in with the invited Partner account");
        }

        PartnerProfile company = lockCompany(found.getPartnerProfile().getId());
        // re-read under the lock: a concurrent acceptance, resend or revocation has already been applied
        entityManager.refresh(found);
        if (found.getStatus() != PartnerInvitationStatus.PENDING || !found.getTokenHash().equals(hashOf(rawToken))) {
            throw invalid();
        }
        requireCanJoin(userId, company);
        if (company.getVerificationStatus() != PartnerVerificationStatus.APPROVED) {
            throw new ApiException(HttpStatus.CONFLICT, WORKSPACE_UNAVAILABLE,
                "This company cannot accept new members right now");
        }
        List<GrantSpec> grants = grantsOf(found);
        requireStillValid(found, company, grants);

        PartnerTeamMember member = memberships.createMembership(company, user,
            grants.stream().map(g -> Map.entry(g.role(), g.scope())).toList(), userId, found.getCreatedAt());
        found.accept(user, member, now);
        invitations.saveAndFlush(found);

        String after = "member #" + member.getId() + ": " + describeMember(grants);
        audit.audit(company.getId(), userId, "TEAM_INVITATION_ACCEPTED", ENTITY, found.getId(),
            "Invitation #" + found.getId() + " accepted; team member #" + member.getId() + " joined",
            describe(grants, PartnerInvitationStatus.PENDING), after, null);
        if (grants.stream().anyMatch(g -> g.role() == PartnerTeamRole.OWNER)) {
            audit.audit(company.getId(), userId, "OWNER_GRANTED", "TEAM_MEMBER", member.getId(),
                "Owner granted to team member #" + member.getId() + " through invitation #" + found.getId(),
                null, describeMember(grants), null);
        }
        securityNotifier.notifyOwners(company, userId, "Invitation accepted",
            user.getEmail() + " joined the team: " + describeMember(grants));
        return company.getId();
    }

    /** {@code POST /api/me/partner-invitations/decline} (AC-1): anyone holding the link may refuse it. */
    @Transactional
    public void decline(Long userId, String rawToken) {
        PartnerInvitation found = byToken(rawToken);
        Instant now = clock.instant();
        if (!found.getExpiresAt().isAfter(now)) throw expired();
        PartnerProfile company = lockCompany(found.getPartnerProfile().getId());
        entityManager.refresh(found);
        if (found.getStatus() != PartnerInvitationStatus.PENDING || !found.getTokenHash().equals(hashOf(rawToken))) {
            throw invalid();
        }
        User user = users.getReferenceById(userId);
        found.close(PartnerInvitationStatus.DECLINED, "DECLINED", user, now);
        invitations.saveAndFlush(found);
        audit.audit(company.getId(), userId, "TEAM_INVITATION_DECLINED", ENTITY, found.getId(),
            "Invitation #" + found.getId() + " declined", "PENDING", "DECLINED", null);
    }

    // ── PA-4 (§16): a property moving to another company ─────────────────────

    /**
     * Revokes the previous company's pending invitations whose grants reference the moved property or one of its
     * room types, in the caller's (admin assign-owner) transaction, audited in that company's trail.
     */
    @Transactional
    public void revokeForMovedProperty(Long adminUserId, PartnerProfile previous, Long propertyId,
                                       Collection<Long> unitIds) {
        Collection<Long> units = unitIds == null || unitIds.isEmpty() ? List.of(-1L) : unitIds;
        Instant now = clock.instant();
        for (PartnerInvitation invitation : invitations.findPendingReferencing(previous.getId(), propertyId, units)) {
            closeAndAudit(previous, adminUserId, invitation, PartnerInvitationStatus.REVOKED, REASON_PROPERTY_MOVED,
                "Invitation #" + invitation.getId() + " revoked: property #" + propertyId + " moved to another company",
                now);
        }
    }

    // ── Checks ───────────────────────────────────────────────────────────────

    /** §14 step 2 / AC-3 / AC-4: a PARTNER account, enabled, its email verified when verification applies. */
    private static void requirePartnerAccount(User user) {
        boolean verified = !user.isEmailVerificationRequired() || user.getEmailVerifiedAt() != null;
        if (!"PARTNER".equals(user.getRole()) || !user.isEnabled() || !verified) throw partnerAccountRequired();
    }

    /** WS-3: no own company of any status, no live membership here, no ACTIVE membership elsewhere. */
    private void requireCanJoin(Long userId, PartnerProfile company) {
        if (profiles.findByUserId(userId).isPresent()) {
            throw workspaceConflict(PartnerMembershipService.REASON_OWN_PROFILE_EXISTS);
        }
        if (members.findByPartnerProfileIdAndUserId(company.getId(), userId).isPresent()) {
            throw workspaceConflict(PartnerMembershipService.REASON_MEMBERSHIP_EXISTS);
        }
        memberships.joinConflict(userId, company.getId(), true)
            .ifPresent(reason -> { throw workspaceConflict(reason); });
    }

    /**
     * §14 step 6: every grant still lies inside the company and the inviter still holds the authority and
     * delegation it needed — otherwise 409 {@code INVITATION_STALE}. The inviter's step-up is not re-checked: it
     * was required when the owner invitation was created.
     */
    private void requireStillValid(PartnerInvitation invitation, PartnerProfile company, List<GrantSpec> grants) {
        try {
            for (GrantSpec g : grants) memberships.validateGrant(company.getId(), g.role(), g.scope());
            Long inviterId = invitation.getInvitedBy().getId();
            PartnerAccessContext inviterCtx = access.requireWorkspace(inviterId);
            if (!company.getId().equals(inviterCtx.companyId())) throw stale();
            PartnerTeamAuthority.Actor inviter = authority.actor(inviterCtx);
            authority.requireSomewhere(inviter, TEAM_INVITE);
            Set<PartnerTeamRole> roles = grants.stream().map(GrantSpec::role).collect(Collectors.toSet());
            authority.requireAuthorityOver(inviter, roles, false);
            for (GrantSpec g : grants) {
                ScopePath path = memberships.validateGrant(company.getId(), g.role(), g.scope());
                authority.requireDelegable(inviter, TEAM_INVITE, g.role(), path);
            }
            if (roles.contains(PartnerTeamRole.OWNER) && (!inviter.owner()
                    || PartnerAuthorization.company(inviterCtx, PartnerPermission.TEAM_OWNER_MANAGE) != AuthorizationDecision.ALLOW)) {
                throw stale();
            }
        } catch (ApiException e) {
            if (INVITATION_STALE.equals(e.code())) throw e;
            log.warn("Invitation #{} is stale: {}", invitation.getId(), e.code());
            throw stale();
        }
    }

    private PartnerInvitation visibleInvitation(PartnerTeamAuthority.Actor actor, PartnerProfile company, Long id) {
        return invitations.findById(id)
            .filter(i -> i.getPartnerProfile().getId().equals(company.getId()))
            .map(i -> { entityManager.refresh(i); return i; })
            .filter(i -> authority.sees(actor, scopesOf(i)))
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Invitation not found: " + id));
    }

    private void requireEmailDelivery() {
        if (!emailSender.isAvailable()) {
            throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE, EMAIL_DELIVERY_UNAVAILABLE,
                "Email delivery is not available right now. Please try again later.");
        }
    }

    private static boolean sentWithinCooldown(PartnerInvitation invitation, Instant now) {
        Instant last = invitation.getLastSentAt() != null ? invitation.getLastSentAt() : invitation.getCreatedAt();
        return last != null && last.plus(COOLDOWN).isAfter(now);
    }

    // ── Delivery (after commit) ──────────────────────────────────────────────

    /**
     * Sends the link and records the outcome. A failure is logged with the invitation id only — never the link —
     * and leaves the invitation PENDING with delivery FAILED, to be resent. The outcome is recorded only while the
     * token is still the one sent (a concurrent resend wins).
     */
    private void deliver(Issued issued) {
        PartnerInvitationDeliveryStatus outcome;
        try {
            emailSender.send(new AccountEmail(issued.email(), AccountEmail.Kind.PARTNER_INVITATION, linkFor(issued.rawToken())));
            outcome = PartnerInvitationDeliveryStatus.SENT;
        } catch (RuntimeException e) {
            log.warn("Invitation #{} could not be delivered ({}); it stays pending and can be resent",
                issued.invitationId(), e.getClass().getSimpleName());
            outcome = PartnerInvitationDeliveryStatus.FAILED;
        }
        String hash = AuthTokenService.hash(issued.rawToken());
        PartnerInvitationDeliveryStatus result = outcome;
        tx.executeWithoutResult(status -> invitations.recordDelivery(issued.invitationId(), hash, result));
    }

    /** The token travels in the fragment, like Phase A links, so it never reaches a server log or a Referer. */
    private String linkFor(String rawToken) {
        String origin = properties.getPartnerAppUrl();
        String base = origin.endsWith("/") ? origin.substring(0, origin.length() - 1) : origin;
        return base + "/accept-invitation#token=" + rawToken;
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private PartnerInvitation byToken(String rawToken) {
        if (rawToken == null || rawToken.isBlank()) throw invalid();
        PartnerInvitation invitation = invitations.findByTokenHash(hashOf(rawToken)).orElseThrow(PartnerInvitationService::invalid);
        if (invitation.getStatus() != PartnerInvitationStatus.PENDING) throw invalid();
        return invitation;
    }

    private static String hashOf(String rawToken) {
        return AuthTokenService.hash(rawToken.trim());
    }

    private void closeAndAudit(PartnerProfile company, Long actorUserId, PartnerInvitation invitation,
                               PartnerInvitationStatus status, String statusReason, String description, Instant now) {
        closeAndAudit(company, actorUserId, invitation, status, statusReason, description, now, null);
    }

    private void closeAndAudit(PartnerProfile company, Long actorUserId, PartnerInvitation invitation,
                               PartnerInvitationStatus status, String statusReason, String description, Instant now,
                               String reason) {
        List<GrantSpec> grants = grantsOf(invitation);
        invitation.close(status, statusReason, null, now);
        invitations.saveAndFlush(invitation);
        audit.audit(company.getId(), actorUserId, "TEAM_INVITATION_REVOKED", ENTITY, invitation.getId(), description,
            describe(grants, PartnerInvitationStatus.PENDING), describe(grants, status),
            reason != null ? reason : statusReason);
        securityNotifier.notifyOwners(company, null, "Team invitation revoked",
            "The invitation of " + invitation.getEmail() + " was closed (" + statusReason + ").");
    }

    private List<GrantSpec> grantsOf(PartnerInvitation invitation) {
        List<GrantSpec> specs = new ArrayList<>();
        for (PartnerInvitationGrant g : invitationGrants.findByInvitationIdOrderByIdAsc(invitation.getId())) {
            specs.add(new GrantSpec(g.getRole(), g.scope()));
        }
        return specs;
    }

    private Set<PartnerTeamRole> rolesOf(PartnerInvitation invitation) {
        return grantsOf(invitation).stream().map(GrantSpec::role).collect(Collectors.toSet());
    }

    /** The invitation's scope as a team resource (§11.2): its grants as they resolve today; unresolvable ones drop. */
    private List<ScopePath> scopesOf(PartnerInvitation invitation) {
        Long companyId = invitation.getPartnerProfile().getId();
        List<ScopePath> scopes = new ArrayList<>();
        for (GrantSpec g : grantsOf(invitation)) targets.resolveGrantScope(companyId, g.scope()).ifPresent(scopes::add);
        return scopes;
    }

    private InvitationView toView(PartnerInvitation i, Instant now) {
        String status = i.getStatus() == PartnerInvitationStatus.PENDING && !i.getExpiresAt().isAfter(now)
            ? PartnerInvitationStatus.EXPIRED.name() : i.getStatus().name();
        List<PartnerTeamGrantView> grants = grantsOf(i).stream()
            .map(g -> new PartnerTeamGrantView(g.role().name(), g.scope().toString())).toList();
        User inviter = i.getInvitedBy();
        return new InvitationView(i.getId(), i.getEmail(), grants, status, i.getStatusReason(),
            i.getDeliveryStatus().name(), i.getExpiresAt(), i.getResendCount(), i.getLastSentAt(),
            inviter.getId(), inviter.getFullName(), i.getCreatedAt());
    }

    private List<MyInvitationGrant> myGrants(PartnerInvitation invitation) {
        List<MyInvitationGrant> out = new ArrayList<>();
        for (GrantSpec g : grantsOf(invitation)) {
            ScopeRef scope = g.scope();
            String name = switch (scope.type()) {
                case COMPANY -> invitation.getPartnerProfile().getBusinessName();
                case PROPERTY -> places.findById(scope.id()).map(p -> p.getName()).orElse(null);
                case UNIT -> rooms.findById(scope.id()).map(r -> r.getRoomName()).orElse(null);
            };
            out.add(new MyInvitationGrant(g.role().name(), scope.type().name(), name));
        }
        return out;
    }

    private static String describe(List<GrantSpec> grants, PartnerInvitationStatus status) {
        return String.join(",", PartnerTeamService.labels(grants)) + "|" + status.name();
    }

    private static String describeMember(List<GrantSpec> grants) {
        return String.join(",", PartnerTeamService.labels(grants)) + "|" + PartnerMembershipStatus.ACTIVE.name();
    }

    private PartnerProfile lockCompany(Long companyId) {
        return profiles.findByIdForUpdate(companyId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Partner profile not found"));
    }

    private static ApiException rateLimited(String message) {
        return new ApiException(HttpStatus.TOO_MANY_REQUESTS, INVITATION_RATE_LIMITED, message);
    }

    private static ApiException invalid() {
        return new ApiException(HttpStatus.BAD_REQUEST, INVITATION_INVALID,
            "This invitation link is invalid or has already been used");
    }

    private static ApiException expired() {
        return new ApiException(HttpStatus.BAD_REQUEST, INVITATION_EXPIRED, "This invitation has expired");
    }

    private static ApiException stale() {
        return new ApiException(HttpStatus.CONFLICT, INVITATION_STALE,
            "This invitation is no longer valid; ask the team for a new invitation");
    }

    private static ApiException partnerAccountRequired() {
        return new ApiException(HttpStatus.FORBIDDEN, PARTNER_ACCOUNT_REQUIRED,
            "Join with a verified Partner account that uses the invited address");
    }

    private static ApiException workspaceConflict(String reason) {
        return new ApiException(HttpStatus.CONFLICT, PartnerMembershipService.WORKSPACE_CONFLICT, null,
            "This account already belongs to a partner workspace", reason);
    }
}
