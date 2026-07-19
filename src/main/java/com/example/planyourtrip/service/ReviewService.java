package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.MediaDto.MediaAssetRequest;
import com.example.planyourtrip.dto.MediaDto.MediaAssetResponse;
import com.example.planyourtrip.dto.MediaDto.ReviewMediaRequest;
import com.example.planyourtrip.dto.ReviewDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class ReviewService {

    private final ReviewRepository reviewRepo;
    private final BookingRepository bookingRepo;
    private final PlaceRepository placeRepo;
    private final UserRepository userRepo;
    private final PartnerProfileRepository partnerProfileRepo;
    private final NotificationService notificationService;
    private final MediaAssetService mediaAssetService;
    private final MediaAssetRepository mediaAssetRepo;

    public ReviewService(ReviewRepository reviewRepo,
                          BookingRepository bookingRepo,
                          PlaceRepository placeRepo,
                          UserRepository userRepo,
                          PartnerProfileRepository partnerProfileRepo,
                          NotificationService notificationService,
                          MediaAssetService mediaAssetService,
                          MediaAssetRepository mediaAssetRepo) {
        this.reviewRepo = reviewRepo;
        this.bookingRepo = bookingRepo;
        this.placeRepo = placeRepo;
        this.userRepo = userRepo;
        this.partnerProfileRepo = partnerProfileRepo;
        this.notificationService = notificationService;
        this.mediaAssetService = mediaAssetService;
        this.mediaAssetRepo = mediaAssetRepo;
    }

    /** Body-based create route: {@code POST /api/reviews} (bookingId in the payload). */
    @Transactional
    public ReviewResponse createReview(Long userId, ReviewRequest req) {
        return create(userId, req.bookingId(),
            req.ratingOverall(), req.ratingCleanliness(), req.ratingService(),
            req.ratingLocation(), req.ratingValue(), req.ratingFacilities(),
            req.title(), req.content());
    }

    /**
     * Phase 7.43 — booking-scoped alias route:
     * {@code POST /api/me/bookings/{bookingId}/review} (bookingId in the path).
     * Delegates to the SAME shared create logic as the body-based route.
     */
    @Transactional
    public ReviewResponse createReviewForBooking(Long userId, Long bookingId, BookingScopedReviewRequest req) {
        return create(userId, bookingId,
            req.ratingOverall(), req.ratingCleanliness(), req.ratingService(),
            req.ratingLocation(), req.ratingValue(), req.ratingFacilities(),
            req.title(), req.content());
    }

    /** Shared create logic used by both the body-based and path-based routes. */
    private ReviewResponse create(Long userId, Long bookingId,
                                  Integer ratingOverall, Integer ratingCleanliness, Integer ratingService,
                                  Integer ratingLocation, Integer ratingValue, Integer ratingFacilities,
                                  String title, String content) {
        Booking booking = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));
        if (!booking.getUser().getId().equals(userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied: booking belongs to another user");
        if (booking.getStatus() != BookingStatus.COMPLETED)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "Only completed bookings can be reviewed");
        if (reviewRepo.existsByBookingId(booking.getId()))
            throw new ApiException(HttpStatus.CONFLICT, "A review already exists for this booking");

        Review review = new Review();
        review.setBooking(booking);
        review.setUser(booking.getUser());
        review.setPlace(booking.getHotel());
        review.setRatingOverall(ratingOverall);
        review.setRatingCleanliness(ratingCleanliness);
        review.setRatingService(ratingService);
        review.setRatingLocation(ratingLocation);
        review.setRatingValue(ratingValue);
        review.setRatingFacilities(ratingFacilities);
        review.setTitle(title);
        review.setContent(content);
        review.setStatus(ReviewStatus.PENDING);

        review = reviewRepo.save(review);
        Review savedReview = review;

        // Notify ADMINS — a new review is pending moderation (unchanged).
        userRepo.findAll().stream()
            .filter(u -> "ADMIN".equals(u.getRole()))
            .forEach(admin -> notificationService.create(admin.getId(), NotificationType.REVIEW, Priority.NORMAL,
                "New review submitted",
                "A new review was submitted for " + savedReview.getPlace().getName() + " and is pending moderation.",
                RelatedEntityType.HOTEL, savedReview.getPlace().getId()));

        // Phase 7.43 — notify the hotel/place OWNER (partner) that a review arrived.
        PartnerProfile owner = savedReview.getPlace().getOwner();
        if (owner != null && owner.getUser() != null) {
            notificationService.create(owner.getUser().getId(), NotificationType.REVIEW, Priority.NORMAL,
                "New review submitted",
                "A new review has been submitted for " + savedReview.getPlace().getName() + ".",
                RelatedEntityType.HOTEL, savedReview.getPlace().getId());
        }

        return toResponse(review);
    }

    @Transactional(readOnly = true)
    public ReviewResponse getReview(Long userId, Long reviewId) {
        Review review = reviewOrThrow(reviewId);
        checkOwnerOrAdmin(userId, review.getUser().getId());
        return toResponse(review);
    }

    @Transactional(readOnly = true)
    public List<ReviewSummaryResponse> getMyReviews(Long userId) {
        List<Review> reviews = reviewRepo.findByUserIdOrderByCreatedAtDesc(userId);
        Map<Long, List<ReviewMediaItem>> media = loadMediaBatch(reviews);
        return reviews.stream()
            .map(r -> toSummary(r, media.getOrDefault(r.getId(), List.of())))
            .toList();
    }

    @Transactional(readOnly = true)
    public List<ReviewSummaryResponse> getPlaceReviews(Long placeId) {
        List<Review> reviews = reviewRepo.findByPlaceIdAndStatusOrderByCreatedAtDesc(placeId, ReviewStatus.APPROVED);
        Map<Long, List<ReviewMediaItem>> media = loadMediaBatch(reviews);
        return reviews.stream()
            .map(r -> toSummary(r, media.getOrDefault(r.getId(), List.of())))
            .toList();
    }

    @Transactional(readOnly = true)
    public List<ReviewResponse> adminListReviews() {
        List<Review> reviews = reviewRepo.findAllByOrderByCreatedAtDesc();
        Map<Long, List<ReviewMediaItem>> media = loadMediaBatch(reviews);
        return reviews.stream()
            .map(r -> toResponse(r, media.getOrDefault(r.getId(), List.of())))
            .toList();
    }

    // ── Phase 7.45 — customer review-media management (reuses MediaAssetService) ──

    /**
     * Attach media to a review the caller owns. The registration reuses
     * {@link MediaAssetService#create} verbatim (same validation: url required,
     * mediaType required, cover-only-IMAGE). {@code ownerType}/{@code ownerId} are
     * FORCED to REVIEW / the path reviewId — never taken from the client.
     * Wrong owner → 403, matching the existing review ownership convention.
     */
    @Transactional
    public MediaAssetResponse addReviewMedia(Long userId, Long reviewId, ReviewMediaRequest req) {
        Review review = reviewOrThrow(reviewId);
        requireOwner(userId, review);
        MediaAssetRequest full = new MediaAssetRequest(
            MediaOwnerType.REVIEW, reviewId,
            req.url(), req.thumbnailUrl(), req.mediaType(),
            req.altText(), req.sortOrder(), req.cover());
        return mediaAssetService.create(full, userId);
    }

    /**
     * Soft-delete (deactivate) one media asset attached to a review the caller owns.
     * Reuses {@link MediaAssetService#deactivate} — the same soft-delete the admin
     * media surface uses. The media must belong to THIS review (ownerType=REVIEW,
     * ownerId=reviewId) else 404; wrong review owner → 403.
     */
    @Transactional
    public MediaAssetResponse deleteReviewMedia(Long userId, Long reviewId, Long mediaId) {
        Review review = reviewOrThrow(reviewId);
        requireOwner(userId, review);
        if (!mediaAssetRepo.existsByOwnerTypeAndOwnerIdAndId(MediaOwnerType.REVIEW, reviewId, mediaId))
            throw new ApiException(HttpStatus.NOT_FOUND, "Media asset not found: " + mediaId);
        return mediaAssetService.deactivate(mediaId);
    }

    private void requireOwner(Long userId, Review review) {
        if (!review.getUser().getId().equals(userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied: review belongs to another user");
    }

    @Transactional
    public ReviewResponse adminModerateReview(Long reviewId, ReviewModerationRequest req) {
        Review review = reviewOrThrow(reviewId);
        Instant now = Instant.now();
        ReviewStatus newStatus = req.status();

        review.setStatus(newStatus);
        if (newStatus == ReviewStatus.APPROVED) {
            review.setApprovedAt(now);
        } else if (newStatus == ReviewStatus.REJECTED) {
            review.setRejectedAt(now);
            review.setRejectReason(req.rejectReason());
        }
        review = reviewRepo.save(review);

        Long placeId = review.getPlace().getId();
        if (newStatus == ReviewStatus.APPROVED || newStatus == ReviewStatus.REJECTED
                || newStatus == ReviewStatus.HIDDEN) {
            recalculatePlaceRating(placeId);
        }

        if (newStatus == ReviewStatus.APPROVED) {
            notificationService.create(review.getUser().getId(), NotificationType.REVIEW, Priority.NORMAL,
                "Review approved", "Your review was approved.",
                RelatedEntityType.HOTEL, placeId);
        } else if (newStatus == ReviewStatus.REJECTED) {
            String reason = req.rejectReason();
            notificationService.create(review.getUser().getId(), NotificationType.REVIEW, Priority.NORMAL,
                "Review rejected",
                "Your review was rejected" + (reason != null && !reason.isBlank() ? ": " + reason : ".") ,
                RelatedEntityType.HOTEL, placeId);
        }

        return toResponse(review);
    }

    /**
     * Phase 7.44 — an authorized partner posts or updates the single reply to a review
     * for a hotel they own. Additive on the existing {@link Review} row (no new entity).
     *
     * <ul>
     *   <li>Caller must have an APPROVED {@link PartnerProfile} (same
     *       {@code myApprovedProfileOrThrow} convention as the other partner services);
     *       an admin/anyone without an approved profile → 404 (no cross-partner leak).</li>
     *   <li>The review's place must be owned by that profile; otherwise a uniform 404
     *       (same status as an unknown review — no existence leak across partners).</li>
     *   <li>Reply is allowed ONLY on the publicly-visible status — APPROVED — because that
     *       is the exact set {@code getPlaceReviews} exposes. Any other status → 422
     *       (matching the {@code UNPROCESSABLE_ENTITY} convention used elsewhere here for
     *       invalid-state operations).</li>
     *   <li>One reply per review: the first PUT sets {@code partnerRepliedAt}; every PUT
     *       (create or edit) bumps {@code partnerReplyUpdatedAt}. The customer is notified
     *       only on the FIRST reply.</li>
     * </ul>
     */
    @Transactional
    public ReviewResponse partnerReply(Long userId, Long reviewId, PartnerReplyRequest req) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        Review review = reviewOrThrow(reviewId);

        PartnerProfile owner = review.getPlace().getOwner();
        if (owner == null || !owner.getId().equals(profile.getId()))
            throw new ApiException(HttpStatus.NOT_FOUND, "Review not found: " + reviewId);

        if (review.getStatus() != ReviewStatus.APPROVED)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Only published (approved) reviews can be replied to");

        boolean firstReply = review.getPartnerRepliedAt() == null;
        Instant now = Instant.now();

        review.setPartnerReply(req.content().trim());
        if (firstReply) review.setPartnerRepliedAt(now);
        review.setPartnerReplyUpdatedAt(now);
        review.setPartnerRepliedBy(profile);
        review = reviewRepo.save(review);

        // Notify the review author ONLY on the first reply (idempotent on edits).
        if (firstReply) {
            notificationService.create(review.getUser().getId(), NotificationType.REVIEW, Priority.NORMAL,
                "Hotel replied to your review",
                review.getPlace().getName() + " replied to your review.",
                RelatedEntityType.HOTEL, review.getId());
        }

        return toResponse(review);
    }

    // Same APPROVED-profile ownership convention as PartnerBookingService / PartnerPricingService.
    private PartnerProfile myApprovedProfileOrThrow(Long userId) {
        PartnerProfile profile = partnerProfileRepo.findByUserId(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Partner profile not found"));
        if (profile.getVerificationStatus() != PartnerVerificationStatus.APPROVED)
            throw new ApiException(HttpStatus.FORBIDDEN, "Partner profile is not approved");
        return profile;
    }

    @Transactional
    public void recalculatePlaceRating(Long placeId) {
        Place place = placeRepo.findById(placeId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Place not found: " + placeId));

        List<Review> approved = reviewRepo.findByPlaceIdAndStatusOrderByCreatedAtDesc(placeId, ReviewStatus.APPROVED);
        double avg = approved.stream().mapToInt(Review::getRatingOverall).average().orElse(0.0);

        place.setRatingAvg(Math.round(avg * 10) / 10.0);
        place.setReviewCount(approved.size());
        placeRepo.save(place);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private Review reviewOrThrow(Long reviewId) {
        return reviewRepo.findById(reviewId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Review not found: " + reviewId));
    }

    private void checkOwnerOrAdmin(Long userId, Long ownerId) {
        if (ownerId.equals(userId)) return;
        User requestingUser = userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));
        if (!"ADMIN".equals(requestingUser.getRole()))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied");
    }

    private ReviewResponse toResponse(Review r) {
        return toResponse(r, loadMedia(r.getId()));
    }

    private ReviewResponse toResponse(Review r, List<ReviewMediaItem> media) {
        return new ReviewResponse(
            r.getId(),
            r.getBooking().getId(), r.getBooking().getBookingCode(),
            r.getUser().getId(), r.getUser().getFullName(),
            r.getPlace().getId(), r.getPlace().getName(),
            r.getRatingOverall(), r.getRatingCleanliness(), r.getRatingService(),
            r.getRatingLocation(), r.getRatingValue(), r.getRatingFacilities(),
            r.getTitle(), r.getContent(),
            r.getStatus().name(),
            r.getHelpfulCount(), r.getReportedCount(),
            r.getApprovedAt(), r.getRejectedAt(), r.getRejectReason(),
            r.getCreatedAt(), r.getUpdatedAt(),
            toReplyInfo(r),
            media
        );
    }

    private ReviewSummaryResponse toSummary(Review r) {
        return toSummary(r, loadMedia(r.getId()));
    }

    private ReviewSummaryResponse toSummary(Review r, List<ReviewMediaItem> media) {
        return new ReviewSummaryResponse(
            r.getId(),
            r.getPlace().getId(), r.getPlace().getName(),
            r.getUser().getId(), r.getUser().getFullName(),
            r.getRatingOverall(), r.getTitle(),
            r.getStatus().name(), r.getCreatedAt(),
            toReplyInfo(r),
            media
        );
    }

    // ── Phase 7.45 — review media read projection (ownerType=REVIEW) ─────────────

    /** Active media for ONE review, ordered by (sortOrder, id). Used by single-review reads. */
    private List<ReviewMediaItem> loadMedia(Long reviewId) {
        return mediaAssetRepo
            .findByOwnerTypeAndOwnerIdAndActiveTrueOrderBySortOrderAscIdAsc(MediaOwnerType.REVIEW, reviewId)
            .stream().map(this::toMediaItem).toList();
    }

    /**
     * Batch load of active media for many reviews — ONE query — grouped by reviewId,
     * so list endpoints avoid an N+1 media lookup per review.
     */
    private Map<Long, List<ReviewMediaItem>> loadMediaBatch(List<Review> reviews) {
        if (reviews.isEmpty()) return Map.of();
        List<Long> ids = reviews.stream().map(Review::getId).toList();
        return mediaAssetRepo
            .findByOwnerTypeAndOwnerIdInAndActiveTrueOrderBySortOrderAscIdAsc(MediaOwnerType.REVIEW, ids)
            .stream()
            .collect(Collectors.groupingBy(MediaAsset::getOwnerId,
                Collectors.mapping(this::toMediaItem, Collectors.toList())));
    }

    private ReviewMediaItem toMediaItem(MediaAsset a) {
        return new ReviewMediaItem(
            a.getId(), a.getUrl(), a.getThumbnailUrl(),
            a.getMediaType(), a.getSortOrder(), a.isCover(), a.getAltText());
    }

    /** Safe reply projection: null when the review has no partner reply. */
    private PartnerReplyInfo toReplyInfo(Review r) {
        if (r.getPartnerRepliedAt() == null) return null;
        String displayName = r.getPartnerRepliedBy() != null
            ? r.getPartnerRepliedBy().getBusinessName() : null;
        return new PartnerReplyInfo(
            r.getPartnerReply(),
            r.getPartnerRepliedAt(),
            r.getPartnerReplyUpdatedAt(),
            displayName);
    }
}
