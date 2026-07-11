package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.LoyaltyAccount;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface LoyaltyAccountRepository extends JpaRepository<LoyaltyAccount, Long> {

    Optional<LoyaltyAccount> findByUserId(Long userId);

    /**
     * Pessimistic write lock (SELECT ... FOR UPDATE) used by every point
     * mutation in {@code LoyaltyService#credit} so concurrent earn/grant
     * requests on the same account serialize instead of racing on
     * balanceBefore/balanceAfter — same strategy as
     * {@code TravelCreditAccountRepository#findByUserIdForUpdate}.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select a from LoyaltyAccount a where a.user.id = :userId")
    Optional<LoyaltyAccount> findByUserIdForUpdate(@Param("userId") Long userId);
}
