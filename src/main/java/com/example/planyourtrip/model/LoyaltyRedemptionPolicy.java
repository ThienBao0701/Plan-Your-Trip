package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Phase 7.20 — Loyalty Points Redemption.
 * Persistent, admin-configurable rule set governing how loyalty points convert
 * to a booking discount. All conversion/limit numbers live here as DB rows —
 * never hardcoded in service logic — mirroring the configurable-definition
 * discipline of {@link MembershipTierDefinition}.
 *
 * <p>Conversion is integer/BigDecimal money only, never floating point:
 * {@code discount = points × valuePerUnit / pointsPerUnit}. With the seeded
 * default ({@code pointsPerUnit=100}, {@code valuePerUnit=1000 VND}) a point is
 * worth 10 VND.
 *
 * <p>"At most one applicable active default policy" is selected at redemption
 * time by {@code LoyaltyRedemptionPolicyRepository#findActiveDefaultAt}
 * (active + effective window contains now, newest effectiveFrom wins). The
 * exact policy and its frozen financial result are snapshotted onto each
 * {@link LoyaltyPointsRedemption}, so historical redemptions stay auditable
 * even after the policy is edited. Optimistic {@link #version} locking guards
 * concurrent admin edits.
 */
@Entity
@Table(name = "loyalty_redemption_policies",
       uniqueConstraints = @UniqueConstraint(name = "uk_loyalty_redemption_policy_code", columnNames = "policy_code"),
       indexes = {
           @Index(name = "idx_loyalty_redemption_policy_active", columnList = "active"),
           @Index(name = "idx_loyalty_redemption_policy_effective_from", columnList = "effective_from")
       })
@Getter @Setter
public class LoyaltyRedemptionPolicy {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "policy_code", nullable = false, length = 60)
    private String policyCode;

    @Column(nullable = false)
    private String displayName;

    /** Points that map to {@link #valuePerUnit} of money. Positive. */
    @Column(name = "points_per_unit", nullable = false)
    private long pointsPerUnit;

    /** Money value of one {@link #pointsPerUnit} block of points. Positive. */
    @Column(name = "value_per_unit", precision = 15, scale = 2, nullable = false)
    private BigDecimal valuePerUnit;

    /** Fewest points that may be redeemed on a single booking. Positive. */
    @Column(name = "minimum_redemption_points", nullable = false)
    private long minimumRedemptionPoints;

    /** Redemptions must be a whole multiple of this. Positive. */
    @Column(name = "redemption_increment_points", nullable = false)
    private long redemptionIncrementPoints;

    /** Cap on the loyalty discount as a percentage of the eligible amount. 0..100. */
    @Column(name = "maximum_discount_percentage", nullable = false)
    private int maximumDiscountPercentage;

    /** The loyalty discount may never take the final payable below this. >= 0. */
    @Column(name = "minimum_final_payable_amount", precision = 15, scale = 2, nullable = false)
    private BigDecimal minimumFinalPayableAmount;

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
