package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.time.LocalDate;

/**
 * Phase 7.4 itinerary planner root — deliberately named {@code TripPlan} (not
 * {@code Trip}) to avoid colliding with the pre-existing, unrelated {@code Trip}
 * entity/{@code TripController}/{@code TripService} (a simpler earlier
 * title+destination+budget module mapped at {@code /api/trips}, untouched here).
 */
@Entity
@Table(name = "trip_plans",
       indexes = {
           @Index(name = "idx_trip_plans_user_id", columnList = "user_id")
       })
@Getter @Setter
public class TripPlan {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    private String destination;

    private String coverImage;

    @Column(nullable = false)
    private LocalDate startDate;

    @Column(nullable = false)
    private LocalDate endDate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TripPlanStatus status = TripPlanStatus.PLANNING;

    @Column(nullable = false)
    private boolean isPublic = false;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
