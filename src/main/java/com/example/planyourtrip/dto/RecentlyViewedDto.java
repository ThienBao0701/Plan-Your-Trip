package com.example.planyourtrip.dto;

import java.time.Instant;
import java.util.List;

public class RecentlyViewedDto {

    public record RecentlyViewedItemResponse(
        Long placeId,
        String name,
        String slug,
        String categoryName,
        String address,
        String shortDescription,
        double ratingAvg,
        int reviewCount,
        Instant viewedAt
    ) {}

    public record RecentlyViewedResponse(
        List<RecentlyViewedItemResponse> items
    ) {}
}
