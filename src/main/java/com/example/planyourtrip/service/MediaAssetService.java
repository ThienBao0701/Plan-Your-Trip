package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.MediaDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.MediaAsset;
import com.example.planyourtrip.model.MediaOwnerType;
import com.example.planyourtrip.model.MediaType;
import com.example.planyourtrip.repository.MediaAssetRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class MediaAssetService {

    private final MediaAssetRepository mediaAssets;
    private final PlaceRepository places;

    public MediaAssetService(MediaAssetRepository mediaAssets, PlaceRepository places) {
        this.mediaAssets = mediaAssets;
        this.places = places;
    }

    // ─── Public ───────────────────────────────────────────────────────────────

    public List<MediaAssetResponse> listActiveMedia(MediaOwnerType ownerType, Long ownerId) {
        return mediaAssets
            .findByOwnerTypeAndOwnerIdAndActiveTrueOrderBySortOrderAsc(ownerType, ownerId)
            .stream().map(this::toResponse).toList();
    }

    // ─── Admin ────────────────────────────────────────────────────────────────

    public List<MediaAssetResponse> listAllMedia(MediaOwnerType ownerType, Long ownerId) {
        return mediaAssets
            .findByOwnerTypeAndOwnerIdOrderBySortOrderAsc(ownerType, ownerId)
            .stream().map(this::toResponse).toList();
    }

    @Transactional
    public MediaAssetResponse create(MediaAssetRequest req, Long uploadedById) {
        validateOwnerExists(req.ownerType(), req.ownerId());

        if (req.cover() != null && req.cover()) {
            if (req.mediaType() != MediaType.IMAGE) {
                throw new ApiException(HttpStatus.BAD_REQUEST, "Only IMAGE media can be set as cover");
            }
            mediaAssets.clearCoverByOwner(req.ownerType(), req.ownerId());
        }

        MediaAsset asset = new MediaAsset();
        asset.setOwnerType(req.ownerType());
        asset.setOwnerId(req.ownerId());
        asset.setUrl(req.url());
        asset.setThumbnailUrl(req.thumbnailUrl());
        asset.setMediaType(req.mediaType());
        asset.setAltText(req.altText());
        asset.setSortOrder(req.sortOrder() != null ? req.sortOrder() : 0);
        asset.setCover(req.cover() != null && req.cover());
        asset.setUploadedBy(uploadedById);

        return toResponse(mediaAssets.save(asset));
    }

    @Transactional
    public MediaAssetResponse update(Long id, MediaAssetRequest req) {
        MediaAsset asset = mediaAssets.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Media asset not found: " + id));

        if (req.cover() != null && req.cover()) {
            if (req.mediaType() != MediaType.IMAGE) {
                throw new ApiException(HttpStatus.BAD_REQUEST, "Only IMAGE media can be set as cover");
            }
            mediaAssets.clearCoverByOwner(asset.getOwnerType(), asset.getOwnerId());
        }

        asset.setUrl(req.url());
        asset.setThumbnailUrl(req.thumbnailUrl());
        asset.setMediaType(req.mediaType());
        asset.setAltText(req.altText());
        if (req.sortOrder() != null) asset.setSortOrder(req.sortOrder());
        if (req.cover() != null) asset.setCover(req.cover());

        return toResponse(mediaAssets.save(asset));
    }

    @Transactional
    public MediaAssetResponse deactivate(Long id) {
        MediaAsset asset = mediaAssets.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Media asset not found: " + id));
        asset.setActive(false);
        if (asset.isCover()) asset.setCover(false);
        return toResponse(mediaAssets.save(asset));
    }

    @Transactional
    public MediaAssetResponse setCover(MediaCoverRequest req) {
        MediaAsset asset = mediaAssets.findByIdAndActiveTrue(req.mediaId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Active media asset not found: " + req.mediaId()));

        if (asset.getMediaType() != MediaType.IMAGE) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Only IMAGE media can be set as cover");
        }

        mediaAssets.clearCoverByOwner(asset.getOwnerType(), asset.getOwnerId());
        asset.setCover(true);
        return toResponse(mediaAssets.save(asset));
    }

    @Transactional
    public List<MediaAssetResponse> reorder(MediaReorderRequest req) {
        if (req.items().isEmpty()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Reorder list cannot be empty");
        }

        List<MediaAsset> assets = req.items().stream()
            .map(item -> mediaAssets.findById(item.mediaId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                    "Media asset not found: " + item.mediaId())))
            .toList();

        MediaOwnerType ownerType = assets.get(0).getOwnerType();
        Long ownerId = assets.get(0).getOwnerId();

        for (MediaAsset asset : assets) {
            if (asset.getOwnerType() != ownerType || !asset.getOwnerId().equals(ownerId)) {
                throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Cannot reorder media from different owners in one request");
            }
        }

        for (int i = 0; i < assets.size(); i++) {
            assets.get(i).setSortOrder(req.items().get(i).sortOrder());
        }

        return mediaAssets.saveAll(assets).stream().map(this::toResponse).toList();
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private void validateOwnerExists(MediaOwnerType ownerType, Long ownerId) {
        if (ownerType == MediaOwnerType.PLACE) {
            if (!places.existsById(ownerId)) {
                throw new ApiException(HttpStatus.NOT_FOUND, "Place not found: " + ownerId);
            }
        }
    }

    public MediaAssetResponse toResponse(MediaAsset a) {
        return new MediaAssetResponse(
            a.getId(), a.getOwnerType(), a.getOwnerId(),
            a.getUrl(), a.getThumbnailUrl(), a.getMediaType(),
            a.getAltText(), a.getSortOrder(), a.isCover(), a.isActive(),
            a.getUploadedBy(), a.getCreatedAt(), a.getUpdatedAt()
        );
    }
}
