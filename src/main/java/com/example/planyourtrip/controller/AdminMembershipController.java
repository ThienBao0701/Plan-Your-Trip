package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.MembershipDto.*;
import com.example.planyourtrip.model.MembershipTier;
import com.example.planyourtrip.service.CustomerMembershipService;
import com.example.planyourtrip.service.MembershipTierService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Phase 7.19 — Membership Tier &amp; Loyalty Qualification.
 * Admin-only: tier-definition and benefit-definition CRUD, plus per-user
 * customer support (read-only view + explicit assign/reevaluate/clear-manual
 * mutation endpoints). Access restricted to ROLE_ADMIN by SecurityConfig's
 * blanket {@code /api/admin/**} rule — no per-controller annotation needed,
 * matching every other admin controller.
 */
@RestController
@Tag(name = "Admin - Membership", description = "Tier/benefit definition CRUD and per-user membership support")
@SecurityRequirement(name = "bearerAuth")
public class AdminMembershipController {

    private final MembershipTierService tierService;
    private final CustomerMembershipService membershipService;

    public AdminMembershipController(MembershipTierService tierService, CustomerMembershipService membershipService) {
        this.tierService = tierService;
        this.membershipService = membershipService;
    }

    // ── Tier definitions ─────────────────────────────────────────────────────

    @GetMapping("/api/admin/membership/tiers")
    @Operation(summary = "List all tier definitions, ordered by sortOrder")
    public List<MembershipTierDefinitionResponse> listTiers() {
        return tierService.getAllTierDefinitions();
    }

    @PostMapping("/api/admin/membership/tiers")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a tier definition (one row per tier — duplicate tier rejected with 409)")
    public MembershipTierDefinitionResponse createTier(@Valid @RequestBody MembershipTierDefinitionRequest req) {
        return tierService.createTierDefinition(req);
    }

    @GetMapping("/api/admin/membership/tiers/{tier}")
    @Operation(summary = "Get a tier definition by tier")
    public MembershipTierDefinitionResponse getTier(@PathVariable MembershipTier tier) {
        return tierService.getTierDefinition(tier);
    }

    @PutMapping("/api/admin/membership/tiers/{tier}")
    @Operation(summary = "Update a tier definition's thresholds/multiplier/metadata")
    public MembershipTierDefinitionResponse updateTier(@PathVariable MembershipTier tier,
                                                         @Valid @RequestBody MembershipTierDefinitionRequest req) {
        return tierService.updateTierDefinition(tier, req);
    }

    @PatchMapping("/api/admin/membership/tiers/{tier}/activate")
    @Operation(summary = "Activate a tier definition (participates in qualification again)")
    public MembershipTierDefinitionResponse activateTier(@PathVariable MembershipTier tier) {
        return tierService.activateTierDefinition(tier);
    }

    @PatchMapping("/api/admin/membership/tiers/{tier}/deactivate")
    @Operation(summary = "Deactivate a tier definition (excluded from qualification and multiplier resolution)")
    public MembershipTierDefinitionResponse deactivateTier(@PathVariable MembershipTier tier) {
        return tierService.deactivateTierDefinition(tier);
    }

    // ── Benefit definitions (metadata only) ──────────────────────────────────

    @GetMapping("/api/admin/membership/benefits")
    @Operation(summary = "List all benefit definitions across all tiers")
    public List<MembershipBenefitResponse> listBenefits() {
        return tierService.getAllBenefits();
    }

    @PostMapping("/api/admin/membership/benefits")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a benefit metadata row for a tier")
    public MembershipBenefitResponse createBenefit(@Valid @RequestBody MembershipBenefitRequest req) {
        return tierService.createBenefit(req);
    }

    @PutMapping("/api/admin/membership/benefits/{id}")
    @Operation(summary = "Update a benefit metadata row")
    public MembershipBenefitResponse updateBenefit(@PathVariable Long id,
                                                     @Valid @RequestBody MembershipBenefitRequest req) {
        return tierService.updateBenefit(id, req);
    }

    @DeleteMapping("/api/admin/membership/benefits/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete a benefit metadata row")
    public void deleteBenefit(@PathVariable Long id) {
        tierService.deleteBenefit(id);
    }

    // ── Customer support ──────────────────────────────────────────────────────

    @GetMapping("/api/admin/users/{userId}/membership")
    @Operation(summary = "Inspect a user's membership (read-only; 404 if never enrolled)")
    public CustomerMembershipResponse view(@PathVariable Long userId) {
        return membershipService.adminView(userId);
    }

    @PostMapping("/api/admin/users/{userId}/membership/assign")
    @Operation(summary = "Manually assign any active tier to a user (creates the membership if none exists)")
    public CustomerMembershipResponse assign(@PathVariable Long userId,
                                              @Valid @RequestBody MembershipManualAssignmentRequest req) {
        return membershipService.adminAssign(userId, req);
    }

    @PostMapping("/api/admin/users/{userId}/membership/reevaluate")
    @Operation(summary = "Recalculate the user's tier from current qualification metrics — the only path that can downgrade or process an expired validity window")
    public MembershipEvaluationResultResponse reevaluate(@PathVariable Long userId) {
        return membershipService.adminReevaluate(userId);
    }

    @PostMapping("/api/admin/users/{userId}/membership/clear-manual-assignment")
    @Operation(summary = "Clear the manuallyAssigned flag and restore the tier to calculated eligibility")
    public MembershipEvaluationResultResponse clearManualAssignment(@PathVariable Long userId) {
        return membershipService.clearManualAssignment(userId);
    }
}
