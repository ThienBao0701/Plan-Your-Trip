package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.MembershipTierHistory;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MembershipTierHistoryRepository extends JpaRepository<MembershipTierHistory, Long> {

    List<MembershipTierHistory> findByMembershipIdOrderByEffectiveAtDescIdDesc(Long membershipId);
}
