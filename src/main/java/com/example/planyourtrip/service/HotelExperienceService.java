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
    private final AdminActivityLogService adminAudit;

    public HotelExperienceService(HotelDetailRepository hotelDetails,
                                   PlaceRepository places,
                                   HotelFacilityService facilityService,
                                   HotelServiceService serviceService,
                                   AdminActivityLogService adminAudit) {
        this.hotelDetails    = hotelDetails;
        this.places          = places;
        this.facilityService = facilityService;
        this.serviceService  = serviceService;
        this.adminAudit      = adminAudit;
    }

    public ExperienceResponse getExperience(Long placeId) {
        HotelDetail detail = detailOrThrow(placeId);
        return buildResponse(detail);
    }

    /**
     * D3G — audited inline for the same reason as {@code HotelDetailService}: this service has
     * exactly one injector, {@code AdminHotelController}, so there is no non-admin path that could
     * be filed as an administrative action.
     *
     * <p>The trail records a <b>shape summary</b>, not the payload. The request carries facility
     * and service lists whose entries are free-form names and icons, plus free-text parking and
     * internet descriptions; copying them would put an uncontrolled, operator-supplied blob into
     * permanent storage. Counts and the two availability flags are what an operator actually needs
     * later — "the experience block was replaced, and it went from 8 facilities to 3".
     */
    @Transactional
    public ExperienceResponse updateExperience(Long placeId, ExperienceRequest req, Long adminId) {
        HotelDetail detail = detailOrThrow(placeId);
        // Read before anything is replaced: facilities and services are rewritten below, and the
        // language and payment collections are cleared in place.
        String before = summarise(
            facilityService.getByHotelDetail(detail.getId()).size(),
            serviceService.getByHotelDetail(detail.getId()).size(),
            detail.getLanguages().size(), detail.getPaymentMethods().size(),
            detail.isParkingAvailable(), detail.isWifiAvailable());

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
        ExperienceResponse response = buildResponse(detail);
        adminAudit.record(adminId, "HOTEL_EXPERIENCE_UPDATE", "PLACE", placeId,
            "Admin replaced the hotel experience block for place " + placeId,
            before,
            summarise(response.facilities().size(), response.services().size(),
                      response.languages().size(), response.paymentMethods().size(),
                      response.parking().parkingAvailable(),
                      response.internet().wifiAvailable()));
        return response;
    }

    /** Counts and flags only — never a facility name, an icon, or a free-text description. */
    private static String summarise(int facilities, int services, int languages, int payments,
                                     boolean parking, boolean wifi) {
        return "facilities:" + facilities
            + " services:" + services
            + " languages:" + languages
            + " payments:" + payments
            + " parking:" + parking
            + " wifi:" + wifi;
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
