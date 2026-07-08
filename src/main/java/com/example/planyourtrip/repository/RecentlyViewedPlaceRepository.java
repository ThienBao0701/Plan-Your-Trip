package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.RecentlyViewedPlace;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface RecentlyViewedPlaceRepository extends JpaRepository<RecentlyViewedPlace, Long> {

    List<RecentlyViewedPlace> findByUserIdOrderByViewedAtDesc(Long userId);

    Optional<RecentlyViewedPlace> findByUserIdAndPlaceId(Long userId, Long placeId);

    void deleteByUserId(Long userId);
}
