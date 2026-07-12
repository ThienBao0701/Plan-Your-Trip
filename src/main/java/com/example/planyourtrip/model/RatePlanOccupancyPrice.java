package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Phase 7.29 — occupancy-specific nightly price for a rate plan.
 *
 * <p>One row per (ratePlan, adults, children) combination. When a matching row exists for
 * the requested occupancy it OVERRIDES the plan's base {@link RatePlan#getPricePerNight()};
 * when none matches the pricing falls back to the base price (documented in
 * {@code RatePlanPricingService}). This is a NEW table — no equivalent existed on the
 * previously minimal {@link RatePlan}.
 */
@Entity
@Table(name = "rate_plan_occupancy_prices",
       uniqueConstraints = {
           @UniqueConstraint(name = "uk_occupancy_price_plan_occupancy",
                             columnNames = {"rate_plan_id", "adults", "children"})
       })
@Getter @Setter
public class RatePlanOccupancyPrice {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "rate_plan_id", nullable = false)
    private RatePlan ratePlan;

    /** Number of adults this price applies to (>= 1). */
    @Column(nullable = false)
    private int adults;

    /** Number of children this price applies to (>= 0). */
    @Column(nullable = false)
    private int children;

    @Column(name = "price_per_night", nullable = false, precision = 15, scale = 2)
    private BigDecimal pricePerNight;

    /** Per-child supplement per night for this occupancy row. Null = none. */
    @Column(name = "child_supplement", precision = 15, scale = 2)
    private BigDecimal childSupplement;

    /** Per-extra-bed supplement per night for this occupancy row. Null = fall back to plan. */
    @Column(name = "extra_bed_supplement", precision = 15, scale = 2)
    private BigDecimal extraBedSupplement;

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
