package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.CouponDto.CustomerCouponResponse;
import com.example.planyourtrip.service.CustomerCouponService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Phase 7.14 — Customer Coupons &amp; Travel Credits Foundation.
 * Admin support view of a user's claimed coupons — mirrors
 * {@code AdminTravelWalletController}'s {@code /api/admin/users/{userId}/...}
 * shape. Phase 7.16 adds the revocation tooling (the only admin mutation of a
 * claimed coupon). Access restricted to ROLE_ADMIN by SecurityConfig's blanket
 * {@code /api/admin/**} rule.
 */
@RestController
@RequestMapping("/api/admin/users")
@Tag(name = "Admin - Customer Coupons", description = "Admin visibility into a user's claimed coupons, plus revocation")
@SecurityRequirement(name = "bearerAuth")
public class AdminCustomerCouponController {

    private final CustomerCouponService service;

    public AdminCustomerCouponController(CustomerCouponService service) { this.service = service; }

    @GetMapping("/{userId}/coupons")
    @Operation(summary = "List a user's claimed coupons (read-only support view)")
    public List<CustomerCouponResponse> list(@PathVariable Long userId) {
        return service.adminListForUser(userId);
    }

    @PostMapping("/{userId}/coupons/{couponId}/revoke")
    @Operation(summary = "Revoke an AVAILABLE claimed coupon (terminal; frees the total-usage slot; "
        + "409 when already used or revoked)")
    public CustomerCouponResponse revoke(@PathVariable Long userId, @PathVariable Long couponId) {
        return service.adminRevoke(userId, couponId);
    }
}
