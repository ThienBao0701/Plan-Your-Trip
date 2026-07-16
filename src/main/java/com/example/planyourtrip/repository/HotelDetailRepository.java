package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.HotelDetail;
import com.example.planyourtrip.model.PlaceStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface HotelDetailRepository extends JpaRepository<HotelDetail, Long> {
    Optional<HotelDetail> findByPlaceId(Long placeId);
    boolean existsByPlaceId(Long placeId);

    /** Phase 7.23 — bounded batch load of hotel details for a set of places (identifies which places are hotels). */
    List<HotelDetail> findByPlaceIdIn(Collection<Long> placeIds);

    /** Phase 7.37 — admin platform analytics: count of hotels whose backing place is in the given status (PUBLISHED = live). */
    @Query("SELECT COUNT(hd) FROM HotelDetail hd WHERE hd.place.status = :status")
    long countByPlaceStatus(@Param("status") PlaceStatus status);
}
