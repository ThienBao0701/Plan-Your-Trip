package com.example.planyourtrip.model;

/**
 * Phase 7.14 — Customer Coupons &amp; Travel Credits Foundation.
 * What a {@code TravelCreditTransaction} loosely points back at (soft reference —
 * paired with {@code referenceId}, never a foreign key, so ledger rows survive
 * deletion of whatever produced them).
 */
public enum TravelCreditReferenceType {
    BOOKING, PAYMENT, REFUND, PROMOTION, ADMIN, SYSTEM
}
