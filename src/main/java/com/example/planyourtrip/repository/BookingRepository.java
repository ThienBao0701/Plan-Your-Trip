package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.Booking;
import com.example.planyourtrip.model.BookingStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.time.LocalDate;
import java.util.Collection;
import java.util.List;

public interface BookingRepository extends JpaRepository<Booking, Long>,
        JpaSpecificationExecutor<Booking> {

    List<Booking> findByUserIdOrderByCreatedAtDesc(Long userId);

    List<Booking> findAllByOrderByCreatedAtDesc();

    List<Booking> findByUserIdAndCheckInDateGreaterThanEqualAndStatusInOrderByCheckInDateAsc(
            Long userId, LocalDate from, Collection<BookingStatus> statuses);

    List<Booking> findByUserIdAndStatusInOrderByCheckInDateDesc(
            Long userId, Collection<BookingStatus> statuses);

    List<Booking> findByUserIdAndStatusInOrderByCreatedAtDesc(
            Long userId, Collection<BookingStatus> statuses);

    // ── Phase 7.17 — customer-segment eligibility (own booking history only) ──

    /** NEW_USER / firstBookingOnly: true when the user has any "qualifying" (non-cancelled, non-refunded) booking. */
    boolean existsByUserIdAndStatusNotIn(Long userId, Collection<BookingStatus> statuses);

    /** RETURNING_USER: true when the user has at least one confirmed-or-later booking. */
    boolean existsByUserIdAndStatusIn(Long userId, Collection<BookingStatus> statuses);

    /** HIGH_VALUE: count of the user's bookings in a given status (COMPLETED), compared against a threshold. */
    long countByUserIdAndStatus(Long userId, BookingStatus status);
}
