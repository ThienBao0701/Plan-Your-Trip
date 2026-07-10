package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Phase 7.14 — Customer Coupons &amp; Travel Credits Foundation.
 * PROMOTIONAL PLATFORM CREDIT ONLY: this is not a bank account, not a payment
 * wallet, and holds no real money — the balance cannot be withdrawn, transferred
 * to another user, or converted to cash. One account per user (enforced by the
 * unique constraint on {@code user_id}), created lazily on first access by
 * {@code TravelCreditService}. Balance is never negative and every change is
 * recorded as exactly one immutable {@link TravelCreditTransaction}.
 */
@Entity
@Table(name = "travel_credit_accounts",
       uniqueConstraints = @UniqueConstraint(name = "uk_travel_credit_account_user", columnNames = "user_id"))
@Getter @Setter
public class TravelCreditAccount {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(nullable = false, precision = 15, scale = 2)
    private BigDecimal balance = BigDecimal.ZERO;

    /** Fixed at account creation from the customer profile's preferred currency (else "VND"). */
    @Column(nullable = false, length = 10)
    private String currency = "VND";

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
