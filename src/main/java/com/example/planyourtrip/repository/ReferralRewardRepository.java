package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.ReferralReward;
import com.example.planyourtrip.model.ReferralRewardStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

/**
 * Phase 7.22 — Referral &amp; Invite Rewards.
 * Lifecycle/audit records for referral relationships. The DB-unique
 * {@code invitee_id} column backstops "a user can only ever be an invitee once".
 */
public interface ReferralRewardRepository extends JpaRepository<ReferralReward, Long> {

    Optional<ReferralReward> findByInviteeId(Long inviteeId);

    Optional<ReferralReward> findByInviteeIdAndStatus(Long inviteeId, ReferralRewardStatus status);

    boolean existsByInviteeId(Long inviteeId);

    List<ReferralReward> findByInviterIdOrderByCreatedAtDescIdDesc(Long inviterId);

    long countByInviterIdAndStatus(Long inviterId, ReferralRewardStatus status);

    List<ReferralReward> findAllByOrderByCreatedAtDescIdDesc();
}
