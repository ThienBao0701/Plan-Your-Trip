package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.dto.PlaceDetailResponse;
import com.example.planyourtrip.dto.PlaceDto.PlaceSummaryResponse;
import com.example.planyourtrip.service.PlaceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.*;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/places")
@Tag(name = "Places", description = "Public place discovery")
@Validated
public class PlaceController {

    private final PlaceService service;

    public PlaceController(PlaceService service) {
        this.service = service;
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
        return service.getDetailBySlug(slug);
    }

    @GetMapping("/{id}")
    @Operation(
        summary = "Get a published place by ID",
        description = "Returns full place detail including cover image, gallery, opening hours, openNow status, and similar places. Returns 404 if not found or not PUBLISHED."
    )
    public PlaceDetailResponse get(@PathVariable Long id) {
        return service.getDetail(id);
    }
}
