package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.WishlistItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface WishlistItemRepository extends JpaRepository<WishlistItem, Long> {

    List<WishlistItem> findByWishlistIdOrderByCreatedAtDesc(Long wishlistId);

    Optional<WishlistItem> findByWishlistIdAndPlaceId(Long wishlistId, Long placeId);

    boolean existsByWishlistIdAndPlaceId(Long wishlistId, Long placeId);
}
