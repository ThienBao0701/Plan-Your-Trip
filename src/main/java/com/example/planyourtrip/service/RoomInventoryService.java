package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.RoomInventoryDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.HotelRoom;
import com.example.planyourtrip.model.RoomInventory;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.RoomInventoryRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Service
@Transactional(readOnly = true)
public class RoomInventoryService {

    private final RoomInventoryRepository inventoryRepo;
    private final HotelRoomRepository roomRepo;

    public RoomInventoryService(RoomInventoryRepository inventoryRepo,
                                 HotelRoomRepository roomRepo) {
        this.inventoryRepo = inventoryRepo;
        this.roomRepo      = roomRepo;
    }

    public InventoryCalendarResponse getCalendar(Long roomId,
                                                  LocalDate from,
                                                  LocalDate to) {
        HotelRoom room = roomOrThrow(roomId);
        List<RoomInventory> records = (from != null && to != null)
            ? inventoryRepo.findBetweenDates(roomId, from, to)
            : inventoryRepo.findByHotelRoomIdOrderByInventoryDateAsc(roomId);
        return new InventoryCalendarResponse(
            roomId, room.getRoomCode(), room.getRoomName(),
            records.stream().map(this::toResponse).toList()
        );
    }

    @Transactional
    public RoomInventoryResponse create(Long roomId, RoomInventoryRequest req) {
        roomOrThrow(roomId);
        validateCounts(req);
        if (inventoryRepo.existsByHotelRoomIdAndInventoryDate(roomId, req.inventoryDate())) {
            throw new ApiException(HttpStatus.CONFLICT,
                "Inventory already exists for room " + roomId + " on " + req.inventoryDate());
        }
        HotelRoom room = roomOrThrow(roomId);
        RoomInventory inv = new RoomInventory();
        inv.setHotelRoom(room);
        fill(inv, req);
        return toResponse(inventoryRepo.save(inv));
    }

    @Transactional
    public RoomInventoryResponse update(Long roomId, LocalDate date, RoomInventoryRequest req) {
        roomOrThrow(roomId);
        validateCounts(req);
        RoomInventory inv = inventoryRepo.findByHotelRoomIdAndInventoryDate(roomId, date)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Inventory not found for room " + roomId + " on " + date));
        fill(inv, req);
        return toResponse(inventoryRepo.save(inv));
    }

    @Transactional
    public List<RoomInventoryResponse> bulkUpsert(Long roomId, BulkInventoryRequest req) {
        HotelRoom room = roomOrThrow(roomId);
        List<RoomInventoryResponse> results = new ArrayList<>();
        for (RoomInventoryRequest item : req.items()) {
            validateCounts(item);
            RoomInventory inv = inventoryRepo
                .findByHotelRoomIdAndInventoryDate(roomId, item.inventoryDate())
                .orElseGet(() -> {
                    RoomInventory fresh = new RoomInventory();
                    fresh.setHotelRoom(room);
                    return fresh;
                });
            fill(inv, item);
            results.add(toResponse(inventoryRepo.save(inv)));
        }
        return results;
    }

    private void fill(RoomInventory inv, RoomInventoryRequest req) {
        inv.setInventoryDate(req.inventoryDate());
        inv.setTotalInventory(req.totalInventory());
        inv.setAvailableInventory(req.availableInventory());
        inv.setBlockedInventory(req.blockedInventory());
        inv.setSoldInventory(req.soldInventory());
        inv.setMaintenanceInventory(req.maintenanceInventory());
        inv.setStopSell(req.stopSell());
        inv.setClosedArrival(req.closedArrival());
        inv.setClosedDeparture(req.closedDeparture());
    }

    private void validateCounts(RoomInventoryRequest req) {
        int total = req.totalInventory();
        List<String> errors = new ArrayList<>();
        if (req.availableInventory()   > total) errors.add("availableInventory exceeds totalInventory");
        if (req.blockedInventory()     > total) errors.add("blockedInventory exceeds totalInventory");
        if (req.soldInventory()        > total) errors.add("soldInventory exceeds totalInventory");
        if (req.maintenanceInventory() > total) errors.add("maintenanceInventory exceeds totalInventory");
        if (!errors.isEmpty()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, String.join("; ", errors));
        }
    }

    RoomInventoryResponse toResponse(RoomInventory inv) {
        return new RoomInventoryResponse(
            inv.getId(),
            inv.getHotelRoom().getId(),
            inv.getInventoryDate(),
            inv.getTotalInventory(),
            inv.getAvailableInventory(),
            inv.getBlockedInventory(),
            inv.getSoldInventory(),
            inv.getMaintenanceInventory(),
            inv.isStopSell(),
            inv.isClosedArrival(),
            inv.isClosedDeparture(),
            inv.getCreatedAt(),
            inv.getUpdatedAt()
        );
    }

    private HotelRoom roomOrThrow(Long roomId) {
        return roomRepo.findById(roomId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Room not found: " + roomId));
    }
}
