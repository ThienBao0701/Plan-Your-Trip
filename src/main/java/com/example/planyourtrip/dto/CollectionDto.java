package com.example.planyourtrip.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.List;

/**
 * DTOs for the customer "Saved Collections" feature. The record names keep the spec's
 * "Collection" wording even though the backing JPA entities are {@code SavedCollection}
 * / {@code SavedCollectionPlace} (renamed to avoid the {@link java.util.Collection}
 * clash). Mirrors the record/validation style of {@code WishlistDto}.
 */
public class CollectionDto {

    public record CollectionRequest(
        @NotBlank @Size(max = 120) String name,
        @Size(max = 1000) String description,
        @Size(max = 2048) String coverImageUrl,
        Boolean privateCollection,
        Integer sortOrder
    ) {}

    public record CollectionSummaryResponse(
        Long id,
        String name,
        String description,
        String coverImageUrl,
        boolean privateCollection,
        int sortOrder,
        long placeCount,
        Instant createdAt,
        Instant updatedAt
    ) {}

    /** Place summary embedded in a collection's detail — real {@link com.example.planyourtrip.model.Place} fields only. */
    public record CollectionPlaceResponse(
        Long placeId,
        String name,
        String slug,
        String categoryName,
        String address,
        String shortDescription,
        double ratingAvg,
        int reviewCount,
        int position,
        Instant addedAt
    ) {}

    public record CollectionDetailResponse(
        Long id,
        String name,
        String description,
        String coverImageUrl,
        boolean privateCollection,
        int sortOrder,
        long placeCount,
        Instant createdAt,
        Instant updatedAt,
        List<CollectionPlaceResponse> places
    ) {}
}
