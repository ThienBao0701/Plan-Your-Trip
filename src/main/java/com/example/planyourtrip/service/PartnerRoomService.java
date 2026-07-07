package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.HotelRoomDto.HotelRoomRequest;
import com.example.planyourtrip.dto.HotelRoomDto.HotelRoomResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class PartnerRoomService {

    private final PartnerProfileRepository partnerProfiles;
    private final PlaceRepository places;
    private final HotelDetailRepository hotelDetails;
    private final HotelRoomRepository rooms;
    private final HotelRoomService hotelRoomService;

    public PartnerRoomService(PartnerProfileRepository partnerProfiles,
                               PlaceRepository places,
                               HotelDetailRepository hotelDetails,
                               HotelRoomRepository rooms,
                               HotelRoomService hotelRoomService) {
        this.partnerProfiles = partnerProfiles;
        this.places = places;
        this.hotelDetails = hotelDetails;
        this.rooms = rooms;
        this.hotelRoomService = hotelRoomService;
    }

    @Transactional(readOnly = true)
    public List<HotelRoomResponse> getMyRooms(Long userId, Long hotelId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        Place place = ownedPlaceOrThrow(hotelId, profile.getId());
        HotelDetail detail = hotelDetails.findByPlaceId(place.getId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Hotel detail not found for place: " + hotelId));
        return hotelRoomService.getByHotelDetail(detail.getId(), false);
    }

    @Transactional(readOnly = true)
    public HotelRoomResponse getRoom(Long userId, Long roomId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        HotelRoom room = ownedRoomOrThrow(roomId, profile.getId());
        return hotelRoomService.toResponse(room);
    }

    @Transactional
    public HotelRoomResponse updateRoomInformation(Long userId, Long roomId, HotelRoomRequest req) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        ownedRoomOrThrow(roomId, profile.getId());
        return hotelRoomService.update(roomId, req);
    }

    @Transactional
    public HotelRoomResponse activate(Long userId, Long roomId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        HotelRoom room = ownedRoomOrThrow(roomId, profile.getId());
        hotelRoomService.activate(room.getId());
        return hotelRoomService.getById(room.getId());
    }

    @Transactional
    public HotelRoomResponse deactivate(Long userId, Long roomId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        HotelRoom room = ownedRoomOrThrow(roomId, profile.getId());
        hotelRoomService.deactivate(room.getId());
        return hotelRoomService.getById(room.getId());
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private PartnerProfile myApprovedProfileOrThrow(Long userId) {
        PartnerProfile profile = partnerProfiles.findByUserId(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Partner profile not found"));
        if (profile.getVerificationStatus() != PartnerVerificationStatus.APPROVED)
            throw new ApiException(HttpStatus.FORBIDDEN, "Partner profile is not approved");
        return profile;
    }

    private Place ownedPlaceOrThrow(Long hotelId, Long ownerId) {
        return places.findByIdAndOwnerId(hotelId, ownerId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Hotel not found: " + hotelId));
    }

    private HotelRoom ownedRoomOrThrow(Long roomId, Long ownerId) {
        HotelRoom room = rooms.findById(roomId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Room not found: " + roomId));
        PartnerProfile owner = room.getHotelDetail().getPlace().getOwner();
        if (owner == null || !owner.getId().equals(ownerId))
            throw new ApiException(HttpStatus.NOT_FOUND, "Room not found: " + roomId);
        return room;
    }
}
