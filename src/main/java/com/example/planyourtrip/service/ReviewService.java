package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.ReviewDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Service
public class ReviewService {

    private final ReviewRepository reviewRepo;
    private final BookingRepository bookingRepo;
    private final PlaceRepository placeRepo;
    private final UserRepository userRepo;
    private final NotificationService notificationService;

    public ReviewService(ReviewRepository reviewRepo,
                          BookingRepository bookingRepo,
                          PlaceRepository placeRepo,
                          UserRepository userRepo,
                          NotificationService notificationService) {
        this.reviewRepo = reviewRepo;
        this.bookingRepo = bookingRepo;
        this.placeRepo = placeRepo;
        this.userRepo = userRepo;
        this.notificationService = notificationService;
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
        return reviewRepo.findByUserIdOrderByCreatedAtDesc(userId)
            .stream().map(this::toSummary).toList();
    }

    @Transactional(readOnly = true)
    public List<ReviewSummaryResponse> getPlaceReviews(Long placeId) {
        return reviewRepo.findByPlaceIdAndStatusOrderByCreatedAtDesc(placeId, ReviewStatus.APPROVED)
            .stream().map(this::toSummary).toList();
    }

    @Transactional(readOnly = true)
    public List<ReviewResponse> adminListReviews() {
        return reviewRepo.findAllByOrderByCreatedAtDesc()
            .stream().map(this::toResponse).toList();
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
            r.getCreatedAt(), r.getUpdatedAt()
        );
    }

    private ReviewSummaryResponse toSummary(Review r) {
        return new ReviewSummaryResponse(
            r.getId(),
            r.getPlace().getId(), r.getPlace().getName(),
            r.getUser().getId(), r.getUser().getFullName(),
            r.getRatingOverall(), r.getTitle(),
            r.getStatus().name(), r.getCreatedAt()
        );
    }
}
