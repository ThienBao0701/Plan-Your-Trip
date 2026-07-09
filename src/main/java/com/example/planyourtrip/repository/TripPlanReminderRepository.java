package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.TripPlanReminder;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TripPlanReminderRepository extends JpaRepository<TripPlanReminder, Long> {

    List<TripPlanReminder> findByTripPlanIdOrderByReminderAtAsc(Long tripPlanId);

    void deleteByTripPlanId(Long tripPlanId);
}
