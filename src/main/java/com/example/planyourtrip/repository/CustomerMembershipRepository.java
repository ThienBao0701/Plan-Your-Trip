package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.CustomerMembership;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface CustomerMembershipRepository extends JpaRepository<CustomerMembership, Long> {

    Optional<CustomerMembership> findByUserId(Long userId);

    /**
     * The query used everywhere a membership needs to be "the" current one for
     * a user — including the read-only MEMBER coupon-eligibility signal
     * ({@code CustomerCouponService#evaluateSegment}), which must never create
     * a row as a side effect (plain repository read, no service call).
     */
    Optional<CustomerMembership> findByUserIdAndActiveTrue(Long userId);
}
