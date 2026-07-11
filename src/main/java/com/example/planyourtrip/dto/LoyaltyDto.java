package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.LoyaltyReferenceType;
import com.example.planyourtrip.model.LoyaltyTransactionType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.time.Instant;
import java.util.List;

/**
 * Phase 7.18 — Loyalty Points Foundation.
 * Points are integer counts, not money — {@code long}, never {@code BigDecimal}
 * (the BigDecimal-only rule applies to money, not point quantities). Single-file
 * record style mirrors {@code TravelCreditDto}.
 */
public class LoyaltyDto {

    public record LoyaltyAccountResponse(
        Long id,
        Long userId,
        long currentBalance,
        long lifetimePointsEarned,
        Instant createdAt,
        Instant updatedAt
    ) {}

    public record LoyaltyTransactionResponse(
        Long id,
        Long accountId,
        LoyaltyTransactionType transactionType,
        long points,
        long balanceBefore,
        long balanceAfter,
        String description,
        LoyaltyReferenceType referenceType,
        Long referenceId,
        String idempotencyKey,
        Instant createdAt
    ) {}

    /**
     * Admin grant payload (customers have no loyalty-mutation endpoints at all —
     * points are earned automatically on booking completion, or awarded via the
     * internal review-bonus path). {@code points} is always positive.
     * {@code description} is an internal admin note persisted on the ledger row;
     * it is deliberately kept out of the user-facing notification message.
     * {@code idempotencyKey} is optional but unique when supplied — replaying
     * the same key returns the original transaction without a second award.
     */
    public record LoyaltyGrantRequest(
        @NotNull @Positive Long points,
        @NotBlank String description,
        LoyaltyReferenceType referenceType,
        Long referenceId,
        String idempotencyKey
    ) {}

    /**
     * Admin read-only support view. {@code account} is null when the user has
     * never touched loyalty points — the admin view never creates the account
     * (only customer access and grant/earn do), keeping GET strictly read-only.
     */
    public record LoyaltyAdminViewResponse(
        Long userId,
        LoyaltyAccountResponse account,
        List<LoyaltyTransactionResponse> recentTransactions
    ) {}
}
