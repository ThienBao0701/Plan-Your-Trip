package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.TripPlanPackingCategory;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;
import java.util.List;

public class TripPlanPackingDto {

    public record TripPlanPackingItemRequest(
        @NotBlank String label,
        @NotNull TripPlanPackingCategory category,
        @Min(1) int quantity,
        Long assignedToUserId,
        String notes
    ) {}

    public record TripPlanPackingItemResponse(
        Long id,
        Long tripPlanId,
        String label,
        String category,
        int quantity,
        boolean checked,
        Long assignedToUserId,
        String assignedToUserName,
        String notes,
        int sortOrder,
        Instant createdAt,
        Instant updatedAt,
        Instant checkedAt
    ) {}

    public record TripPlanPackingReorderRequest(
        @NotNull List<Long> orderedItemIds
    ) {}
}
