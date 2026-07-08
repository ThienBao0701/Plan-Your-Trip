package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.CustomerProfileDto.CustomerProfileResponse;
import com.example.planyourtrip.service.CustomerProfileService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/users")
@Tag(name = "Admin - Customer Profile", description = "Read-only admin visibility into a customer's travel profile")
public class AdminCustomerProfileController {

    private final CustomerProfileService service;

    public AdminCustomerProfileController(CustomerProfileService service) { this.service = service; }

    @GetMapping("/{id}/profile")
    @Operation(summary = "Get a user's travel profile (read-only; passport is masked)")
    public CustomerProfileResponse getProfile(@PathVariable Long id) {
        return service.adminGetProfile(id);
    }
}
