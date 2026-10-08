package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.HotelRoomDto.HotelRoomRequest;
import com.example.planyourtrip.dto.HotelRoomDto.HotelRoomResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.AmenityRepository;
import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.repository.RoomAmenityRepository;
import com.example.planyourtrip.security.rbac.PartnerAccessContext;
import com.example.planyourtrip.security.rbac.PartnerPermission;
import com.example.planyourtrip.security.rbac.ResourceType;
import com.example.planyourtrip.security.rbac.ScopePath;
import com.example.planyourtrip.security.rbac.ScopeSet;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.EnumSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import static com.example.planyourtrip.security.rbac.PartnerPermission.ROOM_COMMERCIAL_EDIT;
import static com.example.planyourtrip.security.rbac.PartnerPermission.ROOM_CONTENT_EDIT;
import static com.example.planyourtrip.security.rbac.PartnerPermission.ROOM_STATUS_TOGGLE;
import static com.example.planyourtrip.security.rbac.PartnerPermission.ROOM_VIEW;

/**
 * Partner room types (RBAC V1.1 §25.1 Room rows). RBAC R3b — every handler is decided by the kernel from the
 * room's stored location: {@code room → hotel_detail → place → owner} (UNIT scope, §11.2). Room view (P21) has
 * floor U, so a member holding a single room type sees exactly that room type and nothing else of its property.
 */
@Service
public class PartnerRoomService {

    private final PlaceRepository places;
    private final HotelDetailRepository hotelDetails;
    private final HotelRoomRepository rooms;
    private final HotelRoomService hotelRoomService;
    private final RoomAmenityRepository roomAmenities;
    private final AmenityRepository amenities;
    private final PartnerAccessService partnerAccess;

    public PartnerRoomService(PlaceRepository places,
                               HotelDetailRepository hotelDetails,
                               HotelRoomRepository rooms,
                               HotelRoomService hotelRoomService,
                               RoomAmenityRepository roomAmenities,
                               AmenityRepository amenities,
                               PartnerAccessService partnerAccess) {
        this.places = places;
        this.hotelDetails = hotelDetails;
        this.rooms = rooms;
        this.hotelRoomService = hotelRoomService;
        this.roomAmenities = roomAmenities;
        this.amenities = amenities;
        this.partnerAccess = partnerAccess;
    }

    /**
     * §4.5 COLLECTION (room): the room types of {@code hotelId} that the caller's scope set covers — all of them
     * for a company or property grant, only the granted ones for unit grants. A property outside the set is 404.
     */
    @Transactional(readOnly = true)
    public List<HotelRoomResponse> getMyRooms(Long userId, Long hotelId) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        ScopeSet scope = partnerAccess.requireCollection(access, ROOM_VIEW);
        Place place = places.findByIdAndOwnerId(hotelId, access.companyId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Hotel not found: " + hotelId));
        boolean wholeProperty = scope.permits(ScopePath.property(access.companyId(), place.getId()));
        Set<Long> grantedUnits = scope.units().stream()
            .filter(unit -> place.getId().equals(unit.propertyId()))
            .map(ScopePath::unitId).collect(Collectors.toSet());
        if (!wholeProperty && grantedUnits.isEmpty())
            throw new ApiException(HttpStatus.NOT_FOUND, "Hotel not found: " + hotelId);
        HotelDetail detail = hotelDetails.findByPlaceId(place.getId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Hotel detail not found for place: " + hotelId));
        return hotelRoomService.getByHotelDetail(detail.getId(), false).stream()
            .filter(room -> wholeProperty || grantedUnits.contains(room.id()))
            .toList();
    }

    @Transactional(readOnly = true)
    public HotelRoomResponse getRoom(Long userId, Long roomId) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        return hotelRoomService.toResponse(authorizedRoom(access, ROOM_VIEW, roomId));
    }

    /**
     * {@code PUT /rooms/{roomId}} — B9 field-diff: the whole write is authorized before anything is saved, by the
     * fields that actually change (content P23, commercial P24, the active switch P25). A write that changes
     * nothing needs P23 or P24.
     */
    @Transactional
    public HotelRoomResponse updateRoomInformation(Long userId, Long roomId, HotelRoomRequest req) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        ScopePath target = partnerAccess.requireAny(access, List.of(ROOM_CONTENT_EDIT, ROOM_COMMERCIAL_EDIT),
            ResourceType.ROOM, partnerAccess.target(ResourceType.ROOM, roomId), notFound(roomId));
        HotelRoom room = rooms.findById(roomId).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, notFound(roomId)));
        Set<String> storedSlugs = roomAmenities.findAllByRoomId(roomId).stream()
            .map(link -> link.getAmenity().getSlug()).collect(Collectors.toSet());
        Set<String> requestedSlugs = req.amenitySlugs() == null ? Set.of() : req.amenitySlugs().stream()
            .filter(slug -> amenities.findBySlug(slug).isPresent()).collect(Collectors.toSet());
        Set<PartnerPermission> needed = PartnerFieldDiff.room(room, storedSlugs, req, requestedSlugs);
        if (!needed.isEmpty()) {
            partnerAccess.requireAll(access, EnumSet.copyOf(needed), ResourceType.ROOM, target, notFound(roomId));
        }
        return hotelRoomService.update(roomId, req);
    }

    @Transactional
    public HotelRoomResponse activate(Long userId, Long roomId) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        HotelRoom room = authorizedRoom(access, ROOM_STATUS_TOGGLE, roomId);
        hotelRoomService.activate(room.getId());
        return hotelRoomService.getById(room.getId());
    }

    @Transactional
    public HotelRoomResponse deactivate(Long userId, Long roomId) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        HotelRoom room = authorizedRoom(access, ROOM_STATUS_TOGGLE, roomId);
        hotelRoomService.deactivate(room.getId());
        return hotelRoomService.getById(room.getId());
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private HotelRoom authorizedRoom(PartnerAccessContext access, PartnerPermission permission, Long roomId) {
        partnerAccess.requireResource(access, permission, ResourceType.ROOM, roomId, notFound(roomId));
        return rooms.findById(roomId).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, notFound(roomId)));
    }

    private static String notFound(Long roomId) {
        return "Room not found: " + roomId;
    }
}
