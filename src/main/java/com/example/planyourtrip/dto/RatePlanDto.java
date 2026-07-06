package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.BedType;
import com.example.planyourtrip.model.RatePlanType;
import com.example.planyourtrip.model.RoomType;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public class RatePlanDto {

    public record RatePlanRequest(
        @NotBlank String rateName,
        @NotNull RatePlanType rateType,
        @NotNull @DecimalMin("0.0") BigDecimal pricePerNight,
        @NotNull LocalDate startDate,
        @NotNull LocalDate endDate,
        Boolean active
    ) {}

    public record RatePlanResponse(
        Long id,
        Long roomId,
        String rateName,
        RatePlanType rateType,
        BigDecimal pricePerNight,
        LocalDate startDate,
        LocalDate endDate,
        boolean active,
        Instant createdAt,
        Instant updatedAt
    ) {}

    public record AvailableRoomResult(
        Long roomId,
        String roomName,
        String roomCode,
        RoomType roomType,
        BedType bedType,
        Integer bedCount,
        Integer maxAdults,
        Integer maxChildren,
        Integer maxGuests,
        Double roomSizeSqm,
        boolean breakfastIncluded,
        boolean freeCancellation,
        boolean instantConfirmation,
        BigDecimal pricePerNight,
        BigDecimal originalPricePerNight,
        BigDecimal totalPrice,
        int nights,
        String appliedRatePlan,
        String coverImageUrl,
        List<PlaceDto.AmenityRef> amenities
    ) {}

    public record HotelAvailabilityResponse(
        Long placeId,
        String placeName,
        LocalDate checkIn,
        LocalDate checkOut,
        int nights,
        int adults,
        int children,
        List<AvailableRoomResult> availableRooms
    ) {}
}
