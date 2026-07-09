package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

/**
 * Freeform notes and journal entries for a trip. {@code noteType = JOURNAL} is
 * just a value of this same entity — journal entries are not a separate table,
 * per the Phase 7.8 spec ("Journal entries are still notes; no separate entity").
 */
@Entity
@Table(name = "trip_plan_notes",
       indexes = {
           @Index(name = "idx_trip_plan_notes_trip_plan_id", columnList = "trip_plan_id"),
           @Index(name = "idx_trip_plan_notes_trip_plan_day_id", columnList = "trip_plan_day_id"),
           @Index(name = "idx_trip_plan_notes_trip_plan_item_id", columnList = "trip_plan_item_id")
       })
@Getter @Setter
public class TripPlanNote {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "trip_plan_id", nullable = false)
    private TripPlan tripPlan;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trip_plan_day_id")
    private TripPlanDay tripDay;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trip_plan_item_id")
    private TripPlanItem tripItem;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "author_user_id", nullable = false)
    private User authorUser;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TripPlanNoteType noteType;

    private String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    @Enumerated(EnumType.STRING)
    private TripPlanMood mood;

    private String photoUrl;

    @Column(nullable = false)
    private boolean pinned = false;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
