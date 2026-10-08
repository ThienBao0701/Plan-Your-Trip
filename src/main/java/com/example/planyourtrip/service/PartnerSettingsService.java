package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PartnerSettingsDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import com.example.planyourtrip.security.StepUpPolicy;
import com.example.planyourtrip.security.rbac.PartnerAccessContext;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static com.example.planyourtrip.security.rbac.PartnerPermission.PAYOUT_ACCOUNT_MANAGE;
import static com.example.planyourtrip.security.rbac.PartnerPermission.PAYOUT_ACCOUNT_VIEW;
import static com.example.planyourtrip.security.rbac.PartnerPermission.SETTINGS_EDIT;
import static com.example.planyourtrip.security.rbac.PartnerPermission.WORKSPACE_ACCESS;

/**
 * Partner-side business settings and payout metadata. Team management is {@link PartnerTeamService} (RBAC R3a).
 *
 * <p>Unlike the operational partner services (which only ever resolve "the caller IS the
 * profile-owning user"), this service allows delegated team access: a caller is either the
 * profile's own user (who holds every partner permission) or an active {@link PartnerTeamMember}
 * of some partner profile, whose role's legacy bundle governs what they may do. Both are resolved
 * by {@link PartnerAccessService#requireTeamWorkspace} and checked through the RBAC kernel; the
 * bundles reproduce the pre-RBAC rules exactly ({@code LegacyPartnerBundles}).
 *
 * <p>No payout is ever executed and no real bank account number is ever persisted —
 * {@link PartnerPayoutAccount#getBankAccountLast4()} is derived once from the request
 * and the full number is discarded immediately after.
 */
@Service
public class PartnerSettingsService {

    private static final String SETTINGS_DENIED = "Your role does not allow you to manage business/notification settings";
    private static final String PAYOUT_DENIED = "Your role does not allow you to manage payout metadata";

    private final PartnerProfileRepository partnerProfileRepo;
    private final PartnerSettingsRepository settingsRepo;
    private final PartnerPayoutAccountRepository payoutAccountRepo;
    private final PartnerActivityLogService activityLogService;
    private final PartnerAccessService partnerAccess;
    private final PartnerTeamService teamService;
    private final PartnerSecurityNotifier securityNotifier;
    private final StepUpPolicy stepUp;

    public PartnerSettingsService(PartnerProfileRepository partnerProfileRepo,
                                   PartnerSettingsRepository settingsRepo,
                                   PartnerPayoutAccountRepository payoutAccountRepo,
                                   PartnerActivityLogService activityLogService,
                                   PartnerAccessService partnerAccess,
                                   PartnerTeamService teamService,
                                   PartnerSecurityNotifier securityNotifier,
                                   StepUpPolicy stepUp) {
        this.partnerProfileRepo = partnerProfileRepo;
        this.settingsRepo = settingsRepo;
        this.payoutAccountRepo = payoutAccountRepo;
        this.activityLogService = activityLogService;
        this.partnerAccess = partnerAccess;
        this.teamService = teamService;
        this.securityNotifier = securityNotifier;
        this.stepUp = stepUp;
    }

    // ── Settings ─────────────────────────────────────────────────────────────

    @Transactional
    public PartnerSettingsResponse getSettings(Long userId) {
        PartnerAccessContext access = partnerAccess.requireTeamWorkspace(userId);
        partnerAccess.requireCompanyPermission(access, WORKSPACE_ACCESS, null);
        return toSettingsResponse(getOrCreateSettings(access.profile()));
    }

    @Transactional
    public PartnerSettingsResponse updateSettings(Long userId, PartnerSettingsRequest req) {
        PartnerAccessContext access = partnerAccess.requireTeamWorkspace(userId);
        partnerAccess.requireCompanyPermission(access, SETTINGS_EDIT, SETTINGS_DENIED);

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
        PartnerAccessContext access = partnerAccess.requireTeamWorkspace(userId);
        partnerAccess.requireCompanyPermission(access, PAYOUT_ACCOUNT_VIEW, null);
        PartnerPayoutAccount account = payoutAccountRepo.findByPartnerProfileId(access.profile().getId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Payout account not configured yet"));
        return toPayoutResponse(account);
    }

    /**
     * Same as {@link #getPayoutAccount} but returns null instead of throwing when no
     * payout account is configured yet — for callers (like account-summary
     * aggregation) that need to tolerate "not configured" without relying on
     * exception-based control flow across a transactional boundary (catching an
     * exception thrown by a nested {@code @Transactional} call does not clear Spring's
     * rollback-only flag on the shared transaction and would surface as an
     * {@code UnexpectedRollbackException} instead).
     */
    @Transactional(readOnly = true)
    public PartnerPayoutAccountResponse getPayoutAccountOrNull(Long userId) {
        PartnerAccessContext access = partnerAccess.requireTeamWorkspace(userId);
        partnerAccess.requireCompanyPermission(access, PAYOUT_ACCOUNT_VIEW, null);
        return payoutAccountRepo.findByPartnerProfileId(access.profile().getId())
            .map(this::toPayoutResponse).orElse(null);
    }

    @Transactional
    public PartnerPayoutAccountResponse updatePayoutAccount(Long userId, PartnerPayoutAccountRequest req) {
        PartnerAccessContext access = partnerAccess.requireTeamWorkspace(userId);
        partnerAccess.requireCompanyPermission(access, PAYOUT_ACCOUNT_MANAGE, PAYOUT_DENIED);
        // RBAC R3a §20 FI-4, §18 O-7 — changing where money goes needs a fresh session.
        stepUp.requireFresh();

        Optional<PartnerPayoutAccount> existing = payoutAccountRepo.findByPartnerProfileId(access.profile().getId());
        String before = existing.map(a -> masked(a.getBankAccountLast4())).orElse("none");
        PartnerPayoutAccount account = existing
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
        String after = masked(saved.getBankAccountLast4());
        // RBAC R3a — strict audit with masked before/after (AU-1, FI-4) and every owner notified (O-8, FI-6).
        activityLogService.audit(access.profile().getId(), userId, "PAYOUT_ACCOUNT_UPDATED",
            "PAYOUT_ACCOUNT", saved.getId(), "Payout account updated", before, after, null);
        securityNotifier.notifyOwners(access.profile(), null, "Payout account updated",
            "Your payout account details have been updated (" + before + " -> " + after + ").");
        return toPayoutResponse(saved);
    }

    // ── Admin (unrestricted, no role/ownership checks) ──────────────────────────

    @Transactional(readOnly = true)
    public PartnerSettingsResponse adminGetSettings(Long partnerProfileId) {
        PartnerProfile profile = partnerProfileRepo.findById(partnerProfileId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Partner profile not found: " + partnerProfileId));
        return toSettingsResponse(getOrCreateSettings(profile));
    }

    /** The caller's team (members not revoked); kept for the account summary — {@link PartnerTeamService#list}. */
    @Transactional(readOnly = true)
    public List<PartnerTeamMemberResponse> getTeamMembers(Long userId) {
        return teamService.list(userId);
    }

    @Transactional(readOnly = true)
    public List<PartnerTeamMemberResponse> adminGetTeamMembers(Long partnerProfileId) {
        return teamService.adminList(partnerProfileId);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────


    private PartnerSettings getOrCreateSettings(PartnerProfile profile) {
        return settingsRepo.findByPartnerProfileId(profile.getId()).orElseGet(() -> {
            PartnerSettings settings = new PartnerSettings();
            settings.setPartnerProfile(profile);
            return settingsRepo.save(settings);
        });
    }

    private static String masked(String lastFour) {
        return lastFour == null ? "none" : "****" + lastFour;
    }

    private String lastFour(String accountNumber) {
        String trimmed = accountNumber.trim();
        return trimmed.length() <= 4 ? trimmed : trimmed.substring(trimmed.length() - 4);
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

}
