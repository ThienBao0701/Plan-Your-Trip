package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.TripPlanTimelineDto.TripPlanReminderRequest;
import com.example.planyourtrip.dto.TripPlanTimelineDto.TripPlanReminderResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.TripPlanCollaboratorRepository;
import com.example.planyourtrip.repository.TripPlanDayRepository;
import com.example.planyourtrip.repository.TripPlanDocumentRepository;
import com.example.planyourtrip.repository.TripPlanItemRepository;
import com.example.planyourtrip.repository.TripPlanReminderRepository;
import com.example.planyourtrip.repository.TripPlanRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

/**
 * In-app reminder foundation for a trip — no push/email/background scheduling
 * (Phase 7.10 scope is deliberately storage + CRUD only). Mirrors
 * {@code TripPlannerService}'s three-tier permission model (owner / active
 * EDITOR / active VIEWER) via its own small, independently-duplicated ownership
 * checks — matching the established per-service convention.
 */
@Service
public class TripPlanReminderService {

    private final TripPlanRepository tripRepo;
    private final TripPlanDayRepository dayRepo;
    private final TripPlanItemRepository itemRepo;
    private final TripPlanDocumentRepository documentRepo;
    private final TripPlanCollaboratorRepository collaboratorRepo;
    private final TripPlanReminderRepository reminderRepo;
    private final UserRepository userRepo;

    public TripPlanReminderService(TripPlanRepository tripRepo,
                                    TripPlanDayRepository dayRepo,
                                    TripPlanItemRepository itemRepo,
                                    TripPlanDocumentRepository documentRepo,
                                    TripPlanCollaboratorRepository collaboratorRepo,
                                    TripPlanReminderRepository reminderRepo,
                                    UserRepository userRepo) {
        this.tripRepo = tripRepo;
        this.dayRepo = dayRepo;
        this.itemRepo = itemRepo;
        this.documentRepo = documentRepo;
        this.collaboratorRepo = collaboratorRepo;
        this.reminderRepo = reminderRepo;
        this.userRepo = userRepo;
    }

    @Transactional(readOnly = true)
    public List<TripPlanReminderResponse> list(Long userId, Long tripId, boolean includeCancelled) {
        TripPlan trip = viewableTripOrThrow(userId, tripId);
        return reminderRepo.findByTripPlanIdOrderByReminderAtAsc(trip.getId()).stream()
            .filter(r -> includeCancelled || r.getStatus() != TripPlanReminderStatus.CANCELLED)
            .map(this::toResponse).toList();
    }

    @Transactional
    public TripPlanReminderResponse create(Long userId, Long tripId, TripPlanReminderRequest req) {
        TripPlan trip = editableTripOrThrow(userId, tripId);
        TripPlanDay day = resolveSameTripDayOrNull(trip.getId(), req.tripDayId());
        TripPlanItem item = resolveSameTripItemOrNull(trip.getId(), req.tripItemId());
        TripPlanDocument document = resolveSameTripDocumentOrNull(trip.getId(), req.documentId());
        User user = userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));

        TripPlanReminder reminder = new TripPlanReminder();
        reminder.setTripPlan(trip);
        reminder.setTripDay(day);
        reminder.setTripItem(item);
        reminder.setDocument(document);
        reminder.setUser(user);
        applyRequest(reminder, req);
        return toResponse(reminderRepo.save(reminder));
    }

    @Transactional
    public TripPlanReminderResponse update(Long userId, Long reminderId, TripPlanReminderRequest req) {
        TripPlanReminder reminder = editableReminderOrThrow(userId, reminderId);
        Long tripId = reminder.getTripPlan().getId();
        reminder.setTripDay(resolveSameTripDayOrNull(tripId, req.tripDayId()));
        reminder.setTripItem(resolveSameTripItemOrNull(tripId, req.tripItemId()));
        reminder.setDocument(resolveSameTripDocumentOrNull(tripId, req.documentId()));
        applyRequest(reminder, req);
        return toResponse(reminderRepo.save(reminder));
    }

    @Transactional
    public TripPlanReminderResponse complete(Long userId, Long reminderId) {
        TripPlanReminder reminder = editableReminderOrThrow(userId, reminderId);
        reminder.setStatus(TripPlanReminderStatus.COMPLETED);
        reminder.setCompletedAt(Instant.now());
        return toResponse(reminderRepo.save(reminder));
    }

    @Transactional
    public TripPlanReminderResponse cancel(Long userId, Long reminderId) {
        TripPlanReminder reminder = editableReminderOrThrow(userId, reminderId);
        reminder.setStatus(TripPlanReminderStatus.CANCELLED);
        return toResponse(reminderRepo.save(reminder));
    }

    @Transactional
    public void delete(Long userId, Long reminderId) {
        reminderRepo.delete(editableReminderOrThrow(userId, reminderId));
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
            throw new ApiException(HttpStatus.FORBIDDEN, "You do not have permission to manage reminders for this trip");
        return trip;
    }

    private TripPlanReminder editableReminderOrThrow(Long userId, Long reminderId) {
        TripPlanReminder reminder = reminderRepo.findById(reminderId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Reminder not found: " + reminderId));
        TripPlan trip = reminder.getTripPlan();
        if (trip == null) {
            // Phase 7.13: a WalletExpiryReminderService-generated reminder for a wallet item with
            // no linked trip has a null tripPlan — no collaborator concept applies, so it is
            // strictly owner-only here (mirrors TravelWalletService's own wallet-item ownership rule).
            if (!reminder.getUser().getId().equals(userId))
                throw new ApiException(HttpStatus.NOT_FOUND, "Reminder not found: " + reminderId);
            return reminder;
        }
        if (!canView(trip, userId))
            throw new ApiException(HttpStatus.NOT_FOUND, "Reminder not found: " + reminderId);
        if (!canEdit(trip, userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "You do not have permission to manage reminders for this trip");
        return reminder;
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

    private TripPlanDocument resolveSameTripDocumentOrNull(Long tripId, Long documentId) {
        if (documentId == null) return null;
        TripPlanDocument document = documentRepo.findById(documentId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Document not found: " + documentId));
        if (!document.getTripPlan().getId().equals(tripId))
            throw new ApiException(HttpStatus.BAD_REQUEST, "Document does not belong to this trip");
        return document;
    }

    private void applyRequest(TripPlanReminder reminder, TripPlanReminderRequest req) {
        reminder.setReminderType(req.reminderType());
        reminder.setTitle(req.title());
        reminder.setMessage(req.message());
        reminder.setReminderAt(req.reminderAt());
    }

    // ── Response mapping ─────────────────────────────────────────────────────

    private TripPlanReminderResponse toResponse(TripPlanReminder r) {
        return new TripPlanReminderResponse(
            r.getId(), r.getTripPlan() != null ? r.getTripPlan().getId() : null,
            r.getTripDay() != null ? r.getTripDay().getId() : null,
            r.getTripItem() != null ? r.getTripItem().getId() : null,
            r.getDocument() != null ? r.getDocument().getId() : null,
            r.getUser().getId(), r.getUser().getFullName(),
            r.getReminderType().name(), r.getTitle(), r.getMessage(), r.getReminderAt(),
            r.getStatus().name(), r.getCreatedAt(), r.getUpdatedAt(), r.getCompletedAt()
        );
    }
}
