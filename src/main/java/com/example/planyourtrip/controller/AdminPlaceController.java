package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.dto.PlaceDetailResponse;
import com.example.planyourtrip.dto.PlaceDto.*;
import com.example.planyourtrip.dto.PlaceMetadataDto.PlaceMetadataRequest;
import com.example.planyourtrip.dto.PlaceMetadataDto.PlaceMetadataResponse;
import com.example.planyourtrip.model.PlaceStatus;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.PlaceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.http.HttpStatus;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/places")
@Tag(name = "Admin - Places", description = "Admin place management")
@SecurityRequirement(name = "bearerAuth")
@Validated
public class AdminPlaceController {

    private final PlaceService service;

    public AdminPlaceController(PlaceService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "Search/list places (all statuses, paginated)")
    public PageResponse<PlaceSummaryResponse> list(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) PlaceStatus status,
            @RequestParam(required = false) Long locationId,
            @RequestParam(required = false) Boolean featured,
            @RequestParam(required = false) Boolean verified,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int size,
            @RequestParam(required = false) String sort) {
        return service.searchAdmin(q, categoryId, status, locationId, featured, verified, page, size, sort);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get a place by ID (any status)")
    public PlaceDetailResponse getById(@PathVariable Long id) {
        return service.getAdminDetail(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a place")
    public PlaceResponse create(@Valid @RequestBody PlaceRequest req, @AuthUser Long adminId) {
        return service.create(req, adminId);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update a place")
    public PlaceResponse update(@PathVariable Long id, @Valid @RequestBody PlaceRequest req) {
        return service.update(id, req);
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Update place status (validates allowed transitions)")
    public PlaceResponse updateStatus(
            @PathVariable Long id,
            @Valid @RequestBody PlaceStatusRequest req,
            @AuthUser Long adminId) {
        return service.updateStatus(id, req.status(), adminId);
    }

    @PatchMapping("/{id}/featured")
    @Operation(summary = "Set featured flag (APPROVED or PUBLISHED only)")
    public PlaceResponse updateFeatured(@PathVariable Long id, @RequestBody PlaceFlagRequest req) {
        return service.updateFeatured(id, req.value());
    }

    @PatchMapping("/{id}/verified")
    @Operation(summary = "Set verified flag (APPROVED or PUBLISHED only)")
    public PlaceResponse updateVerified(@PathVariable Long id, @RequestBody PlaceFlagRequest req) {
        return service.updateVerified(id, req.value());
    }

    @PutMapping("/{id}/metadata")
    @Operation(summary = "Upsert place metadata (recommendation signals)")
    public PlaceMetadataResponse upsertMetadata(
            @PathVariable Long id,
            @Valid @RequestBody PlaceMetadataRequest req) {
        return service.upsertMetadata(id, req);
    }
}
