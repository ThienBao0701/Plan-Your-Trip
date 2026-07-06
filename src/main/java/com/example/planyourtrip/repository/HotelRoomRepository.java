package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.HotelRoom;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface HotelRoomRepository extends JpaRepository<HotelRoom, Long> {

    List<HotelRoom> findAllByHotelDetailId(Long hotelDetailId);

    List<HotelRoom> findAllByHotelDetailIdAndActiveTrue(Long hotelDetailId);

    boolean existsByHotelDetailIdAndRoomCode(Long hotelDetailId, String roomCode);

    boolean existsByHotelDetailIdAndRoomCodeAndIdNot(Long hotelDetailId, String roomCode, Long id);
}
