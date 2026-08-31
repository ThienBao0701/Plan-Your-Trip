package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.PaymentSession;
import com.example.planyourtrip.model.PaymentSessionStatus;
import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface PaymentSessionRepository
        extends JpaRepository<PaymentSession, Long>, JpaSpecificationExecutor<PaymentSession> {

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

    /** Time-based expiry sweep candidates: non-terminal sessions whose {@code expiresAt} has passed. */
    @Query("select s from PaymentSession s where s.expiresAt < :now and s.status in :statuses order by s.id asc")
    List<PaymentSession> findExpirationCandidates(@Param("now") Instant now,
                                                  @Param("statuses") List<PaymentSessionStatus> statuses);

    /**
     * D1c — the administrative session grid renders each row's booking code, and {@code booking} is
     * a lazy to-one, so the graph turns 1+N selects per page into one.
     */
    @Override
    @EntityGraph(attributePaths = {"booking"})
    Page<PaymentSession> findAll(Specification<PaymentSession> spec, Pageable pageable);
}
