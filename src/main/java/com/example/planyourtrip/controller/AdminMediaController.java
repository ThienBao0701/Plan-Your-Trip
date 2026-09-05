package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.MediaDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.MediaOwnerType;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.MediaAssetService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@Tag(name = "Admin - Media", description = "Admin media asset management")
@SecurityRequirement(name = "bearerAuth")
public class AdminMediaController {

    private final MediaAssetService mediaService;
    private final PlaceRepository places;

    public AdminMediaController(MediaAssetService mediaService, PlaceRepository places) {
        this.mediaService = mediaService;
        this.places = places;
    }

    @GetMapping("/api/admin/places/{placeId}/media")
    @Operation(summary = "List all media for a place (admin, includes inactive)")
    public List<MediaAssetResponse> listMedia(@PathVariable Long placeId) {
        places.findById(placeId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Place not found: " + placeId));
        return mediaService.listAllMedia(MediaOwnerType.PLACE, placeId);
    }

    @PostMapping("/api/admin/media")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a media asset")
    public MediaAssetResponse create(
            @Valid @RequestBody MediaAssetRequest req,
            @AuthUser Long adminId) {
        return mediaService.adminCreate(adminId, req);
    }

    @PutMapping("/api/admin/media/{id}")
    @Operation(summary = "Update a media asset")
    public MediaAssetResponse update(
            @AuthUser Long adminId,
            @PathVariable Long id,
            @Valid @RequestBody MediaAssetRequest req) {
        return mediaService.update(adminId, id, req);
    }

    @PatchMapping("/api/admin/media/{id}/deactivate")
    @Operation(summary = "Deactivate a media asset (soft delete)")
    public MediaAssetResponse deactivate(@AuthUser Long adminId, @PathVariable Long id) {
        return mediaService.adminDeactivate(adminId, id);
    }

    @PatchMapping("/api/admin/media/cover")
    @Operation(summary = "Set cover media for an owner (unsets previous cover)")
    public MediaAssetResponse setCover(@AuthUser Long adminId,
                                       @Valid @RequestBody MediaCoverRequest req) {
        return mediaService.setCover(adminId, req);
    }

    @PatchMapping("/api/admin/media/reorder")
    @Operation(summary = "Reorder media assets (all must belong to same owner)")
    public List<MediaAssetResponse> reorder(@AuthUser Long adminId,
                                            @Valid @RequestBody MediaReorderRequest req) {
        return mediaService.reorder(adminId, req);
    }
}
