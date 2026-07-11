package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

/**
 * Phase 7.18 — Loyalty Points Foundation.
 * One loyalty account per user (enforced by the unique constraint on
 * {@code user_id}), created lazily on first access by {@code LoyaltyService} —
 * structural template is {@code TravelCreditAccount}. Points are not money:
 * no withdrawal, no transfer, no cash-out — this phase does not implement
 * redemption at all.
 *
 * <p>Two deliberately separate counters:
 * <ul>
 *   <li>{@link #lifetimePointsEarned} — a MONOTONIC counter. It only ever
 *       increases, via EARN/GRANT-type positive transactions
 *       ({@code LoyaltyService#credit}), and is never decremented by anything —
 *       not even a future redemption. This is the field Phase 7.19's tier
 *       qualification depends on, so the monotonic guarantee must never be
 *       broken.</li>
 *   <li>{@link #currentBalance} — the actual spendable point balance. In this
 *       phase it only ever moves in lockstep with {@code lifetimePointsEarned}
 *       (every earn/grant increases both by the same amount), because no
 *       redemption/decrease path exists yet. The fields are kept structurally
 *       independent so a future redemption phase can decrement
 *       {@code currentBalance} without ever touching
 *       {@code lifetimePointsEarned}.</li>
 * </ul>
 */
@Entity
@Table(name = "loyalty_accounts",
       uniqueConstraints = @UniqueConstraint(name = "uk_loyalty_account_user", columnNames = "user_id"))
@Getter @Setter
public class LoyaltyAccount {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    /** Spendable balance — see class javadoc. Never negative (Phase 7.20 redemption debit guards this). */
    @Column(name = "current_balance", nullable = false)
    private long currentBalance = 0L;

    /**
     * Phase 7.20 — account status gate for redemption. Defaults to ACTIVE, so
     * every pre-7.20 account and every account created by the earn/grant paths
     * remains fully usable (earning is never gated by status). Only redemption
     * ({@code LoyaltyRedemptionService}) checks this: SUSPENDED/CLOSED accounts
     * cannot reserve points.
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private LoyaltyAccountStatus status = LoyaltyAccountStatus.ACTIVE;

    /** MONOTONIC — only ever increases. See class javadoc. */
    @Column(name = "lifetime_points_earned", nullable = false)
    private long lifetimePointsEarned = 0L;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
