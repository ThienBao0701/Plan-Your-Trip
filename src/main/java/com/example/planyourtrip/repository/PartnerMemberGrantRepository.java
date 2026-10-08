package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.PartnerMemberGrant;
import com.example.planyourtrip.model.PartnerMembershipStatus;
import com.example.planyourtrip.model.PartnerTeamMember;
import com.example.planyourtrip.model.PartnerTeamRole;
import com.example.planyourtrip.security.rbac.ScopeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

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

    boolean existsByTeamMemberIdAndRoleAndScopeType(Long teamMemberId, PartnerTeamRole role, ScopeType scopeType);

    /**
     * RBAC R3a §19 — the memberships of a company that hold a confirmed {@code OWNER@COMPANY} grant in the
     * given state, with their accounts. Callers filter on {@code enabled} where the rule needs it (LO-1).
     */
    @Query("select m from PartnerMemberGrant g join g.teamMember m join fetch m.user "
        + "where g.partnerProfile.id = :companyId and g.role = :role and g.scopeType = :scopeType "
        + "and m.status = :status and m.pendingOwnerConfirmation = false")
    List<PartnerTeamMember> findMembersHolding(@Param("companyId") Long companyId, @Param("role") PartnerTeamRole role,
                                               @Param("scopeType") ScopeType scopeType,
                                               @Param("status") PartnerMembershipStatus status);
}
