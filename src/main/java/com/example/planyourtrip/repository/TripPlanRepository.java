package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.TripPlan;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TripPlanRepository extends JpaRepository<TripPlan, Long> {

    List<TripPlan> findByUserIdOrderByUpdatedAtDesc(Long userId);

    Optional<TripPlan> findByIdAndUserId(Long id, Long userId);
}
