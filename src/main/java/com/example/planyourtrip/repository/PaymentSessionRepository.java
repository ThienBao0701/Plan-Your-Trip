package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.PaymentSession;
import com.example.planyourtrip.model.PaymentSessionStatus;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface PaymentSessionRepository extends JpaRepository<PaymentSession, Long> {

    Optional<PaymentSession> findBySessionId(String sessionId);

    /**
     * Pessimistic write lock (SELECT ... FOR UPDATE) used by every state mutation in
     * {@code PaymentGatewayService} — same strategy as
     * {@code GiftCardRepository#findByIdForUpdate}, so concurrent callbacks on the same
     * session serialize instead of racing.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select s from PaymentSession s where s.sessionId = :sessionId")
    Optional<PaymentSession> findBySessionIdForUpdate(@Param("sessionId") String sessionId);

    List<PaymentSession> findByBookingIdOrderByCreatedAtDesc(Long bookingId);

    List<PaymentSession> findAllByOrderByCreatedAtDesc();

    /** Time-based expiry sweep candidates: non-terminal sessions whose {@code expiresAt} has passed. */
    @Query("select s from PaymentSession s where s.expiresAt < :now and s.status in :statuses order by s.id asc")
    List<PaymentSession> findExpirationCandidates(@Param("now") Instant now,
                                                  @Param("statuses") List<PaymentSessionStatus> statuses);
}
