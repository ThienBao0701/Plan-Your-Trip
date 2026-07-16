package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.AdminAnalyticsDto.AdminAnalyticsOverviewResponse;
import com.example.planyourtrip.service.AdminAnalyticsService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

/**
 * Read-only platform-wide analytics for the platform ADMIN. Secured by the blanket
 * {@code /api/admin/**} → ROLE_ADMIN rule in SecurityConfig (no per-method annotation needed).
 */
@RestController
@RequestMapping("/api/admin/analytics")
@Tag(name = "Admin - Analytics", description = "Read-only platform-wide analytics for the platform operator")
@SecurityRequirement(name = "bearerAuth")
public class AdminAnalyticsController {

    private final AdminAnalyticsService service;

    public AdminAnalyticsController(AdminAnalyticsService service) { this.service = service; }

    @GetMapping("/overview")
    @Operation(summary = "Platform-wide headline metrics (bookings, revenue, active hotels/rooms/users/partners); "
        + "date window defaults to the last 30 days")
    public AdminAnalyticsOverviewResponse overview(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return service.getOverview(from, to);
    }
}
