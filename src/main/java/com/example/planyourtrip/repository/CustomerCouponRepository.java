package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.CustomerCoupon;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface CustomerCouponRepository extends JpaRepository<CustomerCoupon, Long> {

    List<CustomerCoupon> findByUserIdOrderByCreatedAtDesc(Long userId);

    /** Ownership-scoped lookup — another user's coupon id simply comes back empty (mapped to 404, never 403). */
    Optional<CustomerCoupon> findByIdAndUserId(Long id, Long userId);

    /** Per-user claim count against {@code CouponDefinition#usageLimitPerUser}. */
    long countByUserIdAndCouponDefinitionId(Long userId, Long couponDefinitionId);

    /**
     * Phase 7.15 checkout — all of a user's claims of a given (normalized,
     * upper-case) code, oldest claim first so the earliest AVAILABLE claim is
     * consumed first when {@code usageLimitPerUser > 1}.
     */
    List<CustomerCoupon> findByUserIdAndCouponDefinitionCodeOrderByClaimedAtAsc(Long userId, String code);

    /**
     * D4 — the locked counterpart used by checkout, keyed on the resolved definition id so the
     * {@code SELECT ... FOR UPDATE} touches {@code customer_coupons} alone (the definition id is a
     * plain FK column, so this does not join).
     *
     * <p>Spending a coupon is an AVAILABLE-check followed by a write to USED, and the unlocked
     * version let two bookings placed at the same moment both see the same AVAILABLE claim: both
     * were granted the discount and the customer spent one single-use coupon twice. Taking the row
     * lock here — as the first read in the transaction, so the status is read under the lock rather
     * than from a stale persistence context — serialises the two checkouts, and the loser correctly
     * sees the coupon as already used.
     *
     * <p>Ordered oldest claim first, preserving
     * {@link #findByUserIdAndCouponDefinitionCodeOrderByClaimedAtAsc}'s consumption order when
     * {@code usageLimitPerUser > 1}.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select c from CustomerCoupon c where c.user.id = :userId "
         + "and c.couponDefinition.id = :definitionId order by c.claimedAt asc")
    List<CustomerCoupon> findForCheckoutForUpdate(@Param("userId") Long userId,
                                                   @Param("definitionId") Long definitionId);

    /** Phase 7.15 cancellation — the coupon consumed by a booking (at most one per booking). */
    Optional<CustomerCoupon> findByBookingId(Long bookingId);
}
