package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.Invoice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.List;
import java.util.Optional;

public interface InvoiceRepository extends JpaRepository<Invoice, Long>,
        JpaSpecificationExecutor<Invoice> {

    Optional<Invoice> findByBookingId(Long bookingId);

    boolean existsByBookingId(Long bookingId);

    List<Invoice> findByUserIdOrderByCreatedAtDesc(Long userId);

    List<Invoice> findAllByOrderByCreatedAtDesc();

    List<Invoice> findByBookingIdIn(List<Long> bookingIds);
}
