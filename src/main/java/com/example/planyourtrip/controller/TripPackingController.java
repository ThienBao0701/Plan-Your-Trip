package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.TripPlanPackingDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.TripPlanPackingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/me/trips")
@Tag(name = "Customer - Trip Packing Checklist", description = "Per-trip packing checklist")
@SecurityRequirement(name = "bearerAuth")
public class TripPackingController {

    private final TripPlanPackingService service;

    public TripPackingController(TripPlanPackingService service) { this.service = service; }

    @GetMapping("/{tripId}/packing")
    @Operation(summary = "List a trip's packing checklist, unchecked first, then by order")
    public List<TripPlanPackingItemResponse> list(@AuthUser Long uid, @PathVariable Long tripId) {
        return service.list(uid, tripId);
    }

    @PostMapping("/{tripId}/packing")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Add a packing item (owner or EDITOR collaborator)")
    public TripPlanPackingItemResponse create(@AuthUser Long uid, @PathVariable Long tripId,
                                               @Valid @RequestBody TripPlanPackingItemRequest req) {
        return service.create(uid, tripId, req);
    }

    @PutMapping("/packing/{itemId}")
    @Operation(summary = "Update a packing item (owner or EDITOR collaborator)")
    public TripPlanPackingItemResponse update(@AuthUser Long uid, @PathVariable Long itemId,
                                               @Valid @RequestBody TripPlanPackingItemRequest req) {
        return service.update(uid, itemId, req);
    }

    @DeleteMapping("/packing/{itemId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete a packing item (owner or EDITOR collaborator)")
    public void delete(@AuthUser Long uid, @PathVariable Long itemId) {
        service.delete(uid, itemId);
    }

    @PatchMapping("/packing/{itemId}/check")
    @Operation(summary = "Mark a packing item as checked")
    public TripPlanPackingItemResponse check(@AuthUser Long uid, @PathVariable Long itemId) {
        return service.check(uid, itemId);
    }

    @PatchMapping("/packing/{itemId}/uncheck")
    @Operation(summary = "Mark a packing item as unchecked")
    public TripPlanPackingItemResponse uncheck(@AuthUser Long uid, @PathVariable Long itemId) {
        return service.uncheck(uid, itemId);
    }

    @PatchMapping("/{tripId}/packing/reorder")
    @Operation(summary = "Reorder a trip's packing checklist")
    public List<TripPlanPackingItemResponse> reorder(@AuthUser Long uid, @PathVariable Long tripId,
                                                       @Valid @RequestBody TripPlanPackingReorderRequest req) {
        return service.reorder(uid, tripId, req);
    }
}
