package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PartnerAnalyticsDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.PartnerAnalyticsService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/partner/analytics")
@Tag(name = "Partner - Analytics", description = "Read-only analytics for approved partners, scoped to hotels they own")
@SecurityRequirement(name = "bearerAuth")
public class PartnerAnalyticsController {

    private final PartnerAnalyticsService service;

    public PartnerAnalyticsController(PartnerAnalyticsService service) { this.service = service; }

    @GetMapping("/overview")
    @Operation(summary = "Overview metrics across owned hotels (defaults to the last 30 days)")
    public PartnerAnalyticsOverviewResponse overview(
            @AuthUser Long uid,
            @RequestParam(required = false) Long hotelId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return service.getOverview(uid, hotelId, from, to);
    }

    @GetMapping("/revenue")
    @Operation(summary = "Revenue breakdown by day, room and hotel")
    public RevenueAnalyticsResponse revenue(
            @AuthUser Long uid,
            @RequestParam(required = false) Long hotelId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return service.getRevenue(uid, hotelId, from, to);
    }

    @GetMapping("/occupancy")
    @Operation(summary = "Occupancy breakdown using RoomInventory")
    public OccupancyAnalyticsResponse occupancy(
            @AuthUser Long uid,
            @RequestParam(required = false) Long hotelId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return service.getOccupancy(uid, hotelId, from, to);
    }

    @GetMapping("/bookings")
    @Operation(summary = "Booking status, arrival/departure and stay-length analytics")
    public BookingAnalyticsResponse bookings(
            @AuthUser Long uid,
            @RequestParam(required = false) Long hotelId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return service.getBookingAnalytics(uid, hotelId, from, to);
    }

    @GetMapping("/rooms")
    @Operation(summary = "Top rooms by revenue/bookings and availability summary")
    public RoomAnalyticsResponse rooms(
            @AuthUser Long uid,
            @RequestParam(required = false) Long hotelId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return service.getRoomAnalytics(uid, hotelId, from, to);
    }

    @GetMapping("/promotions")
    @Operation(summary = "Structural promotion analytics (no exact discount attribution yet)")
    public PromotionAnalyticsResponse promotions(
            @AuthUser Long uid,
            @RequestParam(required = false) Long hotelId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return service.getPromotionAnalytics(uid, hotelId, from, to);
    }

    @GetMapping("/reviews")
    @Operation(summary = "Review rating and moderation-status analytics")
    public ReviewAnalyticsResponse reviews(
            @AuthUser Long uid,
            @RequestParam(required = false) Long hotelId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return service.getReviewAnalytics(uid, hotelId, from, to);
    }

    @GetMapping("/messages")
    @Operation(summary = "Conversation and response-time analytics")
    public MessageAnalyticsResponse messages(
            @AuthUser Long uid,
            @RequestParam(required = false) Long hotelId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return service.getMessageAnalytics(uid, hotelId, from, to);
    }
}
