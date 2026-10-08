package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PartnerInvitationDto.InvitationRequestResult;
import com.example.planyourtrip.dto.PartnerSettingsDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.PartnerInvitationService;
import com.example.planyourtrip.service.PartnerSettingsService;
import com.example.planyourtrip.service.PartnerTeamService;
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
    private final PartnerTeamService teamService;
    private final PartnerInvitationService invitationService;

    public PartnerSettingsController(PartnerSettingsService service, PartnerTeamService teamService,
                                     PartnerInvitationService invitationService) {
        this.service = service;
        this.teamService = teamService;
        this.invitationService = invitationService;
    }

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
    @Operation(summary = "List my team members with their status and grants")
    public List<PartnerTeamMemberResponse> getTeam(@AuthUser Long uid) {
        return teamService.list(uid);
    }

    /**
     * RBAC R4 (§29): no longer attaches accounts directly — an alias of {@code POST /api/partner/team/invitations}
     * with {@code role} at company scope. 202 with the uniform invitation body; {@code active} is ignored.
     */
    @PostMapping("/team")
    @ResponseStatus(HttpStatus.ACCEPTED)
    @Operation(summary = "Invite an address to my team with a company-wide role (alias of POST /team/invitations)")
    public InvitationRequestResult addTeamMember(@AuthUser Long uid, @Valid @RequestBody PartnerTeamMemberRequest req) {
        return invitationService.inviteLegacy(uid, req);
    }

    @PatchMapping("/team/{id}")
    @Operation(summary = "Update a team member's role or active flag (within delegated authority; owner changes need step-up)")
    public PartnerTeamMemberResponse updateTeamMember(@AuthUser Long uid, @PathVariable Long id,
                                                       @Valid @RequestBody PartnerTeamMemberRequest req) {
        return teamService.updateLegacy(uid, id, req);
    }

    @PutMapping("/team/{id}/grants")
    @Operation(summary = "Replace a team member's grants (within delegated authority; owner changes need step-up)")
    public PartnerTeamMemberResponse replaceGrants(@AuthUser Long uid, @PathVariable Long id,
                                                   @Valid @RequestBody PartnerTeamGrantsRequest req) {
        return teamService.replaceGrants(uid, id, req);
    }

    @PostMapping("/team/{id}/suspend")
    @Operation(summary = "Suspend a team member (within delegated authority)")
    public PartnerTeamMemberResponse suspendTeamMember(@AuthUser Long uid, @PathVariable Long id,
                                                       @Valid @RequestBody(required = false) PartnerTeamReasonRequest req) {
        return teamService.suspend(uid, id, req == null ? null : req.reason());
    }

    @PostMapping("/team/{id}/reactivate")
    @Operation(summary = "Reactivate a suspended team member (within delegated authority)")
    public PartnerTeamMemberResponse reactivateTeamMember(@AuthUser Long uid, @PathVariable Long id) {
        return teamService.reactivate(uid, id);
    }

    @DeleteMapping("/team/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Remove a team member: the membership is revoked and kept for history (within delegated authority)")
    public void removeTeamMember(@AuthUser Long uid, @PathVariable Long id,
                                 @Valid @RequestBody(required = false) PartnerTeamReasonRequest req) {
        teamService.remove(uid, id, req == null ? null : req.reason());
    }

    @PostMapping("/team/leave")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Leave the team I belong to (not available to the primary owner)")
    public void leaveTeam(@AuthUser Long uid) {
        teamService.leave(uid);
    }
}
