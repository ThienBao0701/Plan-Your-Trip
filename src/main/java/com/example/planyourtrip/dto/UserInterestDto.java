package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.AccessibilityLevel;
import com.example.planyourtrip.model.BudgetLevel;
import com.example.planyourtrip.model.CrowdLevel;
import com.example.planyourtrip.model.TravelStyle;
import com.example.planyourtrip.model.WeatherType;

import java.time.Instant;
import java.util.List;

/**
 * Phase 7.48 — response DTOs for the read-only User Interest Profile.
 */
public final class UserInterestDto {

    private UserInterestDto() {}

    /**
     * The derived interest profile for the acting user. All list fields are deterministic,
     * de-duplicated top-N summaries. Enum modes are null when no signal carried that dimension.
     * {@code lastRecalculatedAt} is null until the first recalculation.
     */
    public record InterestProfileResponse(
        Long userId,
        List<TravelStyle> preferredTravelStyles,
        List<WeatherType> preferredWeatherTypes,
        BudgetLevel preferredBudgetLevel,
        CrowdLevel preferredCrowdLevel,
        AccessibilityLevel preferredAccessibilityLevel,
        List<String> favoriteProvinces,
        List<String> favoriteCategories,
        List<String> favoriteTags,
        int signalCount,
        Instant lastRecalculatedAt
    ) {}
}
