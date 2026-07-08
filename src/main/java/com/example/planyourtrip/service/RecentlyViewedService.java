package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.RecentlyViewedDto.RecentlyViewedItemResponse;
import com.example.planyourtrip.dto.RecentlyViewedDto.RecentlyViewedResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.Place;
import com.example.planyourtrip.model.PlaceStatus;
import com.example.planyourtrip.model.RecentlyViewedPlace;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.repository.RecentlyViewedPlaceRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

/**
 * Tracks the places a customer has recently viewed — one row per (user, place),
 * refreshed on repeat views rather than duplicated, capped to the most recent
 * {@value #MAX_ENTRIES} per user. Only {@link PlaceStatus#PUBLISHED} places are
 * tracked, matching the same visibility rule already enforced for the customer
 * Wishlist (Phase 7.2).
 */
@Service
public class RecentlyViewedService {

    private static final int MAX_ENTRIES = 50;

    private final RecentlyViewedPlaceRepository repo;
    private final PlaceRepository placeRepo;
    private final UserRepository userRepo;

    public RecentlyViewedService(RecentlyViewedPlaceRepository repo,
                                  PlaceRepository placeRepo,
                                  UserRepository userRepo) {
        this.repo = repo;
        this.placeRepo = placeRepo;
        this.userRepo = userRepo;
    }

    @Transactional
    public RecentlyViewedItemResponse recordView(Long userId, Long placeId) {
        Place place = placeRepo.findById(placeId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Place not found: " + placeId));
        if (place.getStatus() != PlaceStatus.PUBLISHED)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "Only published places can be tracked");

        RecentlyViewedPlace entry = repo.findByUserIdAndPlaceId(userId, placeId).orElseGet(() -> {
            User user = userRepo.findById(userId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));
            RecentlyViewedPlace fresh = new RecentlyViewedPlace();
            fresh.setUser(user);
            fresh.setPlace(place);
            return fresh;
        });
        entry.setViewedAt(Instant.now());
        RecentlyViewedPlace saved = repo.save(entry);

        enforceMaxEntries(userId);
        return toItemResponse(saved);
    }

    @Transactional(readOnly = true)
    public RecentlyViewedResponse getMine(Long userId) {
        List<RecentlyViewedItemResponse> items = repo.findByUserIdOrderByViewedAtDesc(userId)
            .stream().map(this::toItemResponse).toList();
        return new RecentlyViewedResponse(items);
    }

    @Transactional
    public void clearMine(Long userId) {
        repo.deleteByUserId(userId);
    }

    @Transactional
    public void removeOne(Long userId, Long placeId) {
        RecentlyViewedPlace entry = repo.findByUserIdAndPlaceId(userId, placeId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Place not in recently viewed: " + placeId));
        repo.delete(entry);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private void enforceMaxEntries(Long userId) {
        List<RecentlyViewedPlace> all = repo.findByUserIdOrderByViewedAtDesc(userId);
        if (all.size() > MAX_ENTRIES) {
            repo.deleteAll(all.subList(MAX_ENTRIES, all.size()));
        }
    }

    private RecentlyViewedItemResponse toItemResponse(RecentlyViewedPlace entry) {
        Place p = entry.getPlace();
        return new RecentlyViewedItemResponse(
            p.getId(), p.getName(), p.getSlug(),
            p.getCategory() != null ? p.getCategory().getName() : null,
            p.getAddress(), p.getShortDescription(), p.getRatingAvg(), p.getReviewCount(),
            entry.getViewedAt()
        );
    }
}
