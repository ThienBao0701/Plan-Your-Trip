package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.PartnerSettings;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PartnerSettingsRepository extends JpaRepository<PartnerSettings, Long> {

    Optional<PartnerSettings> findByPartnerProfileId(Long partnerProfileId);

    boolean existsByPartnerProfileId(Long partnerProfileId);
}
