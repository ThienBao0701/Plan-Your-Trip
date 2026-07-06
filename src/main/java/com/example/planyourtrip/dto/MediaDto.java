package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.MediaOwnerType;
import com.example.planyourtrip.model.MediaType;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.time.Instant;
import java.util.List;

public class MediaDto {

    public record MediaAssetRequest(
        @NotNull MediaOwnerType ownerType,
        @NotNull Long ownerId,
        @NotBlank String url,
        String thumbnailUrl,
        @NotNull MediaType mediaType,
        String altText,
        @Min(0) Integer sortOrder,
        Boolean cover
    ) {}

    public record MediaAssetResponse(
        Long id,
        MediaOwnerType ownerType,
        Long ownerId,
        String url,
        String thumbnailUrl,
        MediaType mediaType,
        String altText,
        int sortOrder,
        boolean cover,
        boolean active,
        Long uploadedByUserId,
        Instant createdAt,
        Instant updatedAt
    ) {}

    public record MediaReorderRequest(
        @NotEmpty @Valid List<MediaOrderItem> items
    ) {
        public record MediaOrderItem(
            @NotNull Long mediaId,
            @Min(0) int sortOrder
        ) {}
    }

    public record MediaCoverRequest(@NotNull Long mediaId) {}
}
