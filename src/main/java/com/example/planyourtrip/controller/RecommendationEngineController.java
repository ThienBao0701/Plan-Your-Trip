package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.RecommendationEngineDto.RecommendationResponse;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.RecommendationEngineService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Phase 7.49 — the live, deterministic Recommendation Engine endpoint.
 *
 * <p>Mounted at {@code GET /api/me/recommendations/engine}, deliberately alongside (not replacing)
 * the Phase 7.23 persisted/rule-based snapshot endpoints under {@code /api/me/recommendations}. The
 * literal {@code /engine} segment takes precedence over that controller's {@code /{id}} template, so
 * there is no mapping collision and Phase 7.23 is untouched. The {@code /engine} name leaves room for
 * sibling engine routes later (e.g. {@code /ai}, {@code /similar}, {@code /trending}, {@code /nearby}).
 *
 * <p>Authenticated-only (401 otherwise) and strictly own-scoped: the result derives ONLY from the
 * acting user's {@link com.example.planyourtrip.model.UserInterestProfile} — no cross-user leakage,
 * no path parameter.
 */
@RestController
@RequestMapping("/api/me/recommendations")
@Tag(name = "Customer - Recommendation Engine",
     description = "Live, deterministic, profile-driven place recommendations")
@SecurityRequirement(name = "bearerAuth")
public class RecommendationEngineController {

    private final RecommendationEngineService service;

    public RecommendationEngineController(RecommendationEngineService service) {
        this.service = service;
    }

    @GetMapping("/engine")
    @Operation(summary = "Live recommendations scored against my interest profile (deterministic)")
    public List<RecommendationResponse> engine(@AuthUser Long uid) {
        return service.recommend(uid);
    }
}
