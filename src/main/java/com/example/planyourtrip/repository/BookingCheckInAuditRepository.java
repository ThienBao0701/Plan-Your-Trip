package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.BookingCheckInAudit;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

/**
 * Phase 7.40 — repository for the immutable partner check-in audit trail.
 * {@link #countByBookingId} backs the idempotency guarantee (a booking accrues exactly one row).
 */
public interface BookingCheckInAuditRepository extends JpaRepository<BookingCheckInAudit, Long> {

    long countByBookingId(Long bookingId);

    List<BookingCheckInAudit> findByBookingId(Long bookingId);
}
