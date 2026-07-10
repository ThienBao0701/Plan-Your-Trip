package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.TravelCreditDto.CreditExpirationRunResponse;
import com.example.planyourtrip.service.TravelCreditService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Phase 7.16 — Coupon &amp; Credit Lifecycle Completion (admin manual trigger).
 * Expires unspent promotional travel credits whose grant carried an
 * {@code expiresAt} that has passed. No scheduler is wired up — system-wide
 * processing is triggered manually here, mirroring
 * {@code AdminWalletExpiryController} (7.13) / {@code AdminTripReminderController}
 * (7.11). Access is restricted to ROLE_ADMIN by SecurityConfig's blanket
 * {@code "/api/admin/**"} -&gt; hasRole("ADMIN") rule, matching every other
 * admin controller in this codebase.
 */
@RestController
@RequestMapping("/api/admin/travel-credits")
@Tag(name = "Admin - Travel Credit Expiration",
     description = "Manual system-wide expiration sweep for promotional travel credits")
@SecurityRequirement(name = "bearerAuth")
public class AdminCreditExpirationController {

    private final TravelCreditService travelCreditService;

    public AdminCreditExpirationController(TravelCreditService travelCreditService) {
        this.travelCreditService = travelCreditService;
    }

    @PostMapping("/process-expirations")
    @Operation(summary = "Expire unspent credits from grants whose expiresAt has passed, system-wide "
        + "(FIFO unconsumed computation; one immutable EXPIRATION ledger row per grant; idempotent across runs)")
    public CreditExpirationRunResponse processExpirations() {
        return travelCreditService.processExpirations();
    }
}
