package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.RatePlanDto.RatePlanCancellationPreviewResponse;
import com.example.planyourtrip.dto.RatePlanDto.RatePlanPricingBreakdownResponse;
import com.example.planyourtrip.service.RatePlanPricingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

/**
 * Phase 7.29 — public rate-plan discovery, pricing preview and cancellation preview for a
 * room and stay. Read-only and unauthenticated (see SecurityConfig permitAll). The existing
 * {@code GET /api/rooms/{roomId}/pricing} endpoint is unchanged and remains the promotion
 * pricing breakdown; these endpoints add the rate-plan dimension.
 */
@RestController
@Tag(name = "Rate Plans", description = "Public rate-plan listing and pricing preview")
public class CustomerRatePlanController {

    private final RatePlanPricingService pricingService;

    public CustomerRatePlanController(RatePlanPricingService pricingService) {
        this.pricingService = pricingService;
    }

    @GetMapping("/api/rooms/{roomId}/rate-plans")
    @Operation(summary = "List sellable rate plans for a room with pricing + eligibility for a stay")
    public List<RatePlanPricingBreakdownResponse> list(
            @PathVariable Long roomId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkIn,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkOut,
            @RequestParam(defaultValue = "2") int adults,
            @RequestParam(defaultValue = "0") int children,
            @RequestParam(defaultValue = "0") int extraBeds) {
        return pricingService.previewRoom(roomId, checkIn, checkOut, adults, children, extraBeds);
    }

    @GetMapping("/api/rooms/{roomId}/rate-plans/{ratePlanId}/preview")
    @Operation(summary = "Pricing + eligibility + cancellation terms for one rate plan and stay")
    public RatePlanPricingBreakdownResponse preview(
            @PathVariable Long roomId,
            @PathVariable Long ratePlanId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkIn,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkOut,
            @RequestParam(defaultValue = "2") int adults,
            @RequestParam(defaultValue = "0") int children,
            @RequestParam(defaultValue = "0") int extraBeds) {
        return pricingService.preview(roomId, ratePlanId, checkIn, checkOut, adults, children, extraBeds);
    }

    @GetMapping("/api/rooms/{roomId}/rate-plans/{ratePlanId}/cancellation-preview")
    @Operation(summary = "Preview the cancellation penalty for one rate plan and stay")
    public RatePlanCancellationPreviewResponse cancellationPreview(
            @PathVariable Long roomId,
            @PathVariable Long ratePlanId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkIn,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkOut,
            @RequestParam(defaultValue = "2") int adults,
            @RequestParam(defaultValue = "0") int children,
            @RequestParam(defaultValue = "0") int extraBeds) {
        return pricingService.cancellationPreview(roomId, ratePlanId, checkIn, checkOut, adults, children, extraBeds);
    }
}
