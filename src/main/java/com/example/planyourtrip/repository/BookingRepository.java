package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.Booking;
import com.example.planyourtrip.model.BookingStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface BookingRepository extends JpaRepository<Booking, Long>,
        JpaSpecificationExecutor<Booking> {

    List<Booking> findByUserIdOrderByCreatedAtDesc(Long userId);

    /**
     * Phase 7.39 — resolve a booking by its immutable, unique {@code bookingCode} (the value signed
     * into the customer voucher QR payload). Read-only derived finder backed by the existing unique
     * index {@code idx_bookings_code}.
     */
    Optional<Booking> findByBookingCode(String bookingCode);

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

    // ── Phase 7.37 — admin platform analytics (un-scoped, platform-wide aggregates) ──
    // These compute totals across ALL bookings (no owner/hotel scope), which is a
    // distinct, simpler computation than the owner-scoped partner analytics queries.

    /** Platform-wide booking count grouped by status: rows of [BookingStatus, Long count]. */
    @Query("SELECT b.status, COUNT(b) FROM Booking b GROUP BY b.status")
    List<Object[]> countGroupedByStatus();

    /** Platform-wide gross revenue: sum of finalPrice over all bookings in the given (revenue-recognised) statuses. */
    @Query("SELECT COALESCE(SUM(b.finalPrice), 0) FROM Booking b WHERE b.status IN :statuses")
    BigDecimal sumFinalPriceByStatusIn(@Param("statuses") Collection<BookingStatus> statuses);

    /** Platform-wide count of bookings whose check-in date falls within the range (inclusive). */
    long countByCheckInDateBetween(LocalDate from, LocalDate to);

    /** Platform-wide gross revenue for revenue-recognised bookings whose check-in date is within the range (inclusive). */
    @Query("SELECT COALESCE(SUM(b.finalPrice), 0) FROM Booking b "
         + "WHERE b.status IN :statuses AND b.checkInDate BETWEEN :from AND :to")
    BigDecimal sumFinalPriceByStatusInAndCheckInDateBetween(@Param("statuses") Collection<BookingStatus> statuses,
                                                            @Param("from") LocalDate from,
                                                            @Param("to") LocalDate to);
}
