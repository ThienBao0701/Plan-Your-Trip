package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PartnerAnalyticsDto.PlaceReviewAnalyticsResponse;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.PartnerAnalyticsService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

/**
 * Phase 7.46 — read-only per-place review analytics for an approved partner. Secured by the
 * {@code /api/partner/**} → PARTNER/ADMIN rule in SecurityConfig; the service additionally enforces
 * that the caller OWNS {@code placeId} (unknown place or a place owned by someone else → uniform 404).
 */
@RestController
@Tag(name = "Partner - Review Analytics",
     description = "Read-only detailed review analytics for a single hotel/place the partner owns")
@SecurityRequirement(name = "bearerAuth")
public class PartnerPlaceReviewAnalyticsController {

    private final PartnerAnalyticsService service;

    public PartnerPlaceReviewAnalyticsController(PartnerAnalyticsService service) { this.service = service; }

    @GetMapping("/api/partner/places/{placeId}/reviews/analytics")
    @Operation(summary = "Detailed review analytics (status breakdown, averages, star distribution, "
        + "reply rate) for one owned place; 404 if the place is unknown or not owned by the caller")
    public PlaceReviewAnalyticsResponse placeReviewAnalytics(
            @AuthUser Long uid,
            @PathVariable Long placeId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return service.getPlaceReviewAnalytics(uid, placeId, from, to);
    }
}
