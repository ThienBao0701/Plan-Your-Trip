package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.PartnerActivityLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PartnerActivityLogRepository extends JpaRepository<PartnerActivityLog, Long> {

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
