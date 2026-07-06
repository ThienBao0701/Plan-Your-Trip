package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.Payment;
import com.example.planyourtrip.model.PaymentStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PaymentRepository extends JpaRepository<Payment, Long> {

    List<Payment> findByBookingIdOrderByCreatedAtDesc(Long bookingId);

    List<Payment> findAllByOrderByCreatedAtDesc();

    boolean existsByBookingIdAndStatus(Long bookingId, PaymentStatus status);
}
