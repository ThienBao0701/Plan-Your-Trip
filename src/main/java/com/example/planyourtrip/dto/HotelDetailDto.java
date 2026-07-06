package com.example.planyourtrip.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;
import java.time.LocalTime;
import java.util.List;

public class HotelDetailDto {

    public record HotelDetailRequest(
        Long placeId,
        @Min(1) @Max(5) int starRating,
        @NotNull LocalTime checkInTime,
        @NotNull LocalTime checkOutTime,
        @Min(0) Integer distanceToBeachMeters,
        @Min(0) Integer distanceToCityCenterMeters,
        @Min(0) Integer totalRooms,
        @Min(0) Integer availableRooms,
        boolean freeCancellation,
        String cancellationPolicy,
        boolean prepaymentRequired,
        String paymentPolicy,
        String childrenPolicy,
        String petPolicy,
        String smokingPolicy,
        boolean breakfastIncluded,
        boolean airportShuttle
    ) {}

    public record HotelDetailResponse(
        Long id,
        int starRating,
        LocalTime checkInTime,
        LocalTime checkOutTime,
        Integer distanceToBeachMeters,
        Integer distanceToCityCenterMeters,
        Integer totalRooms,
        Integer availableRooms,
        boolean freeCancellation,
        String cancellationPolicy,
        boolean prepaymentRequired,
        String paymentPolicy,
        String childrenPolicy,
        String petPolicy,
        String smokingPolicy,
        boolean breakfastIncluded,
        boolean airportShuttle,
        Instant createdAt,
        Instant updatedAt,
        List<HotelExperienceDto.FacilityResponse> facilities,
        List<HotelExperienceDto.ServiceResponse> services,
        List<String> languages,
        List<String> paymentMethods,
        HotelExperienceDto.ParkingInfo parking,
        HotelExperienceDto.InternetInfo internet,
        List<HotelRoomDto.HotelRoomResponse> rooms
    ) {}
}
