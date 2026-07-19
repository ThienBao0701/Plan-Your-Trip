package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.MediaDto.MediaAssetResponse;
import com.example.planyourtrip.dto.MediaDto.ReviewMediaRequest;
import com.example.planyourtrip.dto.ReviewDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.ReviewService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@Tag(name = "Review")
public class ReviewController {

    private final ReviewService service;

    public ReviewController(ReviewService service) { this.service = service; }

    @PostMapping("/api/reviews")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a review for a completed booking (owner only)")
    public ReviewResponse create(@AuthUser Long uid, @RequestBody @Valid ReviewRequest req) {
        return service.createReview(uid, req);
    }

    @PostMapping("/api/me/bookings/{bookingId}/review")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a review for a completed booking, booking-scoped (owner only)")
    public ReviewResponse createForBooking(@AuthUser Long uid, @PathVariable Long bookingId,
                                           @RequestBody @Valid BookingScopedReviewRequest req) {
        return service.createReviewForBooking(uid, bookingId, req);
    }

    @GetMapping("/api/reviews/{id}")
    @Operation(summary = "Get review by ID (owner or admin)")
    public ReviewResponse getById(@AuthUser Long uid, @PathVariable Long id) {
        return service.getReview(uid, id);
    }

    @GetMapping("/api/me/reviews")
    @Operation(summary = "List current user's reviews")
    public List<ReviewSummaryResponse> getMine(@AuthUser Long uid) {
        return service.getMyReviews(uid);
    }

    @GetMapping("/api/places/{placeId}/reviews")
    @Operation(summary = "List approved reviews for a place (public)")
    public List<ReviewSummaryResponse> getPlaceReviews(@PathVariable Long placeId) {
        return service.getPlaceReviews(placeId);
    }

    // ── Phase 7.45 — customer manages media on their OWN review ─────────────────
    // Review-scoped, owner-gated conveniences over the same MediaAssetService the
    // admin media surface uses; ownerType/ownerId are forced server-side.

    @PostMapping("/api/me/reviews/{reviewId}/media")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Attach media to your own review (owner only)")
    public MediaAssetResponse addMedia(@AuthUser Long uid, @PathVariable Long reviewId,
                                       @RequestBody @Valid ReviewMediaRequest req) {
        return service.addReviewMedia(uid, reviewId, req);
    }

    @DeleteMapping("/api/me/reviews/{reviewId}/media/{mediaId}")
    @Operation(summary = "Remove (soft-delete) media from your own review (owner only)")
    public MediaAssetResponse deleteMedia(@AuthUser Long uid, @PathVariable Long reviewId,
                                          @PathVariable Long mediaId) {
        return service.deleteReviewMedia(uid, reviewId, mediaId);
    }
}
