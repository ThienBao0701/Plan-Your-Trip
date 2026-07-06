package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.HotelDetail;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface HotelDetailRepository extends JpaRepository<HotelDetail, Long> {
    Optional<HotelDetail> findByPlaceId(Long placeId);
    boolean existsByPlaceId(Long placeId);
}
