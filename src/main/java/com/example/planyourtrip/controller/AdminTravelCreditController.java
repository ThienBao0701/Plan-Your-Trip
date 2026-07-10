package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.TravelCreditDto.*;
import com.example.planyourtrip.service.TravelCreditService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

/**
 * Phase 7.14 — Customer Coupons &amp; Travel Credits Foundation.
 * Admin-only travel-credit operations: read-only support view plus the ONLY
 * two mutation paths that exist for promotional credits (grant/deduct).
 * Customers can never mutate their own balance — a customer token hitting
 * these endpoints gets 403 from SecurityConfig's blanket {@code /api/admin/**}
 * rule. Promotional credit only: no withdrawal, transfer or cash-out.
 */
@RestController
@RequestMapping("/api/admin/users")
@Tag(name = "Admin - Travel Credits", description = "Support view and grant/deduct of promotional travel credits")
@SecurityRequirement(name = "bearerAuth")
public class AdminTravelCreditController {

    private final TravelCreditService service;

    public AdminTravelCreditController(TravelCreditService service) { this.service = service; }

    @GetMapping("/{userId}/travel-credits")
    @Operation(summary = "Inspect a user's travel-credit account and recent transactions (read-only; never creates the account)")
    public TravelCreditAdminViewResponse view(@PathVariable Long userId) {
        return service.adminView(userId);
    }

    @PostMapping("/{userId}/travel-credits/grant")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Grant promotional travel credits (immutable ledger entry; idempotent via idempotencyKey)")
    public TravelCreditTransactionResponse grant(@PathVariable Long userId,
                                                  @Valid @RequestBody TravelCreditAdjustmentRequest req) {
        return service.grant(userId, req);
    }

    @PostMapping("/{userId}/travel-credits/deduct")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Deduct promotional travel credits (409 if it would overdraw; idempotent via idempotencyKey)")
    public TravelCreditTransactionResponse deduct(@PathVariable Long userId,
                                                   @Valid @RequestBody TravelCreditAdjustmentRequest req) {
        return service.deduct(userId, req);
    }
}
