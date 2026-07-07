package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PromotionDto.PromotionRequest;
import com.example.planyourtrip.dto.PromotionDto.PromotionResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.repository.PromotionRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Objects;

@Service
public class PartnerPromotionService {

    private final PartnerProfileRepository partnerProfiles;
    private final PlaceRepository places;
    private final HotelDetailRepository hotelDetails;
    private final HotelRoomRepository rooms;
    private final PromotionRepository promotionRepo;
    private final PromotionService promotionService;
    private final NotificationService notificationService;

    public PartnerPromotionService(PartnerProfileRepository partnerProfiles,
                                    PlaceRepository places,
                                    HotelDetailRepository hotelDetails,
                                    HotelRoomRepository rooms,
                                    PromotionRepository promotionRepo,
                                    PromotionService promotionService,
                                    NotificationService notificationService) {
        this.partnerProfiles = partnerProfiles;
        this.places = places;
        this.hotelDetails = hotelDetails;
        this.rooms = rooms;
        this.promotionRepo = promotionRepo;
        this.promotionService = promotionService;
        this.notificationService = notificationService;
    }

    @Transactional(readOnly = true)
    public List<PromotionResponse> getMyPromotions(Long userId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        List<Long> hotelDetailIds = ownedHotelDetailIds(profile.getId());
        List<Long> roomIds = ownedRoomIds(hotelDetailIds);
        if (hotelDetailIds.isEmpty() && roomIds.isEmpty()) return List.of();

        return promotionRepo.findByOwnedTargets(
                PromotionTargetType.HOTEL, hotelDetailIds.isEmpty() ? List.of(-1L) : hotelDetailIds,
                PromotionTargetType.ROOM, roomIds.isEmpty() ? List.of(-1L) : roomIds)
            .stream().map(promotionService::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public PromotionResponse getPromotion(Long userId, Long id) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        Promotion promo = ownedPromotionOrThrow(id, profile.getId());
        return promotionService.toResponse(promo);
    }

    @Transactional
    public PromotionResponse createPromotion(Long userId, PromotionRequest req) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        validateTargetOwnership(req.targetType(), req.targetId(), profile.getId());
        PromotionResponse res = promotionService.create(req);
        notifyPromotionUpdated(profile, res.id(), res.name());
        return res;
    }

    @Transactional
    public PromotionResponse updatePromotion(Long userId, Long id, PromotionRequest req) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        ownedPromotionOrThrow(id, profile.getId());
        validateTargetOwnership(req.targetType(), req.targetId(), profile.getId());
        PromotionResponse res = promotionService.update(id, req);
        notifyPromotionUpdated(profile, res.id(), res.name());
        return res;
    }

    @Transactional
    public void deletePromotion(Long userId, Long id) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        Promotion promo = ownedPromotionOrThrow(id, profile.getId());
        String name = promo.getName();
        promotionService.delete(id);
        notifyPromotionUpdated(profile, id, name);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private PartnerProfile myApprovedProfileOrThrow(Long userId) {
        PartnerProfile profile = partnerProfiles.findByUserId(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Partner profile not found"));
        if (profile.getVerificationStatus() != PartnerVerificationStatus.APPROVED)
            throw new ApiException(HttpStatus.FORBIDDEN, "Partner profile is not approved");
        return profile;
    }

    private Promotion ownedPromotionOrThrow(Long id, Long ownerId) {
        Promotion promo = promotionRepo.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Promotion not found: " + id));
        if (!isOwnedTarget(promo.getTargetType(), promo.getTargetId(), ownerId)) {
            throw new ApiException(HttpStatus.NOT_FOUND, "Promotion not found: " + id);
        }
        return promo;
    }

    private void validateTargetOwnership(PromotionTargetType targetType, Long targetId, Long ownerId) {
        if (targetType == null || targetType == PromotionTargetType.ALL) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Partners cannot create global ALL promotions");
        }
        if (targetId == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "targetId is required for HOTEL/ROOM promotions");
        }
        if (!isOwnedTarget(targetType, targetId, ownerId)) {
            throw new ApiException(HttpStatus.NOT_FOUND, "Target hotel/room not found: " + targetId);
        }
    }

    private boolean isOwnedTarget(PromotionTargetType targetType, Long targetId, Long ownerId) {
        if (targetId == null) return false;
        return switch (targetType) {
            case HOTEL -> hotelDetails.findById(targetId)
                .map(hd -> hd.getPlace().getOwner() != null && hd.getPlace().getOwner().getId().equals(ownerId))
                .orElse(false);
            case ROOM -> rooms.findById(targetId)
                .map(r -> r.getHotelDetail().getPlace().getOwner() != null
                    && r.getHotelDetail().getPlace().getOwner().getId().equals(ownerId))
                .orElse(false);
            case ALL -> false;
        };
    }

    private List<Long> ownedHotelDetailIds(Long ownerId) {
        return places.findAllByOwnerId(ownerId).stream()
            .map(place -> hotelDetails.findByPlaceId(place.getId()).map(HotelDetail::getId).orElse(null))
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
