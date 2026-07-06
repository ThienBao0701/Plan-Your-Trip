package com.example.planyourtrip.dto;

import jakarta.validation.constraints.NotBlank;

import java.time.Instant;
import java.util.List;

public class CategoryDto {

    public record CategoryResponse(
        Long id,
        Long parentId,
        String name,
        String slug,
        String type,
        String icon,
        String color,
        String coverImageUrl,
        Integer sortOrder,
        boolean active,
        Instant createdAt,
        Instant updatedAt
    ) {}

    public record CategoryTreeResponse(
        Long id,
        Long parentId,
        String name,
        String slug,
        String type,
        String icon,
        String color,
        String coverImageUrl,
        Integer sortOrder,
        boolean active,
        List<CategoryTreeResponse> children
    ) {}

    public record CategoryRequest(
        Long parentId,
        @NotBlank String name,
        String slug,
        String type,
        String icon,
        String color,
        String coverImageUrl,
        Integer sortOrder
    ) {}
}
