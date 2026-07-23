package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.SavedCollectionPlace;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface SavedCollectionPlaceRepository extends JpaRepository<SavedCollectionPlace, Long> {

    List<SavedCollectionPlace> findByCollectionIdOrderByPositionAsc(Long collectionId);

    Optional<SavedCollectionPlace> findByCollectionIdAndPlaceId(Long collectionId, Long placeId);

    boolean existsByCollectionIdAndPlaceId(Long collectionId, Long placeId);

    long countByCollectionId(Long collectionId);

    /** Highest existing position in a collection, or null when empty (for next-position assignment). */
    @Query("select max(p.position) from SavedCollectionPlace p where p.collection.id = :collectionId")
    Integer findMaxPositionByCollectionId(@Param("collectionId") Long collectionId);
}
