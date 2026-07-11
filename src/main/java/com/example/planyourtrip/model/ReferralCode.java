package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

/**
 * Phase 7.22 — Referral &amp; Invite Rewards.
 * One immutable personal referral code per user, created lazily on first access
 * to {@code GET /api/me/referral} — the exact one-per-user, get-or-create
 * pattern established by {@code LoyaltyAccount}/{@code TravelCreditAccount}. The
 * {@link #code} is unique and never regenerated once created (there is no
 * rotate/reset path), and {@link #owner} carries a DB-unique constraint so a
 * user can hold at most one code.
 */
@Entity
@Table(name = "referral_codes",
       uniqueConstraints = {
           @UniqueConstraint(name = "uk_referral_code_owner", columnNames = "owner_id"),
           @UniqueConstraint(name = "uk_referral_code_code", columnNames = "code")
       })
@Getter @Setter
public class ReferralCode {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "owner_id", nullable = false, unique = true)
    private User owner;

    @Column(nullable = false, unique = true, length = 32)
    private String code;

    @Column(updatable = false)
    private Instant createdAt;

    @PrePersist
    void onCreate() { createdAt = Instant.now(); }
}
