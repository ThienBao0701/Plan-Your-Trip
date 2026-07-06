package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PartnerProfileDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.PartnerProfileService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/partner/profile")
@Tag(name = "Partner - Profile")
public class PartnerProfileController {

    private final PartnerProfileService service;

    public PartnerProfileController(PartnerProfileService service) { this.service = service; }

    @PostMapping
    @Operation(summary = "Create or update my partner profile (draft/rejected only)")
    public PartnerProfileResponse createOrUpdate(@AuthUser Long uid, @RequestBody @Valid PartnerProfileRequest req) {
        return service.createOrUpdateMyProfile(uid, req);
    }

    @GetMapping
    @Operation(summary = "Get my partner profile")
    public PartnerProfileResponse getMine(@AuthUser Long uid) {
        return service.getMyProfile(uid);
    }

    @PostMapping("/submit")
    @Operation(summary = "Submit my partner profile for review")
    public PartnerSubmitResponse submit(@AuthUser Long uid) {
        return service.submitMyProfile(uid);
    }
}
