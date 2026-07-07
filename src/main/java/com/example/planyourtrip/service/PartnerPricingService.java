package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PromotionDto.PricingBreakdownResponse;
import com.example.planyourtrip.dto.RatePlanDto.RatePlanRequest;
import com.example.planyourtrip.dto.RatePlanDto.RatePlanResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.HotelRoom;
import com.example.planyourtrip.model.NotificationType;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.PartnerVerificationStatus;
import com.example.planyourtrip.model.Priority;
import com.example.planyourtrip.model.RatePlan;
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
    private final PricingEngineService pricingEngineService;
    private final NotificationService notificationService;

    public PartnerPricingService(PartnerProfileRepository partnerProfiles,
                                  HotelRoomRepository rooms,
                                  RatePlanRepository ratePlanRepo,
                                  RatePlanService ratePlanService,
                                  PricingEngineService pricingEngineService,
                                  NotificationService notificationService) {
        this.partnerProfiles = partnerProfiles;
        this.rooms = rooms;
        this.ratePlanRepo = ratePlanRepo;
        this.ratePlanService = ratePlanService;
        this.pricingEngineService = pricingEngineService;
        this.notificationService = notificationService;
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
        ownedRoomOrThrow(roomId, profile.getId());
        return pricingEngineService.calculate(roomId, checkIn, checkOut);
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
