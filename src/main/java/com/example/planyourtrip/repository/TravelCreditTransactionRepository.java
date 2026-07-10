package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.TravelCreditTransaction;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface TravelCreditTransactionRepository extends JpaRepository<TravelCreditTransaction, Long> {

    List<TravelCreditTransaction> findByAccountIdOrderByCreatedAtDescIdDesc(Long accountId);

    /** Idempotency pre-check — see {@code TravelCreditTransaction#idempotencyKey}. */
    Optional<TravelCreditTransaction> findByIdempotencyKey(String idempotencyKey);

    /**
     * Phase 7.16 — expiration candidates: ledger rows whose {@code expiresAt}
     * has passed (a grant is valid through its expiry date, so "expired" means
     * {@code expiresAt < today}), ordered by id so processing follows ledger
     * insert order (FIFO). Type filtering (increase types only) happens
     * in-stream in {@code TravelCreditService#processExpirations}.
     */
    List<TravelCreditTransaction> findByExpiresAtBeforeOrderByIdAsc(LocalDate date);
}
