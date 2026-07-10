package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.TravelCreditReferenceType;
import com.example.planyourtrip.model.TravelCreditTransactionType;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

/**
 * Phase 7.14 — Customer Coupons &amp; Travel Credits Foundation.
 * Promotional platform credit only — no withdrawal, transfer or cash-out
 * concepts exist anywhere in these shapes. Single-file record style mirrors
 * {@code TravelWalletDto}.
 */
public class TravelCreditDto {

    public record TravelCreditAccountResponse(
        Long id,
        Long userId,
        BigDecimal balance,
        String currency,
        Instant createdAt,
        Instant updatedAt
    ) {}

    public record TravelCreditTransactionResponse(
        Long id,
        Long accountId,
        TravelCreditTransactionType transactionType,
        BigDecimal amount,
        BigDecimal balanceBefore,
        BigDecimal balanceAfter,
        String description,
        TravelCreditReferenceType referenceType,
        Long referenceId,
        String idempotencyKey,
        LocalDate expiresAt,
        Instant createdAt
    ) {}

    /**
     * Admin grant/deduct payload (customers have no credit-mutation endpoints
     * at all). {@code amount} is always positive — direction comes from the
     * endpoint. {@code transactionType} is optional: grant defaults to GRANT
     * (allowed: GRANT/PROMOTION/REFUND_CREDIT/REVERSAL), deduct defaults to
     * ADJUSTMENT (allowed: ADJUSTMENT/REDEMPTION/EXPIRATION) — a type from the
     * wrong direction set is rejected with 400. {@code description} is an
     * internal admin note persisted on the ledger row; it is deliberately kept
     * out of the user-facing notification message. {@code idempotencyKey} is
     * optional but unique when supplied — replaying the same key returns the
     * original transaction without a second balance change.
     */
    public record TravelCreditAdjustmentRequest(
        @NotNull @DecimalMin(value = "0.0", inclusive = false) BigDecimal amount,
        @NotBlank String currency,
        @NotBlank String description,
        TravelCreditReferenceType referenceType,
        Long referenceId,
        String idempotencyKey,
        LocalDate expiresAt,
        TravelCreditTransactionType transactionType
    ) {}

    /**
     * Admin read-only support view. {@code account} is null when the user has
     * never touched travel credits — the admin view never creates the account
     * (only customer access and grant/deduct do), keeping GET strictly read-only.
     */
    public record TravelCreditAdminViewResponse(
        Long userId,
        TravelCreditAccountResponse account,
        List<TravelCreditTransactionResponse> recentTransactions
    ) {}

    /**
     * Phase 7.16 — result of an admin-triggered expiration sweep
     * ({@code POST /api/admin/travel-credits/process-expirations}).
     * {@code expirations} lists every EXPIRATION ledger row inserted by THIS
     * run (already-processed grants replay to nothing and are not listed) —
     * shape mirrors {@code WalletExpiryReminderResultResponse} (Phase 7.13).
     */
    public record CreditExpirationRunResponse(
        int accountsAffected,
        int transactionsExpired,
        BigDecimal totalAmountExpired,
        List<TravelCreditTransactionResponse> expirations
    ) {}
}
