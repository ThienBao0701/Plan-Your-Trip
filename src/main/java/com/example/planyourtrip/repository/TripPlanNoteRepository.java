package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.TripPlanNote;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TripPlanNoteRepository extends JpaRepository<TripPlanNote, Long> {

    List<TripPlanNote> findByTripPlanIdOrderByPinnedDescUpdatedAtDesc(Long tripPlanId);

    void deleteByTripPlanId(Long tripPlanId);
}
