package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.HotelService;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface HotelServiceRepository extends JpaRepository<HotelService, Long> {

    List<HotelService> findAllByHotelDetailId(Long hotelDetailId);

    boolean existsByHotelDetailId(Long hotelDetailId);

    @Modifying
    @Query("DELETE FROM HotelService s WHERE s.hotelDetail.id = :hotelDetailId")
    void deleteAllByHotelDetailId(@Param("hotelDetailId") Long hotelDetailId);
}
