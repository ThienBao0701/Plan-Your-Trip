package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.TravelCreditTransaction;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TravelCreditTransactionRepository extends JpaRepository<TravelCreditTransaction, Long> {

    List<TravelCreditTransaction> findByAccountIdOrderByCreatedAtDescIdDesc(Long accountId);

    /** Idempotency pre-check — see {@code TravelCreditTransaction#idempotencyKey}. */
    Optional<TravelCreditTransaction> findByIdempotencyKey(String idempotencyKey);
}
