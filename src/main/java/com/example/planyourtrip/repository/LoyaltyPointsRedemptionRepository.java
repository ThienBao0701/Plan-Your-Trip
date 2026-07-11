package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.LoyaltyPointsRedemption;
import com.example.planyourtrip.model.LoyaltyRedemptionStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

/**
 * Phase 7.20 — Loyalty Points Redemption.
 * Redemption lookups by reference / booking / idempotency key, the "already has
 * a non-terminal redemption" exclusivity check, the expired-reservation sweep,
 * and admin filtered listing (via {@link JpaSpecificationExecutor}).
 */
public interface LoyaltyPointsRedemptionRepository extends JpaRepository<LoyaltyPointsRedemption, Long>,
        JpaSpecificationExecutor<LoyaltyPointsRedemption> {

    Optional<LoyaltyPointsRedemption> findByRedemptionReference(String redemptionReference);

    Optional<LoyaltyPointsRedemption> findByIdempotencyKey(String idempotencyKey);

    List<LoyaltyPointsRedemption> findByBookingIdOrderByCreatedAtDescIdDesc(Long bookingId);

    /** The (at most one) non-terminal redemption for a booking — enforces per-booking exclusivity. */
    List<LoyaltyPointsRedemption> findByBookingIdAndStatusIn(Long bookingId, Collection<LoyaltyRedemptionStatus> statuses);

    /** Expired-reservation sweep candidates: still RESERVED and past their expiry. */
    List<LoyaltyPointsRedemption> findByStatusAndExpiresAtLessThanEqual(LoyaltyRedemptionStatus status, Instant cutoff);
}
