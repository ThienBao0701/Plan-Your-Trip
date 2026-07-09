package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.TripPlanPackingDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.TripPlanCollaboratorRepository;
import com.example.planyourtrip.repository.TripPlanPackingItemRepository;
import com.example.planyourtrip.repository.TripPlanRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Per-trip packing checklist. Mirrors {@code TripPlannerService}'s three-tier
 * permission model (owner / active EDITOR / active VIEWER) via its own small,
 * independently-duplicated ownership checks — matching the established
 * per-service convention. Unlike the budget module (Phase 7.6, owner-only
 * mutation), packing items follow the same owner-or-EDITOR mutation rule as
 * days/items (Phase 7.4).
 */
@Service
public class TripPlanPackingService {

    private final TripPlanRepository tripRepo;
    private final TripPlanCollaboratorRepository collaboratorRepo;
    private final TripPlanPackingItemRepository packingRepo;
    private final UserRepository userRepo;

    public TripPlanPackingService(TripPlanRepository tripRepo,
                                   TripPlanCollaboratorRepository collaboratorRepo,
                                   TripPlanPackingItemRepository packingRepo,
                                   UserRepository userRepo) {
        this.tripRepo = tripRepo;
        this.collaboratorRepo = collaboratorRepo;
        this.packingRepo = packingRepo;
        this.userRepo = userRepo;
    }

    @Transactional(readOnly = true)
    public List<TripPlanPackingItemResponse> list(Long userId, Long tripId) {
        TripPlan trip = viewableTripOrThrow(userId, tripId);
        return packingRepo.findByTripPlanIdOrderByCheckedAscSortOrderAsc(trip.getId())
            .stream().map(this::toResponse).toList();
    }

    @Transactional
    public TripPlanPackingItemResponse create(Long userId, Long tripId, TripPlanPackingItemRequest req) {
        TripPlan trip = editableTripOrThrow(userId, tripId);
        User assignedUser = resolveAssignedUserOrNull(trip, req.assignedToUserId());

        TripPlanPackingItem item = new TripPlanPackingItem();
        item.setTripPlan(trip);
        applyRequest(item, req);
        item.setAssignedToUser(assignedUser);
        item.setSortOrder((int) packingRepo.countByTripPlanId(trip.getId()));
        return toResponse(packingRepo.save(item));
    }

    @Transactional
    public TripPlanPackingItemResponse update(Long userId, Long itemId, TripPlanPackingItemRequest req) {
        TripPlanPackingItem item = editableItemOrThrow(userId, itemId);
        User assignedUser = resolveAssignedUserOrNull(item.getTripPlan(), req.assignedToUserId());
        applyRequest(item, req);
        item.setAssignedToUser(assignedUser);
        return toResponse(packingRepo.save(item));
    }

    @Transactional
    public void delete(Long userId, Long itemId) {
        TripPlanPackingItem item = editableItemOrThrow(userId, itemId);
        Long tripId = item.getTripPlan().getId();
        packingRepo.delete(item);
        resequence(tripId);
    }

    @Transactional
    public TripPlanPackingItemResponse check(Long userId, Long itemId) {
        TripPlanPackingItem item = editableItemOrThrow(userId, itemId);
        item.setChecked(true);
        item.setCheckedAt(Instant.now());
        return toResponse(packingRepo.save(item));
    }

    @Transactional
    public TripPlanPackingItemResponse uncheck(Long userId, Long itemId) {
        TripPlanPackingItem item = editableItemOrThrow(userId, itemId);
        item.setChecked(false);
        item.setCheckedAt(null);
        return toResponse(packingRepo.save(item));
    }

    @Transactional
    public List<TripPlanPackingItemResponse> reorder(Long userId, Long tripId, TripPlanPackingReorderRequest req) {
        TripPlan trip = editableTripOrThrow(userId, tripId);
        List<TripPlanPackingItem> items = packingRepo.findByTripPlanIdOrderByCheckedAscSortOrderAsc(trip.getId());
        Map<Long, TripPlanPackingItem> byId = items.stream()
            .collect(Collectors.toMap(TripPlanPackingItem::getId, Function.identity()));

        if (req.orderedItemIds().size() != items.size() || !byId.keySet().containsAll(req.orderedItemIds()))
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "orderedItemIds must contain exactly the items in this trip's packing list");

        for (int i = 0; i < req.orderedItemIds().size(); i++) {
            byId.get(req.orderedItemIds().get(i)).setSortOrder(i);
        }
        packingRepo.saveAll(items);
        return packingRepo.findByTripPlanIdOrderByCheckedAscSortOrderAsc(trip.getId())
            .stream().map(this::toResponse).toList();
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
            throw new ApiException(HttpStatus.FORBIDDEN, "You do not have permission to manage the packing list for this trip");
        return trip;
    }

    private TripPlanPackingItem editableItemOrThrow(Long userId, Long itemId) {
        TripPlanPackingItem item = packingRepo.findById(itemId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Packing item not found: " + itemId));
        TripPlan trip = item.getTripPlan();
        if (!canView(trip, userId))
            throw new ApiException(HttpStatus.NOT_FOUND, "Packing item not found: " + itemId);
        if (!canEdit(trip, userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "You do not have permission to manage the packing list for this trip");
        return item;
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

    private User resolveAssignedUserOrNull(TripPlan trip, Long assignedToUserId) {
        if (assignedToUserId == null) return null;
        User user = userRepo.findById(assignedToUserId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found: " + assignedToUserId));
        if (!canView(trip, assignedToUserId))
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "assignedToUser must be the trip owner or an active collaborator");
        return user;
    }

    private void applyRequest(TripPlanPackingItem item, TripPlanPackingItemRequest req) {
        item.setLabel(req.label());
        item.setCategory(req.category());
        item.setQuantity(req.quantity());
        item.setNotes(req.notes());
    }

    private void resequence(Long tripId) {
        List<TripPlanPackingItem> items = packingRepo.findByTripPlanIdOrderByCheckedAscSortOrderAsc(tripId);
        for (int i = 0; i < items.size(); i++) items.get(i).setSortOrder(i);
        packingRepo.saveAll(items);
    }

    // ── Response mapping ─────────────────────────────────────────────────────

    private TripPlanPackingItemResponse toResponse(TripPlanPackingItem item) {
        User assignedUser = item.getAssignedToUser();
        return new TripPlanPackingItemResponse(
            item.getId(), item.getTripPlan().getId(), item.getLabel(), item.getCategory().name(),
            item.getQuantity(), item.isChecked(),
            assignedUser != null ? assignedUser.getId() : null,
            assignedUser != null ? assignedUser.getFullName() : null,
            item.getNotes(), item.getSortOrder(),
            item.getCreatedAt(), item.getUpdatedAt(), item.getCheckedAt()
        );
    }
}
