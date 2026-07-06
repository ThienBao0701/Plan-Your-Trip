package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.RoomAmenity;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface RoomAmenityRepository extends JpaRepository<RoomAmenity, Long> {

    @EntityGraph(attributePaths = {"amenity"})
    List<RoomAmenity> findAllByRoomId(Long roomId);

    @Modifying
    @Query("DELETE FROM RoomAmenity ra WHERE ra.room.id = :roomId")
    void deleteAllByRoomId(@Param("roomId") Long roomId);
}
