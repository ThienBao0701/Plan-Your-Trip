package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.dto.PersonalizationDto.CustomerRecommendationResponse;
import com.example.planyourtrip.dto.PersonalizationDto.RecommendationGenerationResponse;
import com.example.planyourtrip.model.RecommendationType;
import com.example.planyourtrip.service.CustomerPersonalizationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

/**
 * Phase 7.23 — Personalized Offers &amp; Rule-Based Recommendations.
 * Admin customer-support view of a user's recommendations. Restricted to
 * ROLE_ADMIN by SecurityConfig's blanket {@code /api/admin/**} rule. Read-only
 * except for the explicit generation trigger, which reuses the SAME customer
 * personalization engine ({@code CustomerPersonalizationService#generate}).
 */
@RestController
@RequestMapping("/api/admin/users/{userId}/recommendations")
@Tag(name = "Admin - User Recommendations", description = "Support view + generation of a user's recommendations")
@SecurityRequirement(name = "bearerAuth")
public class AdminUserRecommendationController {

    private final CustomerPersonalizationService service;

    public AdminUserRecommendationController(CustomerPersonalizationService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "Inspect a user's recommendations (read-only)")
    public PageResponse<CustomerRecommendationResponse> list(
            @PathVariable Long userId,
            @RequestParam(required = false) RecommendationType type,
            @RequestParam(required = false) String destination,
            @RequestParam(required = false) Integer minScore,
            @RequestParam(defaultValue = "true") boolean includeDismissed,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return service.list(userId, type, destination, minScore, includeDismissed, page, size);
    }

    @PostMapping("/generate")
    @Operation(summary = "Generate recommendations for a user (reuses the customer engine)")
    public RecommendationGenerationResponse generate(@PathVariable Long userId) {
        return service.generate(userId);
    }
}
