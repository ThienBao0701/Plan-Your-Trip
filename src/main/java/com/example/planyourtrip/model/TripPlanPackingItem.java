package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

/**
 * {@code sortOrder} uniqueness/contiguity within a trip is guaranteed entirely by
 * {@code TripPlanPackingService} (recomputed as a contiguous 0-based sequence on
 * every create/delete/reorder), not by a DB constraint — same rationale as
 * {@link TripPlanItem}'s sortOrder (Phase 7.4).
 */
@Entity
@Table(name = "trip_plan_packing_items",
       indexes = {
           @Index(name = "idx_trip_plan_packing_items_trip_plan_id", columnList = "trip_plan_id")
       })
@Getter @Setter
public class TripPlanPackingItem {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "trip_plan_id", nullable = false)
    private TripPlan tripPlan;

    @Column(nullable = false)
    private String label;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TripPlanPackingCategory category;

    @Column(nullable = false)
    private int quantity = 1;

    @Column(nullable = false)
    private boolean checked = false;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_to_user_id")
    private User assignedToUser;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @Column(nullable = false)
    private int sortOrder;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    private Instant checkedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
