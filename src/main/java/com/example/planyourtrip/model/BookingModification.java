package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

/**
 * Phase 7.36 — Booking Modification Audit &amp; Notification.
 *
 * <p>An IMMUTABLE audit row recording exactly what changed on a single customer modification of a
 * PENDING booking (see {@code BookingService.modify}). One row is inserted per successful
 * modification, so repeated modifications accumulate an ordered history — a bare
 * {@code lastModifiedAt} timestamp on {@link Booking} would lose both the per-modification detail
 * and the history. This is a TRACKING/AUDIT layer only: it performs NO pricing/inventory/payment
 * math — the price fields are the booking's {@code finalPrice} before/after as already computed by
 * the untouched {@code modify()} pipeline.
 *
 * <p>Immutability is enforced in depth exactly like {@code GiftCardTransaction} /
 * {@code LoyaltyPointsTransaction} / {@code InventoryReservation}'s write-once columns: every
 * business column is {@code updatable = false}, there is no {@code @PreUpdate} hook, and the only
 * write path anywhere is the single insert in {@code modify()} — rows are never mutated after
 * creation.
 */
@Entity
@Table(name = "booking_modifications",
       indexes = {
           @Index(name = "idx_booking_modifications_booking_id", columnList = "booking_id")
       })
@Getter @Setter
public class BookingModification {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "booking_id", nullable = false, updatable = false)
    private Booking booking;

    @Column(name = "old_check_in_date", nullable = false, updatable = false)
    private LocalDate oldCheckInDate;

    @Column(name = "new_check_in_date", nullable = false, updatable = false)
    private LocalDate newCheckInDate;

    @Column(name = "old_check_out_date", nullable = false, updatable = false)
    private LocalDate oldCheckOutDate;

    @Column(name = "new_check_out_date", nullable = false, updatable = false)
    private LocalDate newCheckOutDate;

    @Column(name = "old_adults", nullable = false, updatable = false)
    private int oldAdults;

    @Column(name = "new_adults", nullable = false, updatable = false)
    private int newAdults;

    @Column(name = "old_children", nullable = false, updatable = false)
    private int oldChildren;

    @Column(name = "new_children", nullable = false, updatable = false)
    private int newChildren;

    /** Nullable — from the booking's {@code selectedRatePlanId} snapshot (null when no plan resolved). */
    @Column(name = "old_rate_plan_id", updatable = false)
    private Long oldRatePlanId;

    @Column(name = "new_rate_plan_id", updatable = false)
    private Long newRatePlanId;

    @Column(name = "old_rate_plan_name", updatable = false)
    private String oldRatePlanName;

    @Column(name = "new_rate_plan_name", updatable = false)
    private String newRatePlanName;

    /** The booking's {@code finalPrice} BEFORE this modification. */
    @Column(name = "old_total_price", nullable = false, updatable = false, precision = 15, scale = 2)
    private BigDecimal oldTotalPrice;

    /** The booking's {@code finalPrice} AFTER this modification. */
    @Column(name = "new_total_price", nullable = false, updatable = false, precision = 15, scale = 2)
    private BigDecimal newTotalPrice;

    /**
     * {@code newTotalPrice - oldTotalPrice}, signed: positive = the customer would owe more,
     * negative = less. NO actual charge/refund happens for a PENDING modification — this is
     * an informational delta only.
     */
    @Column(name = "price_difference", nullable = false, updatable = false, precision = 15, scale = 2)
    private BigDecimal priceDifference;

    @Column(updatable = false)
    private Instant createdAt;

    @PrePersist
    void onCreate() { createdAt = Instant.now(); }
}
