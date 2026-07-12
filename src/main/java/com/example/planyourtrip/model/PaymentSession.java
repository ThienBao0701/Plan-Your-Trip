package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Phase 7.26 — Payment Gateway Foundation.
 *
 * <p>A PRE-SETTLEMENT gateway checkout session — the future provider-abstraction layer.
 * This is a NEW, SEPARATE table that is NOT wired into the existing {@link Payment}
 * settlement flow in this phase: capturing a session does NOT create/mutate/settle a
 * {@code Payment} row and fires none of the existing booking-payment hooks (loyalty,
 * gift card, notifications tied to {@code Payment}). That wiring is explicit future work
 * (Phase 7.27), mirroring how Gift Cards were pure foundation in 7.24 before checkout
 * wiring landed in 7.25.
 *
 * <p>{@link #sessionId} is the public, non-sequential identifier (never the internal
 * {@link #id}). {@link #callbackToken} is the secret a provider must present on its
 * webhook callback to mutate this session — treated like a credential (see
 * {@code PaymentGatewayService#processCallback}). Every mutation runs under a pessimistic
 * write lock ({@code PaymentSessionRepository#findBySessionIdForUpdate}), the same
 * discipline as {@code GiftCard}.
 */
@Entity
@Table(name = "payment_sessions",
       uniqueConstraints = {
           @UniqueConstraint(name = "uk_payment_session_session_id", columnNames = "session_id")
       },
       indexes = {
           @Index(name = "idx_payment_session_status", columnList = "status"),
           @Index(name = "idx_payment_session_booking_id", columnList = "booking_id"),
           @Index(name = "idx_payment_session_expires_at", columnList = "expires_at")
       })
@Getter @Setter
public class PaymentSession {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Public, non-sequential session identifier — immutable after creation. */
    @Column(name = "session_id", nullable = false, updatable = false, length = 64)
    private String sessionId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, updatable = false, length = 20)
    private PaymentProvider provider;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "booking_id", nullable = false, updatable = false)
    private Booking booking;

    @Column(nullable = false, updatable = false, precision = 15, scale = 2)
    private BigDecimal amount;

    @Column(nullable = false, updatable = false, length = 10)
    private String currency;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PaymentSessionStatus status = PaymentSessionStatus.NEW;

    private Instant expiresAt;

    /** Provider-side reference (e.g. an intent/transaction id) recorded once known. */
    @Column(name = "provider_reference", length = 128)
    private String providerReference;

    /** Secret required on the provider callback to authorize a state transition. */
    @Column(name = "callback_token", nullable = false, updatable = false, length = 64)
    private String callbackToken;

    @Column(name = "checkout_url", length = 1000)
    private String checkoutUrl;

    /**
     * Phase 7.27 — ADDITIVE bridge link to the real {@link Payment} settlement row. Null
     * until the session reaches a terminal state and {@code PaymentSettlementBridge} routes
     * it through the EXISTING {@code PaymentService} settlement methods (never populated by
     * {@code PaymentService} itself — the dependency direction stays one-way: the gateway
     * layer knows about {@code Payment}, {@code PaymentService} stays session-agnostic).
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "payment_id")
    private Payment payment;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @Version
    private Long version;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
