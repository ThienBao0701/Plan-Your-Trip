package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.PartnerMembershipStatus;
import com.example.planyourtrip.model.PartnerTeamMember;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface PartnerTeamMemberRepository extends JpaRepository<PartnerTeamMember, Long> {

    List<PartnerTeamMember> findByPartnerProfileIdOrderByCreatedAtAsc(Long partnerProfileId);

    Optional<PartnerTeamMember> findByUserIdAndActiveTrue(Long userId);

    boolean existsByPartnerProfileIdAndUserId(Long partnerProfileId, Long userId);

    Optional<PartnerTeamMember> findByPartnerProfileIdAndUserId(Long partnerProfileId, Long userId);

    /** RBAC R2 — every membership of a user in the given states, in any company. */
    List<PartnerTeamMember> findByUserIdAndStatusIn(Long userId, Collection<PartnerMembershipStatus> statuses);
}
