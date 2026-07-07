package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PartnerHotelDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.PartnerPropertyService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/partner/hotels")
@Tag(name = "Partner - Hotels", description = "Approved partners manage the hotels they own")
@SecurityRequirement(name = "bearerAuth")
public class PartnerHotelController {

    private final PartnerPropertyService service;

    public PartnerHotelController(PartnerPropertyService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "List my hotels")
    public List<PartnerHotelSummaryResponse> getMyHotels(@AuthUser Long uid) {
        return service.getMyHotels(uid);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get one of my hotels")
    public PartnerHotelResponse getHotel(@AuthUser Long uid, @PathVariable Long id) {
        return service.getHotel(uid, id);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update basic information (name, descriptions, slug)")
    public PartnerHotelResponse updateBasicInformation(@AuthUser Long uid, @PathVariable Long id,
                                                         @Valid @RequestBody PartnerHotelUpdateRequest req) {
        return service.updateBasicInformation(uid, id, req);
    }

    @PutMapping("/{id}/contact")
    @Operation(summary = "Update contact information")
    public PartnerHotelResponse updateContact(@AuthUser Long uid, @PathVariable Long id,
                                               @Valid @RequestBody PartnerContactRequest req) {
        return service.updateContact(uid, id, req);
    }

    @PutMapping("/{id}/policies")
    @Operation(summary = "Update check-in/out and hotel policies")
    public PartnerHotelResponse updatePolicies(@AuthUser Long uid, @PathVariable Long id,
                                                @Valid @RequestBody PartnerPolicyRequest req) {
        return service.updatePolicies(uid, id, req);
    }

    @PutMapping("/{id}/location")
    @Operation(summary = "Update coordinates and address")
    public PartnerHotelResponse updateLocation(@AuthUser Long uid, @PathVariable Long id,
                                                @Valid @RequestBody PartnerLocationRequest req) {
        return service.updateCoordinates(uid, id, req);
    }

    @PatchMapping("/{id}/activate")
    @Operation(summary = "Activate my hotel listing")
    public PartnerHotelResponse activate(@AuthUser Long uid, @PathVariable Long id) {
        return service.activate(uid, id);
    }

    @PatchMapping("/{id}/deactivate")
    @Operation(summary = "Deactivate my hotel listing")
    public PartnerHotelResponse deactivate(@AuthUser Long uid, @PathVariable Long id) {
        return service.deactivate(uid, id);
    }
}
