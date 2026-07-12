package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

/**
 * Phase 7.26 — IMMUTABLE audit row for a {@link PaymentSession} lifecycle transition.
 * Immutability is enforced in depth exactly like {@code GiftCardTransaction}: every
 * business column is {@code updatable = false}, there is no {@code @PreUpdate} hook and
 * no update path anywhere — the service only ever inserts rows.
 *
 * <p>{@link #idempotencyKey} is unique where non-null (DB backstop) and pre-checked by
 * the service, so a duplicate provider callback for the same session/event is a safe
 * no-op that never re-fires a notification — the same deterministic-idempotency-key
 * discipline used by {@code GiftCardTransaction}/{@code LoyaltyPointsTransaction}/
 * {@code TravelCreditTransaction}, applied here to callback processing.
 */
@Entity
@Table(name = "payment_session_events",
       uniqueConstraints = @UniqueConstraint(
           name = "uk_payment_session_event_idempotency_key", columnNames = "idempotency_key"),
       indexes = @Index(name = "idx_payment_session_event_session_id", columnList = "payment_session_id"))
@Getter @Setter
public class PaymentSessionEvent {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "payment_session_id", nullable = false, updatable = false)
    private PaymentSession paymentSession;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, updatable = false, length = 20)
    private PaymentSessionEventType eventType;

    @Enumerated(EnumType.STRING)
    @Column(updatable = false, length = 20)
    private PaymentSessionStatus fromStatus;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, updatable = false, length = 20)
    private PaymentSessionStatus toStatus;

    @Column(updatable = false)
    private String detail;

    @Column(name = "idempotency_key", unique = true, updatable = false, length = 128)
    private String idempotencyKey;

    @Column(updatable = false)
    private Instant createdAt;

    @PrePersist
    void onCreate() { createdAt = Instant.now(); }
}
