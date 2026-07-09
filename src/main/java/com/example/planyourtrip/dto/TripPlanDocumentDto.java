package com.example.planyourtrip.dto;

import com.example.planyourtrip.dto.MediaDto.MediaAssetResponse;
import com.example.planyourtrip.model.MediaType;
import com.example.planyourtrip.model.TripPlanDocumentType;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;

public class TripPlanDocumentDto {

    /**
     * Either {@code mediaAssetId} (reuse an already-uploaded {@link com.example.planyourtrip.model.MediaAsset})
     * or {@code url} (register a new one, via the existing {@code MediaAssetService})
     * must be provided. On update, media-registration fields are ignored — only
     * document metadata (type/title/notes/day/item links) can change.
     */
    public record TripPlanDocumentRequest(
        Long tripDayId,
        Long tripItemId,
        Long mediaAssetId,
        String url,
        String thumbnailUrl,
        MediaType mediaType,
        String altText,
        @NotNull TripPlanDocumentType documentType,
        String title,
        String notes
    ) {}

    public record TripPlanDocumentResponse(
        Long id,
        Long tripPlanId,
        Long tripDayId,
        Long tripItemId,
        MediaAssetResponse mediaAsset,
        Long uploadedByUserId,
        String uploadedByUserName,
        String documentType,
        String title,
        String notes,
        boolean pinned,
        Instant createdAt,
        Instant updatedAt
    ) {}
}
