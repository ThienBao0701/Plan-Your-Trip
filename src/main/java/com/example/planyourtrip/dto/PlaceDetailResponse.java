package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.PlaceStatus;
import java.time.LocalTime;
import java.util.List;

public record PlaceDetailResponse(
    Long id,
    String name,
    String slug,
    String shortDescription,
    String description,
    String address,
    String googleMapUrl,
    Double latitude,
    Double longitude,
    PlaceDto.CategoryRef category,
    PlaceDto.CategoryRef subcategory,
    PlaceDto.LocationRef location,
    double ratingAvg,
    int ratingCount,
    int priceLevel,
    boolean featured,
    boolean verified,
    PlaceStatus status,
    List<PlaceDto.PlaceTagResponse> tags,
    List<PlaceDto.AmenityRef> amenities,
    List<PlaceDto.PlaceOpeningHourResponse> openingHours,
    List<OpeningHourGroupResponse> groupedOpeningHours,
    String coverImageUrl,
    List<ImageRef> galleryImages,
    boolean openNow,
    List<PlaceDto.PlaceSummaryResponse> similarPlaces,
    PlaceMetadataDto.PlaceMetadataResponse metadata,
    HotelDetailDto.HotelDetailResponse hotelDetail
) {
    public record OpeningHourGroupResponse(
        String days,
        LocalTime openTime,
        LocalTime closeTime,
        boolean closed
    ) {}

    public record ImageRef(
        Long id,
        String url,
        String thumbnailUrl,
        String altText,
        int sortOrder,
        boolean cover
    ) {}
}
