package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

/**
 * Phase 7.22 — Referral &amp; Invite Rewards.
 * The audit / lifecycle record of ONE referral relationship: who referred whom,
 * under which {@link ReferralCampaign}, and what happened. This is NOT a second
 * points/credit ledger — it holds no balances. All actual value flows through
 * the existing Loyalty / Coupon / TravelCredit ledgers; this row only tracks the
 * relationship state ({@link ReferralRewardStatus}) and the timestamps around it.
 *
 * <p>{@link #invitee} carries a DB-unique constraint: a user can be an invitee
 * exactly ONCE, ever — this is the physical backstop for "a user may only use
 * one referral code, only at first registration". The one-way
 * {@code USED → REWARDED} status gate, together with deterministic idempotency
 * keys derived from this row's id and threaded into each underlying grant, makes
 * reward-granting exactly-once even under repeated booking-completion triggers.
 */
@Entity
@Table(name = "referral_rewards",
       uniqueConstraints = @UniqueConstraint(name = "uk_referral_reward_invitee", columnNames = "invitee_id"),
       indexes = {
           @Index(name = "idx_referral_reward_inviter", columnList = "inviter_id"),
           @Index(name = "idx_referral_reward_status", columnList = "status")
       })
@Getter @Setter
public class ReferralReward {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "referral_code_id", nullable = false)
    private ReferralCode referralCode;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "inviter_id", nullable = false)
    private User inviter;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "invitee_id", nullable = false, unique = true)
    private User invitee;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "campaign_id", nullable = false)
    private ReferralCampaign campaign;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ReferralRewardStatus status = ReferralRewardStatus.USED;

    /** When the invitee registered/entered the code (row creation time). */
    @Column(nullable = false)
    private Instant usedAt;

    /** When the qualifying booking completed and rewards were granted (null while USED). */
    private Instant qualifiedAt;

    private Long qualifyingBookingId;

    /** Set alongside {@link #qualifiedAt} — they are the same instant under the atomic model. */
    private Instant rewardedAt;

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
