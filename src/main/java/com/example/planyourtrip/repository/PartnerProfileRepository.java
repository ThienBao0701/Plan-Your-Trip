package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.PartnerProfile;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import jakarta.persistence.LockModeType;

import java.util.Optional;

public interface PartnerProfileRepository
        extends JpaRepository<PartnerProfile, Long>, JpaSpecificationExecutor<PartnerProfile> {

    Optional<PartnerProfile> findByUserId(Long userId);

    boolean existsByUserId(Long userId);

    /**
     * RBAC R3a §19 LO-3 — the company row, locked for the rest of the transaction. Every team mutation takes
     * this lock first, so the owner count it checks cannot change underneath it: two concurrent revocations of
     * the last two owners serialize, and the second sees the first.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select p from PartnerProfile p where p.id = :id")
    Optional<PartnerProfile> findByIdForUpdate(@Param("id") Long id);

    /**
     * D1c — the admin partner grid renders the owning user's name/email and the approving admin's
     * name, both lazy {@code @ManyToOne}s. Fetching them with the page turns 1+2N selects into one.
     */
    @Override
    @EntityGraph(attributePaths = {"user", "approvedBy"})
    Page<PartnerProfile> findAll(Specification<PartnerProfile> spec, Pageable pageable);
}
