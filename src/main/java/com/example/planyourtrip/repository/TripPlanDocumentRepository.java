package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.TripPlanDocument;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TripPlanDocumentRepository extends JpaRepository<TripPlanDocument, Long> {

    List<TripPlanDocument> findByTripPlanIdOrderByPinnedDescCreatedAtDesc(Long tripPlanId);

    void deleteByTripPlanId(Long tripPlanId);
}
