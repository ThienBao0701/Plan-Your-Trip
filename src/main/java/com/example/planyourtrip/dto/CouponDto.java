package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.CouponTargetType;
import com.example.planyourtrip.model.CustomerSegment;
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
    /**
     * Phase 7.17 additions (all additive/optional — see {@code CouponDefinition}
     * class javadoc for the backward-compat guarantee): {@code targetType} null
     * defaults to ALL; {@code customerSegment} null defaults to ALL_USERS;
     * {@code firstBookingOnly}/{@code combinableWithPromotions}/
     * {@code combinableWithTravelCredits} null on create default to
     * false/true/true respectively and null on update leaves the existing value
     * unchanged (same convention as {@code active}).
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
        @Min(1) Integer usageLimitPerUser,
        CouponTargetType targetType,
        Long targetId,
        String placeType,
        @Min(1) Integer minimumStayNights,
        LocalDate bookingDateFrom,
        LocalDate bookingDateTo,
        CustomerSegment customerSegment,
        Boolean firstBookingOnly,
        Boolean combinableWithPromotions,
        Boolean combinableWithTravelCredits
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
        CouponTargetType targetType,
        Long targetId,
        String placeType,
        Integer minimumStayNights,
        LocalDate bookingDateFrom,
        LocalDate bookingDateTo,
        CustomerSegment customerSegment,
        boolean firstBookingOnly,
        boolean combinableWithPromotions,
        boolean combinableWithTravelCredits,
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
     * Phase 7.17 — {@code hotelId}/{@code roomId} (present since 7.14 for
     * forward compatibility) are now actually used for target-type eligibility,
     * alongside the new optional {@code checkIn}/{@code checkOut} (minimum-stay
     * and booking-date-window eligibility), {@code travelCreditAmount} (credit
     * stacking) and {@code promotionDiscountApplied} (promotion stacking —
     * null lets the service best-effort detect it via the pricing engine when
     * {@code roomId}/{@code checkIn}/{@code checkOut} are all present).
     * Every new field is optional: a caller that only ever sent
     * {@code orderAmount} keeps getting exactly the pre-7.17 result, since a
     * missing targeting/date/stacking context is treated as "not violated"
     * rather than failed — see {@code CustomerCouponService} class javadoc.
     */
    public record CouponPreviewRequest(
        @NotNull @DecimalMin(value = "0.0", inclusive = false) BigDecimal orderAmount,
        Long hotelId,
        Long roomId,
        LocalDate checkIn,
        LocalDate checkOut,
        BigDecimal travelCreditAmount,
        Boolean promotionDiscountApplied
    ) {}

    /** Preview is strictly read-only — it never marks the coupon used. */
    public record CouponPreviewResponse(
        BigDecimal originalAmount,
        BigDecimal discountAmount,
        BigDecimal finalAmount,
        boolean eligible,
        String reason
    ) {}

    /**
     * Phase 7.17 — request shape shared by both the customer
     * ({@code POST /api/me/coupons/{id}/eligibility}) and admin
     * ({@code GET /api/admin/coupon-definitions/{id}/eligibility-preview})
     * eligibility endpoints. Strictly read-only, same guarantee as
     * {@link CouponPreviewRequest} — never marks a coupon used.
     */
    public record CouponEligibilityRequest(
        Long hotelId,
        Long roomId,
        LocalDate checkIn,
        LocalDate checkOut,
        @NotNull @DecimalMin(value = "0.0", inclusive = false) BigDecimal orderAmount,
        BigDecimal travelCreditAmount
    ) {}

    /** Full eligibility breakdown — one flag per Phase 7.17 rule category, plus the overall verdict. */
    public record CouponEligibilityResponse(
        boolean eligible,
        String reason,
        CouponTargetType matchedTargetType,
        boolean minimumStaySatisfied,
        boolean dateWindowSatisfied,
        boolean customerSegmentSatisfied,
        boolean promotionStackingAllowed,
        boolean creditStackingAllowed,
        BigDecimal previewDiscount
    ) {}
}
