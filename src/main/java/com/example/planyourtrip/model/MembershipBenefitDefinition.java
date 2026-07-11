package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Phase 7.19 — Membership Tier &amp; Loyalty Qualification.
 * Descriptive METADATA row for a benefit attached to a {@link MembershipTier}
 * — this phase never operationally executes any benefit (no real room
 * upgrade, breakfast, priority-support routing, or coupon issuance); it only
 * stores what a tier is entitled to, for display purposes
 * ({@code CustomerMembershipService#getMyBenefits}). Multiple benefit rows
 * may exist per tier (unlike {@link MembershipTierDefinition}, which is
 * one-per-tier).
 */
@Entity
@Table(name = "membership_benefit_definitions",
       indexes = @Index(name = "idx_membership_benefit_tier", columnList = "tier"))
@Getter @Setter
public class MembershipBenefitDefinition {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private MembershipTier tier;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private MembershipBenefitType benefitType;

    @Column(nullable = false)
    private String name;

    @Column(length = 1000)
    private String description;

    /** Optional numeric metadata (e.g. a discount percentage or a duration in hours). Never negative when present. */
    @Column(precision = 12, scale = 2)
    private BigDecimal numericValue;

    /** Optional free-text metadata (e.g. terms, a coupon code prefix). */
    @Column(length = 1000)
    private String textValue;

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
