package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.*;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PlaceMetadataRepository extends JpaRepository<PlaceMetadata, Long> {

    Optional<PlaceMetadata> findByPlaceId(Long placeId);
    boolean existsByPlaceId(Long placeId);

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
