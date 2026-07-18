package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

/**
 * Phase 7.41 — Partner Guest Check-out audit (near-mirror of Phase 7.40's {@link BookingCheckInAudit}).
 *
 * <p>An IMMUTABLE, write-once audit row recording exactly one staff-performed check-out: which partner
 * (profile + acting user) checked the guest out of which booking, by what {@link CheckMethod}, and when.
 * Exactly one row is inserted on the real {@code CHECKED_IN → CHECKED_OUT} transition — the idempotent
 * repeat of an already-{@code CHECKED_OUT} booking writes NO further row, so a booking has at most one
 * check-out audit entry.
 *
 * <p>Mirrors the same immutable conventions as {@link BookingCheckInAudit}: every business column is
 * {@code updatable = false}, there is no {@code @PreUpdate} hook, and the only write path anywhere is
 * the single insert in {@code PartnerCheckOutService}. It ADDITIONALLY carries the {@link CheckMethod}
 * ({@code QR_SCAN} / {@code MANUAL}) derived from the request input shape.
 */
@Entity
@Table(name = "booking_check_out_audits",
       indexes = {
           @Index(name = "idx_booking_check_out_audits_booking_id", columnList = "booking_id")
       })
@Getter @Setter
public class BookingCheckOutAudit {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "booking_id", nullable = false, updatable = false)
    private Booking booking;

    /** The approved partner profile that owns the booking's hotel. */
    @Column(name = "partner_profile_id", nullable = false, updatable = false)
    private Long partnerProfileId;

    /** The authenticated partner/admin user who performed the check-out. */
    @Column(name = "partner_user_id", nullable = false, updatable = false)
    private Long partnerUserId;

    /** Fixed operation discriminator — currently always {@code "CHECK_OUT"}. */
    @Column(name = "operation", nullable = false, updatable = false, length = 40)
    private String operation;

    /** QR_SCAN (voucher payload input) or MANUAL (raw booking code input). */
    @Enumerated(EnumType.STRING)
    @Column(name = "method", nullable = false, updatable = false, length = 20)
    private CheckMethod method;

    @Column(updatable = false)
    private Instant createdAt;

    @PrePersist
    void onCreate() { createdAt = Instant.now(); }
}
