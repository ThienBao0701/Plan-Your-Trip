package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PartnerExtranetDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.PartnerExtranetService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/partner/extranet")
@Tag(name = "Partner - Extranet", description = "Unified partner portal home, menu, account summary and activity log")
@SecurityRequirement(name = "bearerAuth")
public class PartnerExtranetController {

    private final PartnerExtranetService service;

    public PartnerExtranetController(PartnerExtranetService service) { this.service = service; }

    @GetMapping("/home")
    @Operation(summary = "Partner portal home: profile, counts, today's activity, finance summary, quick actions")
    public PartnerExtranetHomeResponse home(@AuthUser Long uid) {
        return service.getHome(uid);
    }

    @GetMapping("/menu")
    @Operation(summary = "Partner portal navigation menu with badge counts")
    public PartnerMenuResponse menu(@AuthUser Long uid) {
        return service.getMenu(uid);
    }

    @GetMapping("/account-summary")
    @Operation(summary = "Business settings, payout account and team size summary")
    public PartnerAccountSummaryResponse accountSummary(@AuthUser Long uid) {
        return service.getAccountSummary(uid);
    }

    @GetMapping("/activity-logs")
    @Operation(summary = "My partner profile's recent activity log")
    public List<PartnerActivityLogResponse> activityLogs(@AuthUser Long uid) {
        return service.getActivityLogs(uid);
    }
}
