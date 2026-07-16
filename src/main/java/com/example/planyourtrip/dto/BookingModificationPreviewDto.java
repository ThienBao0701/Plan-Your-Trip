package com.example.planyourtrip.dto;

import com.example.planyourtrip.dto.BookingDto.BookingSummaryResponse;
import com.example.planyourtrip.dto.CustomerPricingQuoteDto.CustomerPricingQuoteResponse;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Phase 7.35 — the READ-ONLY twin of the Phase 7.34 booking modification.
 *
 * <p>Where {@code BookingService.modify} MUTATES a PENDING booking (restore old inventory,
 * lock+decrement new, re-price, re-snapshot), this preview computes and RETURNS what WOULD happen
 * for the exact same {@link BookingDto.BookingModificationRequest} inputs — the new price, the
 * old→new totals and their difference (→ additional payment or refundable amount), the inventory
 * availability and any advisories — WITHOUT changing anything. It mirrors the established read-only
 * quote pattern of Phase 7.32 ({@link RoomPricingQuoteDto}) and Phase 7.33
 * ({@link CustomerPricingQuoteDto}): reuse the pricing services, compute-and-return, mutate nothing.
 */
public class BookingModificationPreviewDto {

    /**
     * Preview request body. The first six fields are IDENTICAL to
     * {@link BookingDto.BookingModificationRequest} (the Phase 7.34 mutate request) — every field is
     * OPTIONAL and an omitted (null) field keeps the booking's current value, so the preview mirrors
     * exactly the merge {@code modify()} performs. {@code extraBeds} is pricing-only (omitted → 0),
     * matching {@code modify()}.
     *
     * <p>The remaining four fields are OPTIONAL customer-benefit preview inputs, identical in
     * meaning to {@link CustomerPricingQuoteDto.CustomerPricingQuoteRequest}. They do NOT change what
     * {@code modify()} would set (the real modify applies no checkout benefit — its finalPrice is the
     * promotion-discounted total); they layer a hypothetical CHECKOUT benefit preview onto the
     * re-priced modification so the customer can also see what they might pay if they later applied
     * those benefits. The authoritative modify total (and the price difference) is the pre-benefit
     * total; the benefit-inclusive figure is surfaced separately as
     * {@code proposedPricing.estimatedPayable}.
     */
    public record BookingModificationPreviewRequest(
        LocalDate checkIn,
        LocalDate checkOut,
        @Min(1) Integer adults,
        @Min(0) Integer children,
        @Min(0) Integer extraBeds,
        Long ratePlanId,
        // ── Optional customer-benefit preview inputs (hypothetical checkout benefits) ──
        Long couponId,
        @Min(0) Long requestedPoints,
        @DecimalMin(value = "0.0") BigDecimal travelCreditAmountRequested,
        String giftCardCode
    ) {}

    /**
     * Preview response. Composes the existing response shapes as nested fields rather than
     * re-flattening them:
     * <ul>
     *   <li>{@code existingBooking} — the booking's CURRENT {@link BookingSummaryResponse}
     *       (unchanged; this is what it is today).</li>
     *   <li>{@code proposedBooking} — a {@link BookingSummaryResponse} projecting the booking AS IT
     *       WOULD BE after modify() (same id/code/hotel/room/createdAt, new dates/nights/status/
     *       finalPrice). Nothing is persisted.</li>
     *   <li>{@code proposedPricing} — the full Phase 7.33 {@link CustomerPricingQuoteResponse} for
     *       the new params: nightly breakdown, stay subtotal, promotion stage, the four benefit
     *       previews and the benefit-inclusive {@code estimatedPayable}. Reused verbatim.</li>
     * </ul>
     *
     * <p><b>Price difference semantics.</b> {@code oldTotal} is the booking's current finalPrice.
     * {@code estimatedTotal} is the pre-benefit total the modification would set (==
     * {@code proposedPricing.totalBeforeCustomerBenefits}, exactly what {@code modify()} writes to
     * finalPrice). {@code priceDifference = estimatedTotal − oldTotal}; a positive difference is
     * {@code additionalPayment}, a negative one is {@code refundableAmount} (the other is zero). No
     * payment is created. When no rate plan is eligible for the new params, the price fields are
     * {@code null} and {@code eligibilityFailures} carries the reason.
     *
     * <p><b>Room change is NOT supported</b> (Phase 7.34 modify changes only dates/occupancy/rate
     * plan on the SAME room), so {@code oldRoomId}/{@code newRoomId} are ALWAYS equal — the request
     * has no way to express a room change and the preview never implies one.
     *
     * <p>{@code inventoryAvailable}/{@code availableRooms} are the OVERLAP-ADJUSTED availability for
     * the new dates (this booking's own current hold is treated as released on nights shared with
     * the old range — the read-only net effect of modify()'s restore-then-check). This deliberately
     * OVERRIDES {@code proposedPricing.baseQuote}'s naive availability, which would undercount shared
     * nights.
     */
    public record BookingModificationPreviewResponse(
        Long bookingId,
        String bookingCode,
        String currentStatus,
        // ── Existing vs proposed summaries ────────────────────────────────────
        BookingSummaryResponse existingBooking,
        BookingSummaryResponse proposedBooking,
        // ── Room (unchanged — room change not supported) ──────────────────────
        Long oldRoomId, String oldRoomName,
        Long newRoomId, String newRoomName,
        // ── Dates ─────────────────────────────────────────────────────────────
        LocalDate oldCheckIn, LocalDate oldCheckOut,
        LocalDate newCheckIn, LocalDate newCheckOut,
        // ── Occupancy ─────────────────────────────────────────────────────────
        int oldAdults, int oldChildren,
        int newAdults, int newChildren,
        // ── Rate plan ─────────────────────────────────────────────────────────
        Long oldRatePlanId, String oldRatePlanName,
        Long newRatePlanId, String newRatePlanName,
        // ── Inventory (overlap-adjusted, read-only) ───────────────────────────
        boolean inventoryAvailable,
        int availableRooms,
        // ── Full proposed pricing (nightly breakdown + promotion + benefit previews) ──
        CustomerPricingQuoteResponse proposedPricing,
        BigDecimal subtotal,
        // ── Old → New → Difference (no actual payment) ────────────────────────
        BigDecimal oldTotal,
        BigDecimal estimatedTotal,
        BigDecimal priceDifference,
        BigDecimal additionalPayment,
        BigDecimal refundableAmount,
        String currency,
        // ── Advisories ────────────────────────────────────────────────────────
        List<String> warnings,
        List<String> eligibilityFailures
    ) {}
}
