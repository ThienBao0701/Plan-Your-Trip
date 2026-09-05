package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.HotelRoomDto.HotelRoomRequest;
import com.example.planyourtrip.dto.HotelRoomDto.HotelRoomResponse;
import com.example.planyourtrip.dto.PlaceDto.AmenityRef;
import com.example.planyourtrip.dto.HotelRoomDto.RoomImageRef;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class HotelRoomService {

    private final HotelRoomRepository roomRepo;
    private final HotelDetailRepository hotelDetailRepo;
    private final RoomAmenityRepository roomAmenityRepo;
    private final MediaAssetRepository mediaAssetRepo;
    private final AmenityRepository amenityRepo;
    private final AdminActivityLogService adminAudit;

    public HotelRoomService(HotelRoomRepository roomRepo,
                            HotelDetailRepository hotelDetailRepo,
                            RoomAmenityRepository roomAmenityRepo,
                            MediaAssetRepository mediaAssetRepo,
                            AmenityRepository amenityRepo,
                            AdminActivityLogService adminAudit) {
        this.roomRepo        = roomRepo;
        this.hotelDetailRepo = hotelDetailRepo;
        this.roomAmenityRepo = roomAmenityRepo;
        this.mediaAssetRepo  = mediaAssetRepo;
        this.amenityRepo     = amenityRepo;
        this.adminAudit      = adminAudit;
    }

    public List<HotelRoomResponse> getByPlaceId(Long placeId, boolean activeOnly) {
        HotelDetail detail = hotelDetailRepo.findByPlaceId(placeId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Hotel detail not found for place: " + placeId));
        return getByHotelDetail(detail.getId(), activeOnly);
    }

    public List<HotelRoomResponse> getByHotelDetail(Long hotelDetailId, boolean activeOnly) {
        List<HotelRoom> rooms = activeOnly
            ? roomRepo.findAllByHotelDetailIdAndActiveTrue(hotelDetailId)
            : roomRepo.findAllByHotelDetailId(hotelDetailId);
        return rooms.stream().map(this::toResponse).toList();
    }

    public HotelRoomResponse getById(Long id) {
        return toResponse(roomOrThrow(id));
    }

    /**
     * D3F — the audited entry points for an administrator managing rooms.
     *
     * <p>They delegate rather than recording inside {@link #create}, {@link #update} and
     * {@link #deactivate}, because those three are also how a <em>partner</em> manages the rooms of
     * a property they own: {@code PartnerRoomService} calls all of them
     * ({@code update}, {@code activate}, {@code deactivate}). Auditing the shared bodies would file
     * a partner's own housekeeping as an administrative action — the same trap D1c hit when
     * referral rewards reached the audited credit-grant path, and the reason
     * {@code MediaAssetService} grew {@code adminCreate}/{@code adminDeactivate}.
     *
     * <p>Each wrapper is {@code @Transactional}, so the delegate and the audit row share one
     * transaction: a failed mutation rolls the audit back with it, and a failed audit rolls the
     * mutation back.
     */
    @Transactional
    public HotelRoomResponse adminCreate(Long adminUserId, HotelRoomRequest req) {
        HotelRoomResponse created = create(req);
        adminAudit.record(adminUserId, "ROOM_CREATE", "HOTEL_ROOM", created.id(),
            "Admin created room " + created.id() + " on place " + req.placeId(),
            null, "active:" + created.active());
        return created;
    }

    /** See {@link #adminCreate}. */
    @Transactional
    public HotelRoomResponse adminUpdate(Long adminUserId, Long id, HotelRoomRequest req) {
        HotelRoom before = roomOrThrow(id);
        boolean wasActive = before.isActive();
        HotelRoomResponse updated = update(id, req);
        // The room's amenity set is replaced wholesale by the update, which is
        // the part an operator would not guess from a bare "updated".
        adminAudit.record(adminUserId, "ROOM_UPDATE", "HOTEL_ROOM", id,
            "Admin updated room " + id + "; amenities were replaced",
            "active:" + wasActive, "active:" + updated.active());
        return updated;
    }

    /**
     * See {@link #adminCreate}. Deactivation is a soft delete: the row stays and the admin API
     * exposes no counterpart, so the trail is the only record that it happened.
     */
    @Transactional
    public void adminDeactivate(Long adminUserId, Long id) {
        HotelRoom before = roomOrThrow(id);
        boolean wasActive = before.isActive();
        Long placeId = before.getHotelDetail() == null ? null
            : before.getHotelDetail().getPlace().getId();
        deactivate(id);
        adminAudit.record(adminUserId, "ROOM_DEACTIVATE", "HOTEL_ROOM", id,
            "Admin deactivated room " + id
                + (placeId == null ? "" : " on place " + placeId)
                + (wasActive ? "" : "; it was already inactive"),
            "active:" + wasActive, "active:false");
    }

    @Transactional
    public HotelRoomResponse create(HotelRoomRequest req) {
        if (req.placeId() == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "placeId is required");
        }
        HotelDetail detail = hotelDetailRepo.findByPlaceId(req.placeId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Hotel detail not found for place: " + req.placeId()));
        if (roomRepo.existsByHotelDetailIdAndRoomCode(detail.getId(), req.roomCode())) {
            throw new ApiException(HttpStatus.CONFLICT,
                "Room code already exists for this hotel: " + req.roomCode());
        }
        validateAvailability(req.availableQuantity(), req.quantity());
        HotelRoom room = new HotelRoom();
        room.setHotelDetail(detail);
        fill(room, req);
        roomRepo.save(room);
        syncAmenities(room, req.amenitySlugs());
        return toResponse(room);
    }

    @Transactional
    public HotelRoomResponse update(Long id, HotelRoomRequest req) {
        HotelRoom room = roomOrThrow(id);
        if (roomRepo.existsByHotelDetailIdAndRoomCodeAndIdNot(
                room.getHotelDetail().getId(), req.roomCode(), id)) {
            throw new ApiException(HttpStatus.CONFLICT,
                "Room code already exists for this hotel: " + req.roomCode());
        }
        validateAvailability(req.availableQuantity(), req.quantity());
        fill(room, req);
        roomRepo.save(room);
        syncAmenities(room, req.amenitySlugs());
        return toResponse(room);
    }

    @Transactional
    public void deactivate(Long id) {
        HotelRoom room = roomOrThrow(id);
        room.setActive(false);
        roomRepo.save(room);
    }

    @Transactional
    public void activate(Long id) {
        HotelRoom room = roomOrThrow(id);
        room.setActive(true);
        roomRepo.save(room);
    }

    HotelRoomResponse toResponse(HotelRoom room) {
        List<AmenityRef> amenities = roomAmenityRepo.findAllByRoomId(room.getId())
            .stream()
            .map(ra -> {
                Amenity a = ra.getAmenity();
                return new AmenityRef(a.getId(), a.getName(), a.getSlug(), a.getIcon(), a.getGroupName());
            })
            .toList();

        List<MediaAsset> media = mediaAssetRepo
            .findByOwnerTypeAndOwnerIdAndActiveTrueOrderBySortOrderAsc(
                MediaOwnerType.ROOM, room.getId());

        String coverImageUrl = media.stream()
            .filter(m -> m.isCover() && m.getMediaType() == MediaType.IMAGE)
            .findFirst()
            .or(() -> media.stream().filter(m -> m.getMediaType() == MediaType.IMAGE).findFirst())
            .map(MediaAsset::getUrl)
            .orElse(null);

        List<RoomImageRef> gallery = media.stream()
            .map(m -> new RoomImageRef(
                m.getId(), m.getUrl(), m.getThumbnailUrl(),
                m.getAltText(), m.getSortOrder(), m.isCover()))
            .toList();

        return new HotelRoomResponse(
            room.getId(),
            room.getRoomName(),
            room.getRoomCode(),
            room.getRoomType(),
            room.getDescription(),
            room.getBedType(),
            room.getBedCount(),
            room.getMaxAdults(),
            room.getMaxChildren(),
            room.getMaxGuests(),
            room.getRoomSizeSqm(),
            room.getFloorNumber(),
            room.isSmokingAllowed(),
            room.isBreakfastIncluded(),
            room.isFreeCancellation(),
            room.isInstantConfirmation(),
            room.getPriceFrom(),
            room.getOriginalPrice(),
            room.getQuantity(),
            room.getAvailableQuantity(),
            room.isActive(),
            amenities,
            coverImageUrl,
            gallery,
            room.getCreatedAt(),
            room.getUpdatedAt()
        );
    }

    private void fill(HotelRoom room, HotelRoomRequest req) {
        room.setRoomName(req.roomName());
        room.setRoomCode(req.roomCode());
        room.setRoomType(req.roomType());
        room.setDescription(req.description());
        room.setBedType(req.bedType());
        room.setBedCount(req.bedCount());
        room.setMaxAdults(req.maxAdults());
        room.setMaxChildren(req.maxChildren());
        room.setMaxGuests(req.maxGuests());
        room.setRoomSizeSqm(req.roomSizeSqm());
        room.setFloorNumber(req.floorNumber());
        room.setSmokingAllowed(req.smokingAllowed());
        room.setBreakfastIncluded(req.breakfastIncluded());
        room.setFreeCancellation(req.freeCancellation());
        room.setInstantConfirmation(req.instantConfirmation());
        room.setPriceFrom(req.priceFrom());
        room.setOriginalPrice(req.originalPrice());
        room.setQuantity(req.quantity());
        room.setAvailableQuantity(req.availableQuantity());
        if (req.active() != null) room.setActive(req.active());
    }

    private void syncAmenities(HotelRoom room, List<String> slugs) {
        roomAmenityRepo.deleteAllByRoomId(room.getId());
        if (slugs == null || slugs.isEmpty()) return;
        for (String slug : slugs) {
            amenityRepo.findBySlug(slug).ifPresent(amenity -> {
                RoomAmenity ra = new RoomAmenity();
                ra.setRoom(room);
                ra.setAmenity(amenity);
                roomAmenityRepo.save(ra);
            });
        }
    }

    private void validateAvailability(Integer available, Integer total) {
        if (available != null && total != null && available > total) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "availableQuantity cannot exceed quantity");
        }
    }

    private HotelRoom roomOrThrow(Long id) {
        return roomRepo.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Room not found: " + id));
    }
}
