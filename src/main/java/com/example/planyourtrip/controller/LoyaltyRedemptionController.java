package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.LoyaltyRedemptionDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.LoyaltyRedemptionService;
import com.example.planyourtrip.service.LoyaltyRedemptionService.ReserveOutcome;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Phase 7.20 — Loyalty Points Redemption.
 * Customer-facing redemption endpoints. A customer may only preview/reserve
 * against their own booking and may never access another customer's redemption
 * (403). Reservation is idempotent via a mandatory idempotency key.
 */
@RestController
@RequestMapping("/api/loyalty/redemptions")
@Tag(name = "Customer - Loyalty Redemption", description = "Preview, reserve and manage loyalty-point redemptions against bookings")
@SecurityRequirement(name = "bearerAuth")
public class LoyaltyRedemptionController {

    private final LoyaltyRedemptionService service;

    public LoyaltyRedemptionController(LoyaltyRedemptionService service) { this.service = service; }

    @PostMapping("/preview")
    @Operation(summary = "Preview a redemption (no mutation): conversion, discount, maximum redeemable, final payable")
    public RedemptionPreviewResponse preview(@AuthUser Long uid, @Valid @RequestBody RedemptionPreviewRequest req) {
        return service.preview(uid, req);
    }

    @PostMapping("/reserve")
    @Operation(summary = "Reserve points against a PENDING booking (idempotent; 201 new, 200 idempotent replay)")
    public ResponseEntity<RedemptionResponse> reserve(@AuthUser Long uid,
                                                       @Valid @RequestBody RedemptionReserveRequest req) {
        ReserveOutcome outcome = service.reserve(uid, req);
        return ResponseEntity.status(outcome.created() ? HttpStatus.CREATED : HttpStatus.OK)
            .body(outcome.response());
    }

    @GetMapping("/booking/{bookingId}")
    @Operation(summary = "Get the loyalty redemption for one of my bookings")
    public RedemptionResponse forBooking(@AuthUser Long uid, @PathVariable Long bookingId) {
        return service.getForBooking(uid, bookingId);
    }

    @GetMapping("/{redemptionReference}")
    @Operation(summary = "Get one of my redemptions by reference")
    public RedemptionResponse byReference(@AuthUser Long uid, @PathVariable String redemptionReference) {
        return service.getByReferenceForCustomer(uid, redemptionReference);
    }

    @PostMapping("/{redemptionReference}/release")
    @Operation(summary = "Release my own RESERVED redemption (restores points); idempotent")
    public RedemptionResponse release(@AuthUser Long uid, @PathVariable String redemptionReference) {
        return service.releaseByReference(uid, redemptionReference, false);
    }
}
