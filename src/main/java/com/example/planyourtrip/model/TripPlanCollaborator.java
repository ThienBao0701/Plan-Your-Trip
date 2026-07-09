package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

/**
 * Invitations are immediately active — there is no separate "accept" API in
 * Phase 7.5, so {@code acceptedAt} is stamped at creation time alongside
 * {@code invitedAt}. {@code active} is the on/off switch used to remove access
 * without losing the historical row.
 */
@Entity
@Table(name = "trip_plan_collaborators",
       indexes = {
           @Index(name = "idx_trip_plan_collaborators_trip_plan_id", columnList = "trip_plan_id"),
           @Index(name = "idx_trip_plan_collaborators_user_id", columnList = "user_id")
       },
       uniqueConstraints = {
           @UniqueConstraint(name = "uk_trip_plan_collaborator_trip_user", columnNames = {"trip_plan_id", "user_id"})
       })
@Getter @Setter
public class TripPlanCollaborator {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "trip_plan_id", nullable = false)
    private TripPlan tripPlan;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TripCollaboratorRole role;

    @Column(nullable = false)
    private boolean active = true;

    private Instant invitedAt;

    private Instant acceptedAt;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() {
        createdAt = updatedAt = Instant.now();
        if (invitedAt == null) invitedAt = createdAt;
        if (acceptedAt == null) acceptedAt = createdAt;
    }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
