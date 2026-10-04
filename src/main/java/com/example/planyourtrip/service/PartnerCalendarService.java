package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.RatePlanDto.RatePlanRequest;
import com.example.planyourtrip.dto.RatePlanDto.RatePlanResponse;
import com.example.planyourtrip.dto.RoomInventoryDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.HotelRoom;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.RoomInventory;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.RoomInventoryRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
public class PartnerCalendarService {

    private final HotelRoomRepository rooms;
    private final RoomInventoryRepository inventoryRepo;
    private final RoomInventoryService roomInventoryService;
    private final RatePlanService ratePlanService;
    private final PartnerAccessService partnerAccess;

    public PartnerCalendarService(HotelRoomRepository rooms,
                                   RoomInventoryRepository inventoryRepo,
                                   RoomInventoryService roomInventoryService,
                                   RatePlanService ratePlanService,
                                   PartnerAccessService partnerAccess) {
        this.rooms = rooms;
        this.inventoryRepo = inventoryRepo;
        this.roomInventoryService = roomInventoryService;
        this.ratePlanService = ratePlanService;
        this.partnerAccess = partnerAccess;
    }

    @Transactional(readOnly = true)
    public InventoryCalendarResponse getCalendar(Long userId, Long roomId, LocalDate from, LocalDate to) {
        PartnerProfile profile = partnerAccess.requireRegistrantWorkspace(userId).profile();
        ownedRoomOrThrow(roomId, profile.getId());
        return roomInventoryService.getCalendar(roomId, from, to);
    }

    @Transactional
    public RoomInventoryResponse updateDay(Long userId, Long roomId, LocalDate date, RoomInventoryRequest req) {
        PartnerProfile profile = partnerAccess.requireRegistrantWorkspace(userId).profile();
        ownedRoomOrThrow(roomId, profile.getId());
        // PARTNER authority: soldInventory is booking-derived and not editable here (H-FIX 1B).
        return roomInventoryService.update(roomId, date, req, RoomInventoryService.Authority.PARTNER);
    }

    @Transactional
    public List<RoomInventoryResponse> bulkUpdate(Long userId, Long roomId, BulkInventoryRequest req) {
        PartnerProfile profile = partnerAccess.requireRegistrantWorkspace(userId).profile();
        ownedRoomOrThrow(roomId, profile.getId());
        return roomInventoryService.bulkUpsert(roomId, req, RoomInventoryService.Authority.PARTNER);
    }

    @Transactional
    public RoomInventoryResponse updateStopSell(Long userId, Long roomId, LocalDate date, boolean value) {
        PartnerProfile profile = partnerAccess.requireRegistrantWorkspace(userId).profile();
        ownedRoomOrThrow(roomId, profile.getId());
        RoomInventory inv = inventoryOrThrow(roomId, date);
        inv.setStopSell(value);
        return roomInventoryService.toResponse(inventoryRepo.save(inv));
    }

    @Transactional
    public RoomInventoryResponse updateClosedArrival(Long userId, Long roomId, LocalDate date, boolean value) {
        PartnerProfile profile = partnerAccess.requireRegistrantWorkspace(userId).profile();
        ownedRoomOrThrow(roomId, profile.getId());
        RoomInventory inv = inventoryOrThrow(roomId, date);
        inv.setClosedArrival(value);
        return roomInventoryService.toResponse(inventoryRepo.save(inv));
    }

    @Transactional
    public RoomInventoryResponse updateClosedDeparture(Long userId, Long roomId, LocalDate date, boolean value) {
        PartnerProfile profile = partnerAccess.requireRegistrantWorkspace(userId).profile();
        ownedRoomOrThrow(roomId, profile.getId());
        RoomInventory inv = inventoryOrThrow(roomId, date);
        inv.setClosedDeparture(value);
        return roomInventoryService.toResponse(inventoryRepo.save(inv));
    }

    @Transactional
    public RatePlanResponse updateDailyPrice(Long userId, Long roomId, RatePlanRequest req) {
        PartnerProfile profile = partnerAccess.requireRegistrantWorkspace(userId).profile();
        ownedRoomOrThrow(roomId, profile.getId());
        return ratePlanService.create(roomId, req);
    }

    @Transactional(readOnly = true)
    public List<RatePlanResponse> getPrices(Long userId, Long roomId) {
        PartnerProfile profile = partnerAccess.requireRegistrantWorkspace(userId).profile();
        ownedRoomOrThrow(roomId, profile.getId());
        return ratePlanService.getByRoom(roomId);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private HotelRoom ownedRoomOrThrow(Long roomId, Long ownerId) {
        HotelRoom room = rooms.findById(roomId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Room not found: " + roomId));
        PartnerProfile owner = room.getHotelDetail().getPlace().getOwner();
        if (owner == null || !owner.getId().equals(ownerId))
            throw new ApiException(HttpStatus.NOT_FOUND, "Room not found: " + roomId);
        return room;
    }

    private RoomInventory inventoryOrThrow(Long roomId, LocalDate date) {
        return inventoryRepo.findByHotelRoomIdAndInventoryDate(roomId, date)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Inventory not found for room " + roomId + " on " + date));
    }
}
