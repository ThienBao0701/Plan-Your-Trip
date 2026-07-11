package com.example.planyourtrip.model;

/**
 * Phase 7.24 — Gift Cards Foundation.
 * Direction for the admin manual adjustment endpoint
 * ({@code POST /api/admin/gift-cards/{id}/adjust}). CREDIT increases the
 * balance (ledger type {@link GiftCardTransactionType#ADJUSTMENT}, positive
 * amount); DEBIT decreases it and can never overdraw (409).
 */
public enum GiftCardAdjustmentDirection {
    CREDIT, DEBIT
}
