package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PromotionDto.PricingBreakdownResponse;
import com.example.planyourtrip.dto.RatePlanDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.HotelRoom;
import com.example.planyourtrip.model.NotificationType;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.PartnerVerificationStatus;
import com.example.planyourtrip.model.Priority;
import com.example.planyourtrip.model.RatePlan;
import com.example.planyourtrip.model.RatePlanOccupancyPrice;
import com.example.planyourtrip.model.RelatedEntityType;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.RatePlanRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
public class PartnerPricingService {

    private final PartnerProfileRepository partnerProfiles;
    private final HotelRoomRepository rooms;
    private final RatePlanRepository ratePlanRepo;
    private final RatePlanService ratePlanService;
    private final RatePlanPricingService ratePlanPricingService;
    private final PricingEngineService pricingEngineService;
    private final NotificationService notificationService;
    private final PartnerActivityLogService activityLogService;

    public PartnerPricingService(PartnerProfileRepository partnerProfiles,
                                  HotelRoomRepository rooms,
                                  RatePlanRepository ratePlanRepo,
                                  RatePlanService ratePlanService,
                                  RatePlanPricingService ratePlanPricingService,
                                  PricingEngineService pricingEngineService,
                                  NotificationService notificationService,
                                  PartnerActivityLogService activityLogService) {
        this.partnerProfiles = partnerProfiles;
        this.rooms = rooms;
        this.ratePlanRepo = ratePlanRepo;
        this.ratePlanService = ratePlanService;
        this.ratePlanPricingService = ratePlanPricingService;
        this.pricingEngineService = pricingEngineService;
        this.notificationService = notificationService;
        this.activityLogService = activityLogService;
    }

    @Transactional(readOnly = true)
    public List<RatePlanResponse> getRatePlans(Long userId, Long roomId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        ownedRoomOrThrow(roomId, profile.getId());
        return ratePlanService.getByRoom(roomId);
    }

    @Transactional
    public RatePlanResponse createRatePlan(Long userId, Long roomId, RatePlanRequest req) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        HotelRoom room = ownedRoomOrThrow(roomId, profile.getId());
        RatePlanResponse res = ratePlanService.create(roomId, req);
        notifyRatePlanUpdated(room);
        return res;
    }

    @Transactional
    public RatePlanResponse updateRatePlan(Long userId, Long ratePlanId, RatePlanRequest req) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        RatePlan plan = ownedRatePlanOrThrow(ratePlanId, profile.getId());
        RatePlanResponse res = ratePlanService.update(ratePlanId, req);
        notifyRatePlanUpdated(plan.getHotelRoom());
        activityLogService.log(profile.getId(), userId, "RATE_PLAN_UPDATED", "RATE_PLAN", ratePlanId,
            "Updated rate plan " + res.rateName() + " for " + plan.getHotelRoom().getRoomName());
        return res;
    }

    @Transactional
    public void deleteRatePlan(Long userId, Long ratePlanId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        RatePlan plan = ownedRatePlanOrThrow(ratePlanId, profile.getId());
        HotelRoom room = plan.getHotelRoom();
        ratePlanService.delete(ratePlanId);
        notifyRatePlanUpdated(room);
    }

    @Transactional(readOnly = true)
    public PricingBreakdownResponse getPricingPreview(Long userId, Long roomId, LocalDate checkIn, LocalDate checkOut) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        HotelRoom room = ownedRoomOrThrow(roomId, profile.getId());
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
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        RatePlan plan = ownedRatePlanOrThrow(ratePlanId, profile.getId());
        RatePlanResponse res = ratePlanService.setActive(ratePlanId, active);
        notifyRatePlanUpdated(plan.getHotelRoom());
        return res;
    }

    @Transactional
    public RatePlanResponse duplicateRatePlan(Long userId, Long ratePlanId, RatePlanDuplicateRequest req) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        RatePlan plan = ownedRatePlanOrThrow(ratePlanId, profile.getId());
        RatePlanResponse res = ratePlanService.duplicate(ratePlanId, req);
        notifyRatePlanUpdated(plan.getHotelRoom());
        return res;
    }

    @Transactional(readOnly = true)
    public List<RatePlanOccupancyPriceResponse> getOccupancyPrices(Long userId, Long ratePlanId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        ownedRatePlanOrThrow(ratePlanId, profile.getId());
        return ratePlanService.getOccupancyPrices(ratePlanId);
    }

    @Transactional
    public RatePlanOccupancyPriceResponse addOccupancyPrice(Long userId, Long ratePlanId, RatePlanOccupancyPriceRequest req) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        ownedRatePlanOrThrow(ratePlanId, profile.getId());
        return ratePlanService.addOccupancyPrice(ratePlanId, req);
    }

    @Transactional
    public RatePlanOccupancyPriceResponse updateOccupancyPrice(Long userId, Long occupancyPriceId, RatePlanOccupancyPriceRequest req) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        ownedOccupancyPriceOrThrow(occupancyPriceId, profile.getId());
        return ratePlanService.updateOccupancyPrice(occupancyPriceId, req);
    }

    @Transactional
    public void deleteOccupancyPrice(Long userId, Long occupancyPriceId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        ownedOccupancyPriceOrThrow(occupancyPriceId, profile.getId());
        ratePlanService.deleteOccupancyPrice(occupancyPriceId);
    }

    @Transactional(readOnly = true)
    public RatePlanPricingBreakdownResponse previewRatePlan(Long userId, Long ratePlanId, LocalDate checkIn,
                                                            LocalDate checkOut, int adults, int children, int extraBeds) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        ownedRatePlanOrThrow(ratePlanId, profile.getId());
        return ratePlanPricingService.previewByPlan(ratePlanId, checkIn, checkOut, adults, children, extraBeds);
    }

    @Transactional(readOnly = true)
    public RatePlanEligibilityResponse validateRatePlan(Long userId, Long ratePlanId, RatePlanEligibilityRequest req) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        ownedRatePlanOrThrow(ratePlanId, profile.getId());
        return ratePlanPricingService.validate(ratePlanId, req);
    }

    private RatePlan ownedOccupancyPriceOrThrow(Long occupancyPriceId, Long ownerId) {
        RatePlanOccupancyPrice op = ratePlanService.occupancyPriceOrThrow(occupancyPriceId);
        return ownedRatePlanOrThrow(op.getRatePlan().getId(), ownerId);
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

    private RatePlan ownedRatePlanOrThrow(Long ratePlanId, Long ownerId) {
        RatePlan plan = ratePlanRepo.findById(ratePlanId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Rate plan not found: " + ratePlanId));
        PartnerProfile owner = plan.getHotelRoom().getHotelDetail().getPlace().getOwner();
        if (owner == null || !owner.getId().equals(ownerId))
            throw new ApiException(HttpStatus.NOT_FOUND, "Rate plan not found: " + ratePlanId);
        return plan;
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
