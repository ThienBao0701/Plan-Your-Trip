package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.UserInterestDto.InterestProfileResponse;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.UserInterestProfileService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

/**
 * Phase 7.48 — read-only User Interest Profile endpoints.
 *
 * <p>Authenticated-only (401 otherwise) and strictly own-scoped: both paths derive the acting user
 * from {@link AuthUser}, so a customer can only ever read or recalculate <b>their own</b> profile —
 * there is no path parameter, hence no cross-user access surface.
 *
 * <p>Distinct from the Phase 7.23 {@code GET /api/me/recommendations/preferences} endpoint: that
 * returns an ephemeral recommendation-driving preference snapshot; this exposes the persisted,
 * explicitly recalculated interest foundation.
 */
@RestController
@RequestMapping("/api/me/interests")
@Tag(name = "Customer - Interest Profile",
     description = "Derived, persisted, read-only aggregation of a customer's travel interests")
@SecurityRequirement(name = "bearerAuth")
public class UserInterestController {

    private final UserInterestProfileService service;

    public UserInterestController(UserInterestProfileService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "My interest profile (derived; empty until first recalculation)")
    public InterestProfileResponse get(@AuthUser Long uid) {
        return service.get(uid);
    }

    @PostMapping("/recalculate")
    @Operation(summary = "Re-derive my interest profile from current bookings, wishlist, collections and reviews")
    public InterestProfileResponse recalculate(@AuthUser Long uid) {
        return service.recalculate(uid);
    }
}
