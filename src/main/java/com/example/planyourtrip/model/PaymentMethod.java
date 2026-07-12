package com.example.planyourtrip.model;

public enum PaymentMethod {
    MOCK,
    CASH,
    CARD,
    BANK_TRANSFER,
    VNPAY,
    MOMO,
    STRIPE,
    // Phase 7.27 — additive: PayOS gained a real gateway adapter this phase.
    PAYOS
}
