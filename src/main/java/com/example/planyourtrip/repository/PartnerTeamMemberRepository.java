package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.PartnerMembershipStatus;
import com.example.planyourtrip.model.PartnerTeamMember;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface PartnerTeamMemberRepository extends JpaRepository<PartnerTeamMember, Long> {

    List<PartnerTeamMember> findByPartnerProfileIdOrderByCreatedAtAsc(Long partnerProfileId);

    boolean existsByPartnerProfileIdAndUserId(Long partnerProfileId, Long userId);

    /**
     * The account's live (ACTIVE or SUSPENDED) membership of the company — at most one
     * ({@code uk_partner_team_members_live}). RBAC R4: revoked memberships are history and never returned here;
     * see {@link #findByPartnerProfileIdAndUserIdOrderByIdAsc} for every row.
     */
    @Query("select m from PartnerTeamMember m where m.partnerProfile.id = :companyId and m.user.id = :userId "
        + "and m.revocationKey = 0")
    Optional<PartnerTeamMember> findByPartnerProfileIdAndUserId(@Param("companyId") Long partnerProfileId,
                                                                @Param("userId") Long userId);

    /** RBAC R4 — every membership the account ever held in the company, revoked history included, oldest first. */
    List<PartnerTeamMember> findByPartnerProfileIdAndUserIdOrderByIdAsc(Long partnerProfileId, Long userId);

    /** RBAC R2 — every membership of a user in the given states, in any company. */
    List<PartnerTeamMember> findByUserIdAndStatusIn(Long userId, Collection<PartnerMembershipStatus> statuses);
}
