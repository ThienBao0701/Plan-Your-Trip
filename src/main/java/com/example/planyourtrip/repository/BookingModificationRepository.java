package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.BookingModification;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface BookingModificationRepository extends JpaRepository<BookingModification, Long> {

    /**
     * Phase 7.36 — the ordered modification history for a booking (oldest first), used to enrich
     * the booking timeline with one MODIFIED event per row. Ordered by createdAt then id so rows
     * inserted within the same instant remain deterministically ordered.
     */
    List<BookingModification> findByBookingIdOrderByCreatedAtAscIdAsc(Long bookingId);
}
