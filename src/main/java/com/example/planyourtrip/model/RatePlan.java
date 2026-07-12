package com.example.planyourtrip.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

/**
 * Rate plan for a hotel room.
 *
 * <p>Phase 7.29 extends this entity ADDITIVELY: the original columns
 * ({@link #rateName}, {@link #rateType}, {@link #pricePerNight}, {@link #startDate},
 * {@link #endDate}, {@link #active}, timestamps) are unchanged and every new column is
 * nullable / defaulted, so pre-7.29 rows and the existing pricing/availability engines
 * behave exactly as before. {@code rateName} is the plan "name" (reused, NOT duplicated)
 * and {@code rateType}/{@link RatePlanType} is the existing category enum (reused).
 */
@Entity
@Table(name = "rate_plans",
       uniqueConstraints = {
           @UniqueConstraint(name = "uk_rate_plan_room_code", columnNames = {"room_id", "code"})
       })
@Getter @Setter
public class RatePlan {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "room_id", nullable = false)
    private HotelRoom hotelRoom;

    /** The plan "name" — reused as the required display name (Phase 7.29 does NOT add a duplicate). */
    @NotBlank
    @Column(nullable = false)
    private String rateName;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RatePlanType rateType;

    @NotNull
    @DecimalMin("0.0")
    @Column(nullable = false, precision = 15, scale = 2)
    private BigDecimal pricePerNight;

    @NotNull
    @Column(nullable = false)
    private LocalDate startDate;

    @NotNull
    @Column(nullable = false)
    private LocalDate endDate;

    @Column(nullable = false)
    private boolean active = true;

    // ── Phase 7.29 additions (all nullable / defaulted) ───────────────────────

    /** Short code, unique per room (case-insensitive). Optional; null when not supplied. */
    @Column(length = 60)
    private String code;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(name = "meal_plan_type", length = 20)
    private MealPlanType mealPlanType = MealPlanType.ROOM_ONLY;

    @Enumerated(EnumType.STRING)
    @Column(name = "cancellation_policy_type", length = 30)
    private CancellationPolicyType cancellationPolicyType = CancellationPolicyType.FREE_CANCELLATION;

    /** Hours before check-in until which free cancellation applies (FREE_CANCELLATION). */
    @Column(name = "cancellation_deadline_hours")
    private Integer cancellationDeadlineHours;

    /** Penalty percentage (0–100) for PARTIALLY_REFUNDABLE / after-deadline penalties. */
    @Column(name = "cancellation_penalty_percent", precision = 5, scale = 2)
    private BigDecimal cancellationPenaltyPercent;

    @Column(nullable = false)
    private boolean refundable = true;

    // ── Derived-plan relationship ─────────────────────────────────────────────

    @Enumerated(EnumType.STRING)
    @Column(name = "source_type", length = 10, nullable = false)
    private RateSourceType sourceType = RateSourceType.BASE;

    /** Parent plan for a DERIVED rate; must belong to the SAME room. Null for BASE plans. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_rate_plan_id")
    private RatePlan parentRatePlan;

    @Enumerated(EnumType.STRING)
    @Column(name = "adjustment_type", length = 10)
    private RateAdjustmentType adjustmentType;

    /** FIXED_AMOUNT delta or PERCENTAGE (e.g. -10 = 10% cheaper than parent). */
    @Column(name = "adjustment_value", precision = 15, scale = 2)
    private BigDecimal adjustmentValue;

    // ── Ranking & stay restrictions ───────────────────────────────────────────

    @Column(nullable = false)
    private int priority = 0;

    @Column(name = "min_stay_nights")
    private Integer minStayNights;

    @Column(name = "max_stay_nights")
    private Integer maxStayNights;

    @Column(name = "min_advance_booking_days")
    private Integer minAdvanceBookingDays;

    @Column(name = "max_advance_booking_days")
    private Integer maxAdvanceBookingDays;

    @Column(name = "closed_to_arrival", nullable = false)
    private boolean closedToArrival = false;

    @Column(name = "closed_to_departure", nullable = false)
    private boolean closedToDeparture = false;

    // ── Occupancy / child / extra-bed pricing ─────────────────────────────────

    @Column(name = "occupancy_pricing_enabled", nullable = false)
    private boolean occupancyPricingEnabled = false;

    @Column(name = "child_pricing_enabled", nullable = false)
    private boolean childPricingEnabled = false;

    /** Flat supplement per extra bed per night (plan default). Null = no extra-bed charge. */
    @Column(name = "extra_bed_price", precision = 15, scale = 2)
    private BigDecimal extraBedPrice;

    // ── Timestamps & optimistic lock ──────────────────────────────────────────

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
