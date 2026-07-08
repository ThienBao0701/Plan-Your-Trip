package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalTime;

/**
 * {@code sortOrder} uniqueness within a day is guaranteed entirely by
 * {@code TripPlannerService} (always recomputed as a contiguous 0-based sequence on
 * every add/move/reorder/delete) rather than by a DB unique constraint — a hard
 * constraint would reject the intermediate state of a multi-row reorder swap
 * (e.g. two rows briefly sharing a value mid-transaction) unless deferred, which
 * plain JPA/H2 unique constraints are not.
 */
@Entity
@Table(name = "trip_plan_items",
       indexes = {
           @Index(name = "idx_trip_plan_items_trip_plan_day_id", columnList = "trip_plan_day_id")
       })
@Getter @Setter
public class TripPlanItem {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "trip_plan_day_id", nullable = false)
    private TripPlanDay tripPlanDay;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id")
    private Place place;

    private String customTitle;

    @Column(columnDefinition = "TEXT")
    private String customDescription;

    private LocalTime startTime;

    private LocalTime endTime;

    @Column(nullable = false)
    private int sortOrder;

    private BigDecimal estimatedCost;

    private Double latitude;

    private Double longitude;

    private String transportationNote;

    @Column(updatable = false)
    private Instant createdAt;

    @PrePersist
    void onCreate() { createdAt = Instant.now(); }
}
