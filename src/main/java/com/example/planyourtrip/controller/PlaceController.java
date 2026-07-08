package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.dto.PlaceDetailResponse;
import com.example.planyourtrip.dto.PlaceDto.PlaceSummaryResponse;
import com.example.planyourtrip.security.UserPrincipal;
import com.example.planyourtrip.service.PlaceService;
import com.example.planyourtrip.service.RecentlyViewedService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.*;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/places")
@Tag(name = "Places", description = "Public place discovery")
@Validated
public class PlaceController {

    private final PlaceService service;
    private final RecentlyViewedService recentlyViewedService;

    public PlaceController(PlaceService service, RecentlyViewedService recentlyViewedService) {
        this.service = service;
        this.recentlyViewedService = recentlyViewedService;
    }

    @GetMapping
    @Operation(summary = "List all published places")
    public List<PlaceSummaryResponse> list() {
        return service.listPublished();
    }

    @GetMapping("/search")
    @Operation(summary = "Search published places with filters and pagination")
    public PageResponse<PlaceSummaryResponse> search(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) String categorySlug,
            @RequestParam(required = false) Long subcategoryId,
            @RequestParam(required = false) Long locationId,
            @RequestParam(required = false) @DecimalMin("0") @DecimalMax("5") Double minRating,
            @RequestParam(required = false) @Min(0) @Max(4) Integer maxPriceLevel,
            @RequestParam(required = false) Boolean featured,
            @RequestParam(required = false) Boolean verified,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int size,
            @RequestParam(required = false) String sort) {
        return service.searchPublished(q, categoryId, categorySlug, subcategoryId, locationId,
                minRating, maxPriceLevel, featured, verified, page, size, sort);
    }

    @GetMapping("/slug/{slug}")
    @Operation(
        summary = "Get a published place by slug",
        description = "Returns full place detail including cover image, gallery, opening hours, openNow status, and similar places. Only PUBLISHED places are returned."
    )
    public PlaceDetailResponse getBySlug(@PathVariable String slug) {
        PlaceDetailResponse detail = service.getDetailBySlug(slug);
        recordViewIfAuthenticated(detail.id());
        return detail;
    }

    @GetMapping("/{id}")
    @Operation(
        summary = "Get a published place by ID",
        description = "Returns full place detail including cover image, gallery, opening hours, openNow status, and similar places. Returns 404 if not found or not PUBLISHED."
    )
    public PlaceDetailResponse get(@PathVariable Long id) {
        PlaceDetailResponse detail = service.getDetail(id);
        recordViewIfAuthenticated(detail.id());
        return detail;
    }

    /**
     * Best-effort view tracking for logged-in customers. Anonymous public detail
     * access must never be affected: no user, or any failure while recording the
     * view, is silently ignored so it can never break the detail response itself.
     */
    private void recordViewIfAuthenticated(Long placeId) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof UserPrincipal principal)) return;
        try {
            recentlyViewedService.recordView(principal.id(), placeId);
        } catch (RuntimeException ignored) {
            // Never let view-tracking failures break the public detail response.
        }
    }
}
