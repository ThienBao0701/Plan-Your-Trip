package com.example.planyourtrip.dto;

import jakarta.validation.constraints.NotBlank;

import java.time.Instant;

public class AmenityDto {

    public record AmenityResponse(
        Long id,
        String name,
        String slug,
        String icon,
        String groupName,
        String description,
        Integer sortOrder,
        boolean active,
        Instant createdAt,
        Instant updatedAt
    ) {}

    public record AmenityRequest(
        @NotBlank String name,
        String slug,
        String icon,
        String groupName,
        String description,
        Integer sortOrder
    ) {}
}
