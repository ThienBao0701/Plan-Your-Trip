package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.CollectionDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.Place;
import com.example.planyourtrip.model.SavedCollection;
import com.example.planyourtrip.model.SavedCollectionPlace;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.repository.SavedCollectionPlaceRepository;
import com.example.planyourtrip.repository.SavedCollectionRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Customer "Saved Collections" — multiple named lists of {@link Place}s per user
 * (Google-Maps-Lists / Airbnb-wishlists model). Entirely separate from, and additive
 * to, the single-flat-list {@code Wishlist} feature; it does not touch it.
 *
 * <p>Every operation is owner-scoped via {@code findByIdAndOwnerId}: a collection that
 * is unknown OR belongs to another user surfaces a uniform 404 — no 403, no existence
 * leak — mirroring the codebase's owner-scoped read convention.
 *
 * <p>Pure user-owned CRUD: no notification, timeline, analytics, or Place-aggregate side
 * effects. Deleting a collection removes its join rows but NEVER a {@link Place}.
 */
@Service
public class SavedCollectionService {

    /** Max collections a single user may own. Exceeding it → 409. */
    static final int MAX_COLLECTIONS_PER_USER = 100;
    /** Max places a single collection may hold. Exceeding it → 409. */
    static final int MAX_PLACES_PER_COLLECTION = 500;

    private final SavedCollectionRepository collectionRepo;
    private final SavedCollectionPlaceRepository placeLinkRepo;
    private final PlaceRepository placeRepo;
    private final UserRepository userRepo;

    public SavedCollectionService(SavedCollectionRepository collectionRepo,
                                   SavedCollectionPlaceRepository placeLinkRepo,
                                   PlaceRepository placeRepo,
                                   UserRepository userRepo) {
        this.collectionRepo = collectionRepo;
        this.placeLinkRepo = placeLinkRepo;
        this.placeRepo = placeRepo;
        this.userRepo = userRepo;
    }

    // ── Collection CRUD ─────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<CollectionSummaryResponse> listMine(Long userId) {
        return collectionRepo.findByOwnerIdOrderBySortOrderAscCreatedAtAsc(userId)
            .stream().map(this::toSummary).toList();
    }

    @Transactional
    public CollectionDetailResponse create(Long userId, CollectionRequest req) {
        if (collectionRepo.countByOwnerId(userId) >= MAX_COLLECTIONS_PER_USER)
            throw new ApiException(HttpStatus.CONFLICT,
                "You have reached the maximum of " + MAX_COLLECTIONS_PER_USER + " collections");

        User owner = userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));

        SavedCollection c = new SavedCollection();
        c.setOwner(owner);
        applyEditableFields(c, req);
        return toDetail(collectionRepo.save(c));
    }

    @Transactional(readOnly = true)
    public CollectionDetailResponse getDetail(Long userId, Long collectionId) {
        return toDetail(collectionOrThrow(userId, collectionId));
    }

    @Transactional
    public CollectionDetailResponse update(Long userId, Long collectionId, CollectionRequest req) {
        SavedCollection c = collectionOrThrow(userId, collectionId);
        applyEditableFields(c, req);
        return toDetail(collectionRepo.save(c));
    }

    @Transactional
    public void delete(Long userId, Long collectionId) {
        SavedCollection c = collectionOrThrow(userId, collectionId);
        // Remove join rows first (references only) — the Places themselves are never touched.
        placeLinkRepo.deleteAll(placeLinkRepo.findByCollectionIdOrderByPositionAsc(c.getId()));
        collectionRepo.delete(c);
    }

    // ── Places in a collection ──────────────────────────────────────────────────

    @Transactional
    public CollectionPlaceResponse addPlace(Long userId, Long collectionId, Long placeId) {
        SavedCollection c = collectionOrThrow(userId, collectionId);
        Place place = placeRepo.findById(placeId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Place not found: " + placeId));

        if (placeLinkRepo.existsByCollectionIdAndPlaceId(c.getId(), place.getId()))
            throw new ApiException(HttpStatus.CONFLICT, "This place is already in the collection");

        if (placeLinkRepo.countByCollectionId(c.getId()) >= MAX_PLACES_PER_COLLECTION)
            throw new ApiException(HttpStatus.CONFLICT,
                "This collection has reached the maximum of " + MAX_PLACES_PER_COLLECTION + " places");

        Integer maxPos = placeLinkRepo.findMaxPositionByCollectionId(c.getId());
        SavedCollectionPlace link = new SavedCollectionPlace();
        link.setCollection(c);
        link.setPlace(place);
        link.setPosition(maxPos == null ? 0 : maxPos + 1);
        SavedCollectionPlace saved = placeLinkRepo.save(link);

        touch(c);
        return toPlaceResponse(saved);
    }

    @Transactional
    public void removePlace(Long userId, Long collectionId, Long placeId) {
        SavedCollection c = collectionOrThrow(userId, collectionId);
        SavedCollectionPlace link = placeLinkRepo.findByCollectionIdAndPlaceId(c.getId(), placeId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Place not in collection: " + placeId));
        placeLinkRepo.delete(link); // Place row is left untouched — reference only.
        touch(c);
    }

    // ── Helpers ─────────────────────────────────────────────────────────────────

    /** Owner-scoped fetch — uniform 404 for unknown OR foreign collection. */
    private SavedCollection collectionOrThrow(Long userId, Long collectionId) {
        return collectionRepo.findByIdAndOwnerId(collectionId, userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Collection not found: " + collectionId));
    }

    private void applyEditableFields(SavedCollection c, CollectionRequest req) {
        c.setName(req.name());
        c.setDescription(req.description());
        c.setCoverImageUrl(req.coverImageUrl());
        if (req.privateCollection() != null) c.setPrivateCollection(req.privateCollection());
        if (req.sortOrder() != null) c.setSortOrder(req.sortOrder());
    }

    private void touch(SavedCollection c) {
        c.setUpdatedAt(java.time.Instant.now());
        collectionRepo.save(c);
    }

    private CollectionSummaryResponse toSummary(SavedCollection c) {
        return new CollectionSummaryResponse(
            c.getId(), c.getName(), c.getDescription(), c.getCoverImageUrl(),
            c.isPrivateCollection(), c.getSortOrder(),
            placeLinkRepo.countByCollectionId(c.getId()),
            c.getCreatedAt(), c.getUpdatedAt());
    }

    private CollectionDetailResponse toDetail(SavedCollection c) {
        List<CollectionPlaceResponse> places = placeLinkRepo
            .findByCollectionIdOrderByPositionAsc(c.getId())
            .stream().map(this::toPlaceResponse).toList();
        return new CollectionDetailResponse(
            c.getId(), c.getName(), c.getDescription(), c.getCoverImageUrl(),
            c.isPrivateCollection(), c.getSortOrder(), places.size(),
            c.getCreatedAt(), c.getUpdatedAt(), places);
    }

    private CollectionPlaceResponse toPlaceResponse(SavedCollectionPlace link) {
        Place p = link.getPlace();
        return new CollectionPlaceResponse(
            p.getId(), p.getName(), p.getSlug(),
            p.getCategory() != null ? p.getCategory().getName() : null,
            p.getAddress(), p.getShortDescription(), p.getRatingAvg(), p.getReviewCount(),
            link.getPosition(), link.getCreatedAt());
    }
}
