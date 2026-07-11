package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.HotelDetail;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface HotelDetailRepository extends JpaRepository<HotelDetail, Long> {
    Optional<HotelDetail> findByPlaceId(Long placeId);
    boolean existsByPlaceId(Long placeId);

    /** Phase 7.23 — bounded batch load of hotel details for a set of places (identifies which places are hotels). */
    List<HotelDetail> findByPlaceIdIn(Collection<Long> placeIds);
}
