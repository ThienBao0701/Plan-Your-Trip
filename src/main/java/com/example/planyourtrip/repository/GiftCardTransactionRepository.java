package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.GiftCardTransaction;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface GiftCardTransactionRepository extends JpaRepository<GiftCardTransaction, Long> {

    List<GiftCardTransaction> findByGiftCardIdOrderByCreatedAtDescIdDesc(Long giftCardId);

    /** Idempotency pre-check — see {@code GiftCardTransaction#idempotencyKey}. */
    Optional<GiftCardTransaction> findByIdempotencyKey(String idempotencyKey);
}
