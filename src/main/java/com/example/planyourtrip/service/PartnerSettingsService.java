package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PartnerSettingsDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;

/**
 * Partner-side business settings, payout metadata, and team management.
 *
 * <p>Unlike earlier partner services (which only ever resolve "the caller IS the
 * profile-owning user"), this service introduces delegated team access: a caller is
 * either the profile's own user (always treated as {@link PartnerTeamRole#OWNER}) or
 * an active {@link PartnerTeamMember} of some partner profile, in which case their
 * granted role governs what they may do. See {@link #resolveAccess(Long)}.
 *
 * <p>No payout is ever executed and no real bank account number is ever persisted —
 * {@link PartnerPayoutAccount#getBankAccountLast4()} is derived once from the request
 * and the full number is discarded immediately after.
 */
@Service
public class PartnerSettingsService {

    private static final Set<PartnerTeamRole> SETTINGS_WRITE_ROLES =
        EnumSet.of(PartnerTeamRole.OWNER, PartnerTeamRole.MANAGER);
    private static final Set<PartnerTeamRole> PAYOUT_WRITE_ROLES =
        EnumSet.of(PartnerTeamRole.OWNER, PartnerTeamRole.FINANCE);

    private final PartnerProfileRepository partnerProfileRepo;
    private final PartnerSettingsRepository settingsRepo;
    private final PartnerPayoutAccountRepository payoutAccountRepo;
    private final PartnerTeamMemberRepository teamMemberRepo;
    private final UserRepository userRepo;
    private final NotificationService notificationService;

    public PartnerSettingsService(PartnerProfileRepository partnerProfileRepo,
                                   PartnerSettingsRepository settingsRepo,
                                   PartnerPayoutAccountRepository payoutAccountRepo,
                                   PartnerTeamMemberRepository teamMemberRepo,
                                   UserRepository userRepo,
                                   NotificationService notificationService) {
        this.partnerProfileRepo = partnerProfileRepo;
        this.settingsRepo = settingsRepo;
        this.payoutAccountRepo = payoutAccountRepo;
        this.teamMemberRepo = teamMemberRepo;
        this.userRepo = userRepo;
        this.notificationService = notificationService;
    }

    // ── Settings ─────────────────────────────────────────────────────────────

    @Transactional
    public PartnerSettingsResponse getSettings(Long userId) {
        PartnerAccess access = resolveAccess(userId);
        return toSettingsResponse(getOrCreateSettings(access.profile()));
    }

    @Transactional
    public PartnerSettingsResponse updateSettings(Long userId, PartnerSettingsRequest req) {
        PartnerAccess access = resolveAccess(userId);
        requireRole(access.role(), SETTINGS_WRITE_ROLES, "manage business/notification settings");

        PartnerSettings settings = getOrCreateSettings(access.profile());
        if (req.defaultLanguage() != null) settings.setDefaultLanguage(req.defaultLanguage());
        if (req.timezone() != null) settings.setTimezone(req.timezone());
        settings.setNotificationEmailEnabled(req.notificationEmailEnabled());
        settings.setNotificationSmsEnabled(req.notificationSmsEnabled());
        settings.setNotificationInAppEnabled(req.notificationInAppEnabled());
        settings.setBookingNotificationEnabled(req.bookingNotificationEnabled());
        settings.setPaymentNotificationEnabled(req.paymentNotificationEnabled());
        settings.setReviewNotificationEnabled(req.reviewNotificationEnabled());
        settings.setPromotionNotificationEnabled(req.promotionNotificationEnabled());

        return toSettingsResponse(settingsRepo.save(settings));
    }

    // ── Payout account ───────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public PartnerPayoutAccountResponse getPayoutAccount(Long userId) {
        PartnerAccess access = resolveAccess(userId);
        PartnerPayoutAccount account = payoutAccountRepo.findByPartnerProfileId(access.profile().getId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Payout account not configured yet"));
        return toPayoutResponse(account);
    }

    @Transactional
    public PartnerPayoutAccountResponse updatePayoutAccount(Long userId, PartnerPayoutAccountRequest req) {
        PartnerAccess access = resolveAccess(userId);
        requireRole(access.role(), PAYOUT_WRITE_ROLES, "manage payout metadata");

        PartnerPayoutAccount account = payoutAccountRepo.findByPartnerProfileId(access.profile().getId())
            .orElseGet(() -> {
                PartnerPayoutAccount fresh = new PartnerPayoutAccount();
                fresh.setPartnerProfile(access.profile());
                fresh.setStatus(PayoutAccountStatus.DRAFT);
                return fresh;
            });

        account.setAccountHolderName(req.accountHolderName());
        account.setBankName(req.bankName());
        account.setBankAccountLast4(lastFour(req.bankAccountNumber()));
        account.setPayoutMethod(req.payoutMethod());

        PartnerPayoutAccount saved = payoutAccountRepo.save(account);
        notifyPayoutUpdated(access.profile());
        return toPayoutResponse(saved);
    }

    // ── Team ─────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<PartnerTeamMemberResponse> getTeamMembers(Long userId) {
        PartnerAccess access = resolveAccess(userId);
        return teamMemberRepo.findByPartnerProfileIdOrderByCreatedAtAsc(access.profile().getId())
            .stream().map(this::toTeamResponse).toList();
    }

    @Transactional
    public PartnerTeamMemberResponse addTeamMember(Long userId, PartnerTeamMemberRequest req) {
        PartnerAccess access = resolveAccess(userId);
        requireOwner(access.role());

        if (req.email() == null || req.email().isBlank())
            throw new ApiException(HttpStatus.BAD_REQUEST, "email is required");
        if (req.role() == null)
            throw new ApiException(HttpStatus.BAD_REQUEST, "role is required");

        User target = userRepo.findByEmail(req.email())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found: " + req.email()));

        if (teamMemberRepo.existsByPartnerProfileIdAndUserId(access.profile().getId(), target.getId()))
            throw new ApiException(HttpStatus.CONFLICT, "This user is already a team member");

        // /api/partner/** is gated by role at the security-filter level (hasAnyRole("PARTNER","ADMIN")),
        // same as PartnerProfileService.adminApprove() — a team member needs this to reach the
        // finer-grained PartnerTeamRole checks in this service at all.
        if (!"ADMIN".equals(target.getRole()) && !"PARTNER".equals(target.getRole())) {
            target.setRole("PARTNER");
            userRepo.save(target);
        }

        PartnerTeamMember member = new PartnerTeamMember();
        member.setPartnerProfile(access.profile());
        member.setUser(target);
        member.setRole(req.role());
        member.setActive(req.active() == null || req.active());
        Instant now = Instant.now();
        member.setInvitedAt(now);
        member.setJoinedAt(now);

        PartnerTeamMember saved = teamMemberRepo.save(member);

        notificationService.create(target.getId(), NotificationType.PARTNER, Priority.NORMAL,
            "You were added to a partner team",
            "You were added to " + access.profile().getBusinessName() + "'s team as " + req.role().name() + ".",
            RelatedEntityType.PARTNER, access.profile().getId());

        return toTeamResponse(saved);
    }

    @Transactional
    public PartnerTeamMemberResponse updateTeamMember(Long userId, Long teamMemberId, PartnerTeamMemberRequest req) {
        PartnerAccess access = resolveAccess(userId);
        requireOwner(access.role());

        PartnerTeamMember member = ownedTeamMemberOrThrow(teamMemberId, access.profile().getId());
        if (req.role() != null) member.setRole(req.role());
        if (req.active() != null) member.setActive(req.active());

        return toTeamResponse(teamMemberRepo.save(member));
    }

    @Transactional
    public void removeTeamMember(Long userId, Long teamMemberId) {
        PartnerAccess access = resolveAccess(userId);
        requireOwner(access.role());

        PartnerTeamMember member = ownedTeamMemberOrThrow(teamMemberId, access.profile().getId());
        teamMemberRepo.delete(member);
    }

    // ── Access resolution ────────────────────────────────────────────────────

    private record PartnerAccess(PartnerProfile profile, PartnerTeamRole role) {}

    private PartnerAccess resolveAccess(Long userId) {
        PartnerProfile ownProfile = partnerProfileRepo.findByUserId(userId).orElse(null);
        if (ownProfile != null) {
            requireApproved(ownProfile);
            return new PartnerAccess(ownProfile, PartnerTeamRole.OWNER);
        }

        PartnerTeamMember membership = teamMemberRepo.findByUserIdAndActiveTrue(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Partner profile not found"));
        PartnerProfile profile = membership.getPartnerProfile();
        requireApproved(profile);
        return new PartnerAccess(profile, membership.getRole());
    }

    private void requireApproved(PartnerProfile profile) {
        if (profile.getVerificationStatus() != PartnerVerificationStatus.APPROVED)
            throw new ApiException(HttpStatus.FORBIDDEN, "Partner profile is not approved");
    }

    private void requireRole(PartnerTeamRole actual, Set<PartnerTeamRole> allowed, String action) {
        if (!allowed.contains(actual))
            throw new ApiException(HttpStatus.FORBIDDEN, "Your role does not allow you to " + action);
    }

    private void requireOwner(PartnerTeamRole actual) {
        if (actual != PartnerTeamRole.OWNER)
            throw new ApiException(HttpStatus.FORBIDDEN, "Only the partner owner can manage team members");
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private PartnerSettings getOrCreateSettings(PartnerProfile profile) {
        return settingsRepo.findByPartnerProfileId(profile.getId()).orElseGet(() -> {
            PartnerSettings settings = new PartnerSettings();
            settings.setPartnerProfile(profile);
            return settingsRepo.save(settings);
        });
    }

    private String lastFour(String accountNumber) {
        String trimmed = accountNumber.trim();
        return trimmed.length() <= 4 ? trimmed : trimmed.substring(trimmed.length() - 4);
    }

    private void notifyPayoutUpdated(PartnerProfile profile) {
        notificationService.create(profile.getUser().getId(), NotificationType.PARTNER, Priority.NORMAL,
            "Payout account updated",
            "Your payout account details have been updated.",
            RelatedEntityType.PARTNER, profile.getId());
    }

    private PartnerTeamMember ownedTeamMemberOrThrow(Long teamMemberId, Long profileId) {
        PartnerTeamMember member = teamMemberRepo.findById(teamMemberId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Team member not found: " + teamMemberId));
        if (!member.getPartnerProfile().getId().equals(profileId))
            throw new ApiException(HttpStatus.NOT_FOUND, "Team member not found: " + teamMemberId);
        return member;
    }

    private PartnerSettingsResponse toSettingsResponse(PartnerSettings s) {
        return new PartnerSettingsResponse(
            s.getId(), s.getPartnerProfile().getId(),
            s.getDefaultLanguage(), s.getTimezone(),
            s.isNotificationEmailEnabled(), s.isNotificationSmsEnabled(), s.isNotificationInAppEnabled(),
            s.isBookingNotificationEnabled(), s.isPaymentNotificationEnabled(),
            s.isReviewNotificationEnabled(), s.isPromotionNotificationEnabled(),
            s.getCreatedAt(), s.getUpdatedAt()
        );
    }

    private PartnerPayoutAccountResponse toPayoutResponse(PartnerPayoutAccount a) {
        return new PartnerPayoutAccountResponse(
            a.getId(), a.getPartnerProfile().getId(),
            a.getAccountHolderName(), a.getBankName(), a.getBankAccountLast4(),
            a.getPayoutMethod().name(), a.getStatus().name(),
            a.getCreatedAt(), a.getUpdatedAt()
        );
    }

    private PartnerTeamMemberResponse toTeamResponse(PartnerTeamMember m) {
        return new PartnerTeamMemberResponse(
            m.getId(), m.getPartnerProfile().getId(),
            m.getUser().getId(), m.getUser().getFullName(), m.getUser().getEmail(),
            m.getRole().name(), m.isActive(),
            m.getInvitedAt(), m.getJoinedAt(), m.getCreatedAt(), m.getUpdatedAt()
        );
    }
}
