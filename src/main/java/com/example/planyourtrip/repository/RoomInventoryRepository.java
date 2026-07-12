package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.RoomInventory;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface RoomInventoryRepository extends JpaRepository<RoomInventory, Long> {

    Optional<RoomInventory> findByHotelRoomIdAndInventoryDate(Long roomId, LocalDate date);

    /**
     * Phase 7.28 — pessimistic write lock (SELECT ... FOR UPDATE) over the exact inventory
     * rows a booking is about to check-and-decrement. Acquired in
     * {@code BookingService.create} BEFORE the {@code countNightsWithSufficientInventory}
     * availability check so the check + {@code decrementInventory} become atomic against a
     * concurrent booking for the same room/dates: the loser blocks until the winner commits,
     * then re-evaluates availability under the lock and is rejected (422) instead of
     * overselling. Rows are locked in a deterministic {@code inventoryDate} order so
     * multi-night windows cannot deadlock. {@code ri.hotelRoom.id} resolves to the FK column
     * (no join to {@code hotel_rooms}), so ONLY {@code room_inventory} rows are locked.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT ri FROM RoomInventory ri WHERE ri.hotelRoom.id = :roomId " +
           "AND ri.inventoryDate >= :checkIn AND ri.inventoryDate < :checkOut " +
           "ORDER BY ri.inventoryDate ASC")
    List<RoomInventory> lockForUpdate(@Param("roomId") Long roomId,
                                      @Param("checkIn") LocalDate checkIn,
                                      @Param("checkOut") LocalDate checkOut);

    boolean existsByHotelRoomIdAndInventoryDate(Long roomId, LocalDate date);

    List<RoomInventory> findByHotelRoomIdOrderByInventoryDateAsc(Long roomId);

    @Query("SELECT ri FROM RoomInventory ri WHERE ri.hotelRoom.id = :roomId " +
           "AND ri.inventoryDate BETWEEN :from AND :to " +
           "ORDER BY ri.inventoryDate ASC")
    List<RoomInventory> findBetweenDates(@Param("roomId") Long roomId,
                                          @Param("from") LocalDate from,
                                          @Param("to") LocalDate to);

    long countByHotelRoomId(Long roomId);

    @Query("SELECT ri FROM RoomInventory ri WHERE ri.hotelRoom.id IN :roomIds " +
           "AND ri.inventoryDate BETWEEN :from AND :to")
    List<RoomInventory> findByHotelRoomIdInAndInventoryDateBetween(@Param("roomIds") List<Long> roomIds,
                                                                    @Param("from") LocalDate from,
                                                                    @Param("to") LocalDate to);

    @Query("SELECT count(ri) FROM RoomInventory ri " +
           "WHERE ri.hotelRoom.id = :roomId " +
           "AND ri.inventoryDate >= :checkIn " +
           "AND ri.inventoryDate < :checkOut " +
           "AND ri.availableInventory > 0 " +
           "AND ri.stopSell = false")
    long countAvailableNights(@Param("roomId") Long roomId,
                               @Param("checkIn") LocalDate checkIn,
                               @Param("checkOut") LocalDate checkOut);

    @Query("SELECT count(ri) FROM RoomInventory ri " +
           "WHERE ri.hotelRoom.id = :roomId " +
           "AND ri.inventoryDate >= :checkIn " +
           "AND ri.inventoryDate < :checkOut " +
           "AND ri.availableInventory >= :qty " +
           "AND ri.stopSell = false")
    long countNightsWithSufficientInventory(@Param("roomId") Long roomId,
                                             @Param("checkIn") LocalDate checkIn,
                                             @Param("checkOut") LocalDate checkOut,
                                             @Param("qty") int qty);

    @Modifying
    @Query("UPDATE RoomInventory ri " +
           "SET ri.availableInventory = ri.availableInventory - :qty, " +
           "    ri.soldInventory = ri.soldInventory + :qty " +
           "WHERE ri.hotelRoom.id = :roomId " +
           "AND ri.inventoryDate >= :checkIn AND ri.inventoryDate < :checkOut")
    int decrementInventory(@Param("roomId") Long roomId,
                            @Param("checkIn") LocalDate checkIn,
                            @Param("checkOut") LocalDate checkOut,
                            @Param("qty") int qty);

    @Modifying
    @Query("UPDATE RoomInventory ri " +
           "SET ri.availableInventory = ri.availableInventory + :qty, " +
           "    ri.soldInventory = ri.soldInventory - :qty " +
           "WHERE ri.hotelRoom.id = :roomId " +
           "AND ri.inventoryDate >= :checkIn AND ri.inventoryDate < :checkOut")
    int restoreInventory(@Param("roomId") Long roomId,
                          @Param("checkIn") LocalDate checkIn,
                          @Param("checkOut") LocalDate checkOut,
                          @Param("qty") int qty);
}
