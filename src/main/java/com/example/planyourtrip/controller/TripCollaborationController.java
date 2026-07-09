package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.TripCollaborationDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.TripCollaborationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/me/trips")
@Tag(name = "Customer - Trip Collaboration", description = "Invite collaborators to a trip and manage public/private sharing")
@SecurityRequirement(name = "bearerAuth")
public class TripCollaborationController {

    private final TripCollaborationService service;

    public TripCollaborationController(TripCollaborationService service) { this.service = service; }

    @GetMapping("/shared")
    @Operation(summary = "List trips shared with me as an active collaborator")
    public List<SharedTripResponse> listShared(@AuthUser Long uid) {
        return service.listSharedTrips(uid);
    }

    @GetMapping("/{tripId}/collaborators")
    @Operation(summary = "List a trip's collaborators (owner only)")
    public List<TripCollaboratorResponse> listCollaborators(@AuthUser Long uid, @PathVariable Long tripId) {
        return service.listCollaborators(uid, tripId);
    }

    @PostMapping("/{tripId}/collaborators")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Invite a collaborator by email (owner only)")
    public TripCollaboratorResponse invite(@AuthUser Long uid, @PathVariable Long tripId,
                                            @Valid @RequestBody TripCollaboratorRequest req) {
        return service.inviteCollaborator(uid, tripId, req);
    }

    @PatchMapping("/{tripId}/collaborators/{collaboratorId}")
    @Operation(summary = "Update a collaborator's role (owner only)")
    public TripCollaboratorResponse updateRole(@AuthUser Long uid, @PathVariable Long tripId,
                                                @PathVariable Long collaboratorId,
                                                @Valid @RequestBody TripCollaboratorRequest req) {
        return service.updateCollaboratorRole(uid, tripId, collaboratorId, req);
    }

    @DeleteMapping("/{tripId}/collaborators/{collaboratorId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Remove a collaborator (owner only)")
    public void removeCollaborator(@AuthUser Long uid, @PathVariable Long tripId, @PathVariable Long collaboratorId) {
        service.removeCollaborator(uid, tripId, collaboratorId);
    }

    @PatchMapping("/{tripId}/public")
    @Operation(summary = "Make a trip publicly viewable (owner only)")
    public TripShareResponse makePublic(@AuthUser Long uid, @PathVariable Long tripId) {
        return service.setPublic(uid, tripId, true);
    }

    @PatchMapping("/{tripId}/private")
    @Operation(summary = "Make a trip private again (owner only)")
    public TripShareResponse makePrivate(@AuthUser Long uid, @PathVariable Long tripId) {
        return service.setPublic(uid, tripId, false);
    }
}
