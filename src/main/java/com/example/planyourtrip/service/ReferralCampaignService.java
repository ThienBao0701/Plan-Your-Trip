package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.ReferralDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.CouponDefinition;
import com.example.planyourtrip.model.ReferralCampaign;
import com.example.planyourtrip.repository.CouponDefinitionRepository;
import com.example.planyourtrip.repository.ReferralCampaignRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.List;

/**
 * Phase 7.22 — Referral &amp; Invite Rewards.
 * Admin CRUD over {@link ReferralCampaign}, plus the authoritative "campaign
 * applicable now" selector reused by {@code ReferralService}. Follows
 * {@code LoyaltyRedemptionPolicyService}'s conventions exactly: 409 on duplicate
 * code, 404 on unknown id, 400 on invalid business values; optimistic
 * {@code @Version} conflicts on concurrent edits surface as 409 via the global
 * handler.
 */
@Service
@Transactional(readOnly = true)
public class ReferralCampaignService {

    private final ReferralCampaignRepository campaignRepo;
    private final CouponDefinitionRepository couponDefinitionRepo;

    public ReferralCampaignService(ReferralCampaignRepository campaignRepo,
                                    CouponDefinitionRepository couponDefinitionRepo) {
        this.campaignRepo = campaignRepo;
        this.couponDefinitionRepo = couponDefinitionRepo;
    }

    public List<ReferralCampaignResponse> getAll() {
        return campaignRepo.findAllByOrderByEffectiveFromDescIdDesc().stream().map(this::toResponse).toList();
    }

    public ReferralCampaignResponse getById(Long id) {
        return toResponse(campaignOrThrow(id));
    }

    @Transactional
    public ReferralCampaignResponse create(ReferralCampaignRequest req) {
        String code = req.code().trim();
        if (campaignRepo.findByCodeIgnoreCase(code).isPresent())
            throw new ApiException(HttpStatus.CONFLICT, "Referral campaign already exists: " + code);

        ReferralCampaign c = new ReferralCampaign();
        c.setCode(code);
        fill(c, req);
        return toResponse(campaignRepo.save(c));
    }

    @Transactional
    public ReferralCampaignResponse update(Long id, ReferralCampaignRequest req) {
        ReferralCampaign c = campaignOrThrow(id);
        String code = req.code().trim();
        campaignRepo.findByCodeIgnoreCase(code)
            .filter(other -> !other.getId().equals(id))
            .ifPresent(other -> { throw new ApiException(HttpStatus.CONFLICT,
                "Another referral campaign already uses code: " + code); });
        c.setCode(code);
        fill(c, req);
        return toResponse(campaignRepo.save(c));
    }

    @Transactional
    public ReferralCampaignResponse activate(Long id) {
        ReferralCampaign c = campaignOrThrow(id);
        c.setActive(true);
        return toResponse(campaignRepo.save(c));
    }

    @Transactional
    public ReferralCampaignResponse deactivate(Long id) {
        ReferralCampaign c = campaignOrThrow(id);
        c.setActive(false);
        return toResponse(campaignRepo.save(c));
    }

    /** The one campaign in force at {@code at} (newest applicable window), or 409 if none — mirrors {@code LoyaltyRedemptionPolicyService#resolveApplicable}. */
    public ReferralCampaign resolveApplicable(Instant at) {
        return campaignRepo.findApplicable(at).stream().findFirst()
            .orElseThrow(() -> new ApiException(HttpStatus.CONFLICT,
                "No active referral campaign is currently in effect"));
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    ReferralCampaign campaignOrThrow(Long id) {
        return campaignRepo.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Referral campaign not found: " + id));
    }

    private void fill(ReferralCampaign c, ReferralCampaignRequest req) {
        c.setName(req.name().trim());
        c.setMinimumQualifyingBookingAmount(scaleMoney(nonNegative(req.minimumQualifyingBookingAmount(),
            "minimumQualifyingBookingAmount")));

        c.setInviterRewardPoints(positivePoints(req.inviterRewardPoints(), "inviterRewardPoints"));
        c.setInviterRewardCouponDefinition(resolveCoupon(req.inviterRewardCouponDefinitionId()));
        fillCredit(req.inviterRewardCreditAmount(), req.inviterRewardCreditCurrency(), "inviter",
            c::setInviterRewardCreditAmount, c::setInviterRewardCreditCurrency);

        c.setInviteeRewardPoints(positivePoints(req.inviteeRewardPoints(), "inviteeRewardPoints"));
        c.setInviteeRewardCouponDefinition(resolveCoupon(req.inviteeRewardCouponDefinitionId()));
        fillCredit(req.inviteeRewardCreditAmount(), req.inviteeRewardCreditCurrency(), "invitee",
            c::setInviteeRewardCreditAmount, c::setInviteeRewardCreditCurrency);

        Instant from = req.effectiveFrom() != null ? req.effectiveFrom() : Instant.now();
        Instant until = req.effectiveUntil();
        if (until != null && !until.isAfter(from))
            throw new ApiException(HttpStatus.BAD_REQUEST, "effectiveUntil must be after effectiveFrom");
        c.setActive(req.active() == null || req.active());
        c.setEffectiveFrom(from);
        c.setEffectiveUntil(until);
    }

    private void fillCredit(BigDecimal amount, String currency, String who,
                            java.util.function.Consumer<BigDecimal> amountSetter,
                            java.util.function.Consumer<String> currencySetter) {
        BigDecimal amt = nonNegative(amount, who + "RewardCreditAmount");
        if (amt != null && amt.signum() > 0) {
            if (currency == null || currency.isBlank())
                throw new ApiException(HttpStatus.BAD_REQUEST,
                    who + "RewardCreditCurrency is required when " + who + "RewardCreditAmount is set");
            amountSetter.accept(scaleMoney(amt));
            currencySetter.accept(currency.trim().toUpperCase(java.util.Locale.ROOT));
        } else {
            amountSetter.accept(null);
            currencySetter.accept(null);
        }
    }

    private Long positivePoints(Long points, String field) {
        if (points == null) return null;
        if (points < 0) throw new ApiException(HttpStatus.BAD_REQUEST, field + " must not be negative");
        return points == 0 ? null : points;
    }

    private BigDecimal nonNegative(BigDecimal value, String field) {
        if (value == null) return null;
        if (value.signum() < 0) throw new ApiException(HttpStatus.BAD_REQUEST, field + " must not be negative");
        return value;
    }

    private BigDecimal scaleMoney(BigDecimal value) {
        return value == null ? null : value.setScale(2, RoundingMode.HALF_UP);
    }

    private CouponDefinition resolveCoupon(Long couponDefinitionId) {
        if (couponDefinitionId == null) return null;
        return couponDefinitionRepo.findById(couponDefinitionId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Coupon definition not found: " + couponDefinitionId));
    }

    ReferralCampaignResponse toResponse(ReferralCampaign c) {
        return new ReferralCampaignResponse(
            c.getId(), c.getCode(), c.getName(), c.getMinimumQualifyingBookingAmount(),
            c.getInviterRewardPoints(),
            c.getInviterRewardCouponDefinition() != null ? c.getInviterRewardCouponDefinition().getId() : null,
            c.getInviterRewardCreditAmount(), c.getInviterRewardCreditCurrency(),
            c.getInviteeRewardPoints(),
            c.getInviteeRewardCouponDefinition() != null ? c.getInviteeRewardCouponDefinition().getId() : null,
            c.getInviteeRewardCreditAmount(), c.getInviteeRewardCreditCurrency(),
            c.isActive(), c.getEffectiveFrom(), c.getEffectiveUntil(),
            c.getCreatedAt(), c.getUpdatedAt(), c.getVersion()
        );
    }
}
