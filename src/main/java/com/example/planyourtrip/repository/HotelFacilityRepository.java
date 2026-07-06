package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.HotelFacility;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface HotelFacilityRepository extends JpaRepository<HotelFacility, Long> {

    List<HotelFacility> findAllByHotelDetailIdOrderBySortOrderAsc(Long hotelDetailId);

    boolean existsByHotelDetailId(Long hotelDetailId);

    @Modifying
    @Query("DELETE FROM HotelFacility f WHERE f.hotelDetail.id = :hotelDetailId")
    void deleteAllByHotelDetailId(@Param("hotelDetailId") Long hotelDetailId);
}
