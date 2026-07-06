package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.ReviewDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.ReviewService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/reviews")
@Tag(name = "Admin - Review")
public class AdminReviewController {

    private final ReviewService service;

    public AdminReviewController(ReviewService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "List all reviews")
    public List<ReviewResponse> getAll() {
        return service.adminListReviews();
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get review by ID")
    public ReviewResponse getById(@AuthUser Long uid, @PathVariable Long id) {
        return service.getReview(uid, id);
    }

    @PatchMapping("/{id}/moderate")
    @Operation(summary = "Approve, reject, or hide a review")
    public ReviewResponse moderate(@PathVariable Long id, @RequestBody @Valid ReviewModerationRequest req) {
        return service.adminModerateReview(id, req);
    }
}
