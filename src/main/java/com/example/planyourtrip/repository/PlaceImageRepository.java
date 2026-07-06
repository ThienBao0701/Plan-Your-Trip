package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.PlaceImage;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PlaceImageRepository extends JpaRepository<PlaceImage, Long> {
    List<PlaceImage> findAllByPlaceIdOrderBySortOrderAsc(Long placeId);
    boolean existsByPlaceId(Long placeId);
}
