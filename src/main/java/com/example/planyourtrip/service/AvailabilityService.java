package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PlaceDto.AmenityRef;
import com.example.planyourtrip.dto.RatePlanDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

@Service
@Transactional(readOnly = true)
public class AvailabilityService {

    private final PlaceRepository placeRepo;
    private final HotelDetailRepository hotelDetailRepo;
    private final HotelRoomRepository roomRepo;
    private final RoomInventoryRepository inventoryRepo;
    private final RatePlanRepository ratePlanRepo;
    private final RoomAmenityRepository roomAmenityRepo;
    private final MediaAssetRepository mediaAssetRepo;

    public AvailabilityService(PlaceRepository placeRepo,
                                HotelDetailRepository hotelDetailRepo,
                                HotelRoomRepository roomRepo,
                                RoomInventoryRepository inventoryRepo,
                                RatePlanRepository ratePlanRepo,
                                RoomAmenityRepository roomAmenityRepo,
                                MediaAssetRepository mediaAssetRepo) {
        this.placeRepo       = placeRepo;
        this.hotelDetailRepo = hotelDetailRepo;
        this.roomRepo        = roomRepo;
        this.inventoryRepo   = inventoryRepo;
        this.ratePlanRepo    = ratePlanRepo;
        this.roomAmenityRepo = roomAmenityRepo;
        this.mediaAssetRepo  = mediaAssetRepo;
    }

    public HotelAvailabilityResponse search(Long placeId,
                                             LocalDate checkIn,
                                             LocalDate checkOut,
                                             int adults,
                                             int children) {
        if (!checkOut.isAfter(checkIn)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "checkOut must be after checkIn");
        }
        if (checkIn.isBefore(LocalDate.now())) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "checkIn cannot be in the past");
        }
        if (adults < 1) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "adults must be at least 1");
        }

        Place place = placeRepo.findById(placeId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Place not found: " + placeId));

        HotelDetail detail = hotelDetailRepo.findByPlaceId(placeId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "No hotel found for place: " + placeId));

        long nights = ChronoUnit.DAYS.between(checkIn, checkOut);
        LocalDate lastNight = checkOut.minusDays(1);
        int totalGuests = adults + children;

        List<HotelRoom> rooms = roomRepo.findAllByHotelDetailIdAndActiveTrue(detail.getId());
        List<AvailableRoomResult> available = new ArrayList<>();

        for (HotelRoom room : rooms) {
            if (room.getMaxAdults() != null && room.getMaxAdults() < adults) continue;
            if (room.getMaxGuests() != null && room.getMaxGuests() < totalGuests) continue;

            long availableNights = inventoryRepo.countAvailableNights(room.getId(), checkIn, checkOut);
            if (availableNights < nights) continue;

            List<RatePlan> plans = ratePlanRepo.findActiveForStay(room.getId(), checkIn, lastNight);
            Optional<RatePlan> bestPlan = plans.stream()
                .min(Comparator.comparing(RatePlan::getPricePerNight));

            BigDecimal effectivePrice = bestPlan
                .map(RatePlan::getPricePerNight)
                .orElse(room.getPriceFrom());

            String ratePlanName = bestPlan.map(RatePlan::getRateName).orElse(null);

            BigDecimal totalPrice = effectivePrice != null
                ? effectivePrice.multiply(BigDecimal.valueOf(nights))
                : null;

            List<MediaAsset> media = mediaAssetRepo
                .findByOwnerTypeAndOwnerIdAndActiveTrueOrderBySortOrderAsc(
                    MediaOwnerType.ROOM, room.getId());

            String coverImageUrl = media.stream()
                .filter(m -> m.isCover() && m.getMediaType() == MediaType.IMAGE)
                .findFirst()
                .or(() -> media.stream().filter(m -> m.getMediaType() == MediaType.IMAGE).findFirst())
                .map(MediaAsset::getUrl)
                .orElse(null);

            List<AmenityRef> amenities = roomAmenityRepo.findAllByRoomId(room.getId())
                .stream()
                .map(ra -> {
                    Amenity a = ra.getAmenity();
                    return new AmenityRef(a.getId(), a.getName(), a.getSlug(), a.getIcon(), a.getGroupName());
                })
                .toList();

            available.add(new AvailableRoomResult(
                room.getId(),
                room.getRoomName(),
                room.getRoomCode(),
                room.getRoomType(),
                room.getBedType(),
                room.getBedCount(),
                room.getMaxAdults(),
                room.getMaxChildren(),
                room.getMaxGuests(),
                room.getRoomSizeSqm(),
                room.isBreakfastIncluded(),
                room.isFreeCancellation(),
                room.isInstantConfirmation(),
                effectivePrice,
                room.getPriceFrom(),
                totalPrice,
                (int) nights,
                ratePlanName,
                coverImageUrl,
                amenities
            ));
        }

        return new HotelAvailabilityResponse(
            placeId,
            place.getName(),
            checkIn,
            checkOut,
            (int) nights,
            adults,
            children,
            available
        );
    }
}
