package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.TripPlanPackingItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TripPlanPackingItemRepository extends JpaRepository<TripPlanPackingItem, Long> {

    List<TripPlanPackingItem> findByTripPlanIdOrderByCheckedAscSortOrderAsc(Long tripPlanId);

    long countByTripPlanId(Long tripPlanId);

    void deleteByTripPlanId(Long tripPlanId);
}
