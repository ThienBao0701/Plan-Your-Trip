package com.example.planyourtrip.controller;

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
}
