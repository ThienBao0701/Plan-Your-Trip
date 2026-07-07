package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PartnerSettingsDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.PartnerSettingsService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/partner")
@Tag(name = "Partner - Settings", description = "Business settings, payout metadata, and team management for approved partners")
@SecurityRequirement(name = "bearerAuth")
public class PartnerSettingsController {

    private final PartnerSettingsService service;

    public PartnerSettingsController(PartnerSettingsService service) { this.service = service; }

    @GetMapping("/settings")
    @Operation(summary = "Get my partner settings (created with defaults on first access)")
    public PartnerSettingsResponse getSettings(@AuthUser Long uid) {
        return service.getSettings(uid);
    }

    @PutMapping("/settings")
    @Operation(summary = "Update business/notification settings (OWNER or MANAGER)")
    public PartnerSettingsResponse updateSettings(@AuthUser Long uid, @Valid @RequestBody PartnerSettingsRequest req) {
        return service.updateSettings(uid, req);
    }

    @GetMapping("/payout-account")
    @Operation(summary = "Get my payout account metadata (last 4 digits only)")
    public PartnerPayoutAccountResponse getPayoutAccount(@AuthUser Long uid) {
        return service.getPayoutAccount(uid);
    }

    @PutMapping("/payout-account")
    @Operation(summary = "Create or update payout account metadata (OWNER or FINANCE) — only last 4 digits are stored")
    public PartnerPayoutAccountResponse updatePayoutAccount(@AuthUser Long uid,
                                                             @Valid @RequestBody PartnerPayoutAccountRequest req) {
        return service.updatePayoutAccount(uid, req);
    }

    @GetMapping("/team")
    @Operation(summary = "List my team members")
    public List<PartnerTeamMemberResponse> getTeam(@AuthUser Long uid) {
        return service.getTeamMembers(uid);
    }

    @PostMapping("/team")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Add an existing user to my team (OWNER only)")
    public PartnerTeamMemberResponse addTeamMember(@AuthUser Long uid, @Valid @RequestBody PartnerTeamMemberRequest req) {
        return service.addTeamMember(uid, req);
    }

    @PatchMapping("/team/{id}")
    @Operation(summary = "Update a team member's role or active flag (OWNER only)")
    public PartnerTeamMemberResponse updateTeamMember(@AuthUser Long uid, @PathVariable Long id,
                                                       @Valid @RequestBody PartnerTeamMemberRequest req) {
        return service.updateTeamMember(uid, id, req);
    }

    @DeleteMapping("/team/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Remove a team member (OWNER only)")
    public void removeTeamMember(@AuthUser Long uid, @PathVariable Long id) {
        service.removeTeamMember(uid, id);
    }
}
