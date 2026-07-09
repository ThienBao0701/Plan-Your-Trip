package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Phase 7.6 — deliberately named with the {@code TripPlan} prefix (not reusing or
 * touching the pre-existing, unrelated legacy {@code Expense} entity tied to the
 * old {@code Trip} module).
 */
@Entity
@Table(name = "trip_plan_budgets",
       indexes = {
           @Index(name = "idx_trip_plan_budgets_trip_plan_id", columnList = "trip_plan_id", unique = true)
       })
@Getter @Setter
public class TripPlanBudget {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "trip_plan_id", unique = true, nullable = false)
    private TripPlan tripPlan;

    @Column(nullable = false)
    private BigDecimal totalBudget;

    @Column(nullable = false)
    private String currency;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
