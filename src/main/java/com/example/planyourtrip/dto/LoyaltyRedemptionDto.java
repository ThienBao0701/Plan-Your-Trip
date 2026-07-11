package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.LoyaltyRedemptionStatus;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/**
 * Phase 7.20 — Loyalty Points Redemption.
 * Single-file record style mirrors {@code LoyaltyDto}/{@code MembershipDto}.
 * Points are integer counts ({@code long}); every money value is
 * {@code BigDecimal} — never floating point.
 */
public class LoyaltyRedemptionDto {

    // ── Redemption policy (admin) ─────────────────────────────────────────────

    public record RedemptionPolicyRequest(
        @NotBlank String policyCode,
        @NotBlank String displayName,
        @NotNull @Positive Long pointsPerUnit,
        @NotNull @DecimalMin(value = "0.0", inclusive = false) BigDecimal valuePerUnit,
        @NotNull @Positive Long minimumRedemptionPoints,
        @NotNull @Positive Long redemptionIncrementPoints,
        @NotNull @Min(0) @Max(100) Integer maximumDiscountPercentage,
        @NotNull @DecimalMin(value = "0.0") BigDecimal minimumFinalPayableAmount,
        Boolean active,
        Instant effectiveFrom,
        Instant effectiveUntil
    ) {}

    public record RedemptionPolicyResponse(
        Long id,
        String policyCode,
        String displayName,
        long pointsPerUnit,
        BigDecimal valuePerUnit,
        long minimumRedemptionPoints,
        long redemptionIncrementPoints,
        int maximumDiscountPercentage,
        BigDecimal minimumFinalPayableAmount,
        boolean active,
        Instant effectiveFrom,
        Instant effectiveUntil,
        Instant createdAt,
        Instant updatedAt,
        Long version
    ) {}

    /** Compact policy summary embedded in preview/redemption responses. */
    public record RedemptionPolicySummary(
        String policyCode,
        long pointsPerUnit,
        BigDecimal valuePerUnit,
        long minimumRedemptionPoints,
        long redemptionIncrementPoints,
        int maximumDiscountPercentage,
        BigDecimal minimumFinalPayableAmount
    ) {}

    // ── Preview ────────────────────────────────────────────────────────────────

    /**
     * Either {@code bookingId} (compute the eligible amount from the booking) or
     * {@code eligibleAmount} (caller supplies the amount directly, e.g. before a
     * booking exists) must be present. {@code requestedPoints} is the number of
     * points the customer would like to redeem.
     */
    public record RedemptionPreviewRequest(
        Long bookingId,
        @DecimalMin(value = "0.0", inclusive = false) BigDecimal eligibleAmount,
        @NotNull @Min(0) Long requestedPoints
    ) {}

    public record RedemptionPreviewResponse(
        long requestedPoints,
        long acceptedPoints,
        BigDecimal discountAmount,
        long maximumRedeemablePoints,
        long currentBalance,
        long remainingBalance,
        BigDecimal eligibleAmount,
        BigDecimal finalPayableAmount,
        boolean redeemable,
        List<String> messages,
        RedemptionPolicySummary policy
    ) {}

    // ── Reserve ─────────────────────────────────────────────────────────────────

    public record RedemptionReserveRequest(
        @NotNull Long bookingId,
        @NotNull @Positive Long requestedPoints,
        @NotBlank String idempotencyKey
    ) {}

    public record RedemptionResponse(
        Long id,
        String redemptionReference,
        Long customerId,
        Long bookingId,
        Long loyaltyAccountId,
        String policyCode,
        long pointsRedeemed,
        BigDecimal discountAmount,
        BigDecimal eligibleAmount,
        LoyaltyRedemptionStatus status,
        Instant reservedAt,
        Instant appliedAt,
        Instant releasedAt,
        Instant refundedAt,
        Instant cancelledAt,
        Instant expiresAt,
        String reason,
        String idempotencyKey,
        Instant createdAt,
        Instant updatedAt
    ) {}

    /** Admin expire-stale run summary. */
    public record ExpireStaleRunResponse(
        int expiredCount,
        long pointsRestored,
        List<RedemptionResponse> expired
    ) {}
}
