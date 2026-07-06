package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.RatePlan;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;

public interface RatePlanRepository extends JpaRepository<RatePlan, Long> {

    List<RatePlan> findByHotelRoomIdOrderByStartDateAsc(Long roomId);

    @Query("SELECT rp FROM RatePlan rp " +
           "WHERE rp.hotelRoom.id = :roomId " +
           "AND rp.active = true " +
           "AND rp.startDate <= :checkIn " +
           "AND rp.endDate >= :lastNight")
    List<RatePlan> findActiveForStay(@Param("roomId") Long roomId,
                                      @Param("checkIn") LocalDate checkIn,
                                      @Param("lastNight") LocalDate lastNight);
}
