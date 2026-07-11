package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.LoyaltyDto.*;
import com.example.planyourtrip.service.LoyaltyService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

/**
 * Phase 7.18 — Loyalty Points Foundation.
 * Admin-only loyalty operations: read-only support view plus the ONLY
 * mutation path exposed for loyalty points (manual grant). Customers can
 * never mutate their own balance — a customer token hitting these endpoints
 * gets 403 from SecurityConfig's blanket {@code /api/admin/**} rule.
 */
@RestController
@RequestMapping("/api/admin/users")
@Tag(name = "Admin - Loyalty Points", description = "Support view and manual grant of loyalty points")
@SecurityRequirement(name = "bearerAuth")
public class AdminLoyaltyController {

    private final LoyaltyService service;

    public AdminLoyaltyController(LoyaltyService service) { this.service = service; }

    @GetMapping("/{userId}/loyalty")
    @Operation(summary = "Inspect a user's loyalty account and recent transactions (read-only; never creates the account)")
    public LoyaltyAdminViewResponse view(@PathVariable Long userId) {
        return service.adminView(userId);
    }

    @PostMapping("/{userId}/loyalty/grant")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Grant loyalty points (immutable ledger entry; idempotent via idempotencyKey)")
    public LoyaltyTransactionResponse grant(@PathVariable Long userId,
                                             @Valid @RequestBody LoyaltyGrantRequest req) {
        return service.adminGrant(userId, req);
    }
}
