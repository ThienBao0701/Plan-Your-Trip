package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.InventoryReservationDto.*;
import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.model.InventoryReservationStatus;
import com.example.planyourtrip.service.InventoryReservationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

/**
 * Phase 7.28 — Inventory Lock &amp; Room Hold (admin inspection). Access is restricted to
 * ROLE_ADMIN by SecurityConfig's blanket {@code /api/admin/**} rule.
 */
@RestController
@RequestMapping("/api/admin/inventory-reservations")
@Tag(name = "Admin - Inventory Reservations",
     description = "Inspect temporary room holds and run the expiry sweep")
@SecurityRequirement(name = "bearerAuth")
public class AdminInventoryReservationController {

    private final InventoryReservationService service;

    public AdminInventoryReservationController(InventoryReservationService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "List inventory reservations (newest first; optional status filter, paged)")
    public PageResponse<ReservationResponse> list(
            @RequestParam(required = false) InventoryReservationStatus status,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size) {
        return service.adminList(status, page, size);
    }

    @GetMapping("/booking/{bookingId}")
    @Operation(summary = "Get the inventory reservation for a booking")
    public ReservationResponse getByBooking(@PathVariable Long bookingId) {
        return service.adminGetByBooking(bookingId);
    }

    @PostMapping("/process-expirations")
    @Operation(summary = "Expiry sweep — release all overdue HELD holds (no scheduler in this phase)")
    public ExpirationResultResponse processExpirations() {
        return service.expireOverdueHolds();
    }
}
