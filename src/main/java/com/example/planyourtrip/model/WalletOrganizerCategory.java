package com.example.planyourtrip.model;

/**
 * Phase 7.13 — Wallet Expiry Alerts &amp; Smart Organizer.
 * Purely computed, never persisted: a coarser grouping bucket derived
 * deterministically from {@link TravelWalletItemType}, one level up from the
 * item type itself, used by the Smart Organizer's "by category" style views.
 * Adding a new {@code TravelWalletItemType} value requires adding it to the
 * switch below (compiler-enforced exhaustiveness — no default branch).
 */
public enum WalletOrganizerCategory {
    IDENTITY,
    TRANSPORT,
    ACCOMMODATION,
    ACTIVITY,
    INSURANCE,
    FINANCIAL,
    OTHER;

    public static WalletOrganizerCategory forItemType(TravelWalletItemType type) {
        return switch (type) {
            case PASSPORT, VISA -> IDENTITY;
            case BOARDING_PASS, FLIGHT_TICKET, TRAIN_TICKET, BUS_TICKET -> TRANSPORT;
            case HOTEL_VOUCHER -> ACCOMMODATION;
            case TOUR_VOUCHER, ITINERARY -> ACTIVITY;
            case INSURANCE -> INSURANCE;
            case BOOKING_CONFIRMATION, INVOICE, RECEIPT -> FINANCIAL;
            case OTHER -> OTHER;
        };
    }
}
