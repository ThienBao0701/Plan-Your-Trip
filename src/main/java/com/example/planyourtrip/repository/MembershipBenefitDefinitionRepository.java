package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.MembershipBenefitDefinition;
import com.example.planyourtrip.model.MembershipTier;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MembershipBenefitDefinitionRepository extends JpaRepository<MembershipBenefitDefinition, Long> {

    List<MembershipBenefitDefinition> findByTierAndActiveTrueOrderBySortOrderAsc(MembershipTier tier);

    List<MembershipBenefitDefinition> findAllByOrderByTierAscSortOrderAsc();
}
