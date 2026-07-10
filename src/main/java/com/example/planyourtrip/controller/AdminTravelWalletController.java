package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.TravelWalletDto.TravelWalletSummaryResponse;
import com.example.planyourtrip.service.TravelWalletService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Phase 7.12 — Travel Wallet Foundation (admin read-only support view).
 * Mirrors {@code AdminCustomerProfileController}'s {@code /api/admin/users/{id}/...}
 * shape exactly. Never mutates a wallet item — access is restricted to
 * ROLE_ADMIN by SecurityConfig's blanket {@code "/api/admin/**"} ->
 * hasRole("ADMIN") rule, matching every other admin controller (no
 * per-controller @PreAuthorize needed).
 */
@RestController
@RequestMapping("/api/admin/users")
@Tag(name = "Admin - Travel Wallet", description = "Read-only admin visibility into a user's travel wallet")
public class AdminTravelWalletController {

    private final TravelWalletService service;

    public AdminTravelWalletController(TravelWalletService service) { this.service = service; }

    @GetMapping("/{userId}/travel-wallet")
    @Operation(summary = "List a user's travel wallet items (read-only)")
    public List<TravelWalletSummaryResponse> list(@PathVariable Long userId) {
        return service.adminList(userId);
    }
}
