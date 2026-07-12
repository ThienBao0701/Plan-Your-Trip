package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.PaymentSessionEvent;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PaymentSessionEventRepository extends JpaRepository<PaymentSessionEvent, Long> {

    /** Idempotency pre-check — see {@code PaymentSessionEvent#idempotencyKey}. */
    Optional<PaymentSessionEvent> findByIdempotencyKey(String idempotencyKey);

    List<PaymentSessionEvent> findByPaymentSessionIdOrderByCreatedAtAscIdAsc(Long paymentSessionId);
}
