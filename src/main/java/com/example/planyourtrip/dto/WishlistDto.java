package com.example.planyourtrip.dto;

import jakarta.validation.constraints.NotNull;

import java.time.Instant;
import java.util.List;

public class WishlistDto {

    public record WishlistPlaceSummary(
        Long id,
        String name,
        String slug,
        String categoryName,
        String address,
        String shortDescription,
        double ratingAvg,
        int reviewCount
    ) {}

    public record WishlistItemResponse(
        Long id,
        WishlistPlaceSummary place,
        String note,
        Instant createdAt
    ) {}

    public record WishlistResponse(
        Long id,
        Long userId,
        List<WishlistItemResponse> items,
        Instant createdAt,
        Instant updatedAt
    ) {}

    public record AddWishlistItemRequest(
        @NotNull Long placeId,
        String note
    ) {}

    public record WishlistNoteRequest(
        String note
    ) {}
}
