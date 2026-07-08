package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.WishlistDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.Place;
import com.example.planyourtrip.model.PlaceStatus;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.model.Wishlist;
import com.example.planyourtrip.model.WishlistItem;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.repository.WishlistItemRepository;
import com.example.planyourtrip.repository.WishlistRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

/**
 * A customer's personal saved-places list. One {@link Wishlist} per user, lazily
 * created on first access (same "get-or-create" convention used throughout the
 * partner platform, e.g. {@code PartnerSettingsService.getOrCreateSettings}).
 * Only {@link PlaceStatus#PUBLISHED} places can be saved — everything else (draft,
 * pending review, hidden, archived, rejected) is not yet a real, visible listing.
 */
@Service
public class WishlistService {

    private final WishlistRepository wishlistRepo;
    private final WishlistItemRepository itemRepo;
    private final PlaceRepository placeRepo;
    private final UserRepository userRepo;

    public WishlistService(WishlistRepository wishlistRepo,
                            WishlistItemRepository itemRepo,
                            PlaceRepository placeRepo,
                            UserRepository userRepo) {
        this.wishlistRepo = wishlistRepo;
        this.itemRepo = itemRepo;
        this.placeRepo = placeRepo;
        this.userRepo = userRepo;
    }

    @Transactional
    public WishlistResponse getMine(Long userId) {
        return toResponse(getOrCreateWishlist(userId));
    }

    @Transactional
    public WishlistItemResponse addPlace(Long userId, AddWishlistItemRequest req) {
        Wishlist wishlist = getOrCreateWishlist(userId);
        Place place = placeRepo.findById(req.placeId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Place not found: " + req.placeId()));

        if (place.getStatus() != PlaceStatus.PUBLISHED)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Only published places can be added to a wishlist");

        if (itemRepo.existsByWishlistIdAndPlaceId(wishlist.getId(), place.getId()))
            throw new ApiException(HttpStatus.CONFLICT, "This place is already in your wishlist");

        WishlistItem item = new WishlistItem();
        item.setWishlist(wishlist);
        item.setPlace(place);
        item.setNote(req.note());
        WishlistItem saved = itemRepo.save(item);

        touchWishlist(wishlist);
        return toItemResponse(saved);
    }

    @Transactional
    public void removePlace(Long userId, Long placeId) {
        Wishlist wishlist = getOrCreateWishlist(userId);
        WishlistItem item = itemOrThrow(wishlist.getId(), placeId);
        itemRepo.delete(item);
        touchWishlist(wishlist);
    }

    @Transactional
    public WishlistItemResponse updateNote(Long userId, Long placeId, WishlistNoteRequest req) {
        Wishlist wishlist = getOrCreateWishlist(userId);
        WishlistItem item = itemOrThrow(wishlist.getId(), placeId);
        item.setNote(req.note());
        WishlistItem saved = itemRepo.save(item);
        touchWishlist(wishlist);
        return toItemResponse(saved);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private Wishlist getOrCreateWishlist(Long userId) {
        return wishlistRepo.findByUserId(userId).orElseGet(() -> {
            User user = userRepo.findById(userId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));
            Wishlist wishlist = new Wishlist();
            wishlist.setUser(user);
            return wishlistRepo.save(wishlist);
        });
    }

    private WishlistItem itemOrThrow(Long wishlistId, Long placeId) {
        return itemRepo.findByWishlistIdAndPlaceId(wishlistId, placeId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Place not in wishlist: " + placeId));
    }

    private void touchWishlist(Wishlist wishlist) {
        wishlist.setUpdatedAt(Instant.now());
        wishlistRepo.save(wishlist);
    }

    private WishlistResponse toResponse(Wishlist w) {
        var items = itemRepo.findByWishlistIdOrderByCreatedAtDesc(w.getId())
            .stream().map(this::toItemResponse).toList();
        return new WishlistResponse(w.getId(), w.getUser().getId(), items, w.getCreatedAt(), w.getUpdatedAt());
    }

    private WishlistItemResponse toItemResponse(WishlistItem item) {
        return new WishlistItemResponse(item.getId(), toPlaceSummary(item.getPlace()), item.getNote(), item.getCreatedAt());
    }

    private WishlistPlaceSummary toPlaceSummary(Place p) {
        return new WishlistPlaceSummary(
            p.getId(), p.getName(), p.getSlug(),
            p.getCategory() != null ? p.getCategory().getName() : null,
            p.getAddress(), p.getShortDescription(), p.getRatingAvg(), p.getReviewCount()
        );
    }
}
