package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.TripPlanDay;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TripPlanDayRepository extends JpaRepository<TripPlanDay, Long> {

    List<TripPlanDay> findByTripPlanIdOrderByDayNumberAsc(Long tripPlanId);

    boolean existsByTripPlanIdAndDayNumber(Long tripPlanId, int dayNumber);

    long countByTripPlanId(Long tripPlanId);

    void deleteByTripPlanId(Long tripPlanId);
}
