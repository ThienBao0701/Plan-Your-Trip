package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.*;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface PlaceMetadataRepository extends JpaRepository<PlaceMetadata, Long> {

    Optional<PlaceMetadata> findByPlaceId(Long placeId);
    boolean existsByPlaceId(Long placeId);

    /** Phase 7.23 — bounded batch load of metadata for a set of places (avoids N+1 in the recommender). */
    List<PlaceMetadata> findByPlaceIdIn(Collection<Long> placeIds);

    List<PlaceMetadata> findByRomanticTrue();
    List<PlaceMetadata> findByFamilyFriendlyTrue();
    List<PlaceMetadata> findByKidFriendlyTrue();
    List<PlaceMetadata> findByPetFriendlyTrue();
    List<PlaceMetadata> findByWheelchairFriendlyTrue();
    List<PlaceMetadata> findByPhotographySpotTrue();
    List<PlaceMetadata> findBySunsetSpotTrue();
    List<PlaceMetadata> findBySunriseSpotTrue();
    List<PlaceMetadata> findByEstimatedBudgetLevel(BudgetLevel level);
    List<PlaceMetadata> findByAccessibilityLevel(AccessibilityLevel level);
    List<PlaceMetadata> findByDifficultyLevel(DifficultyLevel level);
    List<PlaceMetadata> findByTravelStylesContaining(TravelStyle style);
    List<PlaceMetadata> findByBestSeasonsContaining(BestSeason season);
}
