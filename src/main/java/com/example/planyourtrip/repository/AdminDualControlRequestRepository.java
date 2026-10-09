package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.AdminDualControlRequest;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface AdminDualControlRequestRepository
        extends JpaRepository<AdminDualControlRequest, Long>, JpaSpecificationExecutor<AdminDualControlRequest> {

    /**
     * RBAC R6 — the request row, locked for the decision. Every transition (approve, reject, cancel, expire, stale)
     * takes this lock first, so competing decisions on one request serialize and only the first finds it pending.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select r from AdminDualControlRequest r where r.id = :id")
    Optional<AdminDualControlRequest> lockById(@Param("id") Long id);

    /** The open (live-key 0) request for an action on a target, if any — at most one, by the live unique key. */
    @Query("select r from AdminDualControlRequest r where r.permission = :permission and r.targetType = :targetType "
        + "and r.targetId = :targetId and r.liveKey = 0")
    Optional<AdminDualControlRequest> findOpen(@Param("permission") String permission,
                                               @Param("targetType") String targetType,
                                               @Param("targetId") Long targetId);
}
