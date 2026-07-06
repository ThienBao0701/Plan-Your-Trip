package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.PlaceTag;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface PlaceTagRepository extends JpaRepository<PlaceTag, Long> {

    List<PlaceTag> findAllByPlaceId(Long placeId);

    @Modifying
    @Query("DELETE FROM PlaceTag t WHERE t.place.id = :placeId")
    void deleteAllByPlaceId(@Param("placeId") Long placeId);
}
