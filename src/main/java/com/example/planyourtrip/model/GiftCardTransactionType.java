package com.example.planyourtrip.model;

/**
 * Phase 7.24 — Gift Cards Foundation.
 * Direction is derived from the type, never from a signed amount
 * ({@code GiftCardTransaction#amount} is always &gt;= 0):
 * <ul>
 *   <li>increase: {@code ISSUE} (opening balance), {@code REFUND}, and the CREDIT
 *       direction of {@code ADJUSTMENT};</li>
 *   <li>decrease: {@code REDEMPTION} (Phase 7.25), {@code EXPIRATION},
 *       {@code CANCELLATION}, and the DEBIT direction of {@code ADJUSTMENT};</li>
 *   <li>{@code ACTIVATE}: a zero-amount marker row recording activation — never
 *       changes the balance.</li>
 * </ul>
 */
public enum GiftCardTransactionType {
    ISSUE,
    ACTIVATE,
    REDEMPTION,
    REFUND,
    ADJUSTMENT,
    EXPIRATION,
    CANCELLATION
}
