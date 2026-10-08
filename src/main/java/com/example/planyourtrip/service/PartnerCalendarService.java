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
import com.example.planyourtrip.security.rbac.PartnerAccessContext;
import com.example.planyourtrip.security.rbac.PartnerPermission;
import com.example.planyourtrip.security.rbac.ResourceType;
import com.example.planyourtrip.security.rbac.ScopePath;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.EnumSet;
import java.util.List;

import static com.example.planyourtrip.security.rbac.PartnerPermission.INVENTORY_ALLOTMENT_EDIT;
import static com.example.planyourtrip.security.rbac.PartnerPermission.INVENTORY_RESTRICTION_EDIT;
import static com.example.planyourtrip.security.rbac.PartnerPermission.INVENTORY_VIEW;
import static com.example.planyourtrip.security.rbac.PartnerPermission.RATE_EDIT;
import static com.example.planyourtrip.security.rbac.PartnerPermission.RATE_VIEW;

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
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        partnerAccess.requireResource(access, INVENTORY_VIEW, ResourceType.CALENDAR, roomId, notFound(roomId));
        return roomInventoryService.getCalendar(roomId, from, to);
    }

    @Transactional
    public RoomInventoryResponse updateDay(Long userId, Long roomId, LocalDate date, RoomInventoryRequest req) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        // B9 — counts need P27, restriction flags P28; decided for the whole write before anything is saved
        authorizeCalendarWrite(access, roomId, PartnerFieldDiff.inventoryDay(
            inventoryRepo.findByHotelRoomIdAndInventoryDate(roomId, date).orElse(null), req));
        // PARTNER authority: soldInventory is booking-derived and not editable here (H-FIX 1B).
        return roomInventoryService.update(roomId, date, req, RoomInventoryService.Authority.PARTNER);
    }

    @Transactional
    public List<RoomInventoryResponse> bulkUpdate(Long userId, Long roomId, BulkInventoryRequest req) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        // B9 — the union of what every day changes; one refusal refuses the whole bulk write
        EnumSet<PartnerPermission> needed = EnumSet.noneOf(PartnerPermission.class);
        for (RoomInventoryRequest item : req.items()) {
            needed.addAll(PartnerFieldDiff.inventoryDay(item.inventoryDate() == null ? null
                : inventoryRepo.findByHotelRoomIdAndInventoryDate(roomId, item.inventoryDate()).orElse(null), item));
        }
        authorizeCalendarWrite(access, roomId, needed);
        return roomInventoryService.bulkUpsert(roomId, req, RoomInventoryService.Authority.PARTNER);
    }

    @Transactional
    public RoomInventoryResponse updateStopSell(Long userId, Long roomId, LocalDate date, boolean value) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        partnerAccess.requireResource(access, INVENTORY_RESTRICTION_EDIT, ResourceType.CALENDAR, roomId, notFound(roomId));
        RoomInventory inv = inventoryOrThrow(roomId, date);
        inv.setStopSell(value);
        return roomInventoryService.toResponse(inventoryRepo.save(inv));
    }

    @Transactional
    public RoomInventoryResponse updateClosedArrival(Long userId, Long roomId, LocalDate date, boolean value) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        partnerAccess.requireResource(access, INVENTORY_RESTRICTION_EDIT, ResourceType.CALENDAR, roomId, notFound(roomId));
        RoomInventory inv = inventoryOrThrow(roomId, date);
        inv.setClosedArrival(value);
        return roomInventoryService.toResponse(inventoryRepo.save(inv));
    }

    @Transactional
    public RoomInventoryResponse updateClosedDeparture(Long userId, Long roomId, LocalDate date, boolean value) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        partnerAccess.requireResource(access, INVENTORY_RESTRICTION_EDIT, ResourceType.CALENDAR, roomId, notFound(roomId));
        RoomInventory inv = inventoryOrThrow(roomId, date);
        inv.setClosedDeparture(value);
        return roomInventoryService.toResponse(inventoryRepo.save(inv));
    }

    @Transactional
    public RatePlanResponse updateDailyPrice(Long userId, Long roomId, RatePlanRequest req) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        partnerAccess.requireResourceVia(access, RATE_EDIT, ResourceType.RATE_PLAN, ResourceType.ROOM, roomId, notFound(roomId));
        return ratePlanService.create(roomId, req);
    }

    @Transactional(readOnly = true)
    public List<RatePlanResponse> getPrices(Long userId, Long roomId) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        partnerAccess.requireResourceVia(access, RATE_VIEW, ResourceType.RATE_PLAN, ResourceType.ROOM, roomId, notFound(roomId));
        return ratePlanService.getByRoom(roomId);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    /**
     * B9 — a calendar write needs every permission its changes need; a write that changes nothing needs P27 or
     * P28. The room is resolved from the database (UNIT scope); a room the caller cannot view is 404.
     */
    private void authorizeCalendarWrite(PartnerAccessContext access, Long roomId, java.util.Set<PartnerPermission> needed) {
        ScopePath target = partnerAccess.target(ResourceType.CALENDAR, roomId);
        partnerAccess.requireAny(access, List.of(INVENTORY_ALLOTMENT_EDIT, INVENTORY_RESTRICTION_EDIT),
            ResourceType.CALENDAR, target, notFound(roomId));
        if (!needed.isEmpty()) partnerAccess.requireAll(access, needed, ResourceType.CALENDAR, target, notFound(roomId));
    }

    private static String notFound(Long roomId) {
        return "Room not found: " + roomId;
    }

    private RoomInventory inventoryOrThrow(Long roomId, LocalDate date) {
        return inventoryRepo.findByHotelRoomIdAndInventoryDate(roomId, date)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Inventory not found for room " + roomId + " on " + date));
    }
}
