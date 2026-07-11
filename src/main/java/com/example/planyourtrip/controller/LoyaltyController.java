package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.dto.LoyaltyDto.*;
import com.example.planyourtrip.model.LoyaltyTransactionType;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.LoyaltyService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

/**
 * Phase 7.18 — Loyalty Points Foundation.
 * Customer-side READ-ONLY view of loyalty points: balance/lifetime-earned and
 * immutable transaction history. There are deliberately no customer mutation
 * endpoints — points can only be earned automatically (booking completion),
 * awarded internally (review bonus) or granted by an admin.
 */
@RestController
@RequestMapping("/api/me/loyalty")
@Tag(name = "Customer - Loyalty Points", description = "Loyalty points balance and immutable transaction history (read-only)")
@SecurityRequirement(name = "bearerAuth")
public class LoyaltyController {

    private final LoyaltyService service;

    public LoyaltyController(LoyaltyService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "Get my loyalty account (currentBalance + lifetimePointsEarned); created lazily on first access")
    public LoyaltyAccountResponse account(@AuthUser Long uid) {
        return service.getOrCreateMyAccount(uid);
    }

    @GetMapping("/transactions")
    @Operation(summary = "List my loyalty transactions (immutable ledger), filterable by type and inclusive date range")
    public PageResponse<LoyaltyTransactionResponse> transactions(
            @AuthUser Long uid,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false) LoyaltyTransactionType type,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return service.myTransactions(uid, page, size, type, from, to);
    }
}
