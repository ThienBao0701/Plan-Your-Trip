package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Entity
@Table(name = "partner_activity_logs",
       indexes = {
           @Index(name = "idx_partner_activity_logs_profile_id", columnList = "partner_profile_id"),
           @Index(name = "idx_partner_activity_logs_created_at", columnList = "createdAt")
       })
@Getter @Setter
public class PartnerActivityLog {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "partner_profile_id", nullable = false)
    private PartnerProfile partnerProfile;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "actor_user_id", nullable = false)
    private User actorUser;

    @Column(nullable = false)
    private String action;

    private String entityType;

    private Long entityId;

    @Column(columnDefinition = "TEXT")
    private String description;

    /**
     * RBAC V1.1 §22.1 AU-2 / §28 M-4 — the actor's email as it was when the row was written. A snapshot,
     * never re-resolved on read, so the trail stays truthful if the account's email changes later.
     */
    @Column(name = "actor_email", nullable = false, length = 255)
    private String actorEmail;

    /** Safe scalar summary of the relevant state before the change, e.g. {@code MANAGER@COMPANY:456}. */
    @Column(name = "before_state", length = 500)
    private String beforeState;

    /** Safe scalar summary of the relevant state after the change. */
    @Column(name = "after_state", length = 500)
    private String afterState;

    /** Why the change was made, when the actor gave a reason; V6 marks backfilled actor emails here. */
    @Column(length = 500)
    private String reason;

    @Column(updatable = false)
    private Instant createdAt;

    @PrePersist
    void onCreate() { createdAt = Instant.now(); }
}
