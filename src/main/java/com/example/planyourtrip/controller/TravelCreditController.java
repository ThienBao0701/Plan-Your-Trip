package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.dto.TravelCreditDto.*;
import com.example.planyourtrip.model.TravelCreditTransactionType;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.TravelCreditService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

/**
 * Phase 7.14 — Customer Coupons &amp; Travel Credits Foundation.
 * Customer-side READ-ONLY view of promotional travel credits: balance and
 * immutable transaction history. There are deliberately no customer mutation
 * endpoints — credits can only be granted/deducted by admins, and can never be
 * withdrawn, transferred or converted to cash.
 */
@RestController
@RequestMapping("/api/me/travel-credits")
@Tag(name = "Customer - Travel Credits", description = "Promotional platform credit balance and immutable transaction history (read-only)")
@SecurityRequirement(name = "bearerAuth")
public class TravelCreditController {

    private final TravelCreditService service;

    public TravelCreditController(TravelCreditService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "Get my travel-credit account (balance + currency); created lazily on first access")
    public TravelCreditAccountResponse account(@AuthUser Long uid) {
        return service.getOrCreateMyAccount(uid);
    }

    @GetMapping("/transactions")
    @Operation(summary = "List my credit transactions (immutable ledger), filterable by type and inclusive date range")
    public PageResponse<TravelCreditTransactionResponse> transactions(
            @AuthUser Long uid,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false) TravelCreditTransactionType type,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return service.myTransactions(uid, page, size, type, from, to);
    }
}
