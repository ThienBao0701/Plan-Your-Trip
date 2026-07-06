package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PromotionDto.PricingBreakdownResponse;
import com.example.planyourtrip.service.PricingEngineService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@Tag(name = "Pricing")
public class PricingController {

    private final PricingEngineService service;

    public PricingController(PricingEngineService service) {
        this.service = service;
    }

    @GetMapping("/api/rooms/{roomId}/pricing")
    @Operation(summary = "Calculate pricing breakdown for a room and stay dates")
    public PricingBreakdownResponse getPricing(
            @PathVariable Long roomId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkIn,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkOut) {
        return service.calculate(roomId, checkIn, checkOut);
    }
}
