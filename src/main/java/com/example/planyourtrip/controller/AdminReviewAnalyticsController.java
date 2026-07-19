package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.AdminAnalyticsDto.AdminReviewAnalyticsOverviewResponse;
import com.example.planyourtrip.service.AdminAnalyticsService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

/**
 * Phase 7.46 — read-only platform-wide review-analytics overview for the platform ADMIN. Secured by
 * the blanket {@code /api/admin/**} → ROLE_ADMIN rule in SecurityConfig (no per-method annotation needed).
 */
@RestController
@RequestMapping("/api/admin/reviews/analytics")
@Tag(name = "Admin - Review Analytics", description = "Read-only platform-wide review analytics overview")
@SecurityRequirement(name = "bearerAuth")
public class AdminReviewAnalyticsController {

    private final AdminAnalyticsService service;

    public AdminReviewAnalyticsController(AdminAnalyticsService service) { this.service = service; }

    @GetMapping("/overview")
    @Operation(summary = "Platform-wide review aggregates (status breakdown, rating distribution, "
        + "category averages, reply rate, reviewed places); date window defaults to the last 30 days")
    public AdminReviewAnalyticsOverviewResponse overview(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return service.getReviewAnalyticsOverview(from, to);
    }
}
