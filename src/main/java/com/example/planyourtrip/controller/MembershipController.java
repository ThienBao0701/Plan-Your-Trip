package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.MembershipDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.CustomerMembershipService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Phase 7.19 — Membership Tier &amp; Loyalty Qualification.
 * Customer-side membership operations: explicit (idempotent) enrollment, own
 * membership/progress/benefits/history — all read paths are strictly
 * read-only and never implicitly create a membership. Controllers stay thin:
 * every rule lives in {@code CustomerMembershipService}.
 */
@RestController
@RequestMapping("/api/me/membership")
@Tag(name = "Customer - Membership", description = "Membership tier enrollment, progress, benefits and history")
@SecurityRequirement(name = "bearerAuth")
public class MembershipController {

    private final CustomerMembershipService service;

    public MembershipController(CustomerMembershipService service) { this.service = service; }

    @PostMapping("/enroll")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Enroll in membership (requires an active loyalty account); idempotent — replay returns the existing membership")
    public CustomerMembershipResponse enroll(@AuthUser Long uid) {
        return service.enroll(uid);
    }

    @GetMapping
    @Operation(summary = "Get my membership (currentTier vs expiry-aware effectiveTier); 404 if never enrolled")
    public CustomerMembershipResponse myMembership(@AuthUser Long uid) {
        return service.getMyMembership(uid);
    }

    @GetMapping("/progress")
    @Operation(summary = "Qualification progress toward the next tier — works even before enrolling (a live preview)")
    public MembershipProgressResponse myProgress(@AuthUser Long uid) {
        return service.getProgress(uid);
    }

    @GetMapping("/benefits")
    @Operation(summary = "List active benefit metadata for my effective tier (BRONZE default when not enrolled)")
    public List<MembershipBenefitResponse> myBenefits(@AuthUser Long uid) {
        return service.getMyBenefits(uid);
    }

    @GetMapping("/history")
    @Operation(summary = "List my immutable tier-change history, newest first")
    public List<MembershipTierHistoryResponse> myHistory(@AuthUser Long uid) {
        return service.getMyHistory(uid);
    }
}
