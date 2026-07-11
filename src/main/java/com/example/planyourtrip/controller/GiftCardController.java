package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.GiftCardDto.*;
import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.model.GiftCardStatus;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.GiftCardService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

/**
 * Phase 7.24 — Gift Cards Foundation.
 * Customer-facing gift-card endpoints. A customer may view/act on a card only
 * when they are the purchaser or the recipient (or, for {@link #claim}, a
 * valid email claimant) — every other card is a 404, never a 403, per the
 * established "avoid leaking existence" convention. {@link #preview} is
 * deliberately NOT ownership-scoped — see {@code GiftCardService#preview} javadoc.
 */
@RestController
@RequestMapping("/api/me/gift-cards")
@Tag(name = "Customer - Gift Cards", description = "Issue, activate, claim, list and preview prepaid promotional gift cards")
@SecurityRequirement(name = "bearerAuth")
public class GiftCardController {

    private final GiftCardService service;

    public GiftCardController(GiftCardService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "List my gift cards (purchased or received), filterable by status and expiry inclusion")
    public PageResponse<GiftCardSummaryResponse> listMine(
            @AuthUser Long uid,
            @RequestParam(required = false) GiftCardStatus status,
            @RequestParam(required = false) Boolean includeExpired,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size) {
        return service.listMine(uid, status, includeExpired, page, size);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get one of my gift cards by id (masked code)")
    public GiftCardResponse getMine(@AuthUser Long uid, @PathVariable Long id) {
        return service.getMine(uid, id);
    }

    @GetMapping("/code/{code}")
    @Operation(summary = "Get one of my gift cards by its redeemable code (masked code)")
    public GiftCardResponse getMineByCode(@AuthUser Long uid, @PathVariable String code) {
        return service.getMineByCode(uid, code);
    }

    @PostMapping("/issue")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Issue a gift card (mock/internal path — no real payment collected in this phase); "
        + "response includes the full redeemable code once")
    public GiftCardResponse issue(@AuthUser Long uid, @Valid @RequestBody GiftCardIssueRequest req) {
        return service.issueForCustomer(uid, req);
    }

    @PostMapping("/{id}/activate")
    @Operation(summary = "Activate an ISSUED gift card I purchased or received (idempotent)")
    public GiftCardResponse activate(@AuthUser Long uid, @PathVariable Long id) {
        return service.activate(uid, id);
    }

    @PostMapping("/claim")
    @Operation(summary = "Claim an email-issued gift card after authentication and activate it (idempotent)")
    public GiftCardResponse claim(@AuthUser Long uid, @Valid @RequestBody GiftCardClaimRequest req) {
        return service.claim(uid, req.code());
    }

    @GetMapping("/{id}/transactions")
    @Operation(summary = "List the immutable ledger transactions for one of my gift cards")
    public PageResponse<GiftCardTransactionResponse> transactions(
            @AuthUser Long uid, @PathVariable Long id,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size) {
        return service.myTransactions(uid, id, page, size);
    }

    @PostMapping("/preview")
    @Operation(summary = "Preview redeeming a gift card against an order amount (read-only — never mutates balance)")
    public GiftCardPreviewResponse preview(@Valid @RequestBody GiftCardPreviewRequest req) {
        return service.preview(req);
    }
}
