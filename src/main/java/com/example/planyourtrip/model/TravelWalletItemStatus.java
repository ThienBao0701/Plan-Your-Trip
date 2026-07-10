package com.example.planyourtrip.model;

/**
 * {@code EXPIRED} is never persisted by {@code TravelWalletService} — it is
 * computed on read from {@code validUntil} vs "today" and only ever appears
 * in the "effective status" of a response, never written back to the row.
 */
public enum TravelWalletItemStatus {
    ACTIVE,
    UPCOMING,
    EXPIRED,
    CANCELLED,
    ARCHIVED
}
