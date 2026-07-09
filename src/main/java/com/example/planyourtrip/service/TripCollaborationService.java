package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.TripCollaborationDto.*;
import com.example.planyourtrip.dto.TripPlanDto.TripResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.TripPlanCollaboratorRepository;
import com.example.planyourtrip.repository.TripPlanRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Collaborator management and public/private sharing for {@link TripPlan}.
 * Every mutating operation here (invite, role change, removal, publish toggle)
 * is strictly owner-only — collaborators never manage other collaborators, even
 * EDITORs. Reuses {@link TripPlannerService#toResponse} for the nested
 * trip→days→items mapping rather than re-implementing it.
 */
@Service
public class TripCollaborationService {

    private final TripPlanRepository tripRepo;
    private final TripPlanCollaboratorRepository collaboratorRepo;
    private final UserRepository userRepo;
    private final NotificationService notificationService;
    private final TripPlannerService tripPlannerService;

    public TripCollaborationService(TripPlanRepository tripRepo,
                                     TripPlanCollaboratorRepository collaboratorRepo,
                                     UserRepository userRepo,
                                     NotificationService notificationService,
                                     TripPlannerService tripPlannerService) {
        this.tripRepo = tripRepo;
        this.collaboratorRepo = collaboratorRepo;
        this.userRepo = userRepo;
        this.notificationService = notificationService;
        this.tripPlannerService = tripPlannerService;
    }

    @Transactional
    public TripCollaboratorResponse inviteCollaborator(Long ownerId, Long tripId, TripCollaboratorRequest req) {
        TripPlan trip = myTripOrThrow(ownerId, tripId);
        User target = userRepo.findByEmail(req.email())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found: " + req.email()));

        if (target.getId().equals(ownerId))
            throw new ApiException(HttpStatus.BAD_REQUEST, "The trip owner cannot be added as a collaborator");
        if (collaboratorRepo.existsByTripPlanIdAndUserId(trip.getId(), target.getId()))
            throw new ApiException(HttpStatus.CONFLICT, "This user is already a collaborator on this trip");

        TripPlanCollaborator collaborator = new TripPlanCollaborator();
        collaborator.setTripPlan(trip);
        collaborator.setUser(target);
        collaborator.setRole(req.role());
        collaborator.setActive(true);
        TripPlanCollaborator saved = collaboratorRepo.save(collaborator);

        notificationService.create(target.getId(), NotificationType.TRIP, Priority.NORMAL,
            "You were invited to collaborate on a trip",
            "You were invited to collaborate on \"" + trip.getTitle() + "\" as " + req.role().name() + ".",
            RelatedEntityType.TRIP, trip.getId());

        return toResponse(saved);
    }

    @Transactional
    public TripCollaboratorResponse updateCollaboratorRole(Long ownerId, Long tripId, Long collaboratorId,
                                                             TripCollaboratorRequest req) {
        TripPlan trip = myTripOrThrow(ownerId, tripId);
        TripPlanCollaborator collaborator = collaboratorInTripOrThrow(trip.getId(), collaboratorId);
        collaborator.setRole(req.role());
        return toResponse(collaboratorRepo.save(collaborator));
    }

    @Transactional
    public void removeCollaborator(Long ownerId, Long tripId, Long collaboratorId) {
        TripPlan trip = myTripOrThrow(ownerId, tripId);
        TripPlanCollaborator collaborator = collaboratorInTripOrThrow(trip.getId(), collaboratorId);
        collaboratorRepo.delete(collaborator);
    }

    @Transactional(readOnly = true)
    public List<TripCollaboratorResponse> listCollaborators(Long ownerId, Long tripId) {
        TripPlan trip = myTripOrThrow(ownerId, tripId);
        return collaboratorRepo.findByTripPlanIdOrderByCreatedAtAsc(trip.getId())
            .stream().map(this::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<SharedTripResponse> listSharedTrips(Long userId) {
        return collaboratorRepo.findByUserIdAndActiveTrueOrderByCreatedAtDesc(userId)
            .stream().map(this::toSharedTripResponse).toList();
    }

    @Transactional
    public TripShareResponse setPublic(Long ownerId, Long tripId, boolean isPublic) {
        TripPlan trip = myTripOrThrow(ownerId, tripId);
        trip.setPublic(isPublic);
        tripRepo.save(trip);
        return new TripShareResponse(trip.getId(), trip.isPublic());
    }

    @Transactional(readOnly = true)
    public TripResponse getPublicTrip(Long tripId) {
        TripPlan trip = tripRepo.findById(tripId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Trip not found: " + tripId));
        if (!trip.isPublic())
            throw new ApiException(HttpStatus.NOT_FOUND, "Trip not found: " + tripId);
        return tripPlannerService.toResponse(trip);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    /**
     * Strictly owner-only. A collaborator (who can already see the trip exists)
     * gets 403 here, not 404 — 404 is reserved for callers with no relationship
     * to the trip at all.
     */
    private TripPlan myTripOrThrow(Long ownerId, Long tripId) {
        TripPlan trip = tripRepo.findById(tripId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Trip not found: " + tripId));
        boolean isOwner = trip.getUser().getId().equals(ownerId);
        if (isOwner) return trip;
        boolean isCollaborator = collaboratorRepo.existsByTripPlanIdAndUserId(trip.getId(), ownerId);
        if (isCollaborator)
            throw new ApiException(HttpStatus.FORBIDDEN, "Only the trip owner can perform this action");
        throw new ApiException(HttpStatus.NOT_FOUND, "Trip not found: " + tripId);
    }

    private TripPlanCollaborator collaboratorInTripOrThrow(Long tripId, Long collaboratorId) {
        return collaboratorRepo.findByIdAndTripPlanId(collaboratorId, tripId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Collaborator not found: " + collaboratorId));
    }

    private TripCollaboratorResponse toResponse(TripPlanCollaborator c) {
        return new TripCollaboratorResponse(
            c.getId(), c.getTripPlan().getId(), c.getUser().getId(),
            c.getUser().getEmail(), c.getUser().getFullName(),
            c.getRole().name(), c.isActive(), c.getInvitedAt(), c.getAcceptedAt(),
            c.getCreatedAt(), c.getUpdatedAt()
        );
    }

    private SharedTripResponse toSharedTripResponse(TripPlanCollaborator c) {
        TripPlan trip = c.getTripPlan();
        return new SharedTripResponse(
            trip.getId(), trip.getTitle(), trip.getDestination(), trip.getCoverImage(),
            trip.getStartDate(), trip.getEndDate(), trip.getStatus().name(),
            trip.getUser().getFullName(), c.getRole().name()
        );
    }
}
