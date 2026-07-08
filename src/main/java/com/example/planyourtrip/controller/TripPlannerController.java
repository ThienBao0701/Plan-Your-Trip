package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.TripPlanDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.TripPlannerService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/me/trips")
@Tag(name = "Customer - Trip Planner", description = "Multi-day itinerary planner: trips, days and ordered items")
@SecurityRequirement(name = "bearerAuth")
public class TripPlannerController {

    private final TripPlannerService service;

    public TripPlannerController(TripPlannerService service) { this.service = service; }

    // ── Trip ──────────────────────────────────────────────────────────────────

    @GetMapping
    @Operation(summary = "List my trips")
    public List<TripSummaryResponse> list(@AuthUser Long uid) {
        return service.getMine(uid);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a trip")
    public TripResponse create(@AuthUser Long uid, @Valid @RequestBody TripRequest req) {
        return service.createTrip(uid, req);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get a trip with its days and items, fully ordered")
    public TripResponse get(@AuthUser Long uid, @PathVariable Long id) {
        return service.getById(uid, id);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update a trip")
    public TripResponse update(@AuthUser Long uid, @PathVariable Long id, @Valid @RequestBody TripRequest req) {
        return service.updateTrip(uid, id, req);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete a trip and cascade its days and items")
    public void delete(@AuthUser Long uid, @PathVariable Long id) {
        service.deleteTrip(uid, id);
    }

    @PostMapping("/{id}/duplicate")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Duplicate a trip, copying all days and items")
    public TripResponse duplicate(@AuthUser Long uid, @PathVariable Long id) {
        return service.duplicateTrip(uid, id);
    }

    // ── Day ───────────────────────────────────────────────────────────────────

    @PostMapping("/{tripId}/days")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Add a day to a trip")
    public TripDayResponse addDay(@AuthUser Long uid, @PathVariable Long tripId, @Valid @RequestBody TripDayRequest req) {
        return service.addDay(uid, tripId, req);
    }

    @PutMapping("/days/{dayId}")
    @Operation(summary = "Update a trip day")
    public TripDayResponse updateDay(@AuthUser Long uid, @PathVariable Long dayId, @Valid @RequestBody TripDayRequest req) {
        return service.updateDay(uid, dayId, req);
    }

    @DeleteMapping("/days/{dayId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete a trip day and its items")
    public void deleteDay(@AuthUser Long uid, @PathVariable Long dayId) {
        service.deleteDay(uid, dayId);
    }

    @PatchMapping("/days/{dayId}/reorder")
    @Operation(summary = "Reorder every item within a day")
    public TripDayResponse reorderDay(@AuthUser Long uid, @PathVariable Long dayId,
                                       @Valid @RequestBody ReorderTripDayRequest req) {
        return service.reorderDay(uid, dayId, req);
    }

    // ── Item ──────────────────────────────────────────────────────────────────

    @PostMapping("/days/{dayId}/items")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Add an item (a place or a custom activity) to a day")
    public TripItemResponse addItem(@AuthUser Long uid, @PathVariable Long dayId, @RequestBody TripItemRequest req) {
        return service.addItem(uid, dayId, req);
    }

    @PutMapping("/items/{itemId}")
    @Operation(summary = "Update a trip item")
    public TripItemResponse updateItem(@AuthUser Long uid, @PathVariable Long itemId, @RequestBody TripItemRequest req) {
        return service.updateItem(uid, itemId, req);
    }

    @DeleteMapping("/items/{itemId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete a trip item")
    public void deleteItem(@AuthUser Long uid, @PathVariable Long itemId) {
        service.deleteItem(uid, itemId);
    }

    @PatchMapping("/items/{itemId}/move")
    @Operation(summary = "Move an item to another day and/or position")
    public TripItemResponse moveItem(@AuthUser Long uid, @PathVariable Long itemId,
                                      @Valid @RequestBody MoveTripItemRequest req) {
        return service.moveItem(uid, itemId, req);
    }
}
