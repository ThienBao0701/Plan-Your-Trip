package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.CouponDto.CouponDefinitionRequest;
import com.example.planyourtrip.dto.CouponDto.CouponDefinitionResponse;
import com.example.planyourtrip.service.CouponDefinitionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

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

    public AdminCouponDefinitionController(CouponDefinitionService service) { this.service = service; }

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
}
