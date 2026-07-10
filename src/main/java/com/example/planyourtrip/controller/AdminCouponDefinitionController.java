package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.CouponDto.CouponDefinitionRequest;
import com.example.planyourtrip.dto.CouponDto.CouponDefinitionResponse;
import com.example.planyourtrip.dto.CouponDto.CouponEligibilityResponse;
import com.example.planyourtrip.service.CouponDefinitionService;
import com.example.planyourtrip.service.CustomerCouponService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Phase 7.14 — Customer Coupons &amp; Travel Credits Foundation.
 * Admin CRUD over coupon definitions. Access restricted to ROLE_ADMIN by
 * SecurityConfig's blanket {@code /api/admin/**} rule — no per-controller
 * annotation needed, matching every other admin controller.
 */
@RestController
@RequestMapping("/api/admin/coupon-definitions")
@Tag(name = "Admin - Coupon Definitions")
@SecurityRequirement(name = "bearerAuth")
public class AdminCouponDefinitionController {

    private final CouponDefinitionService service;
    private final CustomerCouponService customerCouponService;

    public AdminCouponDefinitionController(CouponDefinitionService service,
                                            CustomerCouponService customerCouponService) {
        this.service = service;
        this.customerCouponService = customerCouponService;
    }

    @GetMapping
    @Operation(summary = "List all coupon definitions")
    public List<CouponDefinitionResponse> listAll() {
        return service.getAll();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a coupon definition (code unique case-insensitively)")
    public CouponDefinitionResponse create(@Valid @RequestBody CouponDefinitionRequest req) {
        return service.create(req);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get a coupon definition by ID")
    public CouponDefinitionResponse getById(@PathVariable Long id) {
        return service.getById(id);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update a coupon definition")
    public CouponDefinitionResponse update(@PathVariable Long id,
                                            @Valid @RequestBody CouponDefinitionRequest req) {
        return service.update(id, req);
    }

    @PatchMapping("/{id}/activate")
    @Operation(summary = "Activate a coupon definition")
    public CouponDefinitionResponse activate(@PathVariable Long id) {
        return service.activate(id);
    }

    @PatchMapping("/{id}/deactivate")
    @Operation(summary = "Deactivate a coupon definition")
    public CouponDefinitionResponse deactivate(@PathVariable Long id) {
        return service.deactivate(id);
    }

    @GetMapping("/{id}/eligibility-preview")
    @Operation(summary = "Admin support/testing tool — full Phase 7.17 eligibility breakdown for a coupon definition",
        description = "Strictly read-only. Operates on the definition directly (no claim required), so it can be "
            + "tested before any customer has claimed the coupon. targetUserId is optional — when omitted, "
            + "customer-segment and first-booking-only checks are skipped (treated as satisfied).")
    public CouponEligibilityResponse eligibilityPreview(
            @PathVariable Long id,
            @RequestParam(required = false) Long hotelId,
            @RequestParam(required = false) Long roomId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkIn,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkOut,
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false, defaultValue = "0") BigDecimal orderAmount,
            @RequestParam(required = false) BigDecimal travelCreditAmount) {
        return customerCouponService.adminEligibilityPreview(
            id, userId, hotelId, roomId, checkIn, checkOut, orderAmount, travelCreditAmount);
    }
}
