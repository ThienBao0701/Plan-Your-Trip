package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.TravelWalletOrganizerDto.WalletExpiryReminderResultResponse;
import com.example.planyourtrip.service.WalletExpiryReminderService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Phase 7.13 — Wallet Expiry Alerts &amp; Smart Organizer (admin manual trigger).
 * No scheduler is wired up in this phase; system-wide generation is triggered
 * manually here, mirroring {@code AdminTripReminderController} from Phase
 * 7.11. Access is restricted to ROLE_ADMIN by SecurityConfig's blanket
 * {@code "/api/admin/**"} -> hasRole("ADMIN") rule, matching every other
 * admin controller in this codebase (no per-controller @PreAuthorize needed).
 */
@RestController
@RequestMapping("/api/admin/travel-wallet")
@Tag(name = "Admin - Travel Wallet Expiry Reminders")
public class AdminWalletExpiryController {

    private final WalletExpiryReminderService expiryReminderService;

    public AdminWalletExpiryController(WalletExpiryReminderService expiryReminderService) {
        this.expiryReminderService = expiryReminderService;
    }

    @PostMapping("/generate-expiry-reminders")
    @Operation(summary = "Generate 30/7/1-day-before expiry reminders for every eligible wallet item, system-wide (idempotent)")
    public WalletExpiryReminderResultResponse generateForAllUsers() {
        return expiryReminderService.generateExpiryRemindersForAllUsers();
    }
}
