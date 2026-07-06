package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.BedType;
import com.example.planyourtrip.model.RoomType;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public class HotelRoomDto {

    public record RoomImageRef(
        Long id,
        String url,
        String thumbnailUrl,
        String altText,
        int sortOrder,
        boolean cover
    ) {}

    public record HotelRoomRequest(
        Long placeId,
        @NotBlank String roomName,
        @NotBlank String roomCode,
        @NotNull RoomType roomType,
        String description,
        BedType bedType,
        @Min(1) Integer bedCount,
        @Min(1) Integer maxAdults,
        @Min(0) Integer maxChildren,
        @Min(1) Integer maxGuests,
        @DecimalMin("0.0") Double roomSizeSqm,
        Integer floorNumber,
        boolean smokingAllowed,
        boolean breakfastIncluded,
        boolean freeCancellation,
        boolean instantConfirmation,
        @DecimalMin("0.0") BigDecimal priceFrom,
        @DecimalMin("0.0") BigDecimal originalPrice,
        @Min(0) Integer quantity,
        @Min(0) Integer availableQuantity,
        Boolean active,
        List<String> amenitySlugs
    ) {}

    public record HotelRoomResponse(
        Long id,
        String roomName,
        String roomCode,
        RoomType roomType,
        String description,
        BedType bedType,
        Integer bedCount,
        Integer maxAdults,
        Integer maxChildren,
        Integer maxGuests,
        Double roomSizeSqm,
        Integer floorNumber,
        boolean smokingAllowed,
        boolean breakfastIncluded,
        boolean freeCancellation,
        boolean instantConfirmation,
        BigDecimal priceFrom,
        BigDecimal originalPrice,
        Integer quantity,
        Integer availableQuantity,
        boolean active,
        List<PlaceDto.AmenityRef> amenities,
        String coverImageUrl,
        List<RoomImageRef> galleryImages,
        Instant createdAt,
        Instant updatedAt
    ) {}
}
