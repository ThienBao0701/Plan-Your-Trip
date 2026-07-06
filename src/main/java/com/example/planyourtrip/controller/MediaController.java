package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.MediaDto.MediaAssetResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.MediaOwnerType;
import com.example.planyourtrip.model.PlaceStatus;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.service.MediaAssetService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/places")
@Tag(name = "Media", description = "Place media gallery")
public class MediaController {

    private final MediaAssetService mediaService;
    private final PlaceRepository places;

    public MediaController(MediaAssetService mediaService, PlaceRepository places) {
        this.mediaService = mediaService;
        this.places = places;
    }

    @GetMapping("/{placeId}/media")
    @Operation(summary = "List active media for a published place")
    public List<MediaAssetResponse> listMedia(@PathVariable Long placeId) {
        places.findByIdAndStatus(placeId, PlaceStatus.PUBLISHED)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Place not found: " + placeId));
        return mediaService.listActiveMedia(MediaOwnerType.PLACE, placeId);
    }
}
