package com.example.planyourtrip.model;

/**
 * Phase 7.26 — the kind of lifecycle transition recorded by an immutable
 * {@link PaymentSessionEvent}. One event row is written per accepted transition,
 * carrying a deterministic {@code idempotencyKey} (DB-unique backstop) — the same
 * ledger idiom as {@code GiftCardTransaction}/{@code TravelCreditTransaction}, applied
 * here to callback/state-transition processing rather than to a money balance.
 */
public enum PaymentSessionEventType {
    CREATED,
    AUTHORIZED,
    CAPTURED,
    FAILED,
    CANCELLED,
    EXPIRED
}
