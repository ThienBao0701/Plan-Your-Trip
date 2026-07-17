package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

/**
 * Phase 7.40 — Partner Guest Check-in audit.
 *
 * <p>An IMMUTABLE, write-once audit row recording exactly one staff-performed check-in: which partner
 * (profile + acting user) admitted the guest against which booking, and when. Exactly one row is
 * inserted on the real {@code CONFIRMED/CHECK_IN_READY → CHECKED_IN} transition — the idempotent
 * repeat of an already-{@code CHECKED_IN} booking writes NO further row, so a booking has at most one
 * check-in audit entry.
 *
 * <p>This deliberately mirrors the {@link BookingModification} immutable-audit precedent (Phase 7.36):
 * every business column is {@code updatable = false}, there is no {@code @PreUpdate} hook, and the only
 * write path anywhere is the single insert in {@code PartnerCheckInService}. It is intentionally NOT
 * folded into {@code BookingModification} (which is modification-specific) nor the generic mutable
 * {@code PartnerActivityLog} — a dedicated immutable row gives a clean, tamper-evident,
 * count-by-booking check-in record.
 */
@Entity
@Table(name = "booking_check_in_audits",
       indexes = {
           @Index(name = "idx_booking_check_in_audits_booking_id", columnList = "booking_id")
       })
@Getter @Setter
public class BookingCheckInAudit {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "booking_id", nullable = false, updatable = false)
    private Booking booking;

    /** The approved partner profile that owns the booking's hotel. */
    @Column(name = "partner_profile_id", nullable = false, updatable = false)
    private Long partnerProfileId;

    /** The authenticated partner/admin user who performed the check-in. */
    @Column(name = "partner_user_id", nullable = false, updatable = false)
    private Long partnerUserId;

    /** Fixed operation discriminator — currently always {@code "CHECK_IN"}. */
    @Column(name = "operation", nullable = false, updatable = false, length = 40)
    private String operation;

    @Column(updatable = false)
    private Instant createdAt;

    @PrePersist
    void onCreate() { createdAt = Instant.now(); }
}
