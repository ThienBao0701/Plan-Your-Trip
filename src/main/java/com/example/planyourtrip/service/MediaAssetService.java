package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.MediaDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.MediaAsset;
import com.example.planyourtrip.model.MediaOwnerType;
import com.example.planyourtrip.model.MediaType;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.MediaAssetRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.repository.ReviewRepository;
import com.example.planyourtrip.repository.TripPlanRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.net.URI;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

@Service
@Transactional(readOnly = true)
public class MediaAssetService {

    private final MediaAssetRepository mediaAssets;
    private final PlaceRepository places;
    private final HotelRoomRepository rooms;
    private final ReviewRepository reviews;
    private final TripPlanRepository tripPlans;
    private final AdminActivityLogService adminAudit;

    public MediaAssetService(MediaAssetRepository mediaAssets, PlaceRepository places,
                              HotelRoomRepository rooms, ReviewRepository reviews,
                              TripPlanRepository tripPlans,
                              AdminActivityLogService adminAudit) {
        this.mediaAssets = mediaAssets;
        this.places = places;
        this.rooms = rooms;
        this.reviews = reviews;
        this.tripPlans = tripPlans;
        this.adminAudit = adminAudit;
    }

    /**
     * D3M — the only URL schemes this product can actually render.
     *
     * <p>Every media URL ends up in Flutter's {@code Image.network}; nothing in the app
     * passes one to a link launcher (there is no {@code url_launcher} dependency). An
     * {@code <img>} does not execute {@code javascript:} or {@code vbscript:}, and
     * {@code Image.network} cannot load {@code data:} or {@code file:} at all — so an
     * off-list scheme is not a live script-injection path today. It is stored data that
     * can never render, and a scheme the client might treat differently tomorrow.
     *
     * <p>Server-side validation is therefore the authoritative guard rather than a
     * client concern, and the allowlist is deliberately closed: only what the product
     * demonstrably renders. All eight seeded rows are already {@code https}, so nothing
     * existing is invalidated.
     *
     * <p>A <em>host</em> allowlist is deliberately not added: the product has no
     * configured media host (the seed's {@code cdn.planyourtrip.vn} is a literal, not a
     * setting), and inventing one would be product policy this phase has no basis for.
     */
    private static final Set<String> ALLOWED_URL_SCHEMES = Set.of("http", "https");

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

    /**
     * D3M — the audited entry point for an administrator registering media.
     *
     * <p>It delegates rather than recording inside {@link #create}, because that method
     * is also how a guest attaches a photo to their own review
     * ({@code ReviewService.addReviewMedia}) and how a trip document registers its file
     * ({@code TripPlanDocumentService}). Auditing the shared body would file both as
     * administrative actions — the same trap D1c hit when referral rewards reached the
     * audited credit-grant path.
     */
    @Transactional
    public MediaAssetResponse adminCreate(Long adminUserId, MediaAssetRequest req) {
        MediaAssetResponse created = create(req, adminUserId);
        adminAudit.record(adminUserId, "MEDIA_CREATE", "MEDIA_ASSET", created.id(),
            "Admin registered media for " + req.ownerType() + " " + req.ownerId(),
            null, redactUrl(created.url()));
        return created;
    }

    @Transactional
    public MediaAssetResponse create(MediaAssetRequest req, Long uploadedById) {
        validateOwnerExists(req.ownerType(), req.ownerId());
        validateUrl(req.url(), "url");
        validateUrl(req.thumbnailUrl(), "thumbnailUrl");

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
    public MediaAssetResponse update(Long adminUserId, Long id, MediaAssetRequest req) {
        MediaAsset asset = mediaAssets.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Media asset not found: " + id));
        validateUrl(req.url(), "url");
        validateUrl(req.thumbnailUrl(), "thumbnailUrl");
        String previousUrl = asset.getUrl();

        // ownerType/ownerId on the request are deliberately still ignored here: an
        // update may not re-target an asset, and the fields stay in the DTO because
        // removing them would break every existing caller (D3-F11 — contract smell,
        // not a security hole).
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

        MediaAsset saved = mediaAssets.save(asset);
        // Admin-only path, so the record lives here rather than in a wrapper. The URL is
        // redacted to origin + path: a media URL can legitimately carry a signed query
        // string, and the trail must not preserve one.
        adminAudit.record(adminUserId, "MEDIA_UPDATE", "MEDIA_ASSET", saved.getId(),
            "Admin updated media " + saved.getId() + " on " + saved.getOwnerType()
                + " " + saved.getOwnerId(),
            redactUrl(previousUrl), redactUrl(saved.getUrl()));
        return toResponse(saved);
    }

    /**
     * D3M — the audited entry point for an administrator deactivating media.
     *
     * <p>Separate from {@link #deactivate} for the same reason as {@link #adminCreate}:
     * a guest removing a photo from their own review reaches the shared method, and that
     * is not an administrative act.
     */
    @Transactional
    public MediaAssetResponse adminDeactivate(Long adminUserId, Long id) {
        MediaAsset before = mediaAssets.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Media asset not found: " + id));
        boolean wasCover = before.isCover();
        MediaAssetResponse result = deactivate(id);
        // Whether the gallery just lost its cover is the fact an operator needs later:
        // nothing promotes a replacement, so the public page falls back silently.
        adminAudit.record(adminUserId, "MEDIA_DEACTIVATE", "MEDIA_ASSET", id,
            "Admin deactivated media " + id + " on " + result.ownerType() + " " + result.ownerId()
                + (wasCover ? "; it was the cover, and none was promoted" : ""),
            "active:true" + (wasCover ? " cover:true" : ""), "active:false");
        return result;
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
    public MediaAssetResponse setCover(Long adminUserId, MediaCoverRequest req) {
        MediaAsset asset = mediaAssets.findByIdAndActiveTrue(req.mediaId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Active media asset not found: " + req.mediaId()));

        if (asset.getMediaType() != MediaType.IMAGE) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Only IMAGE media can be set as cover");
        }

        // Serialise concurrent cover changes for this gallery before clearing, so two
        // callers cannot each clear a stale snapshot and both then set their own row.
        mediaAssets.lockGalleryForUpdate(asset.getOwnerType(), asset.getOwnerId());
        mediaAssets.clearCoverByOwner(asset.getOwnerType(), asset.getOwnerId());
        asset.setCover(true);
        MediaAsset saved = mediaAssets.save(asset);
        adminAudit.record(adminUserId, "MEDIA_SET_COVER", "MEDIA_ASSET", saved.getId(),
            "Admin set media " + saved.getId() + " as the cover for "
                + saved.getOwnerType() + " " + saved.getOwnerId(),
            null, "cover:true");
        return toResponse(saved);
    }

    @Transactional
    public List<MediaAssetResponse> reorder(Long adminUserId, MediaReorderRequest req) {
        if (req.items().isEmpty()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Reorder list cannot be empty");
        }

        // D3M — the request is a partial update of one gallery's ordering, so the only
        // thing that can make it self-contradictory is repeating an id or a position.
        // Both were previously accepted: a repeated id let the last entry silently win,
        // and a repeated sortOrder left two assets tied with no deterministic order in
        // the admin read (which sorts by sortOrder alone). Neither is normalised —
        // the caller is told, because guessing which position was meant would be
        // inventing product semantics.
        Set<Long> seenIds = new HashSet<>();
        Set<Integer> seenOrders = new HashSet<>();
        for (MediaReorderRequest.MediaOrderItem item : req.items()) {
            if (!seenIds.add(item.mediaId())) {
                throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Duplicate mediaId in reorder request: " + item.mediaId());
            }
            if (!seenOrders.add(item.sortOrder())) {
                throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Duplicate sortOrder in reorder request: " + item.sortOrder());
            }
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

        List<MediaAsset> saved = mediaAssets.saveAll(assets);
        // One row for the whole reorder, targeting the owner rather than any single
        // asset: the change is to the gallery's ordering, not to one image.
        adminAudit.record(adminUserId, "MEDIA_REORDER", "MEDIA_ASSET", null,
            "Admin reordered " + saved.size() + " media on " + ownerType + " " + ownerId,
            null, "reordered:" + saved.size());
        return saved.stream().map(this::toResponse).toList();
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    /**
     * D3M — every owner type is now resolved, not just PLACE.
     *
     * <p>Previously only {@code PLACE} was checked, so media could be attached to a
     * {@code ROOM}, {@code REVIEW} or {@code TRIP_DOCUMENT} id that did not exist — and
     * would then surface on whatever entity later took that id.
     *
     * <p>{@code TRIP_DOCUMENT} resolves against {@link TripPlanRepository} rather than
     * the document table on purpose: {@code TripPlanDocumentService} registers its media
     * with {@code ownerId = tripId}, so the trip is the real referent.
     *
     * <p>{@code SUBMISSION} has no entity anywhere in the codebase, so it is rejected as
     * unsupported rather than silently accepted as a dangling reference.
     */
    private void validateOwnerExists(MediaOwnerType ownerType, Long ownerId) {
        boolean exists = switch (ownerType) {
            case PLACE -> places.existsById(ownerId);
            case ROOM -> rooms.existsById(ownerId);
            case REVIEW -> reviews.existsById(ownerId);
            case TRIP_DOCUMENT -> tripPlans.existsById(ownerId);
            case SUBMISSION -> throw new ApiException(HttpStatus.BAD_REQUEST,
                "ownerType SUBMISSION is not supported: no such entity exists");
        };
        if (!exists) {
            throw new ApiException(HttpStatus.NOT_FOUND,
                ownerType + " not found: " + ownerId);
        }
    }

    /** Rejects any URL this product cannot render. See {@link #ALLOWED_URL_SCHEMES}. */
    private void validateUrl(String value, String field) {
        if (value == null || value.isBlank()) return;      // thumbnailUrl is optional
        final URI uri;
        try {
            uri = URI.create(value.trim());
        } catch (IllegalArgumentException e) {
            throw new ApiException(HttpStatus.BAD_REQUEST, field + " is not a valid URL");
        }
        String scheme = uri.getScheme();
        if (scheme == null) {
            // Covers both a relative path and a protocol-relative "//host/x", whose
            // effective scheme depends on the page that renders it rather than on the
            // stored value. Neither is used by any existing row.
            throw new ApiException(HttpStatus.BAD_REQUEST,
                field + " must be an absolute http or https URL");
        }
        if (!ALLOWED_URL_SCHEMES.contains(scheme.toLowerCase(Locale.ROOT))) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                field + " scheme '" + scheme + "' is not allowed; use http or https");
        }
        if (uri.getHost() == null || uri.getHost().isBlank()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, field + " must include a host");
        }
    }

    /**
     * D3M — a URL is not a credential, but it can carry one in a query string (a signed
     * CDN link, a pre-signed object URL). The audit trail records the origin and path
     * only, so the trail stays useful for "which asset changed" without becoming a place
     * where a bearer parameter is preserved forever.
     */
    private static String redactUrl(String url) {
        if (url == null || url.isBlank()) return null;
        try {
            URI u = URI.create(url.trim());
            if (u.getHost() == null) return "(unparseable)";
            String path = u.getPath() == null ? "" : u.getPath();
            String base = u.getScheme() + "://" + u.getHost() + path;
            return u.getQuery() == null ? base : base + "?(redacted)";
        } catch (IllegalArgumentException e) {
            return "(unparseable)";
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
