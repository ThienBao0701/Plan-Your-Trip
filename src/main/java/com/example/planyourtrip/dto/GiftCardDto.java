package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.GiftCardAdjustmentDirection;
import com.example.planyourtrip.model.GiftCardReferenceType;
import com.example.planyourtrip.model.GiftCardStatus;
import com.example.planyourtrip.model.GiftCardTransactionType;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

/**
 * Phase 7.24 — Gift Cards Foundation.
 * Single-file record style mirrors {@code TravelCreditDto}/{@code LoyaltyRedemptionDto}.
 * Gift cards are PREPAID PROMOTIONAL VALUE ONLY — no withdrawal, no transfer
 * between users, no cash conversion concepts appear anywhere in these shapes.
 */
public class GiftCardDto {

    // ── Admin product CRUD ───────────────────────────────────────────────────

    public record GiftCardProductRequest(
        @NotBlank String productCode,
        @NotBlank String name,
        String description,
        @NotBlank String currency,
        @DecimalMin(value = "0.0", inclusive = false) BigDecimal fixedAmount,
        @DecimalMin(value = "0.0", inclusive = false) BigDecimal minimumAmount,
        @DecimalMin(value = "0.0", inclusive = false) BigDecimal maximumAmount,
        Boolean customAmountAllowed,
        Integer validDaysAfterActivation,
        Boolean active,
        LocalDate validFrom,
        LocalDate validUntil
    ) {}

    public record GiftCardProductResponse(
        Long id,
        String productCode,
        String name,
        String description,
        String currency,
        BigDecimal fixedAmount,
        BigDecimal minimumAmount,
        BigDecimal maximumAmount,
        boolean customAmountAllowed,
        Integer validDaysAfterActivation,
        boolean active,
        LocalDate validFrom,
        LocalDate validUntil,
        Instant createdAt,
        Instant updatedAt,
        Long version
    ) {}

    /** Compact product summary embedded in gift-card responses. */
    public record GiftCardProductSummary(
        Long id,
        String productCode,
        String name,
        String currency
    ) {}

    // ── Party summary (minimal, non-excessive PII) ───────────────────────────

    public record GiftCardPartySummary(
        Long id,
        String fullName
    ) {}

    // ── Issuance ──────────────────────────────────────────────────────────────

    /**
     * Customer self-service issuance — {@code POST /api/me/gift-cards/issue}.
     * No real payment is collected in this phase: this is a clearly named
     * mock/internal issuance path. Production issuance must later be gated on a
     * successful payment (Phase 7.25+). Provide at most one of
     * {@code recipientUserId}/{@code recipientEmail}; omit both to purchase for
     * later self-activation.
     */
    public record GiftCardIssueRequest(
        @NotBlank String productCode,
        @NotNull @DecimalMin(value = "0.0", inclusive = false) BigDecimal amount,
        Long recipientUserId,
        @Email String recipientEmail,
        String personalMessage,
        String idempotencyKey
    ) {}

    /**
     * Admin issuance — {@code POST /api/admin/gift-cards/issue}.
     * {@code purchaserUserId} is optional (null = a house/admin-issued card with
     * no purchaser, e.g. a promotional campaign grant).
     */
    public record AdminGiftCardIssueRequest(
        @NotBlank String productCode,
        @NotNull @DecimalMin(value = "0.0", inclusive = false) BigDecimal amount,
        Long purchaserUserId,
        Long recipientUserId,
        @Email String recipientEmail,
        String personalMessage,
        String idempotencyKey
    ) {}

    // ── Claim ─────────────────────────────────────────────────────────────────

    public record GiftCardClaimRequest(
        @NotBlank String code
    ) {}

    // ── Core response ────────────────────────────────────────────────────────

    /**
     * {@code maskedCode} is always populated ({@code PYT-GC-****-****-XXXX} —
     * last 4 characters visible). {@code fullCode} is populated ONLY on the
     * response returned directly from a successful issuance or claim/activation
     * call to the authorized purchaser/recipient/admin — every other read path
     * (list, get-by-id, get-by-code, admin listing) leaves it {@code null}.
     */
    public record GiftCardResponse(
        Long id,
        String maskedCode,
        String fullCode,
        GiftCardProductSummary product,
        GiftCardPartySummary purchaser,
        GiftCardPartySummary recipient,
        String recipientEmail,
        BigDecimal originalAmount,
        BigDecimal currentBalance,
        String currency,
        GiftCardStatus status,
        GiftCardStatus effectiveStatus,
        String personalMessage,
        Instant issuedAt,
        Instant activatedAt,
        Instant expiresAt,
        Instant cancelledAt,
        Instant fullyRedeemedAt,
        Instant createdAt,
        Instant updatedAt,
        Long version
    ) {}

    /** Compact summary for list views. */
    public record GiftCardSummaryResponse(
        Long id,
        String maskedCode,
        String productName,
        BigDecimal originalAmount,
        BigDecimal currentBalance,
        String currency,
        GiftCardStatus status,
        GiftCardStatus effectiveStatus,
        Instant issuedAt,
        Instant expiresAt
    ) {}

    // ── Preview (read-only) ──────────────────────────────────────────────────

    public record GiftCardPreviewRequest(
        @NotBlank String giftCardCode,
        @NotNull @DecimalMin(value = "0.0", inclusive = false) BigDecimal orderAmount,
        @NotBlank String currency
    ) {}

    public record GiftCardPreviewResponse(
        boolean eligible,
        String reason,
        BigDecimal availableBalance,
        BigDecimal redeemableAmount,
        BigDecimal finalPayableAmount,
        GiftCardStatus effectiveStatus,
        Instant expiresAt
    ) {}

    // ── Phase 7.25 — booking-scoped redemption preview ───────────────────────

    /**
     * Preview redeeming a gift card against an EXISTING PENDING booking's current
     * payable ({@code booking.finalPrice}, already reduced by promotion/coupon/
     * loyalty/travel-credit). {@code POST /api/me/gift-cards/preview-booking}.
     * Read-only — never mutates a balance or the booking.
     */
    public record GiftCardBookingPreviewRequest(
        @NotBlank String giftCardCode,
        @NotNull Long bookingId
    ) {}

    public record GiftCardBookingPreviewResponse(
        boolean eligible,
        String reason,
        BigDecimal giftCardApplied,
        BigDecimal remainingBalance,
        BigDecimal remainingPayable,
        GiftCardStatus effectiveStatus,
        Instant expiresAt
    ) {}

    // ── Admin adjustment ──────────────────────────────────────────────────────

    public record GiftCardAdjustmentRequest(
        @NotNull @DecimalMin(value = "0.0", inclusive = false) BigDecimal amount,
        @NotNull GiftCardAdjustmentDirection direction,
        @NotBlank String description,
        GiftCardReferenceType referenceType,
        Long referenceId,
        String idempotencyKey
    ) {}

    // ── Ledger ────────────────────────────────────────────────────────────────

    public record GiftCardTransactionResponse(
        Long id,
        Long giftCardId,
        GiftCardTransactionType transactionType,
        BigDecimal amount,
        BigDecimal balanceBefore,
        BigDecimal balanceAfter,
        String description,
        GiftCardReferenceType referenceType,
        Long referenceId,
        String idempotencyKey,
        Instant createdAt
    ) {}

    public record GiftCardTransactionPageResponse(
        List<GiftCardTransactionResponse> content,
        int page,
        int size,
        long totalElements,
        int totalPages
    ) {}

    // ── Expiration processor ─────────────────────────────────────────────────

    public record GiftCardExpirationResultResponse(
        int cardsExpired,
        BigDecimal totalAmountExpired,
        List<GiftCardTransactionResponse> expirations
    ) {}
}
