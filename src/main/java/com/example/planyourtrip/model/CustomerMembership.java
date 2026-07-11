package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

/**
 * Phase 7.19 — Membership Tier &amp; Loyalty Qualification.
 * One membership record per user (unique constraint on {@code user_id}),
 * created explicitly via {@code CustomerMembershipService#enroll} — never
 * implicitly by an eligibility/read check, mirroring the "no implicit
 * creation" discipline already established for coupon-eligibility checks in
 * Phase 7.17/7.18.
 *
 * <p>{@link #currentTier} is the STORED tier — it only ever changes via an
 * explicit mutation (enrollment, automatic upgrade, manual assignment, or an
 * explicit admin reevaluation). It is deliberately NOT auto-corrected on
 * every read when {@link #validUntil} has passed — expiry is a read-time
 * projection only (see {@code CustomerMembershipService#effectiveTier}),
 * consistent with the documented downgrade grace-period rule: ordinary point
 * deduction or the mere passage of time never silently downgrades the stored
 * row, only an explicit admin/manual recalculation does.
 *
 * <p>Concurrency: optimistic locking via {@link #version}, chosen over the
 * pessimistic {@code SELECT ... FOR UPDATE} strategy used by
 * {@code LoyaltyAccount}/{@code TravelCreditAccount} — see the class javadoc
 * on {@code CustomerMembershipService} for the rationale (infrequent
 * concurrent writes to a single user's membership row, read-heavy workload;
 * a version conflict surfaces as 409 rather than blocking).
 */
@Entity
@Table(name = "customer_memberships",
       uniqueConstraints = @UniqueConstraint(name = "uk_customer_membership_user", columnNames = "user_id"))
@Getter @Setter
public class CustomerMembership {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    /**
     * Nullable — an admin may manually assign a tier before the user has ever
     * touched loyalty points at all (see {@code CustomerMembershipService#adminAssign}).
     * Self-service enrollment always sets this (requires an active LoyaltyAccount).
     */
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "loyalty_account_id")
    private LoyaltyAccount loyaltyAccount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private MembershipTier currentTier;

    @Column(nullable = false)
    private Instant qualifiedAt;

    @Column(nullable = false)
    private Instant validFrom;

    /** Nullable — see class javadoc: absence means "no expiry configured" (not used by automatic paths). */
    private Instant validUntil;

    @Column(nullable = false)
    private boolean manuallyAssigned = false;

    @Column(nullable = false)
    private boolean active = true;

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
