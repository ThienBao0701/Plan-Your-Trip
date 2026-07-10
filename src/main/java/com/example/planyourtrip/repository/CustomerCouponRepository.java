package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.CustomerCoupon;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CustomerCouponRepository extends JpaRepository<CustomerCoupon, Long> {

    List<CustomerCoupon> findByUserIdOrderByCreatedAtDesc(Long userId);

    /** Ownership-scoped lookup — another user's coupon id simply comes back empty (mapped to 404, never 403). */
    Optional<CustomerCoupon> findByIdAndUserId(Long id, Long userId);

    /** Per-user claim count against {@code CouponDefinition#usageLimitPerUser}. */
    long countByUserIdAndCouponDefinitionId(Long userId, Long couponDefinitionId);
}
