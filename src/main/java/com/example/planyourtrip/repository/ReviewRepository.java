package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.Review;
import com.example.planyourtrip.model.ReviewStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface ReviewRepository extends JpaRepository<Review, Long> {

    boolean existsByBookingId(Long bookingId);

    Optional<Review> findByBookingId(Long bookingId);

    List<Review> findByUserIdOrderByCreatedAtDesc(Long userId);

    List<Review> findByPlaceIdAndStatusOrderByCreatedAtDesc(Long placeId, ReviewStatus status);

    List<Review> findAllByOrderByCreatedAtDesc();

    List<Review> findByPlaceIdIn(List<Long> placeIds);

    // ── Phase 7.46 — read-only review-analytics aggregates (additive; no mutation) ──
    // Aggregate queries let the platform-wide ADMIN overview avoid loading every review row.

    /** [status, count] for every {@link ReviewStatus} that has at least one review. */
    @Query("SELECT r.status, COUNT(r) FROM Review r GROUP BY r.status")
    List<Object[]> countGroupedByStatus();

    /** [ratingOverall, count] restricted to reviews in the given status (e.g. APPROVED). */
    @Query("SELECT r.ratingOverall, COUNT(r) FROM Review r WHERE r.status = :status GROUP BY r.ratingOverall")
    List<Object[]> countRatingGroupedByStatus(@Param("status") ReviewStatus status);

    /**
     * One aggregate row of AVG(overall, cleanliness, service, location, value, facilities) over reviews
     * in the given status. AVG ignores NULL category values. Every element is null when no rows match.
     */
    @Query("SELECT AVG(r.ratingOverall), AVG(r.ratingCleanliness), AVG(r.ratingService), "
         + "AVG(r.ratingLocation), AVG(r.ratingValue), AVG(r.ratingFacilities) "
         + "FROM Review r WHERE r.status = :status")
    List<Object[]> averageRatingsByStatus(@Param("status") ReviewStatus status);

    /** Reviews carrying a partner reply (partnerRepliedAt set once on first reply). */
    long countByPartnerRepliedAtIsNotNull();

    /** Distinct places that have at least one review (any status). */
    @Query("SELECT COUNT(DISTINCT r.place.id) FROM Review r")
    long countDistinctPlaces();

    /** Newest review's createdAt across the whole platform; null when there are no reviews. */
    @Query("SELECT MAX(r.createdAt) FROM Review r")
    Instant maxCreatedAt();

    /** Reviews (any status) created in the half-open instant window [start, end). */
    @Query("SELECT COUNT(r) FROM Review r WHERE r.createdAt >= :start AND r.createdAt < :end")
    long countCreatedInRange(@Param("start") Instant start, @Param("end") Instant end);

    /** AVG(overall) over reviews in the given status created in [start, end); null when none. */
    @Query("SELECT AVG(r.ratingOverall) FROM Review r "
         + "WHERE r.status = :status AND r.createdAt >= :start AND r.createdAt < :end")
    Double averageOverallByStatusCreatedInRange(@Param("status") ReviewStatus status,
                                                @Param("start") Instant start,
                                                @Param("end") Instant end);
}
