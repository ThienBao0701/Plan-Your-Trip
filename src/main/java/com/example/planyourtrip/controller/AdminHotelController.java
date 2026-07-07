package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.HotelDetailDto.HotelDetailRequest;
import com.example.planyourtrip.dto.HotelDetailDto.HotelDetailResponse;
import com.example.planyourtrip.dto.HotelExperienceDto.ExperienceRequest;
import com.example.planyourtrip.dto.HotelExperienceDto.ExperienceResponse;
import com.example.planyourtrip.dto.PartnerHotelDto.AssignOwnerRequest;
import com.example.planyourtrip.dto.PartnerHotelDto.PartnerHotelResponse;
import com.example.planyourtrip.service.HotelDetailService;
import com.example.planyourtrip.service.HotelExperienceService;
import com.example.planyourtrip.service.PartnerPropertyService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/hotels")
@Tag(name = "Admin - Hotels", description = "Admin hotel detail management")
@SecurityRequirement(name = "bearerAuth")
public class AdminHotelController {

    private final HotelDetailService service;
    private final HotelExperienceService experienceService;
    private final PartnerPropertyService partnerPropertyService;

    public AdminHotelController(HotelDetailService service,
                                 HotelExperienceService experienceService,
                                 PartnerPropertyService partnerPropertyService) {
        this.service                = service;
        this.experienceService      = experienceService;
        this.partnerPropertyService = partnerPropertyService;
    }

    @GetMapping("/{placeId}")
    @Operation(summary = "Get hotel detail by place ID")
    public HotelDetailResponse get(@PathVariable Long placeId) {
        return service.get(placeId);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create hotel detail (placeId required in body)")
    public HotelDetailResponse create(@Valid @RequestBody HotelDetailRequest req) {
        return service.create(req);
    }

    @PutMapping("/{placeId}")
    @Operation(summary = "Update hotel detail")
    public HotelDetailResponse update(
            @PathVariable Long placeId,
            @Valid @RequestBody HotelDetailRequest req) {
        return service.update(placeId, req);
    }

    @GetMapping("/{placeId}/experience")
    @Operation(summary = "Get hotel experience (facilities, services, languages, payments, parking, internet)")
    public ExperienceResponse getExperience(@PathVariable Long placeId) {
        return experienceService.getExperience(placeId);
    }

    @PutMapping("/{placeId}/experience")
    @Operation(summary = "Atomically replace hotel experience data")
    public ExperienceResponse updateExperience(
            @PathVariable Long placeId,
            @RequestBody ExperienceRequest req) {
        return experienceService.updateExperience(placeId, req);
    }

    @PostMapping("/{hotelId}/assign-owner")
    @Operation(summary = "Assign a hotel to a partner profile")
    public PartnerHotelResponse assignOwner(
            @PathVariable Long hotelId,
            @Valid @RequestBody AssignOwnerRequest req) {
        return partnerPropertyService.assignOwner(hotelId, req);
    }
}
