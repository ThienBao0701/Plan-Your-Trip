package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.DiscountType;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

/**
 * Phase 7.14 — Customer Coupons &amp; Travel Credits Foundation.
 * Single-file record style mirrors {@code TravelWalletDto} (Phase 7.12/7.13).
 */
public class CouponDto {

    /**
     * Admin create/update payload. {@code code} is normalized (trimmed,
     * upper-cased) and checked for uniqueness case-insensitively.
     * {@code active} null on create defaults to {@code true}; null on update
     * leaves the existing value unchanged. {@code usageLimitPerUser} null
     * defaults to 1. {@code currentUsageCount} is never client-settable.
     */
    public record CouponDefinitionRequest(
        @NotBlank String code,
        @NotBlank String name,
        String description,
        @NotNull DiscountType discountType,
        @NotNull @DecimalMin(value = "0.0", inclusive = false) BigDecimal discountValue,
        @DecimalMin("0.0") BigDecimal maxDiscountAmount,
        @DecimalMin("0.0") BigDecimal minimumSpend,
        @NotNull LocalDate validFrom,
        @NotNull LocalDate validUntil,
        Boolean active,
        @Min(1) Integer totalUsageLimit,
        @Min(1) Integer usageLimitPerUser
    ) {}

    public record CouponDefinitionResponse(
        Long id,
        String code,
        String name,
        String description,
        DiscountType discountType,
        BigDecimal discountValue,
        BigDecimal maxDiscountAmount,
        BigDecimal minimumSpend,
        LocalDate validFrom,
        LocalDate validUntil,
        boolean active,
        Integer totalUsageLimit,
        int usageLimitPerUser,
        int currentUsageCount,
        Instant createdAt,
        Instant updatedAt
    ) {}

    public record CouponClaimRequest(
        @NotBlank String code
    ) {}

    /**
     * {@code status} is the stored status; {@code effectiveStatus} additionally
     * accounts for the computed effective expiry ({@code effectiveExpiresAt} =
     * earlier of the definition's validUntil and this claim's own expiresAt)
     * and is what clients should display — same stored-vs-effective split as
     * {@code TravelWalletDto.TravelWalletItemResponse}.
     */
    public record CustomerCouponResponse(
        Long id,
        Long userId,
        CouponDefinitionResponse coupon,
        String status,
        String effectiveStatus,
        Instant claimedAt,
        Instant usedAt,
        LocalDate expiresAt,
        LocalDate effectiveExpiresAt,
        Long bookingId,
        Instant createdAt,
        Instant updatedAt
    ) {}

    /**
     * {@code hotelId}/{@code roomId} are accepted for forward compatibility with
     * Phase 7.15 checkout integration but are not used by the foundation
     * calculation — eligibility here is amount/date/status based only.
     */
    public record CouponPreviewRequest(
        @NotNull @DecimalMin(value = "0.0", inclusive = false) BigDecimal orderAmount,
        Long hotelId,
        Long roomId
    ) {}

    /** Preview is strictly read-only — it never marks the coupon used. */
    public record CouponPreviewResponse(
        BigDecimal originalAmount,
        BigDecimal discountAmount,
        BigDecimal finalAmount,
        boolean eligible,
        String reason
    ) {}
}
