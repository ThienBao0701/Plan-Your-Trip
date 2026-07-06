package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.UnitType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;

public class LocationDto {

    public record LocationResponse(
        Long id,
        Long parentId,
        String code,
        String name,
        String slug,
        String type,
        Integer level,
        String oldName,
        String fullPath,
        Double latitude,
        Double longitude,
        Integer sortOrder,
        boolean active,
        Instant createdAt,
        Instant updatedAt
    ) {}

    public record LocationRequest(
        Long parentId,
        String code,
        @NotBlank String name,
        String slug,
        @NotNull UnitType type,
        Integer level,
        String oldName,
        String fullPath,
        Double latitude,
        Double longitude,
        Integer sortOrder
    ) {}
}
