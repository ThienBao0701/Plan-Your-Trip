package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.BedType;
import com.example.planyourtrip.model.RoomType;

import java.math.BigDecimal;
import java.util.List;

public class HotelSearchDto {

    public record MatchedRoomResponse(
        Long roomId,
        String roomName,
        RoomType roomType,
        BedType bedType,
        Integer maxGuests,
        BigDecimal priceFrom,
        BigDecimal originalPrice,
        Integer availableQuantity,
        boolean breakfastIncluded,
        boolean freeCancellation,
        String coverImageUrl
    ) {}

    public record HotelSearchResponse(
        Long placeId,
        String name,
        String slug,
        String address,
        String administrativeUnit,
        String googleMapUrl,
        Double latitude,
        Double longitude,
        double ratingAvg,
        int reviewCount,
        int starRating,
        Integer distanceToBeachMeters,
        String coverImageUrl,
        boolean featured,
        boolean verified,
        BigDecimal lowestPrice,
        String currency,
        int availableRooms,
        boolean freeCancellation,
        boolean breakfastIncluded,
        List<MatchedRoomResponse> matchedRooms
    ) {}
}
