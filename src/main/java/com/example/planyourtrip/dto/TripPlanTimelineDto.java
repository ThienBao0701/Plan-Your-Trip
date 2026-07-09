package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.TripPlanReminderType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

public class TripPlanTimelineDto {

    /**
     * {@code type} is one of DAY, ITEM, DOCUMENT, REMINDER. {@code refId} is the id
     * of the underlying entity of that type. {@code status} is only populated for
     * REMINDER entries (PENDING/COMPLETED/CANCELLED).
     */
    public record TripTimelineItemResponse(
        String type,
        LocalDate date,
        LocalTime time,
        Long refId,
        String title,
        String description,
        Long tripDayId,
        String status
    ) {}

    public record TripTimelineResponse(
        Long tripPlanId,
        List<TripTimelineItemResponse> items
    ) {}

    public record TripPlanReminderRequest(
        Long tripDayId,
        Long tripItemId,
        Long documentId,
        @NotNull TripPlanReminderType reminderType,
        @NotBlank String title,
        String message,
        @NotNull Instant reminderAt
    ) {}

    public record TripPlanReminderResponse(
        Long id,
        Long tripPlanId,
        Long tripDayId,
        Long tripItemId,
        Long documentId,
        Long userId,
        String userName,
        String reminderType,
        String title,
        String message,
        Instant reminderAt,
        String status,
        Instant createdAt,
        Instant updatedAt,
        Instant completedAt
    ) {}
}
