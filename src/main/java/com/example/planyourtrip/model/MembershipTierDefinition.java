package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Phase 7.19 — Membership Tier &amp; Loyalty Qualification.
 * Configurable qualification thresholds and reward multiplier for one
 * {@link MembershipTier}. Exactly one row exists per tier (enforced by the
 * unique constraint on {@code tier}) — "one active definition per tier" from
 * the spec is satisfied structurally: there is only ever one definition row
 * per tier at all (active or not), so {@link #active} simply gates whether
 * that tier currently participates in qualification
 * ({@code CustomerMembershipService#computeQualifiedTier}) and multiplier
 * resolution ({@code MembershipTierService#resolveMultiplier} falls back to
 * 1.00 when the tier's row is inactive or missing).
 */
@Entity
@Table(name = "membership_tier_definitions",
       uniqueConstraints = @UniqueConstraint(name = "uk_membership_tier_definition_tier", columnNames = "tier"))
@Getter @Setter
public class MembershipTierDefinition {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20, updatable = false)
    private MembershipTier tier;

    @Column(nullable = false)
    private String displayName;

    @Column(length = 1000)
    private String description;

    @Column(nullable = false)
    private long minimumLifetimePoints = 0L;

    @Column(nullable = false)
    private int minimumCompletedBookings = 0;

    /** Applied to booking-completion loyalty-point awards — see {@code LoyaltyService#awardBookingPoints}. */
    @Column(nullable = false, precision = 5, scale = 2)
    private BigDecimal pointsMultiplier = BigDecimal.ONE;

    /**
     * Phase 7.21 (additive) — applied to the discount amount computed by
     * {@code LoyaltyRedemptionService} when the redeeming customer's current
     * effective tier is this one. Plain Java field default (1.00), the same
     * in-place-column-addition pattern already used by
     * {@code LoyaltyAccount#status} (Phase 7.20) — every pre-7.21 row simply
     * gets the default, no separate migration needed. Falls back to 1.00 (no
     * boost) via {@code MembershipTierService#resolveRedemptionMultiplier}
     * when the tier's definition row is missing or inactive, exactly
     * mirroring {@link #pointsMultiplier}'s fallback.
     */
    @Column(nullable = false, precision = 5, scale = 2)
    private BigDecimal redemptionDiscountMultiplier = new BigDecimal("1.00");

    @Column(nullable = false)
    private boolean active = true;

    @Column(nullable = false)
    private int sortOrder = 0;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
