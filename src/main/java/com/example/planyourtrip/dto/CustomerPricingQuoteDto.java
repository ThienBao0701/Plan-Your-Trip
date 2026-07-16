package com.example.planyourtrip.dto;

import com.example.planyourtrip.dto.CouponDto.CouponPreviewResponse;
import com.example.planyourtrip.dto.GiftCardDto.GiftCardPreviewResponse;
import com.example.planyourtrip.dto.LoyaltyRedemptionDto.RedemptionPreviewResponse;
import com.example.planyourtrip.dto.RoomPricingQuoteDto.RoomPricingQuoteResponse;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Phase 7.33 — the AUTHENTICATED customer pricing quote contract. Where the
 * Phase 7.32 {@link RoomPricingQuoteDto} deliberately stops at the pre-customer-benefit
 * price, this contract LAYERS the four customer-specific benefit previews
 * (coupon → loyalty → travel credit → gift card) on top of that exact base to
 * produce a full {@code estimatedPayable} — WITHOUT mutating any state. Every
 * benefit stage reuses the existing read-only preview of its owning service;
 * nothing is recomputed.
 */
public class CustomerPricingQuoteDto {

    /**
     * Quote request body. The first six fields mirror
     * {@link RoomPricingQuoteDto.RoomPricingQuoteRequest} exactly (room / stay /
     * occupancy / optional explicit rate plan). The remaining four are the
     * OPTIONAL customer benefit inputs — a customer may preview any subset:
     * <ul>
     *   <li>{@code couponId} — one of the caller's OWN claimed coupons (an id that
     *       is not theirs 404s, exactly like every other {@code /me} coupon
     *       endpoint — existence never leaks);</li>
     *   <li>{@code requestedPoints} — loyalty points the customer would like to
     *       redeem (mirrors {@code RedemptionPreviewRequest.requestedPoints});</li>
     *   <li>{@code travelCreditAmountRequested} — how much promotional travel
     *       credit to apply (mirrors checkout's {@code creditAmount});</li>
     *   <li>{@code giftCardCode} — a gift-card code to preview against the
     *       remaining payable (redeemable by whoever holds the code, exactly like
     *       the existing {@code POST /api/me/gift-cards/preview}).</li>
     * </ul>
     * A benefit that is omitted is simply skipped; a benefit that is supplied but
     * ineligible is reported in {@code eligibilityFailures} and contributes no
     * discount — the overall estimate is still returned.
     */
    public record CustomerPricingQuoteRequest(
        @NotNull LocalDate checkIn,
        @NotNull LocalDate checkOut,
        @NotNull @Min(1) Integer adults,
        @Min(0) Integer children,
        @Min(0) Integer extraBeds,
        Long ratePlanId,
        Long couponId,
        @Min(0) Long requestedPoints,
        @DecimalMin(value = "0.0") BigDecimal travelCreditAmountRequested,
        String giftCardCode
    ) {}

    /**
     * Travel-credit preview stage. There is NO existing travel-credit preview to
     * reuse (unlike coupon/loyalty/gift-card, which each own a read-only preview),
     * so this is the one small purpose-built shape for it: the customer's current
     * read-only balance, how much of it would apply to this quote
     * ({@code min(requested, balance, remainingPayable)}) and the resulting
     * remaining payable.
     */
    public record TravelCreditPreview(
        boolean eligible,
        String reason,
        BigDecimal availableBalance,
        BigDecimal appliedAmount,
        BigDecimal remainingPayable,
        String currency
    ) {}

    /**
     * Quote response. {@code baseQuote} is the UNCHANGED Phase 7.32
     * {@link RoomPricingQuoteResponse} (rate plan → promotion → pre-benefit
     * total) — reused verbatim, never re-flattened. Each benefit stage carries
     * the EXISTING preview shape of its owning service as a nested field
     * ({@code couponPreview}/{@code loyaltyPreview}/{@code giftCardPreview}) plus
     * the small purpose-built {@link TravelCreditPreview}; a stage is {@code null}
     * when its input was not supplied.
     *
     * <p>The stacking figures mirror the exact checkout order enforced by
     * {@code BookingService.create}:
     * {@code totalBeforeCustomerBenefits} → {@code afterCoupon} → {@code afterLoyalty}
     * → {@code afterTravelCredit} → {@code estimatedPayable}. When no rate plan is
     * eligible, every benefit stage and price field is {@code null} and
     * {@code eligibilityFailures} carries the base quote's reason.
     */
    public record CustomerPricingQuoteResponse(
        RoomPricingQuoteResponse baseQuote,
        // ── Benefit previews (null = not requested) ───────────────────────────
        CouponPreviewResponse couponPreview,
        RedemptionPreviewResponse loyaltyPreview,
        TravelCreditPreview travelCreditPreview,
        GiftCardPreviewResponse giftCardPreview,
        // ── Stacking figures (null when no rate plan is eligible) ─────────────
        BigDecimal totalBeforeCustomerBenefits,
        BigDecimal couponDiscount,
        BigDecimal afterCoupon,
        BigDecimal loyaltyDiscount,
        BigDecimal afterLoyalty,
        BigDecimal travelCreditApplied,
        BigDecimal afterTravelCredit,
        BigDecimal giftCardApplied,
        BigDecimal estimatedPayable,
        String currency,
        // ── Advisories ────────────────────────────────────────────────────────
        List<String> warnings,
        List<String> eligibilityFailures
    ) {}
}
