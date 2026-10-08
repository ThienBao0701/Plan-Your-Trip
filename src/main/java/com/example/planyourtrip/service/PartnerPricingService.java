package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PromotionDto.PricingBreakdownResponse;
import com.example.planyourtrip.dto.RatePlanDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.HotelRoom;
import com.example.planyourtrip.model.NotificationType;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.Priority;
import com.example.planyourtrip.model.RatePlan;
import com.example.planyourtrip.model.RatePlanOccupancyPrice;
import com.example.planyourtrip.model.RelatedEntityType;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.RatePlanRepository;
import com.example.planyourtrip.security.rbac.PartnerAccessContext;
import com.example.planyourtrip.security.rbac.PartnerPermission;
import com.example.planyourtrip.security.rbac.ResourceType;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

import static com.example.planyourtrip.security.rbac.PartnerPermission.RATE_ACTIVATE;
import static com.example.planyourtrip.security.rbac.PartnerPermission.RATE_EDIT;
import static com.example.planyourtrip.security.rbac.PartnerPermission.RATE_VIEW;

@Service
public class PartnerPricingService {

    private final HotelRoomRepository rooms;
    private final RatePlanRepository ratePlanRepo;
    private final RatePlanService ratePlanService;
    private final RatePlanPricingService ratePlanPricingService;
    private final PricingEngineService pricingEngineService;
    private final NotificationService notificationService;
    private final PartnerActivityLogService activityLogService;
    private final PartnerAccessService partnerAccess;

    public PartnerPricingService(HotelRoomRepository rooms,
                                  RatePlanRepository ratePlanRepo,
                                  RatePlanService ratePlanService,
                                  RatePlanPricingService ratePlanPricingService,
                                  PricingEngineService pricingEngineService,
                                  NotificationService notificationService,
                                  PartnerActivityLogService activityLogService,
                                  PartnerAccessService partnerAccess) {
        this.rooms = rooms;
        this.ratePlanRepo = ratePlanRepo;
        this.ratePlanService = ratePlanService;
        this.ratePlanPricingService = ratePlanPricingService;
        this.pricingEngineService = pricingEngineService;
        this.notificationService = notificationService;
        this.activityLogService = activityLogService;
        this.partnerAccess = partnerAccess;
    }

    @Transactional(readOnly = true)
    public List<RatePlanResponse> getRatePlans(Long userId, Long roomId) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        authorizedRoom(access, RATE_VIEW, roomId);
        return ratePlanService.getByRoom(roomId);
    }

    @Transactional
    public RatePlanResponse createRatePlan(Long userId, Long roomId, RatePlanRequest req) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        HotelRoom room = authorizedRoom(access, RATE_EDIT, roomId);
        RatePlanResponse res = ratePlanService.create(roomId, req);
        notifyRatePlanUpdated(room);
        return res;
    }

    @Transactional
    public RatePlanResponse updateRatePlan(Long userId, Long ratePlanId, RatePlanRequest req) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        RatePlan plan = authorizedPlan(access, RATE_EDIT, ratePlanId);
        RatePlanResponse res = ratePlanService.update(ratePlanId, req);
        notifyRatePlanUpdated(plan.getHotelRoom());
        activityLogService.log(access.companyId(), userId, "RATE_PLAN_UPDATED", "RATE_PLAN", ratePlanId,
            "Updated rate plan " + res.rateName() + " for " + plan.getHotelRoom().getRoomName());
        return res;
    }

    @Transactional
    public void deleteRatePlan(Long userId, Long ratePlanId) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        RatePlan plan = authorizedPlan(access, RATE_EDIT, ratePlanId);
        HotelRoom room = plan.getHotelRoom();
        ratePlanService.delete(ratePlanId);
        notifyRatePlanUpdated(room);
    }

    @Transactional(readOnly = true)
    public PricingBreakdownResponse getPricingPreview(Long userId, Long roomId, LocalDate checkIn, LocalDate checkOut) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        HotelRoom room = authorizedRoom(access, RATE_VIEW, roomId);
        // Phase 7.31 — resolve the best eligible plan with the SAME priority-based selection used by
        // checkout (RatePlanPricingService), then feed its resolved stay subtotal into the unchanged
        // promotion-discount stages of the pricing engine, so the partner preview reflects the plan
        // and price a customer would actually be charged (default single-occupancy quote). When no
        // plan is eligible the resolution is empty and pricing falls back to the base room price —
        // identical to the engine's own "no eligible plan" branch. DTO shape is unchanged.
        return ratePlanPricingService.resolveForBooking(room, null, checkIn, checkOut, 1, 0, 0)
            .map(r -> pricingEngineService.calculate(roomId, checkIn, checkOut,
                r.staySubtotal(), r.plan().getRateName()))
            .orElseGet(() -> pricingEngineService.calculate(roomId, checkIn, checkOut, null, null));
    }

    // ── Phase 7.29 — advanced rate-plan management (owner-scoped) ──────────────

    @Transactional
    public RatePlanResponse activateRatePlan(Long userId, Long ratePlanId, boolean active) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        RatePlan plan = authorizedPlan(access, RATE_ACTIVATE, ratePlanId);
        RatePlanResponse res = ratePlanService.setActive(ratePlanId, active);
        notifyRatePlanUpdated(plan.getHotelRoom());
        return res;
    }

    @Transactional
    public RatePlanResponse duplicateRatePlan(Long userId, Long ratePlanId, RatePlanDuplicateRequest req) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        RatePlan plan = authorizedPlan(access, RATE_EDIT, ratePlanId);
        RatePlanResponse res = ratePlanService.duplicate(ratePlanId, req);
        notifyRatePlanUpdated(plan.getHotelRoom());
        return res;
    }

    @Transactional(readOnly = true)
    public List<RatePlanOccupancyPriceResponse> getOccupancyPrices(Long userId, Long ratePlanId) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        authorizedPlan(access, RATE_VIEW, ratePlanId);
        return ratePlanService.getOccupancyPrices(ratePlanId);
    }

    @Transactional
    public RatePlanOccupancyPriceResponse addOccupancyPrice(Long userId, Long ratePlanId, RatePlanOccupancyPriceRequest req) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        authorizedPlan(access, RATE_EDIT, ratePlanId);
        return ratePlanService.addOccupancyPrice(ratePlanId, req);
    }

    @Transactional
    public RatePlanOccupancyPriceResponse updateOccupancyPrice(Long userId, Long occupancyPriceId, RatePlanOccupancyPriceRequest req) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        authorizedOccupancyPrice(access, RATE_EDIT, occupancyPriceId);
        return ratePlanService.updateOccupancyPrice(occupancyPriceId, req);
    }

    @Transactional
    public void deleteOccupancyPrice(Long userId, Long occupancyPriceId) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        authorizedOccupancyPrice(access, RATE_EDIT, occupancyPriceId);
        ratePlanService.deleteOccupancyPrice(occupancyPriceId);
    }

    @Transactional(readOnly = true)
    public RatePlanPricingBreakdownResponse previewRatePlan(Long userId, Long ratePlanId, LocalDate checkIn,
                                                            LocalDate checkOut, int adults, int children, int extraBeds) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        authorizedPlan(access, RATE_VIEW, ratePlanId);
        return ratePlanPricingService.previewByPlan(ratePlanId, checkIn, checkOut, adults, children, extraBeds);
    }

    @Transactional(readOnly = true)
    public RatePlanEligibilityResponse validateRatePlan(Long userId, Long ratePlanId, RatePlanEligibilityRequest req) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        authorizedPlan(access, RATE_VIEW, ratePlanId);
        return ratePlanPricingService.validate(ratePlanId, req);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    /** RBAC R3b — §25.1 "RESOURCE (rate plan, via room)": resolved through the room, decided with P29's type. */
    private HotelRoom authorizedRoom(PartnerAccessContext access, PartnerPermission permission, Long roomId) {
        partnerAccess.requireResourceVia(access, permission, ResourceType.RATE_PLAN, ResourceType.ROOM, roomId,
            "Room not found: " + roomId);
        return rooms.findById(roomId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Room not found: " + roomId));
    }

    /** RBAC R3b — a rate plan lives at the UNIT of its room (§11.2). */
    private RatePlan authorizedPlan(PartnerAccessContext access, PartnerPermission permission, Long ratePlanId) {
        partnerAccess.requireResource(access, permission, ResourceType.RATE_PLAN, ratePlanId,
            "Rate plan not found: " + ratePlanId);
        return ratePlanRepo.findById(ratePlanId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Rate plan not found: " + ratePlanId));
    }

    /** RBAC R3b — an occupancy price lives where its rate plan's room lives (§11.2). */
    private void authorizedOccupancyPrice(PartnerAccessContext access, PartnerPermission permission, Long occupancyPriceId) {
        partnerAccess.requireResource(access, permission, ResourceType.OCCUPANCY_PRICE, occupancyPriceId,
            "Occupancy price not found: " + occupancyPriceId);
    }

    private void notifyRatePlanUpdated(HotelRoom room) {
        PartnerProfile owner = room.getHotelDetail().getPlace().getOwner();
        if (owner == null) return;
        notificationService.create(owner.getUser().getId(), NotificationType.PARTNER, Priority.NORMAL,
            "Rate plan updated",
            room.getRoomName() + " rate plan has been updated.",
            RelatedEntityType.ROOM, room.getId());
    }
}
