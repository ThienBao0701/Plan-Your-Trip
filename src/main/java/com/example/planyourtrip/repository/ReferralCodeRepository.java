package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.ReferralCode;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

/**
 * Phase 7.22 — Referral &amp; Invite Rewards.
 * One immutable code per user — mirrors the get-or-create lookup on
 * {@code LoyaltyAccountRepository}/{@code TravelCreditAccountRepository}.
 */
public interface ReferralCodeRepository extends JpaRepository<ReferralCode, Long> {

    Optional<ReferralCode> findByOwnerId(Long ownerId);

    Optional<ReferralCode> findByCodeIgnoreCase(String code);

    boolean existsByCodeIgnoreCase(String code);
}
