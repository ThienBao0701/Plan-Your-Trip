package com.example.planyourtrip.dto;

import com.example.planyourtrip.dto.PlaceDto.PlaceSummaryResponse;
import com.example.planyourtrip.model.AccessibilityLevel;
import com.example.planyourtrip.model.BudgetLevel;
import com.example.planyourtrip.model.CrowdLevel;
import com.example.planyourtrip.model.TravelStyle;
import com.example.planyourtrip.model.WeatherType;

import java.util.List;

/**
 * Phase 7.49 — response DTOs for the deterministic, profile-driven Recommendation Engine
 * ({@code GET /api/me/recommendations/engine}).
 *
 * <p>Distinct from the Phase 7.23 {@code CustomerRecommendationResponse} (which describes a
 * persisted, rule-generated, engagement-tracked snapshot). This DTO describes a live scoring result:
 * a place summary plus its 0–100 score, a 0–100 confidence, and the exact interest dimensions that
 * matched, with human-readable reasons. No new place DTO is introduced — the embedded summary reuses
 * {@link PlaceSummaryResponse}.
 */
public final class RecommendationEngineDto {

    private RecommendationEngineDto() {}

    public record RecommendationResponse(
        PlaceSummaryResponse place,
        int score,
        int confidence,
        List<String> reasons,
        List<TravelStyle> matchedTravelStyles,
        BudgetLevel matchedBudget,
        String matchedProvince,
        List<String> matchedCategories,
        List<String> matchedTags,
        List<WeatherType> matchedWeatherTypes,
        CrowdLevel matchedCrowdLevel,
        AccessibilityLevel matchedAccessibilityLevel
    ) {}
}
