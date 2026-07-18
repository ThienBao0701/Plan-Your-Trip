package com.example.planyourtrip.model;

/**
 * Phase 7.41 — how a staff-performed check-out was initiated.
 *
 * <p>Derived purely from the request input shape: a scanned signed voucher payload ⇒ {@link #QR_SCAN};
 * a raw typed booking code ⇒ {@link #MANUAL}. Recorded (immutably) on {@link BookingCheckOutAudit} so
 * the audit trail distinguishes a QR-driven admission from a manual desk override.
 */
public enum CheckMethod {
    QR_SCAN,
    MANUAL
}
