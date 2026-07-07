package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.RatePlanDto.RatePlanRequest;
import com.example.planyourtrip.dto.RatePlanDto.RatePlanResponse;
import com.example.planyourtrip.dto.RoomInventoryDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.HotelRoom;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.PartnerVerificationStatus;
import com.example.planyourtrip.model.RoomInventory;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.RoomInventoryRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
public class PartnerCalendarService {

    private final PartnerProfileRepository partnerProfiles;
    private final HotelRoomRepository rooms;
    private final RoomInventoryRepository inventoryRepo;
    private final RoomInventoryService roomInventoryService;
    private final RatePlanService ratePlanService;

    public PartnerCalendarService(PartnerProfileRepository partnerProfiles,
                                   HotelRoomRepository rooms,
                                   RoomInventoryRepository inventoryRepo,
                                   RoomInventoryService roomInventoryService,
                                   RatePlanService ratePlanService) {
        this.partnerProfiles = partnerProfiles;
        this.rooms = rooms;
        this.inventoryRepo = inventoryRepo;
        this.roomInventoryService = roomInventoryService;
        this.ratePlanService = ratePlanService;
    }

    @Transactional(readOnly = true)
    public InventoryCalendarResponse getCalendar(Long userId, Long roomId, LocalDate from, LocalDate to) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        ownedRoomOrThrow(roomId, profile.getId());
        return roomInventoryService.getCalendar(roomId, from, to);
    }

    @Transactional
    public RoomInventoryResponse updateDay(Long userId, Long roomId, LocalDate date, RoomInventoryRequest req) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        ownedRoomOrThrow(roomId, profile.getId());
        return roomInventoryService.update(roomId, date, req);
    }

    @Transactional
    public List<RoomInventoryResponse> bulkUpdate(Long userId, Long roomId, BulkInventoryRequest req) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        ownedRoomOrThrow(roomId, profile.getId());
        return roomInventoryService.bulkUpsert(roomId, req);
    }

    @Transactional
    public RoomInventoryResponse updateStopSell(Long userId, Long roomId, LocalDate date, boolean value) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        ownedRoomOrThrow(roomId, profile.getId());
        RoomInventory inv = inventoryOrThrow(roomId, date);
        inv.setStopSell(value);
        return roomInventoryService.toResponse(inventoryRepo.save(inv));
    }

    @Transactional
    public RoomInventoryResponse updateClosedArrival(Long userId, Long roomId, LocalDate date, boolean value) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        ownedRoomOrThrow(roomId, profile.getId());
        RoomInventory inv = inventoryOrThrow(roomId, date);
        inv.setClosedArrival(value);
        return roomInventoryService.toResponse(inventoryRepo.save(inv));
    }

    @Transactional
    public RoomInventoryResponse updateClosedDeparture(Long userId, Long roomId, LocalDate date, boolean value) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        ownedRoomOrThrow(roomId, profile.getId());
        RoomInventory inv = inventoryOrThrow(roomId, date);
        inv.setClosedDeparture(value);
        return roomInventoryService.toResponse(inventoryRepo.save(inv));
    }

    @Transactional
    public RatePlanResponse updateDailyPrice(Long userId, Long roomId, RatePlanRequest req) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        ownedRoomOrThrow(roomId, profile.getId());
        return ratePlanService.create(roomId, req);
    }

    @Transactional(readOnly = true)
    public List<RatePlanResponse> getPrices(Long userId, Long roomId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        ownedRoomOrThrow(roomId, profile.getId());
        return ratePlanService.getByRoom(roomId);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private PartnerProfile myApprovedProfileOrThrow(Long userId) {
        PartnerProfile profile = partnerProfiles.findByUserId(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Partner profile not found"));
        if (profile.getVerificationStatus() != PartnerVerificationStatus.APPROVED)
            throw new ApiException(HttpStatus.FORBIDDEN, "Partner profile is not approved");
        return profile;
    }

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
