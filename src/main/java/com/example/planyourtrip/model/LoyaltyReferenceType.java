package com.example.planyourtrip.model;

/**
 * Phase 7.18 — Loyalty Points Foundation.
 * What a {@code LoyaltyPointsTransaction} loosely points back at (soft
 * reference — paired with {@code referenceId}, never a foreign key, so
 * ledger rows survive deletion of whatever produced them). Mirrors
 * {@code TravelCreditReferenceType}'s pattern.
 */
public enum LoyaltyReferenceType {
    BOOKING, REVIEW, ADMIN, SYSTEM,
    /** Phase 7.20 — a redemption ledger row references the {@code LoyaltyPointsRedemption} it belongs to. */
    REDEMPTION
}
