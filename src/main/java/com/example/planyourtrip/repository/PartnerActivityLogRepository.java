package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.PartnerActivityLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PartnerActivityLogRepository extends JpaRepository<PartnerActivityLog, Long> {

    List<PartnerActivityLog> findByPartnerProfileIdOrderByCreatedAtDesc(Long partnerProfileId);
}
