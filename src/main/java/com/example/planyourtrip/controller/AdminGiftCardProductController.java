package com.example.planyourtrip.controller;

import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.dto.GiftCardDto.GiftCardProductRequest;
import com.example.planyourtrip.dto.GiftCardDto.GiftCardProductResponse;
import com.example.planyourtrip.service.GiftCardProductService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Phase 7.24 — Gift Cards Foundation.
 * Admin-only gift-card PRODUCT CRUD. Access is restricted to ROLE_ADMIN by
 * SecurityConfig's blanket {@code /api/admin/**} rule — no per-controller
 * annotation needed, matching every other admin controller.
 */
@RestController
@RequestMapping("/api/admin/gift-card-products")
@Tag(name = "Admin - Gift Card Products", description = "CRUD for gift-card products/campaigns")
@SecurityRequirement(name = "bearerAuth")
public class AdminGiftCardProductController {

    private final GiftCardProductService service;

    public AdminGiftCardProductController(GiftCardProductService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "List all gift card products")
    public List<GiftCardProductResponse> getAll() {
        return service.getAll();
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get a gift card product by id")
    public GiftCardProductResponse getById(@PathVariable Long id) {
        return service.getById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a gift card product (duplicate productCode rejected case-insensitively with 409)")
    public GiftCardProductResponse create(@AuthUser Long uid, @Valid @RequestBody GiftCardProductRequest req) {
        return service.adminCreate(uid, req);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update a gift card product")
    public GiftCardProductResponse update(@AuthUser Long uid, @PathVariable Long id,
                                           @Valid @RequestBody GiftCardProductRequest req) {
        return service.update(uid, id, req);
    }

    @PatchMapping("/{id}/activate")
    @Operation(summary = "Activate a gift card product")
    public GiftCardProductResponse activate(@AuthUser Long uid, @PathVariable Long id) {
        return service.activate(uid, id);
    }

    @PatchMapping("/{id}/deactivate")
    @Operation(summary = "Deactivate a gift card product")
    public GiftCardProductResponse deactivate(@AuthUser Long uid, @PathVariable Long id) {
        return service.deactivate(uid, id);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete a gift card product (409 if any gift card has been issued against it)")
    public void delete(@AuthUser Long uid, @PathVariable Long id) {
        service.delete(uid, id);
    }
}
