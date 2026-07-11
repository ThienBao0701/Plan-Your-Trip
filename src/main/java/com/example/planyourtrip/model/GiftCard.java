package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Phase 7.24 — Gift Cards Foundation.
 * PREPAID PROMOTIONAL VALUE ONLY — not a bank account, cannot be withdrawn,
 * transferred back to cash, or transferred between users. {@link #giftCardCode}
 * is the unique, non-sequential, publicly redeemable code (format
 * {@code PYT-GC-XXXX-XXXX-XXXX}) — immutable after issue and never the same as
 * the internal database {@link #id}. {@link #codeLast4} is a separate,
 * non-sensitive field for support display (masked responses show only this).
 *
 * <p>Every balance mutation goes through {@code GiftCardService} inside a
 * pessimistic write lock on this row and writes exactly one immutable
 * {@link GiftCardTransaction}, mirroring {@code TravelCreditAccount} /
 * {@code LoyaltyAccount}'s established ledger discipline.
 */
@Entity
@Table(name = "gift_cards",
       uniqueConstraints = @UniqueConstraint(name = "uk_gift_card_code", columnNames = "gift_card_code"),
       indexes = {
           @Index(name = "idx_gift_card_status", columnList = "status"),
           @Index(name = "idx_gift_card_purchaser_user_id", columnList = "purchaser_user_id"),
           @Index(name = "idx_gift_card_recipient_user_id", columnList = "recipient_user_id"),
           @Index(name = "idx_gift_card_expires_at", columnList = "expires_at"),
           @Index(name = "idx_gift_card_issued_at", columnList = "issued_at"),
           @Index(name = "idx_gift_card_product_id", columnList = "product_id")
       })
@Getter @Setter
public class GiftCard {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Public redeemable code — immutable after issue. Never expose the internal {@link #id} as the redeemable identifier. */
    @Column(name = "gift_card_code", nullable = false, updatable = false, length = 32)
    private String giftCardCode;

    /** Last 4 characters of the code — safe for support display; the masked response never includes more. */
    @Column(name = "code_last4", nullable = false, updatable = false, length = 4)
    private String codeLast4;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "product_id", nullable = false, updatable = false)
    private GiftCardProduct product;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "purchaser_user_id", updatable = false)
    private User purchaserUser;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipient_user_id")
    private User recipientUser;

    /** Normalized (trimmed lower-case) email for an as-yet-unclaimed gift, if issued without a recipientUser. */
    @Column(length = 255)
    private String recipientEmail;

    @Column(nullable = false, updatable = false, precision = 15, scale = 2)
    private BigDecimal originalAmount;

    @Column(nullable = false, precision = 15, scale = 2)
    private BigDecimal currentBalance;

    /** Fixed at issue — cannot change afterward. */
    @Column(nullable = false, updatable = false, length = 10)
    private String currency;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private GiftCardStatus status;

    @Column(length = 500)
    private String personalMessage;

    @Column(nullable = false, updatable = false)
    private Instant issuedAt;

    private Instant activatedAt;

    private Instant expiresAt;

    private Instant cancelledAt;

    private Instant fullyRedeemedAt;

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
