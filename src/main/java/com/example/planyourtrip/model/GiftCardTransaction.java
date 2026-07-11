package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Phase 7.24 — Gift Cards Foundation.
 * IMMUTABLE ledger entry for a {@link GiftCard} balance change. Immutability is
 * enforced in depth exactly like {@code TravelCreditTransaction}: every business
 * column is {@code updatable = false}, there is no {@code @PreUpdate} hook and no
 * update path anywhere — {@code GiftCardService} only ever inserts rows.
 * {@link #amount} is always &gt;= 0 (0 only for the {@code ACTIVATE} marker
 * row) — direction comes from {@link #transactionType}, never from a sign.
 * {@link #idempotencyKey} is unique where non-null (DB backstop) and pre-checked
 * by the service.
 */
@Entity
@Table(name = "gift_card_transactions",
       uniqueConstraints = @UniqueConstraint(name = "uk_gift_card_tx_idempotency_key", columnNames = "idempotency_key"),
       indexes = @Index(name = "idx_gift_card_tx_gift_card_id", columnList = "gift_card_id"))
@Getter @Setter
public class GiftCardTransaction {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "gift_card_id", nullable = false, updatable = false)
    private GiftCard giftCard;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, updatable = false, length = 20)
    private GiftCardTransactionType transactionType;

    /** Always &gt;= 0 — see class javadoc. */
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
    private GiftCardReferenceType referenceType;

    @Column(updatable = false)
    private Long referenceId;

    @Column(name = "idempotency_key", unique = true, updatable = false)
    private String idempotencyKey;

    @Column(updatable = false)
    private Instant createdAt;

    @PrePersist
    void onCreate() { createdAt = Instant.now(); }
}
