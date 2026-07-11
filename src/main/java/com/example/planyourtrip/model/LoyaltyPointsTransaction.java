package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

/**
 * Phase 7.18 — Loyalty Points Foundation.
 * IMMUTABLE ledger entry for a {@link LoyaltyAccount} balance change — same
 * depth-of-immutability strategy as {@code TravelCreditTransaction}:
 * <ul>
 *   <li>every business column is {@code updatable = false};</li>
 *   <li>there is no {@code @PreUpdate} hook and no update path anywhere —
 *       {@code LoyaltyService} only ever inserts rows;</li>
 *   <li>{@link #points} is always positive — direction comes from
 *       {@link #transactionType}, never from a sign (in this phase every
 *       wired transaction type is an increase — see {@link LoyaltyTransactionType}).</li>
 * </ul>
 * {@link #balanceBefore}/{@link #balanceAfter} refer to {@code LoyaltyAccount#currentBalance},
 * not {@code lifetimePointsEarned}. {@link #idempotencyKey} is unique where
 * non-null (DB backstop) and pre-checked by the service.
 */
@Entity
@Table(name = "loyalty_points_transactions",
       uniqueConstraints = @UniqueConstraint(name = "uk_loyalty_tx_idempotency_key", columnNames = "idempotency_key"),
       indexes = @Index(name = "idx_loyalty_tx_account_id", columnList = "account_id"))
@Getter @Setter
public class LoyaltyPointsTransaction {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "account_id", nullable = false, updatable = false)
    private LoyaltyAccount account;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, updatable = false, length = 20)
    private LoyaltyTransactionType transactionType;

    /** Always &gt; 0 — see class javadoc. */
    @Column(nullable = false, updatable = false)
    private long points;

    @Column(name = "balance_before", nullable = false, updatable = false)
    private long balanceBefore;

    @Column(name = "balance_after", nullable = false, updatable = false)
    private long balanceAfter;

    @Column(nullable = false, updatable = false)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(updatable = false, length = 20)
    private LoyaltyReferenceType referenceType;

    @Column(updatable = false)
    private Long referenceId;

    @Column(name = "idempotency_key", unique = true, updatable = false)
    private String idempotencyKey;

    @Column(updatable = false)
    private Instant createdAt;

    @PrePersist
    void onCreate() { createdAt = Instant.now(); }
}
