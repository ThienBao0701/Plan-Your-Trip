package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.CustomerProfileDto.CustomerProfileRequest;
import com.example.planyourtrip.dto.CustomerProfileDto.CustomerProfileResponse;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.CustomerProfileService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/me/profile")
@Tag(name = "Customer - Travel Profile", description = "Booking/loyalty/recommendation profile, distinct from the User identity")
@SecurityRequirement(name = "bearerAuth")
public class CustomerProfileController {

    private final CustomerProfileService service;

    public CustomerProfileController(CustomerProfileService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "Get my travel profile (created with defaults on first access)")
    public CustomerProfileResponse get(@AuthUser Long uid) {
        return service.getMyProfile(uid);
    }

    @PutMapping
    @Operation(summary = "Update my travel profile")
    public CustomerProfileResponse update(@AuthUser Long uid, @RequestBody CustomerProfileRequest req) {
        return service.updateMyProfile(uid, req);
    }
}
