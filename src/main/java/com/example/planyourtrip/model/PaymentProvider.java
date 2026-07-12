package com.example.planyourtrip.model;

public enum PaymentProvider {
    MOCK,
    VNPAY,
    PAYOS,
    MOMO,
    STRIPE,
    APPLE_PAY,
    GOOGLE_PAY,
    // Retained from the original Payment settlement flow (used by PaymentService.providerFor
    // for CASH/CARD/BANK_TRANSFER methods) — do not remove.
    MANUAL
}
