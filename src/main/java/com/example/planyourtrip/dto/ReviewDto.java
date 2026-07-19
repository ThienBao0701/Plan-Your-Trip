package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.ReviewStatus;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;

public class ReviewDto {

    public record ReviewRequest(
        @NotNull Long bookingId,
        @NotNull @Min(1) @Max(5) Integer ratingOverall,
        @Min(1) @Max(5) Integer ratingCleanliness,
        @Min(1) @Max(5) Integer ratingService,
        @Min(1) @Max(5) Integer ratingLocation,
        @Min(1) @Max(5) Integer ratingValue,
        @Min(1) @Max(5) Integer ratingFacilities,
        @Size(max = 200) String title,
        @Size(max = 5000) String content
    ) {}

    /**
     * Phase 7.43 — body for the booking-scoped alias route
     * {@code POST /api/me/bookings/{bookingId}/review}. Same rating/comment payload
     * as {@link ReviewRequest} but without {@code bookingId} (it comes from the path).
     */
    public record BookingScopedReviewRequest(
        @NotNull @Min(1) @Max(5) Integer ratingOverall,
        @Min(1) @Max(5) Integer ratingCleanliness,
        @Min(1) @Max(5) Integer ratingService,
        @Min(1) @Max(5) Integer ratingLocation,
        @Min(1) @Max(5) Integer ratingValue,
        @Min(1) @Max(5) Integer ratingFacilities,
        @Size(max = 200) String title,
        @Size(max = 5000) String content
    ) {}

    public record ReviewResponse(
        Long id,
        Long bookingId,
        String bookingCode,
        Long userId,
        String userName,
        Long placeId,
        String placeName,
        Integer ratingOverall,
        Integer ratingCleanliness,
        Integer ratingService,
        Integer ratingLocation,
        Integer ratingValue,
        Integer ratingFacilities,
        String title,
        String content,
        String status,
        int helpfulCount,
        int reportedCount,
        Instant approvedAt,
        Instant rejectedAt,
        String rejectReason,
        Instant createdAt,
        Instant updatedAt,
        PartnerReplyInfo partnerReply
    ) {}

    public record ReviewSummaryResponse(
        Long id,
        Long placeId,
        String placeName,
        Long userId,
        String userName,
        Integer ratingOverall,
        String title,
        String status,
        Instant createdAt,
        PartnerReplyInfo partnerReply
    ) {}

    /**
     * Phase 7.44 — body for {@code PUT /api/partner/reviews/{reviewId}/reply}.
     * PUT because a review has exactly one current partner reply; repeated calls
     * replace/update it in place. {@code content} required, non-blank, bounded to the
     * same 5000-char limit as the customer review comment.
     */
    public record PartnerReplyRequest(
        @NotBlank @Size(max = 5000) String content
    ) {}

    /**
     * Phase 7.44 — safe, public reply projection embedded in the read models.
     * Absent ({@code null}) when the review has no partner reply.
     */
    public record PartnerReplyInfo(
        String content,
        Instant repliedAt,
        Instant updatedAt,
        String partnerDisplayName
    ) {}

    public record ReviewModerationRequest(
        @NotNull ReviewStatus status,
        String rejectReason
    ) {}
}
