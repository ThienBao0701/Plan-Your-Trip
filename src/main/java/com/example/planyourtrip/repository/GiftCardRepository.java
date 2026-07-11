package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.GiftCard;
import com.example.planyourtrip.model.GiftCardStatus;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface GiftCardRepository extends JpaRepository<GiftCard, Long>, JpaSpecificationExecutor<GiftCard> {

    Optional<GiftCard> findByGiftCardCode(String giftCardCode);

    /** Guards {@code GiftCardProductService#delete} — a product referenced by any issued gift card cannot be deleted. */
    boolean existsByProductId(Long productId);

    /**
     * Pessimistic write lock (SELECT ... FOR UPDATE) used by every balance
     * mutation in {@code GiftCardService} — same strategy as
     * {@code TravelCreditAccountRepository#findByUserIdForUpdate} /
     * {@code LoyaltyAccountRepository#findByUserIdForUpdate}, chosen over
     * optimistic @Version + retry so concurrent mutations on the same card
     * serialize instead of racing.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select g from GiftCard g where g.id = :id")
    Optional<GiftCard> findByIdForUpdate(@Param("id") Long id);

    List<GiftCard> findByPurchaserUserIdOrderByCreatedAtDesc(Long purchaserUserId);

    List<GiftCard> findByRecipientUserIdOrderByCreatedAtDesc(Long recipientUserId);

    /**
     * Expiration-processor candidates: cards whose {@code expiresAt} has passed
     * and still carry a remaining balance, restricted to the non-terminal
     * statuses that are still eligible to expire (ISSUED/ACTIVE/PARTIALLY_REDEEMED).
     */
    @Query("select g from GiftCard g where g.expiresAt < :now and g.currentBalance > 0 "
        + "and g.status in :eligibleStatuses order by g.id asc")
    List<GiftCard> findExpirationCandidates(@Param("now") Instant now,
                                             @Param("eligibleStatuses") List<GiftCardStatus> eligibleStatuses);
}
