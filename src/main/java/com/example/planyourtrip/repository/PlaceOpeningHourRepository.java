package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.PlaceOpeningHour;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface PlaceOpeningHourRepository extends JpaRepository<PlaceOpeningHour, Long> {

    List<PlaceOpeningHour> findAllByPlaceId(Long placeId);

    @Modifying
    @Query("DELETE FROM PlaceOpeningHour h WHERE h.place.id = :placeId")
    void deleteAllByPlaceId(@Param("placeId") Long placeId);
}
