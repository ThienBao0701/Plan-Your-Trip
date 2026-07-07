package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PartnerExtranetDto.AdminPartnerDetailResponse;
import com.example.planyourtrip.dto.PartnerExtranetDto.PartnerActivityLogResponse;
import com.example.planyourtrip.dto.PartnerProfileDto.*;
import com.example.planyourtrip.dto.PartnerSettingsDto.PartnerSettingsResponse;
import com.example.planyourtrip.dto.PartnerSettingsDto.PartnerTeamMemberResponse;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.PartnerActivityLogService;
import com.example.planyourtrip.service.PartnerExtranetService;
import com.example.planyourtrip.service.PartnerProfileService;
import com.example.planyourtrip.service.PartnerSettingsService;
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
    private final PartnerExtranetService extranetService;
    private final PartnerSettingsService settingsService;
    private final PartnerActivityLogService activityLogService;

    public AdminPartnerController(PartnerProfileService service,
                                   PartnerExtranetService extranetService,
                                   PartnerSettingsService settingsService,
                                   PartnerActivityLogService activityLogService) {
        this.service = service;
        this.extranetService = extranetService;
        this.settingsService = settingsService;
        this.activityLogService = activityLogService;
    }

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

    @GetMapping("/{id}/detail")
    @Operation(summary = "Aggregated partner detail: hotel/team counts, payout status")
    public AdminPartnerDetailResponse detail(@PathVariable Long id) {
        return extranetService.adminGetDetail(id);
    }

    @GetMapping("/{id}/team")
    @Operation(summary = "List a partner's team members")
    public List<PartnerTeamMemberResponse> team(@PathVariable Long id) {
        return settingsService.adminGetTeamMembers(id);
    }

    @GetMapping("/{id}/settings")
    @Operation(summary = "Get a partner's business/notification settings")
    public PartnerSettingsResponse settings(@PathVariable Long id) {
        return settingsService.adminGetSettings(id);
    }

    @GetMapping("/{id}/activity-logs")
    @Operation(summary = "List a partner's activity log")
    public List<PartnerActivityLogResponse> activityLogs(@PathVariable Long id) {
        return activityLogService.adminListByPartner(id);
    }
}
