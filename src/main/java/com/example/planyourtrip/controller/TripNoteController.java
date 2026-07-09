package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.TripPlanNoteDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.TripPlanNoteService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/me/trips")
@Tag(name = "Customer - Trip Notes & Journal", description = "Freeform notes and journal entries for a trip")
@SecurityRequirement(name = "bearerAuth")
public class TripNoteController {

    private final TripPlanNoteService service;

    public TripNoteController(TripPlanNoteService service) { this.service = service; }

    @GetMapping("/{tripId}/notes")
    @Operation(summary = "List a trip's notes, pinned first then newest updated")
    public List<TripPlanNoteResponse> list(@AuthUser Long uid, @PathVariable Long tripId) {
        return service.list(uid, tripId);
    }

    @PostMapping("/{tripId}/notes")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Add a note or journal entry (owner or EDITOR collaborator)")
    public TripPlanNoteResponse create(@AuthUser Long uid, @PathVariable Long tripId,
                                        @Valid @RequestBody TripPlanNoteRequest req) {
        return service.create(uid, tripId, req);
    }

    @GetMapping("/notes/{noteId}")
    @Operation(summary = "Get a single note")
    public TripPlanNoteResponse getNote(@AuthUser Long uid, @PathVariable Long noteId) {
        return service.getNote(uid, noteId);
    }

    @PutMapping("/notes/{noteId}")
    @Operation(summary = "Update a note (owner or EDITOR collaborator)")
    public TripPlanNoteResponse update(@AuthUser Long uid, @PathVariable Long noteId,
                                        @Valid @RequestBody TripPlanNoteRequest req) {
        return service.update(uid, noteId, req);
    }

    @DeleteMapping("/notes/{noteId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete a note (owner or EDITOR collaborator)")
    public void delete(@AuthUser Long uid, @PathVariable Long noteId) {
        service.delete(uid, noteId);
    }

    @PatchMapping("/notes/{noteId}/pin")
    @Operation(summary = "Pin a note to the top of the list")
    public TripPlanNoteResponse pin(@AuthUser Long uid, @PathVariable Long noteId) {
        return service.pin(uid, noteId);
    }

    @PatchMapping("/notes/{noteId}/unpin")
    @Operation(summary = "Unpin a note")
    public TripPlanNoteResponse unpin(@AuthUser Long uid, @PathVariable Long noteId) {
        return service.unpin(uid, noteId);
    }
}
