package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.LoyaltyRedemptionPolicy;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

/**
 * Phase 7.20 — Loyalty Points Redemption.
 * Admin CRUD over {@link LoyaltyRedemptionPolicy} plus the single authoritative
 * "which policy applies right now" selector used by
 * {@code LoyaltyRedemptionService}.
 */
public interface LoyaltyRedemptionPolicyRepository extends JpaRepository<LoyaltyRedemptionPolicy, Long> {

    Optional<LoyaltyRedemptionPolicy> findByPolicyCodeIgnoreCase(String policyCode);

    List<LoyaltyRedemptionPolicy> findAllByOrderByEffectiveFromDescIdDesc();

    /**
     * The one applicable active policy at {@code at}: active, effectiveFrom &le;
     * at, and (effectiveUntil is null or &ge; at). Newest effective window wins
     * so at most one is used even if several overlap.
     */
    @Query("""
        select p from LoyaltyRedemptionPolicy p
        where p.active = true
          and p.effectiveFrom <= :at
          and (p.effectiveUntil is null or p.effectiveUntil >= :at)
        order by p.effectiveFrom desc, p.id desc
        """)
    List<LoyaltyRedemptionPolicy> findApplicable(@Param("at") Instant at);
}
