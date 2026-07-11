package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Phase 7.20 — Loyalty Points Redemption.
 * The lifecycle record of one loyalty-points redemption against one booking.
 * It is the audit anchor tying together the debited points, the frozen
 * financial result, the governing policy, and the lifecycle status (see
 * {@link LoyaltyRedemptionStatus}).
 *
 * <p>Design notes:
 * <ul>
 *   <li>{@link #redemptionReference} is immutable and globally unique (public
 *       handle); {@link #idempotencyKey} is unique and prevents duplicate
 *       reserve operations (application pre-check + DB backstop).</li>
 *   <li>All relationships are LAZY {@code @ManyToOne} with NO cascade — a
 *       redemption is a financial record and must never be deleted as a side
 *       effect of removing a booking/user/account/policy.</li>
 *   <li>{@link #pointsRedeemed} + {@link #discountAmount} are the FROZEN result
 *       captured at reserve time; together with {@link #eligibleAmount} and the
 *       policy snapshot fields they keep the row auditable even if the policy is
 *       later edited.</li>
 *   <li>"At most one non-terminal redemption per booking" is enforced in the
 *       service (a booking may accumulate many terminal history rows but only
 *       one RESERVED/APPLIED at a time).</li>
 *   <li>Optimistic {@link #version} locking guards concurrent status changes
 *       (release/refund/expire callbacks).</li>
 * </ul>
 */
@Entity
@Table(name = "loyalty_points_redemptions",
       uniqueConstraints = {
           @UniqueConstraint(name = "uk_loyalty_redemption_reference", columnNames = "redemption_reference"),
           @UniqueConstraint(name = "uk_loyalty_redemption_idempotency_key", columnNames = "idempotency_key")
       },
       indexes = {
           @Index(name = "idx_loyalty_redemption_booking", columnList = "booking_id"),
           @Index(name = "idx_loyalty_redemption_customer", columnList = "customer_id"),
           @Index(name = "idx_loyalty_redemption_account", columnList = "loyalty_account_id"),
           @Index(name = "idx_loyalty_redemption_status", columnList = "status"),
           @Index(name = "idx_loyalty_redemption_expires_at", columnList = "expires_at")
       })
@Getter @Setter
public class LoyaltyPointsRedemption {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "redemption_reference", nullable = false, updatable = false, length = 40)
    private String redemptionReference;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "customer_id", nullable = false, updatable = false)
    private User customer;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "booking_id", nullable = false, updatable = false)
    private Booking booking;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "loyalty_account_id", nullable = false, updatable = false)
    private LoyaltyAccount loyaltyAccount;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "policy_id", nullable = false, updatable = false)
    private LoyaltyRedemptionPolicy policy;

    @Column(name = "points_redeemed", nullable = false, updatable = false)
    private long pointsRedeemed;

    @Column(name = "discount_amount", precision = 15, scale = 2, nullable = false, updatable = false)
    private BigDecimal discountAmount;

    /** Snapshot of the eligible base (after promo/coupon, before travel-credit) the 20% cap was computed on. */
    @Column(name = "eligible_amount", precision = 15, scale = 2, nullable = false, updatable = false)
    private BigDecimal eligibleAmount;

    /** Frozen policy conversion snapshot — auditable even if the policy row later changes. */
    @Column(name = "points_per_unit_snapshot", nullable = false, updatable = false)
    private long pointsPerUnitSnapshot;

    @Column(name = "value_per_unit_snapshot", precision = 15, scale = 2, nullable = false, updatable = false)
    private BigDecimal valuePerUnitSnapshot;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private LoyaltyRedemptionStatus status = LoyaltyRedemptionStatus.RESERVED;

    private Instant reservedAt;
    private Instant appliedAt;
    private Instant releasedAt;
    private Instant refundedAt;
    private Instant cancelledAt;

    @Column(name = "expires_at")
    private Instant expiresAt;

    @Column(length = 500)
    private String reason;

    @Column(name = "idempotency_key", updatable = false)
    private String idempotencyKey;

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
