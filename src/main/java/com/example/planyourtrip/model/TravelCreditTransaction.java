package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

/**
 * Phase 7.14 — Customer Coupons &amp; Travel Credits Foundation.
 * IMMUTABLE ledger entry for a {@link TravelCreditAccount} balance change.
 * Immutability is enforced in depth:
 * <ul>
 *   <li>every business column is {@code updatable = false}, so Hibernate never
 *       emits an UPDATE for them even if a setter were called post-persist;</li>
 *   <li>there is no {@code @PreUpdate} hook and no update path anywhere —
 *       {@code TravelCreditService} only ever inserts rows, and no controller
 *       exposes a transaction mutation endpoint;</li>
 *   <li>{@link #amount} is always positive — direction comes from
 *       {@link #transactionType}, never from a sign.</li>
 * </ul>
 * {@link #idempotencyKey} is unique where non-null (DB backstop) and pre-checked
 * by the service, mirroring Phase 7.13's {@code TripPlanReminder#sourceKey} pattern.
 */
@Entity
@Table(name = "travel_credit_transactions",
       uniqueConstraints = @UniqueConstraint(name = "uk_travel_credit_tx_idempotency_key", columnNames = "idempotency_key"),
       indexes = @Index(name = "idx_travel_credit_tx_account_id", columnList = "account_id"))
@Getter @Setter
public class TravelCreditTransaction {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "account_id", nullable = false, updatable = false)
    private TravelCreditAccount account;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, updatable = false, length = 20)
    private TravelCreditTransactionType transactionType;

    /** Always &gt; 0 — see class javadoc. */
    @Column(nullable = false, updatable = false, precision = 15, scale = 2)
    private BigDecimal amount;

    @Column(nullable = false, updatable = false, precision = 15, scale = 2)
    private BigDecimal balanceBefore;

    @Column(nullable = false, updatable = false, precision = 15, scale = 2)
    private BigDecimal balanceAfter;

    @Column(nullable = false, updatable = false)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(updatable = false, length = 20)
    private TravelCreditReferenceType referenceType;

    @Column(updatable = false)
    private Long referenceId;

    @Column(name = "idempotency_key", unique = true, updatable = false)
    private String idempotencyKey;

    /** Informational only in this phase — automated expiration sweeps are future work. */
    @Column(updatable = false)
    private LocalDate expiresAt;

    @Column(updatable = false)
    private Instant createdAt;

    @PrePersist
    void onCreate() { createdAt = Instant.now(); }
}
