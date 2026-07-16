package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.CancellationPolicyType;
import com.example.planyourtrip.model.MealPlanType;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

/**
 * Phase 7.32 — the canonical, frontend-oriented pricing quote contract.
 *
 * <p>A quote is a STATELESS, READ-ONLY projection of what checkout would charge for a stay
 * BEFORE any customer-specific benefit (coupon / loyalty / travel credit / gift card). It
 * reuses the exact rate-plan resolution ({@code RatePlanPricingService.resolveForBooking})
 * and promotion stage ({@code PricingEngineService}) used by booking creation, availability
 * search and the partner preview, so a quoted price is consistent with all of them. It never
 * creates a booking, reserves inventory, or mutates any ledger.
 */
public class RoomPricingQuoteDto {

    /**
     * Quote request body. All customer-specific benefit inputs are intentionally absent — a
     * public quote covers room / rate-plan / promotion pricing only (see phase 7.32 scope).
     */
    public record RoomPricingQuoteRequest(
        @NotNull LocalDate checkIn,
        @NotNull LocalDate checkOut,
        @NotNull @Min(1) Integer adults,
        @Min(0) Integer children,
        @Min(0) Integer extraBeds,
        /** Optional — when supplied the plan MUST belong to this room and be eligible (else 422). */
        Long ratePlanId
    ) {}

    /**
     * Quote response. Field semantics (documented for the frontend):
     * <ul>
     *   <li>{@code baseNightlyRate} … {@code extraBedSupplement} — per-night breakdown stages.</li>
     *   <li>{@code finalNightlyRate} — the resolved per-night price (base + derived + occupancy +
     *       child + extra-bed). PER-NIGHT figure.</li>
     *   <li>{@code staySubtotal} — {@code finalNightlyRate × nights}: the rate-plan subtotal for
     *       the whole stay BEFORE any promotion.</li>
     *   <li>{@code promotionDiscount} — promotion (marketing) discount applied to the subtotal.</li>
     *   <li>{@code totalBeforeCustomerBenefits} — {@code staySubtotal − promotionDiscount}: the
     *       total for the whole stay AFTER promotions but BEFORE coupon / loyalty / travel-credit /
     *       gift-card. This equals what {@code BookingService} treats as the order amount before the
     *       customer-discount chain.</li>
     *   <li>{@code finalQuotedPrice} — THE HEADLINE PRICE to display. Identical to
     *       {@code totalBeforeCustomerBenefits}; named separately so the frontend has a stable
     *       "headline" field. Coupon / loyalty / travel-credit / gift-card discounts are NOT yet
     *       included and are applied only at checkout.</li>
     * </ul>
     * When no rate plan is eligible for the stay, all price fields are {@code null},
     * {@code selectedRatePlanId} is {@code null} and {@code eligibilityReason} explains why.
     */
    public record RoomPricingQuoteResponse(
        Long roomId,
        String roomName,
        String roomCode,
        Long placeId,
        Long hotelId,
        LocalDate checkIn,
        LocalDate checkOut,
        int nights,
        int adults,
        int children,
        int extraBeds,
        // ── Selected rate plan ────────────────────────────────────────────────
        Long selectedRatePlanId,
        String selectedRatePlanCode,
        String selectedRatePlanName,
        MealPlanType mealPlanType,
        CancellationPolicyType cancellationPolicyType,
        Boolean refundable,
        Instant cancellationDeadline,
        // ── Per-night breakdown ───────────────────────────────────────────────
        BigDecimal baseNightlyRate,
        BigDecimal derivedAdjustment,
        BigDecimal occupancyAdjustment,
        BigDecimal childSupplement,
        BigDecimal extraBedSupplement,
        BigDecimal finalNightlyRate,
        // ── Stay totals ───────────────────────────────────────────────────────
        BigDecimal staySubtotal,
        BigDecimal promotionDiscount,
        BigDecimal totalBeforeCustomerBenefits,
        BigDecimal finalQuotedPrice,
        String currency,
        // ── Availability (read-only — no hold) ────────────────────────────────
        boolean inventoryAvailable,
        int availableRooms,
        // ── Quote metadata ────────────────────────────────────────────────────
        Instant quoteGeneratedAt,
        Instant quoteExpiresAt,
        List<String> warnings,
        String eligibilityReason
    ) {}
}
