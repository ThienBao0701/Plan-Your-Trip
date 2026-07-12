package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.RatePlanOccupancyPrice;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface RatePlanOccupancyPriceRepository extends JpaRepository<RatePlanOccupancyPrice, Long> {

    List<RatePlanOccupancyPrice> findByRatePlanIdOrderByAdultsAscChildrenAsc(Long ratePlanId);

    Optional<RatePlanOccupancyPrice> findByRatePlanIdAndAdultsAndChildren(Long ratePlanId, int adults, int children);

    boolean existsByRatePlanIdAndAdultsAndChildren(Long ratePlanId, int adults, int children);

    void deleteByRatePlanId(Long ratePlanId);
}
