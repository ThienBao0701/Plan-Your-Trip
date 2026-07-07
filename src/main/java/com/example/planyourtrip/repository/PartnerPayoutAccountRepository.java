package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.PartnerPayoutAccount;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PartnerPayoutAccountRepository extends JpaRepository<PartnerPayoutAccount, Long> {

    Optional<PartnerPayoutAccount> findByPartnerProfileId(Long partnerProfileId);

    boolean existsByPartnerProfileId(Long partnerProfileId);
}
