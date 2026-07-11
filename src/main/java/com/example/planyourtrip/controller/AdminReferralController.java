package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.ReferralDto.*;
import com.example.planyourtrip.service.ReferralCampaignService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Phase 7.22 — Referral &amp; Invite Rewards.
 * Admin CRUD + enable/disable for {@link com.example.planyourtrip.model.ReferralCampaign}.
 * Access is restricted to ROLE_ADMIN by SecurityConfig's blanket
 * {@code /api/admin/**} rule — no per-controller annotation needed, matching
 * every other admin controller (e.g. {@code AdminLoyaltyRedemptionController}).
 */
@RestController
@RequestMapping("/api/admin/referral/campaigns")
@Tag(name = "Admin - Referral", description = "Referral campaign CRUD and activation")
@SecurityRequirement(name = "bearerAuth")
public class AdminReferralController {

    private final ReferralCampaignService service;

    public AdminReferralController(ReferralCampaignService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "List all referral campaigns (newest effective window first)")
    public List<ReferralCampaignResponse> list() {
        return service.getAll();
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get a referral campaign by id")
    public ReferralCampaignResponse get(@PathVariable Long id) {
        return service.getById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a referral campaign (duplicate code rejected with 409)")
    public ReferralCampaignResponse create(@Valid @RequestBody ReferralCampaignRequest req) {
        return service.create(req);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update a referral campaign")
    public ReferralCampaignResponse update(@PathVariable Long id,
                                           @Valid @RequestBody ReferralCampaignRequest req) {
        return service.update(id, req);
    }

    @PostMapping("/{id}/activate")
    @Operation(summary = "Activate a referral campaign")
    public ReferralCampaignResponse activate(@PathVariable Long id) {
        return service.activate(id);
    }

    @PostMapping("/{id}/deactivate")
    @Operation(summary = "Deactivate a referral campaign")
    public ReferralCampaignResponse deactivate(@PathVariable Long id) {
        return service.deactivate(id);
    }
}
