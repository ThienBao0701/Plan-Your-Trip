package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.TripPlanNoteDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.TripPlanCollaboratorRepository;
import com.example.planyourtrip.repository.TripPlanDayRepository;
import com.example.planyourtrip.repository.TripPlanItemRepository;
import com.example.planyourtrip.repository.TripPlanNoteRepository;
import com.example.planyourtrip.repository.TripPlanRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Freeform notes and journal entries for a trip, optionally linked to a specific
 * day or itinerary item. Mirrors {@code TripPlannerService}'s three-tier
 * permission model (owner / active EDITOR / active VIEWER) via its own small,
 * independently-duplicated ownership checks — matching the established
 * per-service convention. {@code authorUser} is fixed at creation time (the
 * caller who wrote the note) and is never reassigned on update, even if a
 * different EDITOR collaborator edits it later.
 */
@Service
public class TripPlanNoteService {

    private final TripPlanRepository tripRepo;
    private final TripPlanDayRepository dayRepo;
    private final TripPlanItemRepository itemRepo;
    private final TripPlanCollaboratorRepository collaboratorRepo;
    private final TripPlanNoteRepository noteRepo;
    private final UserRepository userRepo;

    public TripPlanNoteService(TripPlanRepository tripRepo,
                                TripPlanDayRepository dayRepo,
                                TripPlanItemRepository itemRepo,
                                TripPlanCollaboratorRepository collaboratorRepo,
                                TripPlanNoteRepository noteRepo,
                                UserRepository userRepo) {
        this.tripRepo = tripRepo;
        this.dayRepo = dayRepo;
        this.itemRepo = itemRepo;
        this.collaboratorRepo = collaboratorRepo;
        this.noteRepo = noteRepo;
        this.userRepo = userRepo;
    }

    @Transactional(readOnly = true)
    public List<TripPlanNoteResponse> list(Long userId, Long tripId) {
        TripPlan trip = viewableTripOrThrow(userId, tripId);
        return noteRepo.findByTripPlanIdOrderByPinnedDescUpdatedAtDesc(trip.getId())
            .stream().map(this::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public TripPlanNoteResponse getNote(Long userId, Long noteId) {
        return toResponse(viewableNoteOrThrow(userId, noteId));
    }

    @Transactional
    public TripPlanNoteResponse create(Long userId, Long tripId, TripPlanNoteRequest req) {
        TripPlan trip = editableTripOrThrow(userId, tripId);
        TripPlanDay day = resolveSameTripDayOrNull(trip.getId(), req.tripDayId());
        TripPlanItem item = resolveSameTripItemOrNull(trip.getId(), req.tripItemId());
        User author = userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));

        TripPlanNote note = new TripPlanNote();
        note.setTripPlan(trip);
        note.setTripDay(day);
        note.setTripItem(item);
        note.setAuthorUser(author);
        applyRequest(note, req);
        return toResponse(noteRepo.save(note));
    }

    @Transactional
    public TripPlanNoteResponse update(Long userId, Long noteId, TripPlanNoteRequest req) {
        TripPlanNote note = editableNoteOrThrow(userId, noteId);
        Long tripId = note.getTripPlan().getId();
        note.setTripDay(resolveSameTripDayOrNull(tripId, req.tripDayId()));
        note.setTripItem(resolveSameTripItemOrNull(tripId, req.tripItemId()));
        applyRequest(note, req);
        return toResponse(noteRepo.save(note));
    }

    @Transactional
    public void delete(Long userId, Long noteId) {
        noteRepo.delete(editableNoteOrThrow(userId, noteId));
    }

    @Transactional
    public TripPlanNoteResponse pin(Long userId, Long noteId) {
        TripPlanNote note = editableNoteOrThrow(userId, noteId);
        note.setPinned(true);
        return toResponse(noteRepo.save(note));
    }

    @Transactional
    public TripPlanNoteResponse unpin(Long userId, Long noteId) {
        TripPlanNote note = editableNoteOrThrow(userId, noteId);
        note.setPinned(false);
        return toResponse(noteRepo.save(note));
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
            throw new ApiException(HttpStatus.FORBIDDEN, "You do not have permission to manage notes for this trip");
        return trip;
    }

    private TripPlanNote viewableNoteOrThrow(Long userId, Long noteId) {
        TripPlanNote note = noteRepo.findById(noteId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Note not found: " + noteId));
        if (!canView(note.getTripPlan(), userId))
            throw new ApiException(HttpStatus.NOT_FOUND, "Note not found: " + noteId);
        return note;
    }

    private TripPlanNote editableNoteOrThrow(Long userId, Long noteId) {
        TripPlanNote note = viewableNoteOrThrow(userId, noteId);
        if (!canEdit(note.getTripPlan(), userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "You do not have permission to manage notes for this trip");
        return note;
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

    private void applyRequest(TripPlanNote note, TripPlanNoteRequest req) {
        note.setNoteType(req.noteType());
        note.setTitle(req.title());
        note.setContent(req.content());
        note.setMood(req.mood());
        note.setPhotoUrl(req.photoUrl());
    }

    // ── Response mapping ─────────────────────────────────────────────────────

    private TripPlanNoteResponse toResponse(TripPlanNote n) {
        return new TripPlanNoteResponse(
            n.getId(), n.getTripPlan().getId(),
            n.getTripDay() != null ? n.getTripDay().getId() : null,
            n.getTripItem() != null ? n.getTripItem().getId() : null,
            n.getAuthorUser().getId(), n.getAuthorUser().getFullName(),
            n.getNoteType().name(), n.getTitle(), n.getContent(),
            n.getMood() != null ? n.getMood().name() : null,
            n.getPhotoUrl(), n.isPinned(), n.getCreatedAt(), n.getUpdatedAt()
        );
    }
}
