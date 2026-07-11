package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.MembershipTier;
import com.example.planyourtrip.model.MembershipTierDefinition;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface MembershipTierDefinitionRepository extends JpaRepository<MembershipTierDefinition, Long> {

    Optional<MembershipTierDefinition> findByTier(MembershipTier tier);

    Optional<MembershipTierDefinition> findByTierAndActiveTrue(MembershipTier tier);

    List<MembershipTierDefinition> findAllByOrderBySortOrderAsc();

    /** Only active rows participate in qualification — see {@code CustomerMembershipService#computeQualifiedTier}. */
    List<MembershipTierDefinition> findByActiveTrueOrderBySortOrderAsc();
}
