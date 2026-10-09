package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.HotelDetailDto.HotelDetailRequest;
import com.example.planyourtrip.dto.HotelDetailDto.HotelDetailResponse;
import com.example.planyourtrip.dto.HotelExperienceDto.ExperienceRequest;
import com.example.planyourtrip.dto.HotelExperienceDto.ExperienceResponse;
import com.example.planyourtrip.dto.PartnerHotelDto.AssignOwnerRequest;
import com.example.planyourtrip.dto.AdminDualControlDto.DualControlRequestResponse;
import com.example.planyourtrip.service.AdminDualControlService;
import com.example.planyourtrip.service.HotelDetailService;
import com.example.planyourtrip.service.HotelExperienceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import com.example.planyourtrip.security.AuthUser;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/hotels")
@Tag(name = "Admin - Hotels", description = "Admin hotel detail management")
@SecurityRequirement(name = "bearerAuth")
public class AdminHotelController {

    private final HotelDetailService service;
    private final HotelExperienceService experienceService;
    private final AdminDualControlService dualControl;

    public AdminHotelController(HotelDetailService service,
                                 HotelExperienceService experienceService,
                                 AdminDualControlService dualControl) {
        this.service           = service;
        this.experienceService = experienceService;
        this.dualControl       = dualControl;
    }

    @GetMapping("/{placeId}")
    @Operation(summary = "Get hotel detail by place ID")
    public HotelDetailResponse get(@PathVariable Long placeId) {
        return service.get(placeId);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create hotel detail (placeId required in body)")
    public HotelDetailResponse create(@Valid @RequestBody HotelDetailRequest req,
                                      @AuthUser Long adminId) {
        return service.create(req, adminId);
    }

    @PutMapping("/{placeId}")
    @Operation(summary = "Update hotel detail")
    public HotelDetailResponse update(
            @PathVariable Long placeId,
            @Valid @RequestBody HotelDetailRequest req,
            @AuthUser Long adminId) {
        return service.update(placeId, req, adminId);
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
            @RequestBody ExperienceRequest req,
            @AuthUser Long adminId) {
        return experienceService.updateExperience(placeId, req, adminId);
    }

    /**
     * RBAC R6 — A16 is dual-controlled (§22.6): this submits a request (202) that a second platform owner approves
     * at {@code POST /api/admin/dual-control/requests/{id}/approve}; nothing moves until then.
     */
    @PostMapping("/{hotelId}/assign-owner")
    @ResponseStatus(HttpStatus.ACCEPTED)
    @Operation(summary = "Request moving a hotel to a partner profile (dual control: a second admin approves)")
    public DualControlRequestResponse assignOwner(
            @AuthUser Long uid,
            @PathVariable Long hotelId,
            @Valid @RequestBody AssignOwnerRequest req) {
        return dualControl.submit(uid, hotelId, req);
    }
}
