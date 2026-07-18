package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.BookingCheckOutAudit;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

/**
 * Phase 7.41 — repository for the immutable partner check-out audit trail.
 * {@link #countByBookingId} backs the idempotency guarantee (a booking accrues exactly one row).
 */
public interface BookingCheckOutAuditRepository extends JpaRepository<BookingCheckOutAudit, Long> {

    long countByBookingId(Long bookingId);

    List<BookingCheckOutAudit> findByBookingId(Long bookingId);
}
