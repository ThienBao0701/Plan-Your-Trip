package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

/**
 * Phase 7.19 — Membership Tier &amp; Loyalty Qualification.
 * IMMUTABLE audit trail entry for a {@link CustomerMembership} tier change —
 * same depth-of-immutability strategy as {@code LoyaltyPointsTransaction}:
 * every business column is {@code updatable = false}, there is no
 * {@code @PreUpdate} hook, and no service method anywhere ever updates an
 * existing row — {@code CustomerMembershipService} only ever inserts.
 * {@link #previousTier} is null for {@code INITIAL_ENROLLMENT}.
 */
@Entity
@Table(name = "membership_tier_history",
       indexes = @Index(name = "idx_membership_tier_history_membership_id", columnList = "membership_id"))
@Getter @Setter
public class MembershipTierHistory {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "membership_id", nullable = false, updatable = false)
    private CustomerMembership membership;

    @Enumerated(EnumType.STRING)
    @Column(updatable = false, length = 20)
    private MembershipTier previousTier;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, updatable = false, length = 20)
    private MembershipTier newTier;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, updatable = false, length = 30)
    private MembershipTierChangeType changeType;

    @Column(nullable = false, updatable = false)
    private String reason;

    @Column(nullable = false, updatable = false)
    private Instant effectiveAt;

    @Column(updatable = false)
    private Instant expiresAt;

    @Enumerated(EnumType.STRING)
    @Column(updatable = false, length = 20)
    private MembershipReferenceType referenceType;

    @Column(updatable = false)
    private Long referenceId;

    @Column(updatable = false)
    private Instant createdAt;

    @PrePersist
    void onCreate() { createdAt = Instant.now(); }
}
