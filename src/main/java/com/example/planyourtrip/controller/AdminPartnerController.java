package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PartnerProfileDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.PartnerProfileService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/partners")
@Tag(name = "Admin - Partner")
public class AdminPartnerController {

    private final PartnerProfileService service;

    public AdminPartnerController(PartnerProfileService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "List all partner profiles")
    public List<PartnerProfileResponse> getAll() {
        return service.adminListProfiles();
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get partner profile by ID")
    public PartnerProfileResponse getById(@PathVariable Long id) {
        return service.adminGetProfile(id);
    }

    @PostMapping("/{id}/approve")
    @Operation(summary = "Approve a submitted partner profile")
    public PartnerProfileResponse approve(@AuthUser Long uid, @PathVariable Long id) {
        return service.adminApprove(uid, id);
    }

    @PostMapping("/{id}/reject")
    @Operation(summary = "Reject a submitted partner profile")
    public PartnerProfileResponse reject(@PathVariable Long id, @RequestBody @Valid PartnerRejectRequest req) {
        return service.adminReject(id, req);
    }

    @PostMapping("/{id}/suspend")
    @Operation(summary = "Suspend an approved partner profile")
    public PartnerProfileResponse suspend(@PathVariable Long id,
                                           @RequestBody(required = false) PartnerStatusRequest req) {
        return service.adminSuspend(id, req);
    }
}
