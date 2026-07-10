package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.time.LocalDate;

/**
 * Phase 7.14 — Customer Coupons &amp; Travel Credits Foundation.
 * One user's claimed instance of a {@link CouponDefinition}. The effective
 * expiry is the earlier of {@code couponDefinition.validUntil} and this row's
 * own {@link #expiresAt} (when present); {@code EXPIRED} is computed on read
 * from that effective expiry, never destructively written back — same pattern
 * as {@code TravelWalletService#effectiveStatus} (Phase 7.12).
 *
 * <p>{@link #booking} is a placeholder for Phase 7.15 checkout integration —
 * nothing in this phase links a coupon to a booking or marks one USED.
 */
@Entity
@Table(name = "customer_coupons",
       indexes = {
           @Index(name = "idx_customer_coupons_user_id", columnList = "user_id"),
           @Index(name = "idx_customer_coupons_definition_id", columnList = "coupon_definition_id")
       })
@Getter @Setter
public class CustomerCoupon {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "coupon_definition_id", nullable = false)
    private CouponDefinition couponDefinition;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private CustomerCouponStatus status = CustomerCouponStatus.AVAILABLE;

    @Column(nullable = false)
    private Instant claimedAt;

    private Instant usedAt;

    /** Optional per-claim expiry override; effective expiry = min(this, definition.validUntil). */
    private LocalDate expiresAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "booking_id")
    private Booking booking;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
