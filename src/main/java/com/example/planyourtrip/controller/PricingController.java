package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PromotionDto.PricingBreakdownResponse;
import com.example.planyourtrip.dto.RoomPricingQuoteDto.RoomPricingQuoteRequest;
import com.example.planyourtrip.dto.RoomPricingQuoteDto.RoomPricingQuoteResponse;
import com.example.planyourtrip.service.PricingEngineService;
import com.example.planyourtrip.service.RoomPricingQuoteService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@Tag(name = "Pricing")
public class PricingController {

    private final PricingEngineService service;
    private final RoomPricingQuoteService quoteService;

    public PricingController(PricingEngineService service, RoomPricingQuoteService quoteService) {
        this.service = service;
        this.quoteService = quoteService;
    }

    /**
     * LEGACY (pre-7.30) simple pricing breakdown. Retained for backward compatibility: it keeps
     * the older cheapest-active-plan selection and the {@link PricingBreakdownResponse} contract
     * unchanged. New frontend code should use {@code POST /api/rooms/{roomId}/pricing/quote}, which
     * uses the same priority-based rate-plan resolution as checkout and returns the richer
     * {@link RoomPricingQuoteResponse}.
     */
    @GetMapping("/api/rooms/{roomId}/pricing")
    @Operation(summary = "Legacy simple pricing breakdown (cheapest active plan) — kept for backward compatibility")
    public PricingBreakdownResponse getPricing(
            @PathVariable Long roomId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkIn,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkOut) {
        return service.calculate(roomId, checkIn, checkOut);
    }

    /**
     * Phase 7.32 — CANONICAL pricing quote. Read-only: resolves the same priority-based rate plan
     * and pre-customer-benefit price that availability search and booking checkout use, applies
     * promotions, and reports read-only inventory availability. Never creates a booking, holds
     * inventory, or consumes any customer benefit. Public (permitAll) like the legacy endpoint.
     */
    @PostMapping("/api/rooms/{roomId}/pricing/quote")
    @Operation(summary = "Canonical read-only pricing quote (priority-based plan + promotions, pre customer benefits)")
    public RoomPricingQuoteResponse quote(
            @PathVariable Long roomId,
            @Valid @RequestBody RoomPricingQuoteRequest request) {
        return quoteService.quote(roomId, request);
    }
}
