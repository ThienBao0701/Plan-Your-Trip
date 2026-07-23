package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.UserInterestProfile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

/**
 * Phase 7.48 — repository for the persisted, one-per-user {@link UserInterestProfile}.
 */
public interface UserInterestProfileRepository extends JpaRepository<UserInterestProfile, Long> {

    Optional<UserInterestProfile> findByUserId(Long userId);
}
