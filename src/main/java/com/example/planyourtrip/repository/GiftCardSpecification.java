package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.GiftCard;
import com.example.planyourtrip.model.GiftCardStatus;
import org.springframework.data.jpa.domain.Specification;

import java.time.Instant;

/**
 * Phase 7.24 — Gift Cards Foundation.
 * Filters for the admin gift-card listing, mirroring
 * {@code LoyaltyRedemptionSpecification}'s null-safe composable style.
 */
public final class GiftCardSpecification {

    private GiftCardSpecification() {}

    public static Specification<GiftCard> withCode(String code) {
        if (code == null || code.isBlank()) return Specification.where(null);
        String normalized = code.trim().toUpperCase();
        return (root, query, cb) -> cb.equal(root.get("giftCardCode"), normalized);
    }

    public static Specification<GiftCard> withPurchaserUserId(Long purchaserUserId) {
        if (purchaserUserId == null) return Specification.where(null);
        return (root, query, cb) -> cb.equal(root.get("purchaserUser").get("id"), purchaserUserId);
    }

    public static Specification<GiftCard> withRecipientUserId(Long recipientUserId) {
        if (recipientUserId == null) return Specification.where(null);
        return (root, query, cb) -> cb.equal(root.get("recipientUser").get("id"), recipientUserId);
    }

    public static Specification<GiftCard> withStatus(GiftCardStatus status) {
        if (status == null) return Specification.where(null);
        return (root, query, cb) -> cb.equal(root.get("status"), status);
    }

    public static Specification<GiftCard> withProductId(Long productId) {
        if (productId == null) return Specification.where(null);
        return (root, query, cb) -> cb.equal(root.get("product").get("id"), productId);
    }

    public static Specification<GiftCard> issuedFrom(Instant from) {
        if (from == null) return Specification.where(null);
        return (root, query, cb) -> cb.greaterThanOrEqualTo(root.get("issuedAt"), from);
    }

    public static Specification<GiftCard> issuedTo(Instant to) {
        if (to == null) return Specification.where(null);
        return (root, query, cb) -> cb.lessThanOrEqualTo(root.get("issuedAt"), to);
    }

    public static Specification<GiftCard> expiresFrom(Instant from) {
        if (from == null) return Specification.where(null);
        return (root, query, cb) -> cb.greaterThanOrEqualTo(root.get("expiresAt"), from);
    }

    public static Specification<GiftCard> expiresTo(Instant to) {
        if (to == null) return Specification.where(null);
        return (root, query, cb) -> cb.lessThanOrEqualTo(root.get("expiresAt"), to);
    }
}
