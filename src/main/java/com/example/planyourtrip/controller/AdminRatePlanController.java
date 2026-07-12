package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.RatePlanDto.*;
import com.example.planyourtrip.model.MealPlanType;
import com.example.planyourtrip.model.RatePlanType;
import com.example.planyourtrip.service.RatePlanPricingService;
import com.example.planyourtrip.service.RatePlanService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@Tag(name = "Admin - Rate Plans")
@SecurityRequirement(name = "bearerAuth")
public class AdminRatePlanController {

    private final RatePlanService service;
    private final RatePlanPricingService pricingService;

    public AdminRatePlanController(RatePlanService service, RatePlanPricingService pricingService) {
        this.service = service;
        this.pricingService = pricingService;
    }

    // ── Global list / filter (Phase 7.29) ─────────────────────────────────────

    @GetMapping("/api/admin/rate-plans")
    @Operation(summary = "List/filter all rate plans")
    public List<RatePlanResponse> filter(
            @RequestParam(required = false) Long hotelId,
            @RequestParam(required = false) Long roomId,
            @RequestParam(required = false) Boolean active,
            @RequestParam(required = false) RatePlanType type,
            @RequestParam(required = false) MealPlanType mealPlan,
            @RequestParam(required = false) Boolean refundable,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return service.filter(hotelId, roomId, active, type, mealPlan, refundable, from, to);
    }

    @GetMapping("/api/admin/rooms/{roomId}/rate-plans")
    @Operation(summary = "List rate plans for a room")
    public List<RatePlanResponse> listByRoom(@PathVariable Long roomId) {
        return service.getByRoom(roomId);
    }

    @PostMapping("/api/admin/rooms/{roomId}/rate-plans")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a rate plan for a room")
    public RatePlanResponse create(@PathVariable Long roomId,
                                    @Valid @RequestBody RatePlanRequest req) {
        return service.create(roomId, req);
    }

    @GetMapping("/api/admin/rate-plans/{id}")
    @Operation(summary = "Get a rate plan by ID")
    public RatePlanResponse getById(@PathVariable Long id) {
        return service.getById(id);
    }

    @PutMapping("/api/admin/rate-plans/{id}")
    @Operation(summary = "Update a rate plan")
    public RatePlanResponse update(@PathVariable Long id,
                                    @Valid @RequestBody RatePlanRequest req) {
        return service.update(id, req);
    }

    @DeleteMapping("/api/admin/rate-plans/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete a rate plan")
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }

    @PostMapping("/api/admin/rate-plans/{id}/activate")
    @Operation(summary = "Activate a rate plan")
    public RatePlanResponse activate(@PathVariable Long id) {
        return service.setActive(id, true);
    }

    @PostMapping("/api/admin/rate-plans/{id}/deactivate")
    @Operation(summary = "Deactivate a rate plan")
    public RatePlanResponse deactivate(@PathVariable Long id) {
        return service.setActive(id, false);
    }

    @PostMapping("/api/admin/rate-plans/{id}/duplicate")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Duplicate a rate plan")
    public RatePlanResponse duplicate(@PathVariable Long id,
                                      @RequestBody(required = false) RatePlanDuplicateRequest req) {
        return service.duplicate(id, req);
    }

    // ── Occupancy prices ──────────────────────────────────────────────────────

    @GetMapping("/api/admin/rate-plans/{id}/occupancy-prices")
    @Operation(summary = "List occupancy prices for a rate plan")
    public List<RatePlanOccupancyPriceResponse> listOccupancyPrices(@PathVariable Long id) {
        return service.getOccupancyPrices(id);
    }

    @PostMapping("/api/admin/rate-plans/{id}/occupancy-prices")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Add an occupancy price to a rate plan")
    public RatePlanOccupancyPriceResponse addOccupancyPrice(@PathVariable Long id,
                                                            @Valid @RequestBody RatePlanOccupancyPriceRequest req) {
        return service.addOccupancyPrice(id, req);
    }

    @PutMapping("/api/admin/rate-plan-occupancy-prices/{id}")
    @Operation(summary = "Update an occupancy price")
    public RatePlanOccupancyPriceResponse updateOccupancyPrice(@PathVariable Long id,
                                                               @Valid @RequestBody RatePlanOccupancyPriceRequest req) {
        return service.updateOccupancyPrice(id, req);
    }

    @DeleteMapping("/api/admin/rate-plan-occupancy-prices/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete an occupancy price")
    public void deleteOccupancyPrice(@PathVariable Long id) {
        service.deleteOccupancyPrice(id);
    }

    // ── Validation / pricing preview ──────────────────────────────────────────

    @GetMapping("/api/admin/rate-plans/{id}/preview")
    @Operation(summary = "Preview rate-plan pricing/eligibility for a stay")
    public RatePlanPricingBreakdownResponse preview(
            @PathVariable Long id,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkIn,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkOut,
            @RequestParam(defaultValue = "2") int adults,
            @RequestParam(defaultValue = "0") int children,
            @RequestParam(defaultValue = "0") int extraBeds) {
        return pricingService.previewByPlan(id, checkIn, checkOut, adults, children, extraBeds);
    }

    @PostMapping("/api/admin/rate-plans/{id}/validate")
    @Operation(summary = "Validate rate-plan eligibility for a stay")
    public RatePlanEligibilityResponse validate(@PathVariable Long id,
                                                @Valid @RequestBody RatePlanEligibilityRequest req) {
        return pricingService.validate(id, req);
    }
}
