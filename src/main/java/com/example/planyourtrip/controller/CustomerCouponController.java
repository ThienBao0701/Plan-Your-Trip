package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.CouponDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.CustomerCouponService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Phase 7.14 — Customer Coupons &amp; Travel Credits Foundation.
 * Customer-side coupon endpoints: claim by code (case-insensitive), list/get
 * own coupons and a strictly read-only discount preview. No checkout
 * integration in this phase — nothing here applies a coupon to a Booking.
 */
@RestController
@RequestMapping("/api/me/coupons")
@Tag(name = "Customer - Coupons", description = "Claim coupon codes, view claimed coupons and preview discounts")
@SecurityRequirement(name = "bearerAuth")
public class CustomerCouponController {

    private final CustomerCouponService service;

    public CustomerCouponController(CustomerCouponService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "List my claimed coupons (with computed effective status)")
    public List<CustomerCouponResponse> list(@AuthUser Long uid) {
        return service.listMine(uid);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get one of my own coupons (another user's coupon id returns 404)")
    public CustomerCouponResponse get(@AuthUser Long uid, @PathVariable Long id) {
        return service.getMine(uid, id);
    }

    @PostMapping("/claim")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Claim a coupon by code (case-insensitive)",
        description = "404 unknown code; 400 inactive/expired/not-yet-valid; 409 per-user or total usage limit reached.")
    public CustomerCouponResponse claim(@AuthUser Long uid, @Valid @RequestBody CouponClaimRequest req) {
        return service.claim(uid, req.code());
    }

    @PostMapping("/{id}/preview")
    @Operation(summary = "Preview the discount this coupon would give on an order amount",
        description = "Strictly read-only — never marks the coupon used. Returns eligible=false with a reason when not applicable.")
    public CouponPreviewResponse preview(@AuthUser Long uid, @PathVariable Long id,
                                          @Valid @RequestBody CouponPreviewRequest req) {
        return service.preview(uid, id, req);
    }
}
