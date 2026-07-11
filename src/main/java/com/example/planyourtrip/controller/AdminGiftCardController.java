package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.GiftCardDto.*;
import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.model.GiftCardStatus;
import com.example.planyourtrip.service.GiftCardService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;

/**
 * Phase 7.24 — Gift Cards Foundation.
 * Admin-only gift-card administration: issuance, activation, cancellation,
 * manual adjustment, filtered listing and the manual expiration processor.
 * Access is restricted to ROLE_ADMIN by SecurityConfig's blanket
 * {@code /api/admin/**} rule.
 */
@RestController
@RequestMapping("/api/admin/gift-cards")
@Tag(name = "Admin - Gift Cards", description = "Issuance, activation, cancellation, adjustment and expiration administration")
@SecurityRequirement(name = "bearerAuth")
public class AdminGiftCardController {

    private final GiftCardService service;

    public AdminGiftCardController(GiftCardService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "List gift cards with optional filters (code, purchaser, recipient, status, product, issued/expiry ranges)")
    public PageResponse<GiftCardResponse> list(
            @RequestParam(required = false) String code,
            @RequestParam(required = false) Long purchaserUserId,
            @RequestParam(required = false) Long recipientUserId,
            @RequestParam(required = false) GiftCardStatus status,
            @RequestParam(required = false) Long productId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant issuedFrom,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant issuedTo,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant expiresFrom,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant expiresTo,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size) {
        return service.adminList(code, purchaserUserId, recipientUserId, status, productId,
            issuedFrom, issuedTo, expiresFrom, expiresTo, page, size);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get a gift card by id (support view; masked code)")
    public GiftCardResponse get(@PathVariable Long id) {
        return service.adminGet(id);
    }

    @PostMapping("/issue")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Admin-issue a gift card (purchaserUserId optional — null for a house/campaign grant); "
        + "response includes the full redeemable code once")
    public GiftCardResponse issue(@Valid @RequestBody AdminGiftCardIssueRequest req) {
        return service.issueForAdmin(req);
    }

    @PostMapping("/{id}/activate")
    @Operation(summary = "Admin activation for support/testing — bypasses the purchaser/recipient ownership gate")
    public GiftCardResponse activate(@PathVariable Long id) {
        return service.adminActivate(id);
    }

    @PostMapping("/{id}/cancel")
    @Operation(summary = "Cancel a gift card (zeroes remaining balance; idempotent; no cash refund)")
    public GiftCardResponse cancel(@PathVariable Long id) {
        return service.adminCancel(id);
    }

    @PostMapping("/{id}/adjust")
    @Operation(summary = "Manually credit or debit a gift card balance (immutable ledger row; idempotent via idempotencyKey)")
    public GiftCardTransactionResponse adjust(@PathVariable Long id, @Valid @RequestBody GiftCardAdjustmentRequest req) {
        return service.adminAdjust(id, req);
    }

    @GetMapping("/{id}/transactions")
    @Operation(summary = "List the immutable ledger transactions for a gift card")
    public PageResponse<GiftCardTransactionResponse> transactions(
            @PathVariable Long id,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size) {
        return service.adminTransactions(id, page, size);
    }

    @PostMapping("/process-expirations")
    @Operation(summary = "Manually process gift card expirations (no scheduler in this phase; idempotent)")
    public GiftCardExpirationResultResponse processExpirations() {
        return service.processExpirations();
    }
}
