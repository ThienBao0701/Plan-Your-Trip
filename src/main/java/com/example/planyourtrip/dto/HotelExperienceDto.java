package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.FacilityGroup;
import jakarta.validation.constraints.NotBlank;

import java.util.List;

public class HotelExperienceDto {

    public record FacilityRequest(
        @NotBlank String facilityName,
        FacilityGroup facilityGroup,
        String icon,
        int sortOrder
    ) {}

    public record ServiceRequest(
        @NotBlank String serviceName,
        String icon,
        boolean available
    ) {}

    public record ParkingInfo(
        boolean parkingAvailable,
        boolean parkingFree,
        String parkingDescription
    ) {}

    public record InternetInfo(
        boolean wifiAvailable,
        boolean wifiFree,
        String internetDescription
    ) {}

    public record ExperienceRequest(
        List<FacilityRequest> facilities,
        List<ServiceRequest> services,
        List<String> languages,
        List<String> paymentMethods,
        ParkingInfo parking,
        InternetInfo internet
    ) {}

    public record FacilityResponse(
        Long id,
        String facilityName,
        FacilityGroup facilityGroup,
        String icon,
        int sortOrder
    ) {}

    public record ServiceResponse(
        Long id,
        String serviceName,
        String icon,
        boolean available
    ) {}

    public record ExperienceResponse(
        List<FacilityResponse> facilities,
        List<ServiceResponse> services,
        List<String> languages,
        List<String> paymentMethods,
        ParkingInfo parking,
        InternetInfo internet
    ) {}
}
