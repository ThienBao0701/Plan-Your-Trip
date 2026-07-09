package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.TripPlanExpense;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TripPlanExpenseRepository extends JpaRepository<TripPlanExpense, Long> {

    List<TripPlanExpense> findByTripPlanIdOrderByExpenseDateDescCreatedAtDesc(Long tripPlanId);

    void deleteByTripPlanId(Long tripPlanId);
}
