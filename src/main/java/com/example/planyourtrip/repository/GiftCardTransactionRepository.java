package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.GiftCardReferenceType;
import com.example.planyourtrip.model.GiftCardTransaction;
import com.example.planyourtrip.model.GiftCardTransactionType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface GiftCardTransactionRepository extends JpaRepository<GiftCardTransaction, Long> {

    List<GiftCardTransaction> findByGiftCardIdOrderByCreatedAtDescIdDesc(Long giftCardId);

    /** Idempotency pre-check — see {@code GiftCardTransaction#idempotencyKey}. */
    Optional<GiftCardTransaction> findByIdempotencyKey(String idempotencyKey);

    /**
     * Phase 7.25 — locate the checkout REDEMPTION row for a booking so its
     * release/refund can find the exact gift card again (via the soft
     * referenceType=BOOKING / referenceId=bookingId anchor recorded at redemption).
     */
    Optional<GiftCardTransaction> findFirstByReferenceTypeAndReferenceIdAndTransactionType(
        GiftCardReferenceType referenceType, Long referenceId, GiftCardTransactionType transactionType);
}
