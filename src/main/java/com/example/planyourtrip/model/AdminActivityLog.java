package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

/**
 * D1a — append-only audit record for an administrative action.
 *
 * <p>Deliberately separate from {@link PartnerActivityLog}. A partner log entry is always scoped to
 * one {@code PartnerProfile} and answers "what happened inside this partner's workspace"; an admin
 * action is global and may target any entity in the system, including entities belonging to no
 * partner at all (customers, gift cards, personalization rules). Reusing the partner table would
 * have required a nullable profile FK and would blur two different questions in one place.
 *
 * <h2>Why the actor is denormalised</h2>
 *
 * {@link PartnerActivityLog} references {@code User} by {@code @ManyToOne}. This entity instead
 * stores {@link #actorUserId} as a plain column plus an {@link #actorEmail} snapshot taken at write
 * time. An audit trail must remain readable and truthful after the actor row changes — an email
 * change, a role change, or a future user deletion must not rewrite or cascade away history. A
 * foreign key would couple immutable history to a mutable row; a snapshot cannot be silently
 * altered by editing the user.
 *
 * <h2>Append-only</h2>
 *
 * There is no {@code @PreUpdate}, no setter-driven mutation path exposed by any API, and
 * {@code AdminActivityLogRepository} deliberately does not extend {@code JpaRepository}, so no
 * delete or bulk-update method exists to call. {@link #createdAt} is {@code updatable = false}.
 * An admin cannot rewrite the record of their own action.
 *
 * <h2>What must never be stored here</h2>
 *
 * Passwords, password hashes, JWTs, signing secrets, API keys, payment or bank credentials, card
 * data, and full copies of customer records. {@link #beforeState} / {@link #afterState} are for
 * short, safe scalar summaries (a status transition, an amount and currency) — never a serialised
 * entity. See {@code AdminActivityLogService} for the enforced policy.
 */
@Entity
@Table(name = "admin_activity_logs",
       indexes = {
           @Index(name = "idx_admin_activity_logs_created_at", columnList = "createdAt"),
           @Index(name = "idx_admin_activity_logs_actor", columnList = "actor_user_id"),
           @Index(name = "idx_admin_activity_logs_action", columnList = "action"),
           @Index(name = "idx_admin_activity_logs_target", columnList = "target_type,target_id")
       })
@Getter @Setter
public class AdminActivityLog {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * The acting administrator's user id, or {@code null} for a system/batch action (see
     * {@link #actorEmail}). Not a foreign key — see the class javadoc.
     */
    @Column(name = "actor_user_id")
    private Long actorUserId;

    /**
     * The actor's email as it was at the moment of the action, or {@code "SYSTEM"} for a scheduled
     * or batch job. A snapshot, never re-resolved on read.
     */
    @Column(name = "actor_email", nullable = false, length = 255)
    private String actorEmail;

    /** Stable machine-readable verb, e.g. {@code PARTNER_APPROVE}, {@code PAYMENT_REFUND}. */
    @Column(nullable = false, length = 80)
    private String action;

    /** Stable machine-readable target class, e.g. {@code PARTNER_PROFILE}, {@code BOOKING}. */
    @Column(name = "target_type", length = 60)
    private String targetType;

    /** Identifier of the affected row within {@link #targetType}. */
    @Column(name = "target_id")
    private Long targetId;

    /** Short human-readable summary. Safe text only — no PII beyond an identifier. */
    @Column(columnDefinition = "TEXT")
    private String description;

    /** Safe scalar snapshot of the relevant state before the change (e.g. {@code "CONFIRMED"}). */
    @Column(name = "before_state", length = 500)
    private String beforeState;

    /** Safe scalar snapshot of the relevant state after the change. */
    @Column(name = "after_state", length = 500)
    private String afterState;

    @Column(updatable = false)
    private Instant createdAt;

    @PrePersist
    void onCreate() { createdAt = Instant.now(); }
}
