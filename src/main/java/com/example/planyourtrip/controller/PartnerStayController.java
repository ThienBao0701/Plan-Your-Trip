package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PartnerGuestStayDto.PartnerGuestStayResponse;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.PartnerBookingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

/**
 * Phase 7.42 — Consolidated READ-ONLY Partner Guest Stay Detail.
 *
 * <p>One authenticated (PARTNER/ADMIN via the existing {@code /api/partner/**} rule), ownership-scoped,
 * strictly READ-ONLY endpoint that returns the whole guest-stay screen for a booking in a single call —
 * a superset of {@code GET /api/partner/bookings/{id}} for the stay use-case. An unknown booking AND a
 * booking outside the caller's properties both return a uniform 404 (no cross-partner leak). It mutates
 * nothing — only reads existing rows (see {@link PartnerBookingService#getGuestStay}).
 */
@RestController
@Tag(name = "Partner - Stays", description = "Approved partners view a consolidated read-only guest stay detail")
@SecurityRequirement(name = "bearerAuth")
public class PartnerStayController {

    private final PartnerBookingService service;

    public PartnerStayController(PartnerBookingService service) {
        this.service = service;
    }

    @GetMapping("/api/partner/stays/{bookingId}")
    @Operation(summary = "Consolidated read-only guest stay detail",
        description = "Returns one PartnerGuestStayResponse: booking, guest, hotel/room, derived stay "
            + "schedule/state/night counts, voucher status classification, the reused lifecycle timeline, "
            + "modification history, at-most-one check-in and check-out audit, and derived operational "
            + "warnings. Strictly READ-ONLY — mutates nothing. Unknown booking or a booking outside the "
            + "caller's properties both return a uniform 404.")
    public PartnerGuestStayResponse getGuestStay(@AuthUser Long uid, @PathVariable Long bookingId) {
        return service.getGuestStay(uid, bookingId);
    }
}
