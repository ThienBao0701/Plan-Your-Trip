package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.HotelDetailDto.HotelDetailRequest;
import com.example.planyourtrip.dto.HotelDetailDto.HotelDetailResponse;
import com.example.planyourtrip.dto.HotelExperienceDto.FacilityResponse;
import com.example.planyourtrip.dto.HotelExperienceDto.InternetInfo;
import com.example.planyourtrip.dto.HotelExperienceDto.ParkingInfo;
import com.example.planyourtrip.dto.HotelExperienceDto.ServiceResponse;
import com.example.planyourtrip.dto.HotelRoomDto.HotelRoomResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.HotelDetail;
import com.example.planyourtrip.model.Place;
import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class HotelDetailService {

    private final HotelDetailRepository hotelDetails;
    private final PlaceRepository places;
    private final HotelRoomService hotelRoomService;
    private final HotelFacilityService facilityService;
    private final HotelServiceService serviceService;
    private final AdminActivityLogService adminAudit;

    public HotelDetailService(HotelDetailRepository hotelDetails, PlaceRepository places,
                               HotelRoomService hotelRoomService,
                               HotelFacilityService facilityService,
                               HotelServiceService serviceService,
                               AdminActivityLogService adminAudit) {
        this.hotelDetails     = hotelDetails;
        this.places           = places;
        this.hotelRoomService = hotelRoomService;
        this.facilityService  = facilityService;
        this.serviceService   = serviceService;
        this.adminAudit       = adminAudit;
    }

    public HotelDetailResponse get(Long placeId) {
        placeOrThrow(placeId);
        HotelDetail detail = hotelDetails.findByPlaceId(placeId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Hotel detail not found for place: " + placeId));
        return toResponse(detail);
    }

    /**
     * D3G — hotel detail is an administrative surface end to end.
     *
     * <p>{@link #create} and {@link #update} are reachable only from {@code AdminHotelController}:
     * the sole other injector, {@code PlaceService}, calls {@link #resolveForPlace} — a read — and
     * no partner or customer path writes hotel detail through this service. So the audit records
     * live inline here, as they do in {@code PlaceService}, rather than behind the admin-only
     * wrappers {@code HotelRoomService} needs for its partner-shared bodies.
     *
     * <p>The trail targets the <b>place</b>, not the hotel-detail row: a {@code HotelDetail} is a
     * one-to-one extension owned by its {@code Place} (it is found by {@code findByPlaceId}, both
     * endpoints are addressed by {@code placeId}, and it has no lifecycle of its own). That also
     * matches the existing {@code HOTEL_ASSIGN_OWNER} audit, which already targets {@code PLACE}.
     */
    @Transactional
    public HotelDetailResponse create(HotelDetailRequest req, Long adminId) {
        if (req.placeId() == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "placeId is required");
        }
        Place place = placeOrThrow(req.placeId());
        validateHotelCategory(place);
        if (hotelDetails.existsByPlaceId(req.placeId())) {
            throw new ApiException(HttpStatus.CONFLICT,
                "Hotel detail already exists for place: " + req.placeId());
        }
        HotelDetail detail = new HotelDetail();
        detail.setPlace(place);
        fill(detail, req);
        HotelDetail saved = hotelDetails.save(detail);
        // The target id is the *resolved* place, not the id off the request body: an unknown
        // placeId throws 404 above, so nothing unresolvable can ever be recorded as a target.
        adminAudit.record(adminId, "HOTEL_DETAIL_CREATE", "PLACE", place.getId(),
            "Admin created hotel detail for place " + place.getId(),
            null, summarise(saved));
        return toResponse(saved);
    }

    /** See {@link #create}. */
    @Transactional
    public HotelDetailResponse update(Long placeId, HotelDetailRequest req, Long adminId) {
        Place place = placeOrThrow(placeId);
        validateHotelCategory(place);
        HotelDetail detail = hotelDetails.findByPlaceId(placeId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Hotel detail not found for place: " + placeId));
        // Snapshotted to a String before fill(), not held as an entity reference: `detail` is a
        // managed instance and would otherwise read back the new values by the time it is used.
        String before = summarise(detail);
        fill(detail, req);
        HotelDetail saved = hotelDetails.save(detail);
        adminAudit.record(adminId, "HOTEL_DETAIL_UPDATE", "PLACE", place.getId(),
            "Admin replaced the whole hotel detail for place " + place.getId(),
            before, summarise(saved));
        return toResponse(saved);
    }

    /**
     * A compact, bounded scalar summary — never the entity, the request, or a policy field.
     *
     * <p>Only the bounded values this endpoint actually mutates are included. The free-text policy
     * fields ({@code cancellationPolicy}, {@code petPolicy}, {@code smokingPolicy}, …) are operator
     * prose of unbounded length and content and are deliberately left out; so are the unbounded
     * integer counts, which could otherwise produce a digit run long enough to trip the audit
     * service's credential guard and fail the mutation for a value that is not a secret.
     */
    private static String summarise(HotelDetail d) {
        return "stars:" + d.getStarRating()
            + " checkIn:" + d.getCheckInTime()
            + " checkOut:" + d.getCheckOutTime()
            + " freeCancellation:" + d.isFreeCancellation()
            + " prepayment:" + d.isPrepaymentRequired()
            + " breakfast:" + d.isBreakfastIncluded()
            + " shuttle:" + d.isAirportShuttle();
    }

    HotelDetailResponse toResponse(HotelDetail d) {
        return toResponse(d, false);
    }

    HotelDetailResponse toResponse(HotelDetail d, boolean activeOnly) {
        List<HotelRoomResponse> rooms       = hotelRoomService.getByHotelDetail(d.getId(), activeOnly);
        List<FacilityResponse> facilities   = facilityService.getByHotelDetail(d.getId());
        List<ServiceResponse> services      = serviceService.getByHotelDetail(d.getId());
        ParkingInfo parking   = new ParkingInfo(d.isParkingAvailable(), d.isParkingFree(), d.getParkingDescription());
        InternetInfo internet = new InternetInfo(d.isWifiAvailable(), d.isWifiFree(), d.getInternetDescription());
        return new HotelDetailResponse(
            d.getId(),
            d.getStarRating(),
            d.getCheckInTime(),
            d.getCheckOutTime(),
            d.getDistanceToBeachMeters(),
            d.getDistanceToCityCenterMeters(),
            d.getTotalRooms(),
            d.getAvailableRooms(),
            d.isFreeCancellation(),
            d.getCancellationPolicy(),
            d.isPrepaymentRequired(),
            d.getPaymentPolicy(),
            d.getChildrenPolicy(),
            d.getPetPolicy(),
            d.getSmokingPolicy(),
            d.isBreakfastIncluded(),
            d.isAirportShuttle(),
            d.getCreatedAt(),
            d.getUpdatedAt(),
            facilities,
            services,
            List.copyOf(d.getLanguages()),
            List.copyOf(d.getPaymentMethods()),
            parking,
            internet,
            rooms
        );
    }

    public HotelDetailResponse resolveForPlace(Place place, boolean activeOnly) {
        if (!isHotelCategory(place)) return null;
        return hotelDetails.findByPlaceId(place.getId())
            .map(d -> toResponse(d, activeOnly))
            .orElse(null);
    }

    private boolean isHotelCategory(Place place) {
        return "hotel".equals(place.getCategory().getSlug())
            || (place.getSubcategory() != null && "hotel".equals(place.getSubcategory().getSlug()));
    }

    private void fill(HotelDetail d, HotelDetailRequest req) {
        d.setStarRating(req.starRating());
        d.setCheckInTime(req.checkInTime());
        d.setCheckOutTime(req.checkOutTime());
        d.setDistanceToBeachMeters(req.distanceToBeachMeters());
        d.setDistanceToCityCenterMeters(req.distanceToCityCenterMeters());
        d.setTotalRooms(req.totalRooms());
        d.setAvailableRooms(req.availableRooms());
        d.setFreeCancellation(req.freeCancellation());
        d.setCancellationPolicy(req.cancellationPolicy());
        d.setPrepaymentRequired(req.prepaymentRequired());
        d.setPaymentPolicy(req.paymentPolicy());
        d.setChildrenPolicy(req.childrenPolicy());
        d.setPetPolicy(req.petPolicy());
        d.setSmokingPolicy(req.smokingPolicy());
        d.setBreakfastIncluded(req.breakfastIncluded());
        d.setAirportShuttle(req.airportShuttle());
    }

    private void validateHotelCategory(Place place) {
        boolean isHotel = "hotel".equals(place.getCategory().getSlug())
            || (place.getSubcategory() != null && "hotel".equals(place.getSubcategory().getSlug()));
        if (!isHotel) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "Place category must be 'Hotel' to manage hotel details");
        }
    }

    private Place placeOrThrow(Long id) {
        return places.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Place not found: " + id));
    }
}
