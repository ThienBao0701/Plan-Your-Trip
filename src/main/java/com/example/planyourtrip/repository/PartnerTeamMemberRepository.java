package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.PartnerTeamMember;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PartnerTeamMemberRepository extends JpaRepository<PartnerTeamMember, Long> {

    List<PartnerTeamMember> findByPartnerProfileIdOrderByCreatedAtAsc(Long partnerProfileId);

    Optional<PartnerTeamMember> findByUserIdAndActiveTrue(Long userId);

    boolean existsByPartnerProfileIdAndUserId(Long partnerProfileId, Long userId);
}
