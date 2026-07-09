package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.TripPlanBudget;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface TripPlanBudgetRepository extends JpaRepository<TripPlanBudget, Long> {

    Optional<TripPlanBudget> findByTripPlanId(Long tripPlanId);

    void deleteByTripPlanId(Long tripPlanId);
}
