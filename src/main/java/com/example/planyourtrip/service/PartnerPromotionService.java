package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PromotionDto.PromotionRequest;
import com.example.planyourtrip.dto.PromotionDto.PromotionResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.repository.PromotionRepository;
import com.example.planyourtrip.security.rbac.PartnerAccessContext;
import com.example.planyourtrip.security.rbac.PartnerPermission;
import com.example.planyourtrip.security.rbac.ResourceType;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Objects;

import static com.example.planyourtrip.security.rbac.PartnerPermission.PROMOTION_MANAGE;
import static com.example.planyourtrip.security.rbac.PartnerPermission.PROMOTION_VIEW;

@Service
public class PartnerPromotionService {

    private final PlaceRepository places;
    private final HotelDetailRepository hotelDetails;
    private final HotelRoomRepository rooms;
    private final PromotionRepository promotionRepo;
    private final PromotionService promotionService;
    private final NotificationService notificationService;
    private final PartnerActivityLogService activityLogService;
    private final PartnerAccessService partnerAccess;

    public PartnerPromotionService(PlaceRepository places,
                                    HotelDetailRepository hotelDetails,
                                    HotelRoomRepository rooms,
                                    PromotionRepository promotionRepo,
                                    PromotionService promotionService,
                                    NotificationService notificationService,
                                    PartnerActivityLogService activityLogService,
                                    PartnerAccessService partnerAccess) {
        this.places = places;
        this.hotelDetails = hotelDetails;
        this.rooms = rooms;
        this.promotionRepo = promotionRepo;
        this.promotionService = promotionService;
        this.notificationService = notificationService;
        this.activityLogService = activityLogService;
        this.partnerAccess = partnerAccess;
    }

    @Transactional(readOnly = true)
    public List<PromotionResponse> getMyPromotions(Long userId) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        // §4.5 COLLECTION: promotions targeting the properties (or their rooms) the caller may view
        List<Long> permitted = partnerAccess.propertyIds(access, partnerAccess.requireCollection(access, PROMOTION_VIEW));
        List<Long> hotelDetailIds = hotelDetailIdsOf(permitted);
        List<Long> roomIds = ownedRoomIds(hotelDetailIds);
        if (hotelDetailIds.isEmpty() && roomIds.isEmpty()) return List.of();

        return promotionRepo.findByOwnedTargets(
                PromotionTargetType.HOTEL, hotelDetailIds.isEmpty() ? List.of(-1L) : hotelDetailIds,
                PromotionTargetType.ROOM, roomIds.isEmpty() ? List.of(-1L) : roomIds)
            .stream().map(promotionService::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public PromotionResponse getPromotion(Long userId, Long id) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        Promotion promo = authorizedPromotion(access, PROMOTION_VIEW, id);
        return promotionService.toResponse(promo);
    }

    @Transactional
    public PromotionResponse createPromotion(Long userId, PromotionRequest req) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        PartnerProfile profile = access.profile();
        authorizeTarget(access, req.targetType(), req.targetId());
        PromotionResponse res = promotionService.create(req);
        notifyPromotionUpdated(profile, res.id(), res.name());
        return res;
    }

    @Transactional
    public PromotionResponse updatePromotion(Long userId, Long id, PromotionRequest req) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        PartnerProfile profile = access.profile();
        authorizedPromotion(access, PROMOTION_MANAGE, id);
        authorizeTarget(access, req.targetType(), req.targetId());
        PromotionResponse res = promotionService.update(id, req);
        notifyPromotionUpdated(profile, res.id(), res.name());
        activityLogService.log(profile.getId(), userId, "PROMOTION_UPDATED", "PROMOTION", res.id(),
            "Updated promotion " + res.name());
        return res;
    }

    @Transactional
    public void deletePromotion(Long userId, Long id) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        PartnerProfile profile = access.profile();
        Promotion promo = authorizedPromotion(access, PROMOTION_MANAGE, id);
        String name = promo.getName();
        promotionService.delete(id);
        notifyPromotionUpdated(profile, id, name);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    /** RBAC R3b — §4.5 RESOURCE on a stored promotion, resolved through its target (§11.2). */
    private Promotion authorizedPromotion(PartnerAccessContext access, PartnerPermission permission, Long id) {
        partnerAccess.requireResource(access, permission, ResourceType.PROMOTION, id, "Promotion not found: " + id);
        return promotionRepo.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Promotion not found: " + id));
    }

    /**
     * RBAC R3b — the target a promotion body names must lie inside the caller's {@code promotion.manage} scope:
     * a HOTEL target is a {@code hotel_details} id resolved through its place, a ROOM target a room type; ALL is
     * never a partner scope. Another company's target and a missing one get the same 404.
     */
    private void authorizeTarget(PartnerAccessContext access, PromotionTargetType targetType, Long targetId) {
        if (targetType == null || targetType == PromotionTargetType.ALL) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Partners cannot create global ALL promotions");
        }
        if (targetId == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "targetId is required for HOTEL/ROOM promotions");
        }
        partnerAccess.decide(access, PROMOTION_MANAGE, ResourceType.PROMOTION,
            partnerAccess.promotionTarget(targetType, targetId), "Target hotel/room not found: " + targetId);
    }

    private List<Long> hotelDetailIdsOf(List<Long> placeIds) {
        return placeIds.stream()
            .map(placeId -> hotelDetails.findByPlaceId(placeId).map(HotelDetail::getId).orElse(null))
            .filter(Objects::nonNull)
            .toList();
    }

    private List<Long> ownedRoomIds(List<Long> hotelDetailIds) {
        return hotelDetailIds.stream()
            .flatMap(id -> rooms.findAllByHotelDetailId(id).stream())
            .map(HotelRoom::getId)
            .toList();
    }

    private void notifyPromotionUpdated(PartnerProfile profile, Long promotionId, String promotionName) {
        notificationService.create(profile.getUser().getId(), NotificationType.PARTNER, Priority.NORMAL,
            "Promotion updated",
            promotionName + " promotion has been updated.",
            RelatedEntityType.PROMOTION, promotionId);
    }
}
