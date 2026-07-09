package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Entity
@Table(name = "trip_plan_reminders",
       indexes = {
           @Index(name = "idx_trip_plan_reminders_trip_plan_id", columnList = "trip_plan_id"),
           @Index(name = "idx_trip_plan_reminders_trip_plan_day_id", columnList = "trip_plan_day_id"),
           @Index(name = "idx_trip_plan_reminders_trip_plan_item_id", columnList = "trip_plan_item_id"),
           @Index(name = "idx_trip_plan_reminders_document_id", columnList = "document_id"),
           @Index(name = "idx_trip_plan_reminders_reminder_at", columnList = "reminderAt")
       })
@Getter @Setter
public class TripPlanReminder {

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

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "document_id")
    private TripPlanDocument document;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TripPlanReminderType reminderType;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String message;

    @Column(nullable = false)
    private Instant reminderAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TripPlanReminderStatus status = TripPlanReminderStatus.PENDING;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    private Instant completedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
