package com.example.planyourtrip.dto;

import com.example.planyourtrip.dto.CouponDto.CouponDefinitionResponse;
import com.example.planyourtrip.dto.HotelRoomDto.HotelRoomResponse;
import com.example.planyourtrip.dto.PlaceDto.PlaceSummaryResponse;
import com.example.planyourtrip.dto.PromotionDto.PromotionResponse;
import com.example.planyourtrip.model.MembershipTier;
import com.example.planyourtrip.model.PersonalizationRuleType;
import com.example.planyourtrip.model.RecommendationReasonCode;
import com.example.planyourtrip.model.RecommendationType;
import com.example.planyourtrip.model.TravelStyle;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/**
 * Phase 7.23 — Personalized Offers &amp; Rule-Based Recommendations.
 * Single-file record style, mirroring {@code ReferralDto}/{@code CouponDto}.
 * Recommendation target summaries deliberately REUSE the existing response
 * records ({@link PlaceSummaryResponse}, {@link HotelRoomResponse},
 * {@link PromotionResponse}, {@link CouponDefinitionResponse}) rather than
 * introducing parallel mapping logic — exactly one target field is populated per
 * recommendation, matching its {@link RecommendationType}.
 */
public class PersonalizationDto {

    // ── Admin: personalization rule ───────────────────────────────────────────

    public record PersonalizationRuleRequest(
        @NotBlank String ruleCode,
        @NotBlank String name,
        String description,
        @NotNull PersonalizationRuleType ruleType,
        Integer priority,
        Boolean active,
        Instant validFrom,
        Instant validUntil,
        MembershipTier minimumMembershipTier,
        String targetPlaceType,
        Long targetPlaceId,
        Long targetHotelId,
        Long targetPromotionId,
        Long targetCouponDefinitionId,
        String configurationJson
    ) {}

    public record PersonalizationRuleResponse(
        Long id,
        String ruleCode,
        String name,
        String description,
        PersonalizationRuleType ruleType,
        int priority,
        boolean active,
        Instant validFrom,
        Instant validUntil,
        MembershipTier minimumMembershipTier,
        String targetPlaceType,
        Long targetPlaceId,
        Long targetHotelId,
        Long targetPromotionId,
        Long targetCouponDefinitionId,
        String configurationJson,
        Instant createdAt,
        Instant updatedAt,
        Long version
    ) {}

    // ── Customer: recommendation snapshot ─────────────────────────────────────

    public record CustomerRecommendationResponse(
        Long id,
        RecommendationType type,
        int score,
        RecommendationReasonCode reasonCode,
        String reasonText,
        Instant generatedAt,
        Instant expiresAt,
        String engagementState,      // ACTIVE / CLICKED / CONVERTED / DISMISSED / EXPIRED
        Instant dismissedAt,
        Instant clickedAt,
        Instant convertedAt,
        Long sourceRuleId,
        String sourceRuleCode,
        String targetSummary,        // short human-readable label of the target
        PlaceSummaryResponse place,
        PlaceSummaryResponse hotel,
        HotelRoomResponse room,
        PromotionResponse promotion,
        CouponDefinitionResponse coupon,
        String metadataJson
    ) {}

    // ── Customer: generation result ───────────────────────────────────────────

    public record RecommendationGenerationResponse(
        int generatedCount,
        int totalActive,
        Instant generatedAt,
        List<CustomerRecommendationResponse> recommendations
    ) {}

    // ── Customer: summary metrics ─────────────────────────────────────────────

    public record RecommendationSummaryResponse(
        long totalActive,
        long placeRecommendations,
        long hotelRecommendations,
        long roomRecommendations,
        long promotionRecommendations,
        long couponRecommendations,
        long tripIdeaRecommendations,
        long dismissedCount,
        long clickedCount,
        long convertedCount,
        String topDestination,
        RecommendationType strongestInterestType,
        Instant lastGeneratedAt
    ) {}

    // ── Customer: preference profile (computed signals) ───────────────────────

    public record CustomerPreferenceProfileResponse(
        Long userId,
        List<String> savedDestinations,
        List<String> savedPlaceTypes,
        List<TravelStyle> savedTravelStyles,
        List<String> recentDestinations,
        List<String> bookedDestinations,
        BigDecimal averageBookingValue,
        Integer preferredHotelStarRating,
        Integer typicalStayLengthNights,
        Instant lastBookingDate,
        String profileTravelStyle,
        String preferredLanguage,
        String preferredCurrency,
        String accessibilityNeeds,
        String dietaryPreference,
        MembershipTier membershipTier,
        boolean loyaltyActive,
        Long loyaltyPointsBalance,
        List<String> activePlanningDestinations,
        int wishlistItemCount,
        int recentlyViewedCount,
        int bookingCount
    ) {}

    // ── Customer: why-recommended explanation ─────────────────────────────────

    public record RecommendationReasonResponse(
        Long recommendationId,
        RecommendationType type,
        RecommendationReasonCode reasonCode,
        String reasonText,
        int score,
        Long sourceRuleId,
        String sourceRuleCode
    ) {}
}
