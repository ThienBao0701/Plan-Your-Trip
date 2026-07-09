package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.TripCollaboratorRole;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;
import java.time.LocalDate;

public class TripCollaborationDto {

    public record TripCollaboratorRequest(
        @NotBlank String email,
        @NotNull TripCollaboratorRole role
    ) {}

    public record TripCollaboratorResponse(
        Long id,
        Long tripPlanId,
        Long userId,
        String userEmail,
        String userFullName,
        String role,
        boolean active,
        Instant invitedAt,
        Instant acceptedAt,
        Instant createdAt,
        Instant updatedAt
    ) {}

    public record TripShareResponse(
        Long tripId,
        boolean isPublic
    ) {}

    public record SharedTripResponse(
        Long tripId,
        String title,
        String destination,
        String coverImage,
        LocalDate startDate,
        LocalDate endDate,
        String status,
        String ownerName,
        String role
    ) {}
}
