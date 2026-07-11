package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.dto.PersonalizationDto.*;
import com.example.planyourtrip.model.RecommendationType;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.CustomerPersonalizationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Set;

/**
 * Phase 7.23 — Personalized Offers &amp; Rule-Based Recommendations.
 * Customer-side recommendation endpoints. Authenticated-only (401 otherwise, via
 * the blanket {@code .anyRequest().authenticated()} rule) and strictly
 * own-scoped: every path derives the acting user from {@link AuthUser}, so a
 * customer can only ever see and modify their own recommendation snapshots
 * (another user's id returns 404).
 */
@RestController
@RequestMapping("/api/me/recommendations")
@Tag(name = "Customer - Recommendations", description = "Personalized, rule-based recommendations and engagement tracking")
@SecurityRequirement(name = "bearerAuth")
public class RecommendationController {

    private final CustomerPersonalizationService service;

    public RecommendationController(CustomerPersonalizationService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "List my recommendations (highest score first), with optional filters")
    public PageResponse<CustomerRecommendationResponse> list(
            @AuthUser Long uid,
            @RequestParam(required = false) RecommendationType type,
            @RequestParam(required = false) String destination,
            @RequestParam(required = false) Integer minScore,
            @RequestParam(defaultValue = "false") boolean includeDismissed,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return service.list(uid, type, destination, minScore, includeDismissed, page, size);
    }

    @GetMapping("/summary")
    @Operation(summary = "Summary metrics across my recommendation set")
    public RecommendationSummaryResponse summary(@AuthUser Long uid) {
        return service.summary(uid);
    }

    @GetMapping("/preferences")
    @Operation(summary = "My computed preference profile (the signals driving recommendations)")
    public CustomerPreferenceProfileResponse preferences(@AuthUser Long uid) {
        return service.getPreferenceProfile(uid);
    }

    @GetMapping("/places")
    @Operation(summary = "My active place recommendations (PLACE and TRIP_IDEA)")
    public List<CustomerRecommendationResponse> places(@AuthUser Long uid) {
        return service.listByTypes(uid, Set.of(RecommendationType.PLACE, RecommendationType.TRIP_IDEA));
    }

    @GetMapping("/hotels")
    @Operation(summary = "My active hotel and room recommendations")
    public List<CustomerRecommendationResponse> hotels(@AuthUser Long uid) {
        return service.listByTypes(uid, Set.of(RecommendationType.HOTEL, RecommendationType.ROOM));
    }

    @GetMapping("/offers")
    @Operation(summary = "My active promotion and coupon recommendations")
    public List<CustomerRecommendationResponse> offers(@AuthUser Long uid) {
        return service.listByTypes(uid, Set.of(RecommendationType.PROMOTION, RecommendationType.COUPON));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get one of my recommendations (404 if not mine)")
    public CustomerRecommendationResponse get(@AuthUser Long uid, @PathVariable Long id) {
        return service.get(uid, id);
    }

    @GetMapping("/{id}/reason")
    @Operation(summary = "Explain why an item was recommended")
    public RecommendationReasonResponse reason(@AuthUser Long uid, @PathVariable Long id) {
        return service.explain(uid, id);
    }

    @PostMapping("/generate")
    @Operation(summary = "Regenerate my active recommendations (read-only snapshots; never claims/reserves anything)")
    public RecommendationGenerationResponse generate(@AuthUser Long uid) {
        return service.generate(uid);
    }

    @PatchMapping("/{id}/dismiss")
    @Operation(summary = "Dismiss a recommendation (hides it from the default list)")
    public CustomerRecommendationResponse dismiss(@AuthUser Long uid, @PathVariable Long id) {
        return service.dismiss(uid, id);
    }

    @PatchMapping("/{id}/click")
    @Operation(summary = "Track a click on a recommendation (idempotent)")
    public CustomerRecommendationResponse click(@AuthUser Long uid, @PathVariable Long id) {
        return service.click(uid, id);
    }

    @PatchMapping("/{id}/convert")
    @Operation(summary = "Mark a recommendation as converted (idempotent)")
    public CustomerRecommendationResponse convert(@AuthUser Long uid, @PathVariable Long id) {
        return service.convert(uid, id);
    }
}
