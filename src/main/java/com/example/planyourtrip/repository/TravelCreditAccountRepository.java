package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.TravelCreditAccount;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface TravelCreditAccountRepository extends JpaRepository<TravelCreditAccount, Long> {

    Optional<TravelCreditAccount> findByUserId(Long userId);

    /**
     * Pessimistic write lock (SELECT ... FOR UPDATE) used by every balance
     * mutation in {@code TravelCreditService#mutate} so concurrent grant/deduct
     * requests on the same account serialize instead of racing on
     * balanceBefore/balanceAfter — the strategy chosen for Phase 7.14 (over
     * optimistic @Version + retry).
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select a from TravelCreditAccount a where a.user.id = :userId")
    Optional<TravelCreditAccount> findByUserIdForUpdate(@Param("userId") Long userId);
}
