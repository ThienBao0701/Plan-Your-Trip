package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Phase 7.22 — Referral &amp; Invite Rewards.
 * Admin-configurable rule set governing a referral programme. Mirrors the
 * established single-active-definition discipline of {@link LoyaltyRedemptionPolicy}:
 * every reward number lives here as a DB row (never hardcoded), "the campaign in
 * effect now" is resolved by {@code ReferralCampaignRepository#findApplicable}
 * (active + effective window contains now, newest effectiveFrom wins), and
 * optimistic {@link #version} locking guards concurrent admin edits.
 *
 * <p>Rewards are configured SEPARATELY for the inviter and the invitee, and every
 * reward field is optional/nullable — a campaign may grant any combination of
 * loyalty points, a coupon and/or travel credit (e.g. points-only, or
 * points+coupon). A reward is only granted when its value is present and
 * positive. This entity introduces NO new value mechanism: at qualification time
 * {@code ReferralService} routes every configured reward through the existing
 * Loyalty / Coupon / TravelCredit grant primitives.
 *
 * <p>Qualification rule: the reward is triggered by the invitee's first
 * <em>qualifying</em> COMPLETED booking. When {@link #minimumQualifyingBookingAmount}
 * is set, the completing booking's {@code finalPrice} must be &ge; it; when null,
 * any completed booking qualifies.
 */
@Entity
@Table(name = "referral_campaigns",
       uniqueConstraints = @UniqueConstraint(name = "uk_referral_campaign_code", columnNames = "code"),
       indexes = {
           @Index(name = "idx_referral_campaign_active", columnList = "active"),
           @Index(name = "idx_referral_campaign_effective_from", columnList = "effective_from")
       })
@Getter @Setter
public class ReferralCampaign {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 60)
    private String code;

    @Column(nullable = false)
    private String name;

    /** Null = no minimum; otherwise the qualifying booking's finalPrice must be &ge; this. */
    @Column(name = "minimum_qualifying_booking_amount", precision = 15, scale = 2)
    private BigDecimal minimumQualifyingBookingAmount;

    // ── Inviter reward configuration (all optional) ──────────────────────────

    @Column(name = "inviter_reward_points")
    private Long inviterRewardPoints;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "inviter_reward_coupon_definition_id")
    private CouponDefinition inviterRewardCouponDefinition;

    @Column(name = "inviter_reward_credit_amount", precision = 15, scale = 2)
    private BigDecimal inviterRewardCreditAmount;

    @Column(name = "inviter_reward_credit_currency", length = 3)
    private String inviterRewardCreditCurrency;

    // ── Invitee reward configuration (all optional) ──────────────────────────

    @Column(name = "invitee_reward_points")
    private Long inviteeRewardPoints;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "invitee_reward_coupon_definition_id")
    private CouponDefinition inviteeRewardCouponDefinition;

    @Column(name = "invitee_reward_credit_amount", precision = 15, scale = 2)
    private BigDecimal inviteeRewardCreditAmount;

    @Column(name = "invitee_reward_credit_currency", length = 3)
    private String inviteeRewardCreditCurrency;

    // ── Lifecycle / window ───────────────────────────────────────────────────

    @Column(nullable = false)
    private boolean active = true;

    @Column(name = "effective_from", nullable = false)
    private Instant effectiveFrom;

    /** Nullable — absence means "no expiry". */
    @Column(name = "effective_until")
    private Instant effectiveUntil;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @Version
    private Long version;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
