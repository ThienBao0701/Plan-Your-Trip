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

    public HotelDetailService(HotelDetailRepository hotelDetails, PlaceRepository places,
                               HotelRoomService hotelRoomService,
                               HotelFacilityService facilityService,
                               HotelServiceService serviceService) {
        this.hotelDetails     = hotelDetails;
        this.places           = places;
        this.hotelRoomService = hotelRoomService;
        this.facilityService  = facilityService;
        this.serviceService   = serviceService;
    }

    public HotelDetailResponse get(Long placeId) {
        placeOrThrow(placeId);
        HotelDetail detail = hotelDetails.findByPlaceId(placeId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Hotel detail not found for place: " + placeId));
        return toResponse(detail);
    }

    @Transactional
    public HotelDetailResponse create(HotelDetailRequest req) {
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
        return toResponse(hotelDetails.save(detail));
    }

    @Transactional
    public HotelDetailResponse update(Long placeId, HotelDetailRequest req) {
        Place place = placeOrThrow(placeId);
        validateHotelCategory(place);
        HotelDetail detail = hotelDetails.findByPlaceId(placeId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Hotel detail not found for place: " + placeId));
        fill(detail, req);
        return toResponse(hotelDetails.save(detail));
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
