package com.example.planyourtrip.model;

/**
 * Phase 7.24 — Gift Cards Foundation.
 * Lifecycle of a {@link GiftCard}. ISSUED → ACTIVE on activation/claim;
 * ACTIVE → PARTIALLY_REDEEMED once part of the balance is spent (future Phase
 * 7.25 redemption / admin DEBIT adjustment); → FULLY_REDEEMED when the balance
 * reaches zero. EXPIRED and CANCELLED are terminal administrative end-states.
 * Effective EXPIRED is also computed on reads (see {@code GiftCardService}).
 */
public enum GiftCardStatus {
    ISSUED,
    ACTIVE,
    PARTIALLY_REDEEMED,
    FULLY_REDEEMED,
    EXPIRED,
    CANCELLED
}
