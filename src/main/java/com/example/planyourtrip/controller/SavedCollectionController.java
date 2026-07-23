package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.CollectionDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.SavedCollectionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Customer "Saved Collections" — multiple named place lists per user. All endpoints
 * are owner-scoped under /api/me/** (authenticated customer; anonymous → 401 via
 * SecurityConfig's {@code anyRequest().authenticated()}). A foreign/unknown collection
 * yields a uniform 404. Entirely separate from {@code WishlistController}.
 */
@RestController
@RequestMapping("/api/me/collections")
@Tag(name = "Customer - Saved Collections",
     description = "Create multiple named collections of places (Japan 2027, Honeymoon, Beaches…)")
@SecurityRequirement(name = "bearerAuth")
public class SavedCollectionController {

    private final SavedCollectionService service;

    public SavedCollectionController(SavedCollectionService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "List my collections (ordered by sortOrder then createdAt, with place counts)")
    public List<CollectionSummaryResponse> list(@AuthUser Long uid) {
        return service.listMine(uid);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a new collection")
    public CollectionDetailResponse create(@AuthUser Long uid, @Valid @RequestBody CollectionRequest req) {
        return service.create(uid, req);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get a collection with its places (insertion order)")
    public CollectionDetailResponse get(@AuthUser Long uid, @PathVariable Long id) {
        return service.getDetail(uid, id);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update a collection's name/description/cover/privacy/ordering")
    public CollectionDetailResponse update(@AuthUser Long uid, @PathVariable Long id,
                                           @Valid @RequestBody CollectionRequest req) {
        return service.update(uid, id, req);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete a collection (join rows removed; the Places are never deleted)")
    public void delete(@AuthUser Long uid, @PathVariable Long id) {
        service.delete(uid, id);
    }

    @PostMapping("/{id}/places/{placeId}")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Add a place to a collection (409 if already present)")
    public CollectionPlaceResponse addPlace(@AuthUser Long uid, @PathVariable Long id,
                                            @PathVariable Long placeId) {
        return service.addPlace(uid, id, placeId);
    }

    @DeleteMapping("/{id}/places/{placeId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Remove a place from a collection (the Place itself is untouched)")
    public void removePlace(@AuthUser Long uid, @PathVariable Long id, @PathVariable Long placeId) {
        service.removePlace(uid, id, placeId);
    }
}
