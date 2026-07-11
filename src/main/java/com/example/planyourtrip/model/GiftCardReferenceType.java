package com.example.planyourtrip.model;

/**
 * Phase 7.24 — Gift Cards Foundation.
 * What a {@code GiftCardTransaction} loosely points back at (soft reference —
 * paired with {@code referenceId}, never a foreign key, so ledger rows survive
 * deletion of whatever produced them).
 */
public enum GiftCardReferenceType {
    BOOKING, PAYMENT, REFUND, ADMIN, CAMPAIGN, SYSTEM
}
