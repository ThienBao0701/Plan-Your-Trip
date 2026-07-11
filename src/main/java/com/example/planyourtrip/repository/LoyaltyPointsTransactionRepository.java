package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.LoyaltyPointsTransaction;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface LoyaltyPointsTransactionRepository extends JpaRepository<LoyaltyPointsTransaction, Long> {

    List<LoyaltyPointsTransaction> findByAccountIdOrderByCreatedAtDescIdDesc(Long accountId);

    /** Idempotency pre-check — see {@code LoyaltyPointsTransaction#idempotencyKey}. */
    Optional<LoyaltyPointsTransaction> findByIdempotencyKey(String idempotencyKey);
}
