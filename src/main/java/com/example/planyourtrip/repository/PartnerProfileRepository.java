package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.PartnerProfile;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.Optional;

public interface PartnerProfileRepository
        extends JpaRepository<PartnerProfile, Long>, JpaSpecificationExecutor<PartnerProfile> {

    Optional<PartnerProfile> findByUserId(Long userId);

    boolean existsByUserId(Long userId);

    /**
     * D1c — the admin partner grid renders the owning user's name/email and the approving admin's
     * name, both lazy {@code @ManyToOne}s. Fetching them with the page turns 1+2N selects into one.
     */
    @Override
    @EntityGraph(attributePaths = {"user", "approvedBy"})
    Page<PartnerProfile> findAll(Specification<PartnerProfile> spec, Pageable pageable);
}
