package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.AdminActivityLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Optional;

/**
 * D1a — append-only access to {@link AdminActivityLog}.
 *
 * <p>This deliberately extends the bare {@link Repository} marker rather than {@code JpaRepository}.
 * That is the enforcement mechanism for the append-only guarantee: no {@code delete}, {@code
 * deleteById}, {@code deleteAll} or bulk-update method is inherited, so none can be called from
 * anywhere in the application — an administrator has no code path to erase the record of their own
 * action. Only the four methods declared here exist.
 */
public interface AdminActivityLogRepository extends Repository<AdminActivityLog, Long> {

    AdminActivityLog save(AdminActivityLog entry);

    Optional<AdminActivityLog> findById(Long id);

    long count();

    /**
     * Filtered, database-side paginated read. Every filter is optional: a {@code null} argument
     * disables that predicate, so one query serves the whole read surface without string
     * concatenation. Ordering is fixed to newest-first and is not client-controllable, which
     * removes any sort-injection surface on the audit trail itself.
     */
    @Query("""
           SELECT l FROM AdminActivityLog l
           WHERE (:actorUserId IS NULL OR l.actorUserId = :actorUserId)
             AND (:action     IS NULL OR l.action     = :action)
             AND (:targetType IS NULL OR l.targetType = :targetType)
             AND (:targetId   IS NULL OR l.targetId   = :targetId)
             AND (:from       IS NULL OR l.createdAt >= :from)
             AND (:to         IS NULL OR l.createdAt <= :to)
           ORDER BY l.createdAt DESC, l.id DESC
           """)
    Page<AdminActivityLog> search(@Param("actorUserId") Long actorUserId,
                                  @Param("action") String action,
                                  @Param("targetType") String targetType,
                                  @Param("targetId") Long targetId,
                                  @Param("from") Instant from,
                                  @Param("to") Instant to,
                                  Pageable pageable);
}
