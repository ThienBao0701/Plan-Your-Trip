package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.TripPlanItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TripPlanItemRepository extends JpaRepository<TripPlanItem, Long> {

    List<TripPlanItem> findByTripPlanDayIdOrderBySortOrderAsc(Long tripPlanDayId);

    long countByTripPlanDayId(Long tripPlanDayId);

    void deleteByTripPlanDayId(Long tripPlanDayId);

    void deleteByTripPlanDayIdIn(List<Long> tripPlanDayIds);
}
