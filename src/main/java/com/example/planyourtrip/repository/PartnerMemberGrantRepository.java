package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.PartnerMemberGrant;
import com.example.planyourtrip.model.PartnerTeamRole;
import com.example.planyourtrip.security.rbac.ScopeType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PartnerMemberGrantRepository extends JpaRepository<PartnerMemberGrant, Long> {

    List<PartnerMemberGrant> findByTeamMemberIdOrderByIdAsc(Long teamMemberId);

    Optional<PartnerMemberGrant> findByTeamMemberIdAndRoleAndScopeTypeAndScopeId(
        Long teamMemberId, PartnerTeamRole role, ScopeType scopeType, Long scopeId);

    List<PartnerMemberGrant> findByTeamMemberIdAndScopeType(Long teamMemberId, ScopeType scopeType);

    /** Grants that reference a property directly or through one of its room types (§16 PA-4). */
    List<PartnerMemberGrant> findByPropertyId(Long propertyId);

    void deleteByTeamMemberId(Long teamMemberId);
}
