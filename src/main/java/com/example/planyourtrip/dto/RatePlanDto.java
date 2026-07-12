package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.BedType;
import com.example.planyourtrip.model.CancellationPolicyType;
import com.example.planyourtrip.model.MealPlanType;
import com.example.planyourtrip.model.RateAdjustmentType;
import com.example.planyourtrip.model.RatePlanType;
import com.example.planyourtrip.model.RateSourceType;
import com.example.planyourtrip.model.RoomType;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public class RatePlanDto {

    /**
     * Rate-plan create/update payload.
     *
     * <p>Phase 7.29 extends this ADDITIVELY: the original six fields are unchanged and
     * every new field is optional (defaulted when absent), so a pre-7.29 payload
     * {@code {rateName, rateType, pricePerNight, startDate, endDate, active}} still works.
     */
    public record RatePlanRequest(
        @NotBlank String rateName,
        @NotNull RatePlanType rateType,
        @NotNull @DecimalMin("0.0") BigDecimal pricePerNight,
        @NotNull LocalDate startDate,
        @NotNull LocalDate endDate,
        Boolean active,
        // ── Phase 7.29 additive fields (all optional) ─────────────────────────
        String code,
        String description,
        MealPlanType mealPlanType,
        CancellationPolicyType cancellationPolicyType,
        Integer cancellationDeadlineHours,
        BigDecimal cancellationPenaltyPercent,
        Boolean refundable,
        RateSourceType sourceType,
        Long parentRatePlanId,
        RateAdjustmentType adjustmentType,
        BigDecimal adjustmentValue,
        Integer priority,
        Integer minStayNights,
        Integer maxStayNights,
        Integer minAdvanceBookingDays,
        Integer maxAdvanceBookingDays,
        Boolean closedToArrival,
        Boolean closedToDeparture,
        Boolean occupancyPricingEnabled,
        Boolean childPricingEnabled,
        BigDecimal extraBedPrice
    ) {}

    public record RatePlanResponse(
        Long id,
        Long roomId,
        String rateName,
        RatePlanType rateType,
        BigDecimal pricePerNight,
        LocalDate startDate,
        LocalDate endDate,
        boolean active,
        Instant createdAt,
        Instant updatedAt,
        // ── Phase 7.29 additive fields ────────────────────────────────────────
        String code,
        String description,
        MealPlanType mealPlanType,
        CancellationPolicyType cancellationPolicyType,
        Integer cancellationDeadlineHours,
        BigDecimal cancellationPenaltyPercent,
        boolean refundable,
        RateSourceType sourceType,
        Long parentRatePlanId,
        RateAdjustmentType adjustmentType,
        BigDecimal adjustmentValue,
        int priority,
        Integer minStayNights,
        Integer maxStayNights,
        Integer minAdvanceBookingDays,
        Integer maxAdvanceBookingDays,
        boolean closedToArrival,
        boolean closedToDeparture,
        boolean occupancyPricingEnabled,
        boolean childPricingEnabled,
        BigDecimal extraBedPrice
    ) {}

    // ── Occupancy pricing ─────────────────────────────────────────────────────

    public record RatePlanOccupancyPriceRequest(
        @NotNull Integer adults,
        @NotNull Integer children,
        @NotNull @DecimalMin("0.0") BigDecimal pricePerNight,
        BigDecimal childSupplement,
        BigDecimal extraBedSupplement
    ) {}

    public record RatePlanOccupancyPriceResponse(
        Long id,
        Long ratePlanId,
        int adults,
        int children,
        BigDecimal pricePerNight,
        BigDecimal childSupplement,
        BigDecimal extraBedSupplement,
        Instant createdAt,
        Instant updatedAt
    ) {}

    // ── Eligibility & pricing preview ─────────────────────────────────────────

    public record RatePlanEligibilityRequest(
        @NotNull LocalDate checkIn,
        @NotNull LocalDate checkOut,
        Integer adults,
        Integer children,
        Integer extraBeds
    ) {}

    public record RatePlanEligibilityResponse(
        Long ratePlanId,
        String code,
        String rateName,
        boolean eligible,
        String reason
    ) {}

    /** Full pricing + eligibility + terms breakdown for a single rate plan and stay. */
    public record RatePlanPricingBreakdownResponse(
        Long ratePlanId,
        String code,
        String rateName,
        Long roomId,
        String roomName,
        RateSourceType sourceType,
        Long parentRatePlanId,
        boolean eligible,
        String reason,
        int nights,
        BigDecimal baseNightlyRate,
        BigDecimal derivedAdjustment,
        BigDecimal occupancyAdjustment,
        BigDecimal childSupplement,
        BigDecimal extraBedSupplement,
        BigDecimal finalNightlyRate,
        BigDecimal staySubtotal,
        MealPlanType mealPlan,
        CancellationPolicyType cancellationPolicy,
        boolean refundable,
        Instant cancellationDeadline,
        String policySummary
    ) {}

    /** Preview of the cancellation penalty for a stay under a plan's policy. */
    public record RatePlanCancellationPreviewResponse(
        Long ratePlanId,
        CancellationPolicyType cancellationPolicy,
        boolean refundable,
        Instant cancellationDeadline,
        boolean pastDeadline,
        BigDecimal staySubtotal,
        BigDecimal penaltyAmount,
        BigDecimal refundAmount,
        String policySummary
    ) {}

    public record RatePlanDuplicateRequest(
        String rateName,
        String code
    ) {}

    // ── Availability search (unchanged from earlier phases) ───────────────────

    public record AvailableRoomResult(
        Long roomId,
        String roomName,
        String roomCode,
        RoomType roomType,
        BedType bedType,
        Integer bedCount,
        Integer maxAdults,
        Integer maxChildren,
        Integer maxGuests,
        Double roomSizeSqm,
        boolean breakfastIncluded,
        boolean freeCancellation,
        boolean instantConfirmation,
        BigDecimal pricePerNight,
        BigDecimal originalPricePerNight,
        BigDecimal totalPrice,
        int nights,
        String appliedRatePlan,
        String coverImageUrl,
        List<PlaceDto.AmenityRef> amenities
    ) {}

    public record HotelAvailabilityResponse(
        Long placeId,
        String placeName,
        LocalDate checkIn,
        LocalDate checkOut,
        int nights,
        int adults,
        int children,
        List<AvailableRoomResult> availableRooms
    ) {}
}
