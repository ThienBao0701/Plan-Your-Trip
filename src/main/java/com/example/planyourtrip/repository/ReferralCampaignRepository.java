package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.ReferralCampaign;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

/**
 * Phase 7.22 — Referral &amp; Invite Rewards.
 * Admin CRUD over {@link ReferralCampaign} plus the single authoritative "which
 * campaign applies right now" selector — mirrors
 * {@code LoyaltyRedemptionPolicyRepository}.
 */
public interface ReferralCampaignRepository extends JpaRepository<ReferralCampaign, Long> {

    Optional<ReferralCampaign> findByCodeIgnoreCase(String code);

    List<ReferralCampaign> findAllByOrderByEffectiveFromDescIdDesc();

    /**
     * The one applicable active campaign at {@code at}: active, effectiveFrom &le;
     * at, and (effectiveUntil is null or &ge; at). Newest effective window wins so
     * at most one is used even if several overlap.
     */
    @Query("""
        select c from ReferralCampaign c
        where c.active = true
          and c.effectiveFrom <= :at
          and (c.effectiveUntil is null or c.effectiveUntil >= :at)
        order by c.effectiveFrom desc, c.id desc
        """)
    List<ReferralCampaign> findApplicable(@Param("at") Instant at);
}
