package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.MediaDto.MediaAssetRequest;
import com.example.planyourtrip.dto.MediaDto.MediaAssetResponse;
import com.example.planyourtrip.dto.TripPlanDocumentDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.MediaAssetRepository;
import com.example.planyourtrip.repository.TripPlanCollaboratorRepository;
import com.example.planyourtrip.repository.TripPlanDayRepository;
import com.example.planyourtrip.repository.TripPlanDocumentRepository;
import com.example.planyourtrip.repository.TripPlanItemRepository;
import com.example.planyourtrip.repository.TripPlanRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Travel documents attached to a trip. Never registers media itself — every
 * document either reuses an existing {@link MediaAsset} (by id) or has one
 * created through the existing {@link MediaAssetService#create}, and every
 * response embeds {@link MediaAssetService#toResponse} verbatim so the media
 * mapping is never duplicated. Mirrors {@code TripPlannerService}'s three-tier
 * permission model (owner / active EDITOR / active VIEWER) via its own small,
 * independently-duplicated ownership checks — matching the established
 * per-service convention.
 */
@Service
public class TripPlanDocumentService {

    private final TripPlanRepository tripRepo;
    private final TripPlanDayRepository dayRepo;
    private final TripPlanItemRepository itemRepo;
    private final TripPlanCollaboratorRepository collaboratorRepo;
    private final TripPlanDocumentRepository documentRepo;
    private final MediaAssetRepository mediaAssetRepo;
    private final MediaAssetService mediaAssetService;
    private final UserRepository userRepo;

    public TripPlanDocumentService(TripPlanRepository tripRepo,
                                    TripPlanDayRepository dayRepo,
                                    TripPlanItemRepository itemRepo,
                                    TripPlanCollaboratorRepository collaboratorRepo,
                                    TripPlanDocumentRepository documentRepo,
                                    MediaAssetRepository mediaAssetRepo,
                                    MediaAssetService mediaAssetService,
                                    UserRepository userRepo) {
        this.tripRepo = tripRepo;
        this.dayRepo = dayRepo;
        this.itemRepo = itemRepo;
        this.collaboratorRepo = collaboratorRepo;
        this.documentRepo = documentRepo;
        this.mediaAssetRepo = mediaAssetRepo;
        this.mediaAssetService = mediaAssetService;
        this.userRepo = userRepo;
    }

    @Transactional(readOnly = true)
    public List<TripPlanDocumentResponse> list(Long userId, Long tripId) {
        TripPlan trip = viewableTripOrThrow(userId, tripId);
        return documentRepo.findByTripPlanIdOrderByPinnedDescCreatedAtDesc(trip.getId())
            .stream().map(this::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public TripPlanDocumentResponse getDocument(Long userId, Long documentId) {
        return toResponse(viewableDocumentOrThrow(userId, documentId));
    }

    @Transactional
    public TripPlanDocumentResponse create(Long userId, Long tripId, TripPlanDocumentRequest req) {
        TripPlan trip = editableTripOrThrow(userId, tripId);
        TripPlanDay day = resolveSameTripDayOrNull(trip.getId(), req.tripDayId());
        TripPlanItem item = resolveSameTripItemOrNull(trip.getId(), req.tripItemId());
        MediaAsset media = resolveMediaAsset(trip.getId(), userId, req);
        User uploader = userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));

        TripPlanDocument document = new TripPlanDocument();
        document.setTripPlan(trip);
        document.setTripDay(day);
        document.setTripItem(item);
        document.setMediaAsset(media);
        document.setUploadedBy(uploader);
        applyRequest(document, req);
        return toResponse(documentRepo.save(document));
    }

    @Transactional
    public TripPlanDocumentResponse update(Long userId, Long documentId, TripPlanDocumentRequest req) {
        TripPlanDocument document = editableDocumentOrThrow(userId, documentId);
        Long tripId = document.getTripPlan().getId();
        document.setTripDay(resolveSameTripDayOrNull(tripId, req.tripDayId()));
        document.setTripItem(resolveSameTripItemOrNull(tripId, req.tripItemId()));
        applyRequest(document, req);
        return toResponse(documentRepo.save(document));
    }

    @Transactional
    public void delete(Long userId, Long documentId) {
        documentRepo.delete(editableDocumentOrThrow(userId, documentId));
    }

    @Transactional
    public TripPlanDocumentResponse pin(Long userId, Long documentId) {
        TripPlanDocument document = editableDocumentOrThrow(userId, documentId);
        document.setPinned(true);
        return toResponse(documentRepo.save(document));
    }

    @Transactional
    public TripPlanDocumentResponse unpin(Long userId, Long documentId) {
        TripPlanDocument document = editableDocumentOrThrow(userId, documentId);
        document.setPinned(false);
        return toResponse(documentRepo.save(document));
    }

    // ── Permission helpers (duplicated from TripPlannerService by convention) ──

    private TripPlan viewableTripOrThrow(Long userId, Long tripId) {
        TripPlan trip = tripRepo.findById(tripId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Trip not found: " + tripId));
        if (!canView(trip, userId))
            throw new ApiException(HttpStatus.NOT_FOUND, "Trip not found: " + tripId);
        return trip;
    }

    private TripPlan editableTripOrThrow(Long userId, Long tripId) {
        TripPlan trip = viewableTripOrThrow(userId, tripId);
        if (!canEdit(trip, userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "You do not have permission to manage documents for this trip");
        return trip;
    }

    private TripPlanDocument viewableDocumentOrThrow(Long userId, Long documentId) {
        TripPlanDocument document = documentRepo.findById(documentId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Document not found: " + documentId));
        if (!canView(document.getTripPlan(), userId))
            throw new ApiException(HttpStatus.NOT_FOUND, "Document not found: " + documentId);
        return document;
    }

    private TripPlanDocument editableDocumentOrThrow(Long userId, Long documentId) {
        TripPlanDocument document = viewableDocumentOrThrow(userId, documentId);
        if (!canEdit(document.getTripPlan(), userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "You do not have permission to manage documents for this trip");
        return document;
    }

    private boolean isOwner(TripPlan trip, Long userId) {
        return trip.getUser().getId().equals(userId);
    }

    private boolean canView(TripPlan trip, Long userId) {
        if (isOwner(trip, userId)) return true;
        return collaboratorRepo.findByTripPlanIdAndUserId(trip.getId(), userId)
            .map(TripPlanCollaborator::isActive).orElse(false);
    }

    private boolean canEdit(TripPlan trip, Long userId) {
        if (isOwner(trip, userId)) return true;
        return collaboratorRepo.findByTripPlanIdAndUserId(trip.getId(), userId)
            .filter(TripPlanCollaborator::isActive)
            .map(c -> c.getRole() == TripCollaboratorRole.EDITOR)
            .orElse(false);
    }

    // ── Validation / mutation helpers ───────────────────────────────────────

    private TripPlanDay resolveSameTripDayOrNull(Long tripId, Long dayId) {
        if (dayId == null) return null;
        TripPlanDay day = dayRepo.findById(dayId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Trip day not found: " + dayId));
        if (!day.getTripPlan().getId().equals(tripId))
            throw new ApiException(HttpStatus.BAD_REQUEST, "Trip day does not belong to this trip");
        return day;
    }

    private TripPlanItem resolveSameTripItemOrNull(Long tripId, Long itemId) {
        if (itemId == null) return null;
        TripPlanItem item = itemRepo.findById(itemId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Trip item not found: " + itemId));
        if (!item.getTripPlanDay().getTripPlan().getId().equals(tripId))
            throw new ApiException(HttpStatus.BAD_REQUEST, "Trip item does not belong to this trip");
        return item;
    }

    /** Reuses an existing {@link MediaAsset} by id, or registers a new one via {@link MediaAssetService#create}. */
    private MediaAsset resolveMediaAsset(Long tripId, Long userId, TripPlanDocumentRequest req) {
        if (req.mediaAssetId() != null) {
            return mediaAssetRepo.findById(req.mediaAssetId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Media asset not found: " + req.mediaAssetId()));
        }
        if (req.url() == null || req.url().isBlank())
            throw new ApiException(HttpStatus.BAD_REQUEST, "Either mediaAssetId or url must be provided");

        MediaAssetRequest mediaReq = new MediaAssetRequest(
            MediaOwnerType.TRIP_DOCUMENT, tripId, req.url(), req.thumbnailUrl(),
            req.mediaType() != null ? req.mediaType() : MediaType.DOCUMENT,
            req.altText(), null, false
        );
        MediaAssetResponse created = mediaAssetService.create(mediaReq, userId);
        return mediaAssetRepo.findById(created.id())
            .orElseThrow(() -> new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to register media asset"));
    }

    private void applyRequest(TripPlanDocument document, TripPlanDocumentRequest req) {
        document.setDocumentType(req.documentType());
        document.setTitle(req.title());
        document.setNotes(req.notes());
    }

    // ── Response mapping ─────────────────────────────────────────────────────

    private TripPlanDocumentResponse toResponse(TripPlanDocument d) {
        return new TripPlanDocumentResponse(
            d.getId(), d.getTripPlan().getId(),
            d.getTripDay() != null ? d.getTripDay().getId() : null,
            d.getTripItem() != null ? d.getTripItem().getId() : null,
            mediaAssetService.toResponse(d.getMediaAsset()),
            d.getUploadedBy().getId(), d.getUploadedBy().getFullName(),
            d.getDocumentType().name(), d.getTitle(), d.getNotes(), d.isPinned(),
            d.getCreatedAt(), d.getUpdatedAt()
        );
    }
}
