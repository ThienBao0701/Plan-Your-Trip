package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.LoyaltyDto.LoyaltyGrantRequest;
import com.example.planyourtrip.dto.ReferralDto.*;
import com.example.planyourtrip.dto.TravelCreditDto.TravelCreditAdjustmentRequest;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.ReferralCodeRepository;
import com.example.planyourtrip.repository.ReferralRewardRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/**
 * Phase 7.22 — Referral &amp; Invite Rewards.
 *
 * <p><b>Not a new reward engine.</b> This service creates NO points/credit
 * ledger of its own. {@link ReferralReward} is a pure audit/lifecycle record;
 * every unit of value flows through the existing grant primitives —
 * {@code LoyaltyService.adminGrant}, {@code TravelCreditService.grant} and the
 * Phase 7.22 additive {@code CustomerCouponService.issueDirectly} (which itself
 * reuses claim()'s internals).
 *
 * <p><b>Rewards are granted only after a qualifying first booking — never at
 * registration.</b> {@link #useCode} only records the {@code USED} relationship;
 * value is granted later, at booking completion, by
 * {@link #qualifyBookingForReferral}, wired into the SAME BookingService
 * completion hook that already fires {@code loyaltyService.awardBookingPoints}
 * (no second, competing hook).
 *
 * <p><b>Qualification rule (documented judgment call).</b> When a booking
 * completes for the invitee and the invitee holds a {@code USED} reward, the
 * booking qualifies iff — when the campaign configures a
 * {@code minimumQualifyingBookingAmount} — the booking's {@code finalPrice} is
 * &ge; that minimum (no minimum ⇒ any completed booking qualifies). The spec's
 * "first COMPLETED booking" is realized by the one-way {@code USED → REWARDED}
 * gate: the first completed booking that meets the minimum is the qualifying
 * one, and once rewarded every later completion is a no-op. We deliberately do
 * NOT additionally require it to be literally the very first completed booking,
 * which would permanently lock out an invitee whose first completed booking
 * happened to fall below the minimum.
 *
 * <p><b>Reward-once / idempotency.</b> Two independent guards: (a) the one-way
 * status gate (only a {@code USED} row is eligible; it flips to {@code REWARDED}
 * in the same transaction, so a repeated completion trigger — which Phase 7.18
 * proves happens here — finds {@code REWARDED} and does nothing), and (b) a
 * deterministic idempotency key derived from the reward id threaded into each
 * underlying Loyalty/TravelCredit grant, so even those ledgers physically cannot
 * double-grant.
 */
@Service
public class ReferralService {

    private static final SecureRandom RANDOM = new SecureRandom();
    private static final char[] CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".toCharArray();
    private static final int CODE_LENGTH = 8;

    private final ReferralCodeRepository codeRepo;
    private final ReferralRewardRepository rewardRepo;
    private final UserRepository userRepo;
    private final ReferralCampaignService campaignService;
    private final LoyaltyService loyaltyService;
    private final TravelCreditService travelCreditService;
    private final CustomerCouponService customerCouponService;
    private final NotificationService notificationService;

    public ReferralService(ReferralCodeRepository codeRepo,
                            ReferralRewardRepository rewardRepo,
                            UserRepository userRepo,
                            ReferralCampaignService campaignService,
                            LoyaltyService loyaltyService,
                            TravelCreditService travelCreditService,
                            CustomerCouponService customerCouponService,
                            NotificationService notificationService) {
        this.codeRepo = codeRepo;
        this.rewardRepo = rewardRepo;
        this.userRepo = userRepo;
        this.campaignService = campaignService;
        this.loyaltyService = loyaltyService;
        this.travelCreditService = travelCreditService;
        this.customerCouponService = customerCouponService;
        this.notificationService = notificationService;
    }

    // ── Customer: my code + stats (lazily created) ───────────────────────────

    /** Not readOnly — first access lazily creates the immutable code. */
    @Transactional
    public MyReferralResponse getOrCreateMyReferral(Long userId) {
        ReferralCode code = getOrCreateCode(userId);
        long successful = rewardRepo.countByInviterIdAndStatus(userId, ReferralRewardStatus.REWARDED);
        long pending = rewardRepo.countByInviterIdAndStatus(userId, ReferralRewardStatus.USED);
        return new MyReferralResponse(code.getCode(), successful, pending, code.getCreatedAt());
    }

    // ── Customer: use someone else's code ────────────────────────────────────

    /**
     * Flow step 2: the invitee enters the inviter's code. Validates and records
     * the {@code USED} relationship under the currently-applicable campaign. No
     * value is granted here — that waits for the qualifying booking.
     *
     * <p>Status choices (following existing conventions): unknown code → 404;
     * using your OWN code (self-referral) → 400 (a bad request, not an auth
     * failure); already used ANY code before → 409 (state conflict, backstopped
     * by the DB-unique invitee column); no active campaign → 409 (via
     * {@code ReferralCampaignService#resolveApplicable}).
     */
    @Transactional
    public ReferralRewardResponse useCode(Long inviteeUserId, String rawCode) {
        String code = rawCode == null ? "" : rawCode.trim();
        ReferralCode referralCode = codeRepo.findByCodeIgnoreCase(code)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Referral code not found: " + code));

        Long inviterUserId = referralCode.getOwner().getId();
        if (inviterUserId.equals(inviteeUserId))
            throw new ApiException(HttpStatus.BAD_REQUEST, "You cannot use your own referral code");

        if (rewardRepo.existsByInviteeId(inviteeUserId))
            throw new ApiException(HttpStatus.CONFLICT,
                "You have already used a referral code and cannot use another");

        ReferralCampaign campaign = campaignService.resolveApplicable(Instant.now());
        User invitee = userOrThrow(inviteeUserId);

        ReferralReward reward = new ReferralReward();
        reward.setReferralCode(referralCode);
        reward.setInviter(referralCode.getOwner());
        reward.setInvitee(invitee);
        reward.setCampaign(campaign);
        reward.setStatus(ReferralRewardStatus.USED);
        reward.setUsedAt(Instant.now());
        return toRewardResponse(rewardRepo.save(reward), inviteeUserId);
    }

    // ── Customer: history (as inviter AND/OR invitee) ────────────────────────

    @Transactional(readOnly = true)
    public List<ReferralRewardResponse> myHistory(Long userId) {
        List<ReferralRewardResponse> out = new ArrayList<>();
        rewardRepo.findByInviterIdOrderByCreatedAtDescIdDesc(userId)
            .forEach(r -> out.add(toRewardResponse(r, userId)));
        rewardRepo.findByInviteeId(userId).ifPresent(r -> out.add(toRewardResponse(r, userId)));
        return out;
    }

    // ── Booking-completion qualification hook (called by BookingService) ─────

    /**
     * Wired into the existing booking-completion hook. A cheap no-op for the vast
     * majority of completions (a single indexed lookup returns empty when the
     * booking's owner is not an invitee awaiting qualification). When the invitee
     * holds a {@code USED} reward and this booking qualifies, grants BOTH parties'
     * configured rewards atomically (joins the caller's transaction) and flips the
     * reward to {@code REWARDED}. Returns silently otherwise (non-qualifying
     * booking / already rewarded / not an invitee).
     */
    @Transactional
    public void qualifyBookingForReferral(Long inviteeUserId, Long bookingId, BigDecimal finalPrice) {
        ReferralReward reward = rewardRepo
            .findByInviteeIdAndStatus(inviteeUserId, ReferralRewardStatus.USED).orElse(null);
        if (reward == null) return; // not an invitee, or already rewarded

        ReferralCampaign campaign = reward.getCampaign();
        BigDecimal minimum = campaign.getMinimumQualifyingBookingAmount();
        if (minimum != null) {
            if (finalPrice == null || finalPrice.compareTo(minimum) < 0) return; // non-qualifying
        }

        Long inviterUserId = reward.getInviter().getId();
        Long rewardId = reward.getId();

        // Inviter rewards.
        grantPoints(inviterUserId, campaign.getInviterRewardPoints(), rewardId, "inviter", bookingId);
        grantCredit(inviterUserId, campaign.getInviterRewardCreditAmount(),
            campaign.getInviterRewardCreditCurrency(), rewardId, "inviter", bookingId);
        grantCoupon(inviterUserId, campaign.getInviterRewardCouponDefinition());

        // Invitee rewards.
        grantPoints(inviteeUserId, campaign.getInviteeRewardPoints(), rewardId, "invitee", bookingId);
        grantCredit(inviteeUserId, campaign.getInviteeRewardCreditAmount(),
            campaign.getInviteeRewardCreditCurrency(), rewardId, "invitee", bookingId);
        grantCoupon(inviteeUserId, campaign.getInviteeRewardCouponDefinition());

        Instant now = Instant.now();
        reward.setStatus(ReferralRewardStatus.REWARDED);
        reward.setQualifiedAt(now);
        reward.setRewardedAt(now);
        reward.setQualifyingBookingId(bookingId);
        rewardRepo.save(reward);

        notifyRewarded(inviterUserId, true, campaign, rewardId);
        notifyRewarded(inviteeUserId, false, campaign, rewardId);
    }

    // ── Grant helpers — each routes to an EXISTING primitive ─────────────────

    private void grantPoints(Long userId, Long points, Long rewardId, String who, Long bookingId) {
        if (points == null || points <= 0) return;
        String key = "referral-" + rewardId + "-" + who + "-points";
        loyaltyService.adminGrant(userId, new LoyaltyGrantRequest(
            points, "Referral reward for booking #" + bookingId,
            LoyaltyReferenceType.SYSTEM, rewardId, key));
    }

    private void grantCredit(Long userId, BigDecimal amount, String currency,
                             Long rewardId, String who, Long bookingId) {
        if (amount == null || amount.signum() <= 0) return;
        String key = "referral-" + rewardId + "-" + who + "-credit";
        travelCreditService.grant(userId, new TravelCreditAdjustmentRequest(
            amount, currency, "Referral reward for booking #" + bookingId,
            TravelCreditReferenceType.SYSTEM, rewardId, key, null,
            TravelCreditTransactionType.GRANT));
    }

    private void grantCoupon(Long userId, CouponDefinition couponDefinition) {
        if (couponDefinition == null) return;
        customerCouponService.issueDirectly(userId, couponDefinition.getId());
    }

    // ── Notifications (only at reward time, per spec) ────────────────────────

    private void notifyRewarded(Long userId, boolean inviter, ReferralCampaign campaign, Long rewardId) {
        String granted = describeReward(
            inviter ? campaign.getInviterRewardPoints() : campaign.getInviteeRewardPoints(),
            inviter ? campaign.getInviterRewardCouponDefinition() : campaign.getInviteeRewardCouponDefinition(),
            inviter ? campaign.getInviterRewardCreditAmount() : campaign.getInviteeRewardCreditAmount(),
            inviter ? campaign.getInviterRewardCreditCurrency() : campaign.getInviteeRewardCreditCurrency());
        String title = inviter ? "You earned a referral reward" : "Welcome reward unlocked";
        String lead = inviter
            ? "Your referral reward has been unlocked"
            : "Your welcome reward has been unlocked";
        String message = granted.isBlank() ? lead + "." : lead + ": " + granted + ".";
        notificationService.create(userId, NotificationType.PROMOTION, Priority.NORMAL,
            title, message, RelatedEntityType.PROMOTION, rewardId);
    }

    /** User-facing summary of what was granted — deliberately never exposes campaign/admin config internals. */
    private String describeReward(Long points, CouponDefinition coupon, BigDecimal credit, String currency) {
        List<String> parts = new ArrayList<>();
        if (points != null && points > 0) parts.add(points + " loyalty points");
        if (coupon != null) parts.add("a coupon");
        if (credit != null && credit.signum() > 0)
            parts.add(credit.toPlainString() + " " + currency + " in travel credit");
        return String.join(", ", parts);
    }

    // ── Code helpers ─────────────────────────────────────────────────────────

    private ReferralCode getOrCreateCode(Long userId) {
        return codeRepo.findByOwnerId(userId).orElseGet(() -> {
            ReferralCode c = new ReferralCode();
            c.setOwner(userOrThrow(userId));
            c.setCode(generateUniqueCode());
            return codeRepo.save(c);
        });
    }

    private String generateUniqueCode() {
        for (int attempt = 0; attempt < 20; attempt++) {
            StringBuilder sb = new StringBuilder(CODE_LENGTH);
            for (int i = 0; i < CODE_LENGTH; i++)
                sb.append(CODE_ALPHABET[RANDOM.nextInt(CODE_ALPHABET.length)]);
            String candidate = sb.toString();
            if (!codeRepo.existsByCodeIgnoreCase(candidate)) return candidate;
        }
        throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "Unable to generate a unique referral code");
    }

    private User userOrThrow(Long userId) {
        return userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found: " + userId));
    }

    private ReferralRewardResponse toRewardResponse(ReferralReward r, Long viewerUserId) {
        String role = r.getInviter().getId().equals(viewerUserId) ? "INVITER" : "INVITEE";
        return new ReferralRewardResponse(
            r.getId(), role, r.getCampaign().getCode(),
            r.getInviter().getId(), r.getInvitee().getId(),
            r.getStatus(), r.getUsedAt(), r.getQualifiedAt(),
            r.getQualifyingBookingId(), r.getRewardedAt(), r.getCreatedAt());
    }
}
