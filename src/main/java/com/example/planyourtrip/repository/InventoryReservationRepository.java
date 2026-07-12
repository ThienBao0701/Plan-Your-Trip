package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.InventoryReservation;
import com.example.planyourtrip.model.InventoryReservationStatus;
import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface InventoryReservationRepository extends JpaRepository<InventoryReservation, Long> {

    Optional<InventoryReservation> findByBookingId(Long bookingId);

    boolean existsByBookingId(Long bookingId);

    /**
     * Pessimistic write lock (SELECT ... FOR UPDATE) used by every reservation state
     * transition (consume / release / expire) in {@code InventoryReservationService} —
     * same strategy as {@code PaymentSessionRepository#findBySessionIdForUpdate} /
     * {@code GiftCardRepository#findByIdForUpdate}, so concurrent settlement/cancel/expiry
     * triggers on the SAME booking serialize instead of racing (idempotent, no double-restore).
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select r from InventoryReservation r where r.booking.id = :bookingId")
    Optional<InventoryReservation> findByBookingIdForUpdate(@Param("bookingId") Long bookingId);

    /** Expiry-sweep candidates: still-HELD holds whose {@code expiresAt} has passed. */
    @Query("select r from InventoryReservation r where r.status = :status "
        + "and r.expiresAt < :now order by r.id asc")
    List<InventoryReservation> findExpirationCandidates(@Param("now") Instant now,
                                                        @Param("status") InventoryReservationStatus status);

    Page<InventoryReservation> findAllByOrderByCreatedAtDesc(Pageable pageable);

    Page<InventoryReservation> findByStatusOrderByCreatedAtDesc(InventoryReservationStatus status, Pageable pageable);
}
