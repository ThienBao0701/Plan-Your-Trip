package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.RoomInventory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface RoomInventoryRepository extends JpaRepository<RoomInventory, Long> {

    Optional<RoomInventory> findByHotelRoomIdAndInventoryDate(Long roomId, LocalDate date);

    boolean existsByHotelRoomIdAndInventoryDate(Long roomId, LocalDate date);

    List<RoomInventory> findByHotelRoomIdOrderByInventoryDateAsc(Long roomId);

    @Query("SELECT ri FROM RoomInventory ri WHERE ri.hotelRoom.id = :roomId " +
           "AND ri.inventoryDate BETWEEN :from AND :to " +
           "ORDER BY ri.inventoryDate ASC")
    List<RoomInventory> findBetweenDates(@Param("roomId") Long roomId,
                                          @Param("from") LocalDate from,
                                          @Param("to") LocalDate to);

    long countByHotelRoomId(Long roomId);

    @Query("SELECT count(ri) FROM RoomInventory ri " +
           "WHERE ri.hotelRoom.id = :roomId " +
           "AND ri.inventoryDate >= :checkIn " +
           "AND ri.inventoryDate < :checkOut " +
           "AND ri.availableInventory > 0 " +
           "AND ri.stopSell = false")
    long countAvailableNights(@Param("roomId") Long roomId,
                               @Param("checkIn") LocalDate checkIn,
                               @Param("checkOut") LocalDate checkOut);
}
