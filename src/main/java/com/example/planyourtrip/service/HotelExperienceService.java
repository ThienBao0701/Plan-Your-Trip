package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.HotelExperienceDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.HotelDetail;
import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class HotelExperienceService {

    private final HotelDetailRepository hotelDetails;
    private final PlaceRepository places;
    private final HotelFacilityService facilityService;
    private final HotelServiceService serviceService;

    public HotelExperienceService(HotelDetailRepository hotelDetails,
                                   PlaceRepository places,
                                   HotelFacilityService facilityService,
                                   HotelServiceService serviceService) {
        this.hotelDetails    = hotelDetails;
        this.places          = places;
        this.facilityService = facilityService;
        this.serviceService  = serviceService;
    }

    public ExperienceResponse getExperience(Long placeId) {
        HotelDetail detail = detailOrThrow(placeId);
        return buildResponse(detail);
    }

    @Transactional
    public ExperienceResponse updateExperience(Long placeId, ExperienceRequest req) {
        HotelDetail detail = detailOrThrow(placeId);

        // Replace facilities and services atomically
        facilityService.replaceAll(detail, req.facilities());
        serviceService.replaceAll(detail, req.services());

        // Update languages
        detail.getLanguages().clear();
        if (req.languages() != null) detail.getLanguages().addAll(req.languages());

        // Update payment methods
        detail.getPaymentMethods().clear();
        if (req.paymentMethods() != null) detail.getPaymentMethods().addAll(req.paymentMethods());

        // Update parking
        if (req.parking() != null) {
            detail.setParkingAvailable(req.parking().parkingAvailable());
            detail.setParkingFree(req.parking().parkingFree());
            detail.setParkingDescription(req.parking().parkingDescription());
        }

        // Update internet
        if (req.internet() != null) {
            detail.setWifiAvailable(req.internet().wifiAvailable());
            detail.setWifiFree(req.internet().wifiFree());
            detail.setInternetDescription(req.internet().internetDescription());
        }

        hotelDetails.save(detail);
        return buildResponse(detail);
    }

    private ExperienceResponse buildResponse(HotelDetail d) {
        List<FacilityResponse> facilities = facilityService.getByHotelDetail(d.getId());
        List<ServiceResponse> services    = serviceService.getByHotelDetail(d.getId());
        ParkingInfo parking = new ParkingInfo(
            d.isParkingAvailable(), d.isParkingFree(), d.getParkingDescription());
        InternetInfo internet = new InternetInfo(
            d.isWifiAvailable(), d.isWifiFree(), d.getInternetDescription());
        return new ExperienceResponse(
            facilities, services,
            List.copyOf(d.getLanguages()),
            List.copyOf(d.getPaymentMethods()),
            parking, internet
        );
    }

    private HotelDetail detailOrThrow(Long placeId) {
        places.findById(placeId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Place not found: " + placeId));
        return hotelDetails.findByPlaceId(placeId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Hotel detail not found for place: " + placeId));
    }
}
