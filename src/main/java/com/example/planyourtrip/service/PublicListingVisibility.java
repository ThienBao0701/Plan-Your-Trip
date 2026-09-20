package com.example.planyourtrip.service;

import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.HotelRoom;
import com.example.planyourtrip.model.Place;
import com.example.planyourtrip.model.PlaceStatus;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Phase A (S2) — the one rule for what an unauthenticated caller may see of a property.
 *
 * <p><b>Only {@link PlaceStatus#PUBLISHED} is public.</b> DRAFT, PENDING_REVIEW, APPROVED, HIDDEN,
 * REJECTED and ARCHIVED are not. A room is publicly sellable only when it is active and its property is
 * public — the rule the canonical pricing quote already applied.
 *
 * <p>Anything that is not public is reported exactly like an id that does not exist (404), so a
 * sequential id reveals neither a draft's data nor that it exists. Public availability, pricing and
 * rate-plan endpoints resolve their place or room through this class instead of repeating the status
 * check. The place search/detail/media queries filter by {@link #PUBLIC_STATUS} in the database.
 */
@Service
@Transactional(readOnly = true)
public class PublicListingVisibility {

    /** The only status the public may see. */
    public static final PlaceStatus PUBLIC_STATUS = PlaceStatus.PUBLISHED;

    private final PlaceRepository places;
    private final HotelRoomRepository rooms;

    public PublicListingVisibility(PlaceRepository places, HotelRoomRepository rooms) {
        this.places = places;
        this.rooms = rooms;
    }

    public static boolean isPubliclyVisible(Place place) {
        return place != null && place.getStatus() == PUBLIC_STATUS;
    }

    public static boolean isPubliclySellable(HotelRoom room) {
        return room != null && room.isActive()
            && room.getHotelDetail() != null && isPubliclyVisible(room.getHotelDetail().getPlace());
    }

    /** The public place, or 404 — for a missing id and a non-public place alike. */
    public Place requireVisiblePlace(Long placeId) {
        return places.findById(placeId)
            .filter(PublicListingVisibility::isPubliclyVisible)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Place not found: " + placeId));
    }

    /** The publicly sellable room, or 404 — for a missing id, an inactive room and a non-public property alike. */
    public HotelRoom requireSellableRoom(Long roomId) {
        return rooms.findById(roomId)
            .filter(PublicListingVisibility::isPubliclySellable)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Room not found: " + roomId));
    }
}
