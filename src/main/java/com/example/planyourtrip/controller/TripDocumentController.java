package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.TripPlanDocumentDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.TripPlanDocumentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/me/trips")
@Tag(name = "Customer - Trip Documents & Attachments", description = "Travel documents attached to a trip, backed by the existing MediaAsset gallery")
@SecurityRequirement(name = "bearerAuth")
public class TripDocumentController {

    private final TripPlanDocumentService service;

    public TripDocumentController(TripPlanDocumentService service) { this.service = service; }

    @GetMapping("/{tripId}/documents")
    @Operation(summary = "List a trip's documents, pinned first then newest")
    public List<TripPlanDocumentResponse> list(@AuthUser Long uid, @PathVariable Long tripId) {
        return service.list(uid, tripId);
    }

    @PostMapping("/{tripId}/documents")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Attach a document to a trip (owner or EDITOR collaborator)",
        description = "Provide mediaAssetId to reuse an already-uploaded media asset, or url to register a new one.")
    public TripPlanDocumentResponse create(@AuthUser Long uid, @PathVariable Long tripId,
                                            @Valid @RequestBody TripPlanDocumentRequest req) {
        return service.create(uid, tripId, req);
    }

    @GetMapping("/documents/{id}")
    @Operation(summary = "Get a single document")
    public TripPlanDocumentResponse getDocument(@AuthUser Long uid, @PathVariable Long id) {
        return service.getDocument(uid, id);
    }

    @PutMapping("/documents/{id}")
    @Operation(summary = "Update a document's metadata (owner or EDITOR collaborator)")
    public TripPlanDocumentResponse update(@AuthUser Long uid, @PathVariable Long id,
                                            @Valid @RequestBody TripPlanDocumentRequest req) {
        return service.update(uid, id, req);
    }

    @DeleteMapping("/documents/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete a document (owner or EDITOR collaborator)")
    public void delete(@AuthUser Long uid, @PathVariable Long id) {
        service.delete(uid, id);
    }

    @PatchMapping("/documents/{id}/pin")
    @Operation(summary = "Pin a document to the top of the list")
    public TripPlanDocumentResponse pin(@AuthUser Long uid, @PathVariable Long id) {
        return service.pin(uid, id);
    }

    @PatchMapping("/documents/{id}/unpin")
    @Operation(summary = "Unpin a document")
    public TripPlanDocumentResponse unpin(@AuthUser Long uid, @PathVariable Long id) {
        return service.unpin(uid, id);
    }
}
