package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.InventoryReservationDto.ReservationResponse;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.InventoryReservationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

/**
 * Phase 7.28 — Inventory Lock &amp; Room Hold (customer-facing).
 *
 * <p>Lets a booking owner see the status of their room hold (HELD while payment is pending,
 * CONSUMED once paid, RELEASED/EXPIRED if the hold was given back). Authenticated at the JWT
 * layer and authorized by booking ownership inside the service.
 */
@RestController
@RequestMapping("/api/bookings/{bookingId}/inventory-reservation")
@Tag(name = "Inventory Reservation", description = "Room-hold status for a booking (owner)")
@SecurityRequirement(name = "bearerAuth")
public class InventoryReservationController {

    private final InventoryReservationService service;

    public InventoryReservationController(InventoryReservationService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "Get the inventory-reservation status for a booking (owner or admin)")
    public ReservationResponse get(@AuthUser Long uid, @PathVariable Long bookingId) {
        return service.getForBooking(uid, bookingId);
    }
}
