package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PromotionDto.PricingBreakdownResponse;
import com.example.planyourtrip.dto.RatePlanDto.RatePlanRequest;
import com.example.planyourtrip.dto.RatePlanDto.RatePlanResponse;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.PartnerPricingService;
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
@Tag(name = "Partner - Pricing", description = "Approved partners manage rate plans and preview pricing for rooms they own")
@SecurityRequirement(name = "bearerAuth")
public class PartnerPricingController {

    private final PartnerPricingService service;

    public PartnerPricingController(PartnerPricingService service) { this.service = service; }

    @GetMapping("/api/partner/rooms/{roomId}/rate-plans")
    @Operation(summary = "List rate plans for one of my rooms")
    public List<RatePlanResponse> listRatePlans(@AuthUser Long uid, @PathVariable Long roomId) {
        return service.getRatePlans(uid, roomId);
    }

    @PostMapping("/api/partner/rooms/{roomId}/rate-plans")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a rate plan for one of my rooms")
    public RatePlanResponse createRatePlan(@AuthUser Long uid, @PathVariable Long roomId,
                                            @Valid @RequestBody RatePlanRequest req) {
        return service.createRatePlan(uid, roomId, req);
    }

    @PutMapping("/api/partner/rate-plans/{id}")
    @Operation(summary = "Update a rate plan I own")
    public RatePlanResponse updateRatePlan(@AuthUser Long uid, @PathVariable Long id,
                                            @Valid @RequestBody RatePlanRequest req) {
        return service.updateRatePlan(uid, id, req);
    }

    @DeleteMapping("/api/partner/rate-plans/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete a rate plan I own")
    public void deleteRatePlan(@AuthUser Long uid, @PathVariable Long id) {
        service.deleteRatePlan(uid, id);
    }

    @GetMapping("/api/partner/rooms/{roomId}/pricing-preview")
    @Operation(summary = "Preview computed pricing for one of my rooms (reuses PricingEngineService)")
    public PricingBreakdownResponse pricingPreview(
            @AuthUser Long uid,
            @PathVariable Long roomId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkIn,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkOut) {
        return service.getPricingPreview(uid, roomId, checkIn, checkOut);
    }
}
