package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Entity
@Table(name = "partner_payout_accounts",
       indexes = {
           @Index(name = "idx_partner_payout_accounts_profile_id", columnList = "partner_profile_id", unique = true)
       })
@Getter @Setter
public class PartnerPayoutAccount {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "partner_profile_id", unique = true, nullable = false)
    private PartnerProfile partnerProfile;

    @Column(nullable = false)
    private String accountHolderName;

    @Column(nullable = false)
    private String bankName;

    // Deliberately only the last 4 digits — the full account number is never persisted.
    @Column(name = "bank_account_last4", nullable = false, length = 4)
    private String bankAccountLast4;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PayoutMethod payoutMethod = PayoutMethod.BANK_TRANSFER;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PayoutAccountStatus status = PayoutAccountStatus.DRAFT;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
