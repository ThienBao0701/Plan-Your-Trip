package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.PartnerActivityLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.repository.Repository;

import java.util.List;

/**
 * Append-only access to {@link PartnerActivityLog} (RBAC V1.1 §22.1 AU-3, §28 M-4).
 *
 * <p>Like {@code AdminActivityLogRepository}, this extends the bare {@link Repository} marker rather than
 * {@code JpaRepository}, so no {@code delete}, {@code deleteAll} or bulk-update method exists to call: a
 * partner workspace's trail cannot be rewritten through the application. Only the methods declared here
 * exist.
 */
public interface PartnerActivityLogRepository extends Repository<PartnerActivityLog, Long> {

    PartnerActivityLog save(PartnerActivityLog entry);

    List<PartnerActivityLog> findByPartnerProfileIdOrderByCreatedAtDesc(Long partnerProfileId);

    /**
     * D1c — the administrative view of one partner's trail is append-only and unbounded in time,
     * so it is read a page at a time. {@code id} is appended to the ordering because rows written
     * inside one transaction share a {@code createdAt}, and a non-total order lets a page boundary
     * repeat or skip a row (the same defect {@code AdminPaging.safeSort} exists to prevent).
     */
    Page<PartnerActivityLog> findByPartnerProfileIdOrderByCreatedAtDescIdDesc(
        Long partnerProfileId, Pageable pageable);
}
