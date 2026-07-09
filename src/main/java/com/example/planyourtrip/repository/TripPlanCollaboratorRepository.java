package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.TripPlanCollaborator;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TripPlanCollaboratorRepository extends JpaRepository<TripPlanCollaborator, Long> {

    List<TripPlanCollaborator> findByTripPlanIdOrderByCreatedAtAsc(Long tripPlanId);

    Optional<TripPlanCollaborator> findByTripPlanIdAndUserId(Long tripPlanId, Long userId);

    Optional<TripPlanCollaborator> findByIdAndTripPlanId(Long id, Long tripPlanId);

    boolean existsByTripPlanIdAndUserId(Long tripPlanId, Long userId);

    List<TripPlanCollaborator> findByUserIdAndActiveTrueOrderByCreatedAtDesc(Long userId);

    void deleteByTripPlanId(Long tripPlanId);
}
