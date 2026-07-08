package com.example.planyourtrip.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

/**
 * DTOs for the Phase 7.4 itinerary planner. Named {@code TripPlanDto} (not
 * {@code TripDto}) to avoid colliding with the pre-existing, unrelated
 * {@code TripDto} flat record used by the earlier {@code Trip}/{@code TripController}
 * module mapped at {@code /api/trips}.
 */
public class TripPlanDto {

    public record TripItemResponse(
        Long id,
        Long placeId,
        String placeName,
        String placeSlug,
        String customTitle,
        String customDescription,
        LocalTime startTime,
        LocalTime endTime,
        int sortOrder,
        BigDecimal estimatedCost,
        Double latitude,
        Double longitude,
        String transportationNote,
        Instant createdAt
    ) {}

    public record TripDayResponse(
        Long id,
        int dayNumber,
        LocalDate date,
        String title,
        String notes,
        List<TripItemResponse> items
    ) {}

    public record TripResponse(
        Long id,
        Long userId,
        String title,
        String description,
        String destination,
        String coverImage,
        LocalDate startDate,
        LocalDate endDate,
        String status,
        boolean isPublic,
        List<TripDayResponse> days,
        Instant createdAt,
        Instant updatedAt
    ) {}

    public record TripSummaryResponse(
        Long id,
        String title,
        String destination,
        String coverImage,
        LocalDate startDate,
        LocalDate endDate,
        String status,
        boolean isPublic,
        long dayCount,
        Instant updatedAt
    ) {}

    public record TripRequest(
        @NotBlank String title,
        String description,
        String destination,
        String coverImage,
        @NotNull LocalDate startDate,
        @NotNull LocalDate endDate,
        String status,
        boolean isPublic
    ) {}

    public record TripDayRequest(
        @NotNull Integer dayNumber,
        LocalDate date,
        String title,
        String notes
    ) {}

    public record TripItemRequest(
        Long placeId,
        String customTitle,
        String customDescription,
        LocalTime startTime,
        LocalTime endTime,
        BigDecimal estimatedCost,
        Double latitude,
        Double longitude,
        String transportationNote
    ) {}

    public record MoveTripItemRequest(
        @NotNull Long targetDayId,
        Integer targetSortOrder
    ) {}

    public record ReorderTripDayRequest(
        @NotNull List<Long> orderedItemIds
    ) {}
}
