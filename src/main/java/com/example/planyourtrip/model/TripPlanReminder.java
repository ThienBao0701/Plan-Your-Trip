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

    /**
     * Phase 7.13 — relaxed from {@code optional = false}/{@code nullable = false}
     * to support wallet-expiry reminders generated for a {@code TravelWalletItem}
     * that has no linked {@code TripPlan} (a standalone/metadata-only wallet
     * item). Every reminder created by {@code TripPlanReminderService} still
     * always sets this (it is only ever reached via a {@code /trips/{tripId}/...}
     * route), so existing trip-scoped reminder behavior is unaffected. Only
     * {@code WalletExpiryReminderService} may create a row with this null, and
     * only when the source wallet item itself has no {@code tripPlan}; such rows
     * are still owned/delivered via {@link #user} (see
     * {@code TripReminderDeliveryService}, which already scopes "due reminders"
     * by {@code userId}, not {@code tripPlanId}).
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trip_plan_id")
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

    // ── Delivery tracking (Phase 7.11 — Reminder Delivery Foundation) ─────────

    /** Set once a Notification has been successfully created for this reminder; null until then. */
    private Instant deliveredAt;

    @Column(nullable = false)
    private int deliveryAttempts = 0;

    @Column(columnDefinition = "TEXT")
    private String lastDeliveryError;

    // ── Idempotent-source tracking (Phase 7.13 — Wallet Expiry Alerts) ────────

    /**
     * Nullable discriminator for reminders created by an automated generator
     * rather than a direct user CRUD call (e.g. {@code "WALLET_EXPIRY"} for
     * {@code WalletExpiryReminderService}). Null for ordinary user-created
     * reminders (Phase 7.10 CRUD path).
     */
    private String sourceType;

    /** Nullable id of the source row (e.g. the {@code TravelWalletItem} id) when {@link #sourceType} is set. */
    private Long sourceId;

    /**
     * Nullable, unique-where-non-null deterministic idempotency key, e.g.
     * {@code "WALLET_EXPIRY:" + walletItemId + ":" + windowDays}. Repeated
     * generation runs must check for an existing row with this key before
     * inserting — see {@code WalletExpiryReminderService#generateForItem}.
     * Enforced at the DB level via {@code @Column(unique = true)} below (H2/
     * PostgreSQL both allow multiple NULLs alongside a unique constraint, so
     * ordinary non-source reminders are unaffected).
     */
    @Column(unique = true)
    private String sourceKey;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
