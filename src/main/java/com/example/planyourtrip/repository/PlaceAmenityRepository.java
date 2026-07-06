package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.PlaceAmenity;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface PlaceAmenityRepository extends JpaRepository<PlaceAmenity, Long> {

    @EntityGraph(attributePaths = {"amenity"})
    @Query("SELECT pa FROM PlaceAmenity pa WHERE pa.place.id = :placeId")
    List<PlaceAmenity> findAllByPlaceId(@Param("placeId") Long placeId);

    @Modifying
    @Query("DELETE FROM PlaceAmenity pa WHERE pa.place.id = :placeId")
    void deleteAllByPlaceId(@Param("placeId") Long placeId);
}
