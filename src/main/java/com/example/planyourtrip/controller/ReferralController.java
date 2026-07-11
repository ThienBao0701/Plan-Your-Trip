package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.ReferralDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.ReferralService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Phase 7.22 — Referral &amp; Invite Rewards.
 * Customer-side referral endpoints. Authenticated-only (401 otherwise, via the
 * blanket {@code .anyRequest().authenticated()} rule) and strictly own-scoped:
 * every path derives the acting user from {@link AuthUser}, so a customer can
 * only ever see their own code and history.
 */
@RestController
@RequestMapping("/api/me/referral")
@Tag(name = "Customer - Referral", description = "Personal referral code, referral history and code redemption")
@SecurityRequirement(name = "bearerAuth")
public class ReferralController {

    private final ReferralService service;

    public ReferralController(ReferralService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "Get my referral code (created lazily on first access) and basic stats")
    public MyReferralResponse myReferral(@AuthUser Long uid) {
        return service.getOrCreateMyReferral(uid);
    }

    @GetMapping("/history")
    @Operation(summary = "List my referral activity (as inviter and/or invitee)")
    public List<ReferralRewardResponse> history(@AuthUser Long uid) {
        return service.myHistory(uid);
    }

    @PostMapping("/use")
    @Operation(summary = "Use another user's referral code (records a pending referral; rewards follow a qualifying booking)")
    public ReferralRewardResponse use(@AuthUser Long uid, @Valid @RequestBody UseReferralRequest req) {
        return service.useCode(uid, req.code());
    }
}
