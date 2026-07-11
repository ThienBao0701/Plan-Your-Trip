package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.LoyaltyPointsRedemption;
import com.example.planyourtrip.model.LoyaltyRedemptionStatus;
import org.springframework.data.jpa.domain.Specification;

import java.time.Instant;

/**
 * Phase 7.20 — Loyalty Points Redemption.
 * Filters for the admin redemption listing, mirroring {@code BookingSpecification}'s
 * null-safe composable style.
 */
public final class LoyaltyRedemptionSpecification {

    private LoyaltyRedemptionSpecification() {}

    public static Specification<LoyaltyPointsRedemption> withCustomerId(Long customerId) {
        if (customerId == null) return Specification.where(null);
        return (root, query, cb) -> cb.equal(root.get("customer").get("id"), customerId);
    }

    public static Specification<LoyaltyPointsRedemption> withBookingId(Long bookingId) {
        if (bookingId == null) return Specification.where(null);
        return (root, query, cb) -> cb.equal(root.get("booking").get("id"), bookingId);
    }

    public static Specification<LoyaltyPointsRedemption> withStatus(LoyaltyRedemptionStatus status) {
        if (status == null) return Specification.where(null);
        return (root, query, cb) -> cb.equal(root.get("status"), status);
    }

    public static Specification<LoyaltyPointsRedemption> withReference(String reference) {
        if (reference == null || reference.isBlank()) return Specification.where(null);
        return (root, query, cb) -> cb.equal(root.get("redemptionReference"), reference.trim());
    }

    public static Specification<LoyaltyPointsRedemption> createdFrom(Instant from) {
        if (from == null) return Specification.where(null);
        return (root, query, cb) -> cb.greaterThanOrEqualTo(root.get("createdAt"), from);
    }

    public static Specification<LoyaltyPointsRedemption> createdTo(Instant to) {
        if (to == null) return Specification.where(null);
        return (root, query, cb) -> cb.lessThanOrEqualTo(root.get("createdAt"), to);
    }
}
