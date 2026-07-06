package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.*;
import jakarta.validation.constraints.Min;

import java.time.Instant;
import java.util.List;

public class PlaceMetadataDto {

    public record PlaceMetadataRequest(
        List<TravelStyle> travelStyles,
        List<BestVisitTime> bestVisitTimes,
        List<BestSeason> bestSeasons,
        List<WeatherType> weatherTypes,
        @Min(0) Integer estimatedVisitMinutes,
        BudgetLevel estimatedBudgetLevel,
        DifficultyLevel difficultyLevel,
        AccessibilityLevel accessibilityLevel,
        CrowdLevel crowdLevel,
        boolean romantic,
        boolean familyFriendly,
        boolean kidFriendly,
        boolean petFriendly,
        boolean wheelchairFriendly,
        boolean photographySpot,
        boolean sunsetSpot,
        boolean sunriseSpot,
        boolean indoor,
        boolean outdoor,
        boolean rainyDaySuitable,
        String notes
    ) {}

    public record PlaceMetadataResponse(
        Long id,
        List<TravelStyle> travelStyles,
        List<BestVisitTime> bestVisitTimes,
        List<BestSeason> bestSeasons,
        List<WeatherType> weatherTypes,
        Integer estimatedVisitMinutes,
        BudgetLevel estimatedBudgetLevel,
        DifficultyLevel difficultyLevel,
        AccessibilityLevel accessibilityLevel,
        CrowdLevel crowdLevel,
        boolean romantic,
        boolean familyFriendly,
        boolean kidFriendly,
        boolean petFriendly,
        boolean wheelchairFriendly,
        boolean photographySpot,
        boolean sunsetSpot,
        boolean sunriseSpot,
        boolean indoor,
        boolean outdoor,
        boolean rainyDaySuitable,
        String notes,
        Instant createdAt,
        Instant updatedAt
    ) {}
}
