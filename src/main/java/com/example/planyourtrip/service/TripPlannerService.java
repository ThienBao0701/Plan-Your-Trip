package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.TripPlanDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.repository.TripPlanBudgetRepository;
import com.example.planyourtrip.repository.TripPlanCollaboratorRepository;
import com.example.planyourtrip.repository.TripPlanDayRepository;
import com.example.planyourtrip.repository.TripPlanExpenseRepository;
import com.example.planyourtrip.repository.TripPlanItemRepository;
import com.example.planyourtrip.repository.TripPlanRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Core itinerary planner: {@link TripPlan} → {@link TripPlanDay} → {@link TripPlanItem}.
 *
 * <p>Three tiers of access (Phase 7.5): the trip owner always has full access;
 * an active {@link TripCollaboratorRole#EDITOR} collaborator can view and modify
 * days/items but not trip metadata, deletion, duplication, or collaborator
 * management (those stay strictly owner-only via {@link #myTripOrThrow}); an active
 * {@link TripCollaboratorRole#VIEWER} collaborator can only view. A day/item lookup
 * by bare id always re-resolves its parent trip and re-checks permission against
 * it before any read or write — never trusts the id alone.
 *
 * <p>Deliberately built with no controller-facing state beyond its constructor
 * dependencies so it can be reused as-is by a future AI itinerary generator
 * (e.g. calling {@link #addDay} / {@link #addItem} programmatically).
 */
@Service
public class TripPlannerService {

    private final TripPlanRepository tripRepo;
    private final TripPlanDayRepository dayRepo;
    private final TripPlanItemRepository itemRepo;
    private final PlaceRepository placeRepo;
    private final UserRepository userRepo;
    private final TripPlanCollaboratorRepository collaboratorRepo;
    private final TripPlanBudgetRepository budgetRepo;
    private final TripPlanExpenseRepository expenseRepo;

    public TripPlannerService(TripPlanRepository tripRepo,
                               TripPlanDayRepository dayRepo,
                               TripPlanItemRepository itemRepo,
                               PlaceRepository placeRepo,
                               UserRepository userRepo,
                               TripPlanCollaboratorRepository collaboratorRepo,
                               TripPlanBudgetRepository budgetRepo,
                               TripPlanExpenseRepository expenseRepo) {
        this.tripRepo = tripRepo;
        this.dayRepo = dayRepo;
        this.itemRepo = itemRepo;
        this.placeRepo = placeRepo;
        this.userRepo = userRepo;
        this.collaboratorRepo = collaboratorRepo;
        this.budgetRepo = budgetRepo;
        this.expenseRepo = expenseRepo;
    }

    // ── Trip ──────────────────────────────────────────────────────────────────

    @Transactional
    public TripResponse createTrip(Long userId, TripRequest req) {
        validateDateRange(req.startDate(), req.endDate());
        User user = userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));

        TripPlan trip = new TripPlan();
        trip.setUser(user);
        applyTripRequest(trip, req);
        return toResponse(tripRepo.save(trip));
    }

    @Transactional
    public TripResponse updateTrip(Long userId, Long tripId, TripRequest req) {
        validateDateRange(req.startDate(), req.endDate());
        TripPlan trip = myTripOrThrow(userId, tripId);
        applyTripRequest(trip, req);
        return toResponse(tripRepo.save(trip));
    }

    @Transactional
    public void deleteTrip(Long userId, Long tripId) {
        TripPlan trip = myTripOrThrow(userId, tripId);
        List<Long> dayIds = dayRepo.findByTripPlanIdOrderByDayNumberAsc(tripId)
            .stream().map(TripPlanDay::getId).toList();
        if (!dayIds.isEmpty()) itemRepo.deleteByTripPlanDayIdIn(dayIds);
        dayRepo.deleteByTripPlanId(tripId);
        collaboratorRepo.deleteByTripPlanId(tripId);
        expenseRepo.deleteByTripPlanId(tripId);
        budgetRepo.deleteByTripPlanId(tripId);
        tripRepo.delete(trip);
    }

    @Transactional(readOnly = true)
    public List<TripSummaryResponse> getMine(Long userId) {
        return tripRepo.findByUserIdOrderByUpdatedAtDesc(userId).stream().map(this::toSummary).toList();
    }

    @Transactional(readOnly = true)
    public TripResponse getById(Long userId, Long tripId) {
        return toResponse(viewableTripOrThrow(userId, tripId));
    }

    @Transactional
    public TripResponse duplicateTrip(Long userId, Long tripId) {
        TripPlan original = myTripOrThrow(userId, tripId);

        TripPlan copy = new TripPlan();
        copy.setUser(original.getUser());
        copy.setTitle(original.getTitle() + " (Copy)");
        copy.setDescription(original.getDescription());
        copy.setDestination(original.getDestination());
        copy.setCoverImage(original.getCoverImage());
        copy.setStartDate(original.getStartDate());
        copy.setEndDate(original.getEndDate());
        copy.setStatus(TripPlanStatus.PLANNING);
        copy.setPublic(false);
        TripPlan savedCopy = tripRepo.save(copy);

        for (TripPlanDay originalDay : dayRepo.findByTripPlanIdOrderByDayNumberAsc(original.getId())) {
            TripPlanDay newDay = new TripPlanDay();
            newDay.setTripPlan(savedCopy);
            newDay.setDayNumber(originalDay.getDayNumber());
            newDay.setDate(originalDay.getDate());
            newDay.setTitle(originalDay.getTitle());
            newDay.setNotes(originalDay.getNotes());
            TripPlanDay savedDay = dayRepo.save(newDay);

            for (TripPlanItem originalItem : itemRepo.findByTripPlanDayIdOrderBySortOrderAsc(originalDay.getId())) {
                TripPlanItem newItem = new TripPlanItem();
                newItem.setTripPlanDay(savedDay);
                newItem.setPlace(originalItem.getPlace());
                newItem.setCustomTitle(originalItem.getCustomTitle());
                newItem.setCustomDescription(originalItem.getCustomDescription());
                newItem.setStartTime(originalItem.getStartTime());
                newItem.setEndTime(originalItem.getEndTime());
                newItem.setSortOrder(originalItem.getSortOrder());
                newItem.setEstimatedCost(originalItem.getEstimatedCost());
                newItem.setLatitude(originalItem.getLatitude());
                newItem.setLongitude(originalItem.getLongitude());
                newItem.setTransportationNote(originalItem.getTransportationNote());
                itemRepo.save(newItem);
            }
        }

        return toResponse(savedCopy);
    }

    // ── Day ───────────────────────────────────────────────────────────────────

    @Transactional
    public TripDayResponse addDay(Long userId, Long tripId, TripDayRequest req) {
        TripPlan trip = editableTripOrThrow(userId, tripId);
        if (dayRepo.existsByTripPlanIdAndDayNumber(trip.getId(), req.dayNumber()))
            throw new ApiException(HttpStatus.CONFLICT, "Day number already exists: " + req.dayNumber());

        TripPlanDay day = new TripPlanDay();
        day.setTripPlan(trip);
        applyDayRequest(day, req);
        return toDayResponse(dayRepo.save(day));
    }

    @Transactional
    public TripDayResponse updateDay(Long userId, Long dayId, TripDayRequest req) {
        TripPlanDay day = editableDayOrThrow(userId, dayId);
        if (req.dayNumber() != day.getDayNumber()
                && dayRepo.existsByTripPlanIdAndDayNumber(day.getTripPlan().getId(), req.dayNumber()))
            throw new ApiException(HttpStatus.CONFLICT, "Day number already exists: " + req.dayNumber());

        applyDayRequest(day, req);
        return toDayResponse(dayRepo.save(day));
    }

    @Transactional
    public void deleteDay(Long userId, Long dayId) {
        TripPlanDay day = editableDayOrThrow(userId, dayId);
        itemRepo.deleteByTripPlanDayId(day.getId());
        dayRepo.delete(day);
    }

    // ── Item ──────────────────────────────────────────────────────────────────

    @Transactional
    public TripItemResponse addItem(Long userId, Long dayId, TripItemRequest req) {
        TripPlanDay day = editableDayOrThrow(userId, dayId);
        Place place = resolvePublishedPlaceOrNull(req.placeId());
        validateItemContent(req);

        TripPlanItem item = new TripPlanItem();
        item.setTripPlanDay(day);
        item.setPlace(place);
        applyItemRequest(item, req);
        item.setSortOrder((int) itemRepo.countByTripPlanDayId(day.getId()));
        return toItemResponse(itemRepo.save(item));
    }

    @Transactional
    public TripItemResponse updateItem(Long userId, Long itemId, TripItemRequest req) {
        TripPlanItem item = editableItemOrThrow(userId, itemId);
        Place place = resolvePublishedPlaceOrNull(req.placeId());
        validateItemContent(req);

        item.setPlace(place);
        applyItemRequest(item, req);
        return toItemResponse(itemRepo.save(item));
    }

    @Transactional
    public void deleteItem(Long userId, Long itemId) {
        TripPlanItem item = editableItemOrThrow(userId, itemId);
        Long dayId = item.getTripPlanDay().getId();
        itemRepo.delete(item);
        resequence(dayId);
    }

    @Transactional
    public TripItemResponse moveItem(Long userId, Long itemId, MoveTripItemRequest req) {
        TripPlanItem item = editableItemOrThrow(userId, itemId);
        TripPlanDay sourceDay = item.getTripPlanDay();
        TripPlanDay targetDay = dayRepo.findById(req.targetDayId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Trip day not found: " + req.targetDayId()));

        if (!targetDay.getTripPlan().getId().equals(sourceDay.getTripPlan().getId()))
            throw new ApiException(HttpStatus.BAD_REQUEST, "Cannot move an item to a day in a different trip");

        boolean sameDay = sourceDay.getId().equals(targetDay.getId());
        item.setTripPlanDay(targetDay);
        itemRepo.save(item);

        List<TripPlanItem> targetItems = itemRepo.findByTripPlanDayIdOrderBySortOrderAsc(targetDay.getId())
            .stream().filter(i -> !i.getId().equals(item.getId())).collect(Collectors.toCollection(ArrayList::new));
        int insertAt = req.targetSortOrder() == null
            ? targetItems.size()
            : Math.max(0, Math.min(req.targetSortOrder(), targetItems.size()));
        targetItems.add(insertAt, item);
        for (int i = 0; i < targetItems.size(); i++) targetItems.get(i).setSortOrder(i);
        itemRepo.saveAll(targetItems);

        if (!sameDay) resequence(sourceDay.getId());

        return toItemResponse(item);
    }

    @Transactional
    public TripDayResponse reorderDay(Long userId, Long dayId, ReorderTripDayRequest req) {
        TripPlanDay day = editableDayOrThrow(userId, dayId);
        List<TripPlanItem> items = itemRepo.findByTripPlanDayIdOrderBySortOrderAsc(day.getId());
        Map<Long, TripPlanItem> byId = items.stream().collect(Collectors.toMap(TripPlanItem::getId, Function.identity()));

        if (req.orderedItemIds().size() != items.size() || !byId.keySet().containsAll(req.orderedItemIds()))
            throw new ApiException(HttpStatus.BAD_REQUEST, "orderedItemIds must contain exactly the items in this day");

        for (int i = 0; i < req.orderedItemIds().size(); i++) {
            byId.get(req.orderedItemIds().get(i)).setSortOrder(i);
        }
        itemRepo.saveAll(items);
        return toDayResponse(day);
    }

    // ── Ownership / collaborator permission helpers ─────────────────────────

    /**
     * Strictly owner-only: trip metadata update, delete, duplicate. A collaborator
     * (who can already see the trip exists) gets 403 here, not 404 — 404 is
     * reserved for callers with no relationship to the trip at all.
     */
    private TripPlan myTripOrThrow(Long userId, Long tripId) {
        TripPlan trip = viewableTripOrThrow(userId, tripId);
        if (!isOwner(trip, userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "Only the trip owner can perform this action");
        return trip;
    }

    /** Owner or any active collaborator (VIEWER or EDITOR) may view. */
    private TripPlan viewableTripOrThrow(Long userId, Long tripId) {
        TripPlan trip = tripRepo.findById(tripId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Trip not found: " + tripId));
        if (!canView(trip, userId))
            throw new ApiException(HttpStatus.NOT_FOUND, "Trip not found: " + tripId);
        return trip;
    }

    /** Owner or an active EDITOR collaborator may add/update/delete days and items. */
    private TripPlan editableTripOrThrow(Long userId, Long tripId) {
        TripPlan trip = viewableTripOrThrow(userId, tripId);
        if (!canEdit(trip, userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "You do not have permission to edit this trip");
        return trip;
    }

    private TripPlanDay editableDayOrThrow(Long userId, Long dayId) {
        TripPlanDay day = dayRepo.findById(dayId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Trip day not found: " + dayId));
        checkEditable(userId, day.getTripPlan(), "Trip day not found: " + dayId);
        return day;
    }

    private TripPlanItem editableItemOrThrow(Long userId, Long itemId) {
        TripPlanItem item = itemRepo.findById(itemId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Trip item not found: " + itemId));
        checkEditable(userId, item.getTripPlanDay().getTripPlan(), "Trip item not found: " + itemId);
        return item;
    }

    private void checkEditable(Long userId, TripPlan trip, String notFoundMessage) {
        if (!canView(trip, userId)) throw new ApiException(HttpStatus.NOT_FOUND, notFoundMessage);
        if (!canEdit(trip, userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "You do not have permission to edit this trip");
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

    private void validateDateRange(java.time.LocalDate start, java.time.LocalDate end) {
        if (start != null && end != null && start.isAfter(end))
            throw new ApiException(HttpStatus.BAD_REQUEST, "startDate must not be after endDate");
    }

    private void validateItemContent(TripItemRequest req) {
        if (req.placeId() == null && (req.customTitle() == null || req.customTitle().isBlank()))
            throw new ApiException(HttpStatus.BAD_REQUEST, "Either placeId or customTitle must be provided");
    }

    private Place resolvePublishedPlaceOrNull(Long placeId) {
        if (placeId == null) return null;
        Place place = placeRepo.findById(placeId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Place not found: " + placeId));
        if (place.getStatus() != PlaceStatus.PUBLISHED)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "Only published places can be added to a trip");
        return place;
    }

    private void applyTripRequest(TripPlan trip, TripRequest req) {
        trip.setTitle(req.title());
        trip.setDescription(req.description());
        trip.setDestination(req.destination());
        trip.setCoverImage(req.coverImage());
        trip.setStartDate(req.startDate());
        trip.setEndDate(req.endDate());
        trip.setStatus(parseStatusOrDefault(req.status(), trip.getStatus()));
        trip.setPublic(req.isPublic());
    }

    private TripPlanStatus parseStatusOrDefault(String raw, TripPlanStatus fallback) {
        if (raw == null || raw.isBlank()) return fallback != null ? fallback : TripPlanStatus.PLANNING;
        try {
            return TripPlanStatus.valueOf(raw.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Invalid status: " + raw);
        }
    }

    private void applyDayRequest(TripPlanDay day, TripDayRequest req) {
        day.setDayNumber(req.dayNumber());
        day.setDate(req.date());
        day.setTitle(req.title());
        day.setNotes(req.notes());
    }

    private void applyItemRequest(TripPlanItem item, TripItemRequest req) {
        item.setCustomTitle(req.customTitle());
        item.setCustomDescription(req.customDescription());
        item.setStartTime(req.startTime());
        item.setEndTime(req.endTime());
        item.setEstimatedCost(req.estimatedCost());
        item.setLatitude(req.latitude());
        item.setLongitude(req.longitude());
        item.setTransportationNote(req.transportationNote());
    }

    private void resequence(Long dayId) {
        List<TripPlanItem> items = itemRepo.findByTripPlanDayIdOrderBySortOrderAsc(dayId);
        for (int i = 0; i < items.size(); i++) items.get(i).setSortOrder(i);
        itemRepo.saveAll(items);
    }

    // ── Response mapping ─────────────────────────────────────────────────────

    /** Package-private so {@link TripCollaborationService} can reuse the same nested mapping. */
    TripResponse toResponse(TripPlan trip) {
        List<TripDayResponse> days = dayRepo.findByTripPlanIdOrderByDayNumberAsc(trip.getId())
            .stream().map(this::toDayResponse).toList();
        return new TripResponse(
            trip.getId(), trip.getUser().getId(), trip.getTitle(), trip.getDescription(),
            trip.getDestination(), trip.getCoverImage(), trip.getStartDate(), trip.getEndDate(),
            trip.getStatus().name(), trip.isPublic(), days, trip.getCreatedAt(), trip.getUpdatedAt()
        );
    }

    private TripSummaryResponse toSummary(TripPlan trip) {
        long dayCount = dayRepo.countByTripPlanId(trip.getId());
        return new TripSummaryResponse(
            trip.getId(), trip.getTitle(), trip.getDestination(), trip.getCoverImage(),
            trip.getStartDate(), trip.getEndDate(), trip.getStatus().name(), trip.isPublic(),
            dayCount, trip.getUpdatedAt()
        );
    }

    private TripDayResponse toDayResponse(TripPlanDay day) {
        List<TripItemResponse> items = itemRepo.findByTripPlanDayIdOrderBySortOrderAsc(day.getId())
            .stream().map(this::toItemResponse).toList();
        return new TripDayResponse(day.getId(), day.getDayNumber(), day.getDate(), day.getTitle(), day.getNotes(), items);
    }

    private TripItemResponse toItemResponse(TripPlanItem item) {
        Place place = item.getPlace();
        return new TripItemResponse(
            item.getId(),
            place != null ? place.getId() : null,
            place != null ? place.getName() : null,
            place != null ? place.getSlug() : null,
            item.getCustomTitle(), item.getCustomDescription(),
            item.getStartTime(), item.getEndTime(), item.getSortOrder(),
            item.getEstimatedCost(), item.getLatitude(), item.getLongitude(),
            item.getTransportationNote(), item.getCreatedAt()
        );
    }
}
