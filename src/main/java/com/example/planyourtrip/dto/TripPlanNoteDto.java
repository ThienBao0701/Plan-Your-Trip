package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.TripPlanMood;
import com.example.planyourtrip.model.TripPlanNoteType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;

public class TripPlanNoteDto {

    public record TripPlanNoteRequest(
        Long tripDayId,
        Long tripItemId,
        @NotNull TripPlanNoteType noteType,
        String title,
        @NotBlank String content,
        TripPlanMood mood,
        String photoUrl
    ) {}

    public record TripPlanNoteResponse(
        Long id,
        Long tripPlanId,
        Long tripDayId,
        Long tripItemId,
        Long authorUserId,
        String authorUserName,
        String noteType,
        String title,
        String content,
        String mood,
        String photoUrl,
        boolean pinned,
        Instant createdAt,
        Instant updatedAt
    ) {}
}
