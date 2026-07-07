package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.Review;
import com.example.planyourtrip.model.ReviewStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ReviewRepository extends JpaRepository<Review, Long> {

    boolean existsByBookingId(Long bookingId);

    List<Review> findByUserIdOrderByCreatedAtDesc(Long userId);

    List<Review> findByPlaceIdAndStatusOrderByCreatedAtDesc(Long placeId, ReviewStatus status);

    List<Review> findAllByOrderByCreatedAtDesc();

    List<Review> findByPlaceIdIn(List<Long> placeIds);
}
