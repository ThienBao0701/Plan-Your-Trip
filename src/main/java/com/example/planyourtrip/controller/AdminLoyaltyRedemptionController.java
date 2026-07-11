package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.LoyaltyRedemptionDto.*;
import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.model.LoyaltyRedemptionStatus;
import com.example.planyourtrip.service.LoyaltyRedemptionPolicyService;
import com.example.planyourtrip.service.LoyaltyRedemptionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;

/**
 * Phase 7.20 — Loyalty Points Redemption.
 * Admin-only redemption-policy CRUD plus redemption administration (list,
 * inspect, release, refund, expire-stale). Access is restricted to ROLE_ADMIN
 * by SecurityConfig's blanket {@code /api/admin/**} rule — no per-controller
 * annotation needed, matching every other admin controller.
 */
@RestController
@Tag(name = "Admin - Loyalty Redemption", description = "Redemption policy CRUD and redemption administration")
@SecurityRequirement(name = "bearerAuth")
public class AdminLoyaltyRedemptionController {

    private final LoyaltyRedemptionPolicyService policyService;
    private final LoyaltyRedemptionService redemptionService;

    public AdminLoyaltyRedemptionController(LoyaltyRedemptionPolicyService policyService,
                                            LoyaltyRedemptionService redemptionService) {
        this.policyService = policyService;
        this.redemptionService = redemptionService;
    }

    // ── Redemption policies ────────────────────────────────────────────────────

    @GetMapping("/api/admin/loyalty/redemption-policies")
    @Operation(summary = "List all redemption policies (newest effective window first)")
    public List<RedemptionPolicyResponse> listPolicies() {
        return policyService.getAll();
    }

    @GetMapping("/api/admin/loyalty/redemption-policies/{id}")
    @Operation(summary = "Get a redemption policy by id")
    public RedemptionPolicyResponse getPolicy(@PathVariable Long id) {
        return policyService.getById(id);
    }

    @PostMapping("/api/admin/loyalty/redemption-policies")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a redemption policy (duplicate policyCode rejected with 409)")
    public RedemptionPolicyResponse createPolicy(@Valid @RequestBody RedemptionPolicyRequest req) {
        return policyService.create(req);
    }

    @PutMapping("/api/admin/loyalty/redemption-policies/{id}")
    @Operation(summary = "Update a redemption policy")
    public RedemptionPolicyResponse updatePolicy(@PathVariable Long id,
                                                 @Valid @RequestBody RedemptionPolicyRequest req) {
        return policyService.update(id, req);
    }

    @PostMapping("/api/admin/loyalty/redemption-policies/{id}/activate")
    @Operation(summary = "Activate a redemption policy")
    public RedemptionPolicyResponse activatePolicy(@PathVariable Long id) {
        return policyService.activate(id);
    }

    @PostMapping("/api/admin/loyalty/redemption-policies/{id}/deactivate")
    @Operation(summary = "Deactivate a redemption policy")
    public RedemptionPolicyResponse deactivatePolicy(@PathVariable Long id) {
        return policyService.deactivate(id);
    }

    // ── Redemption administration ──────────────────────────────────────────────

    @GetMapping("/api/admin/loyalty/redemptions")
    @Operation(summary = "List redemptions with optional filters (customer, booking, status, reference, created range)")
    public PageResponse<RedemptionResponse> listRedemptions(
            @RequestParam(required = false) Long customerId,
            @RequestParam(required = false) Long bookingId,
            @RequestParam(required = false) LoyaltyRedemptionStatus status,
            @RequestParam(required = false) String reference,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant createdFrom,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant createdTo,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size) {
        return redemptionService.adminList(customerId, bookingId, status, reference, createdFrom, createdTo, page, size);
    }

    @GetMapping("/api/admin/loyalty/redemptions/{redemptionReference}")
    @Operation(summary = "Inspect a redemption by reference")
    public RedemptionResponse getRedemption(@PathVariable String redemptionReference) {
        return redemptionService.adminGetByReference(redemptionReference);
    }

    @PostMapping("/api/admin/loyalty/redemptions/{redemptionReference}/release")
    @Operation(summary = "Release a RESERVED redemption (restores points); idempotent")
    public RedemptionResponse releaseRedemption(@PathVariable String redemptionReference) {
        return redemptionService.releaseByReference(null, redemptionReference, true);
    }

    @PostMapping("/api/admin/loyalty/redemptions/{redemptionReference}/refund")
    @Operation(summary = "Refund an APPLIED redemption (restores points); idempotent")
    public RedemptionResponse refundRedemption(@PathVariable String redemptionReference) {
        return redemptionService.refundByReference(redemptionReference);
    }

    @PostMapping("/api/admin/loyalty/redemptions/expire-stale")
    @Operation(summary = "Expire stale RESERVED redemptions past their expiry and restore points")
    public ExpireStaleRunResponse expireStale() {
        return redemptionService.expireStale();
    }
}
