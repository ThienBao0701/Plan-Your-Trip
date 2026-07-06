package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.PartnerProfile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PartnerProfileRepository extends JpaRepository<PartnerProfile, Long> {

    Optional<PartnerProfile> findByUserId(Long userId);

    boolean existsByUserId(Long userId);

    List<PartnerProfile> findAllByOrderByCreatedAtDesc();
}
