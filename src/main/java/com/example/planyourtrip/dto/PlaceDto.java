package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.PlaceStatus;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.time.Instant;
import java.time.LocalTime;
import java.util.List;

public class PlaceDto {

    public record CategoryRef(Long id, String name, String slug, String type, String icon, String color) {}

    public record LocationRef(Long id, String name, String slug, String fullPath) {}

    public record AmenityRef(Long id, String name, String slug, String icon, String groupName) {}

    public record PlaceTagResponse(Long id, String tag) {}

    public record PlaceOpeningHourResponse(
        Long id,
        int dayOfWeek,
        LocalTime openTime,
        LocalTime closeTime,
        boolean closed
    ) {}

    public record PlaceOpeningHourRequest(
        @Min(1) @Max(7) int dayOfWeek,
        LocalTime openTime,
        LocalTime closeTime,
        boolean closed
    ) {}

    public record PlaceStatusRequest(@NotNull PlaceStatus status) {}

    public record PlaceFlagRequest(boolean value) {}

    public record PlaceRequest(
        @NotBlank String name,
        @NotNull Long categoryId,
        Long subcategoryId,
        @NotNull Long administrativeUnitId,
        @NotBlank String address,
        @Size(max = 500) String googleMapUrl,
        Double latitude,
        Double longitude,
        @Size(max = 500) String shortDescription,
        String description,
        @Min(0) @Max(4) int priceLevel,
        Long ownerUserId,
        boolean featured,
        boolean verified,
        PlaceStatus status,
        List<String> tags,
        List<Long> amenityIds,
        @Valid List<PlaceOpeningHourRequest> openingHours
    ) {}

    public record PlaceSummaryResponse(
        Long id,
        String name,
        String slug,
        CategoryRef category,
        CategoryRef subcategory,
        LocationRef administrativeUnit,
        String address,
        String googleMapUrl,
        Double latitude,
        Double longitude,
        String shortDescription,
        int priceLevel,
        double ratingAvg,
        int reviewCount,
        PlaceStatus status,
        boolean featured,
        boolean verified,
        String coverImageUrl,
        Instant createdAt
    ) {}

    public record PlaceResponse(
        Long id,
        String name,
        String slug,
        CategoryRef category,
        CategoryRef subcategory,
        LocationRef administrativeUnit,
        String address,
        String googleMapUrl,
        Double latitude,
        Double longitude,
        String shortDescription,
        String description,
        int priceLevel,
        double ratingAvg,
        int reviewCount,
        PlaceStatus status,
        boolean featured,
        boolean verified,
        List<PlaceTagResponse> tags,
        List<AmenityRef> amenities,
        List<PlaceOpeningHourResponse> openingHours,
        Instant createdAt,
        Instant updatedAt
    ) {}
}
