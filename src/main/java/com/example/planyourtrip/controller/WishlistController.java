package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.WishlistDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.WishlistService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/me/wishlist")
@Tag(name = "Customer - Wishlist", description = "Save places/hotels/cafes/restaurants/attractions to a personal wishlist")
@SecurityRequirement(name = "bearerAuth")
public class WishlistController {

    private final WishlistService service;

    public WishlistController(WishlistService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "Get my wishlist (created with defaults on first access)")
    public WishlistResponse get(@AuthUser Long uid) {
        return service.getMine(uid);
    }

    @PostMapping("/items")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Add a published place to my wishlist")
    public WishlistItemResponse addItem(@AuthUser Long uid, @Valid @RequestBody AddWishlistItemRequest req) {
        return service.addPlace(uid, req);
    }

    @DeleteMapping("/items/{placeId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Remove a place from my wishlist")
    public void removeItem(@AuthUser Long uid, @PathVariable Long placeId) {
        service.removePlace(uid, placeId);
    }

    @PutMapping("/items/{placeId}/note")
    @Operation(summary = "Update the note on a saved place")
    public WishlistItemResponse updateNote(@AuthUser Long uid, @PathVariable Long placeId,
                                            @RequestBody WishlistNoteRequest req) {
        return service.updateNote(uid, placeId, req);
    }
}
