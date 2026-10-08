package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PartnerInvitationDto.InvitationRequest;
import com.example.planyourtrip.dto.PartnerInvitationDto.InvitationRequestResult;
import com.example.planyourtrip.dto.PartnerInvitationDto.InvitationView;
import com.example.planyourtrip.dto.PartnerSettingsDto.PartnerTeamReasonRequest;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.PartnerInvitationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** RBAC R4 — team invitations (RBAC V1.1 §13, §25.3). Responses never carry an invitation token. */
@RestController
@RequestMapping("/api/partner/team/invitations")
@Tag(name = "Partner - Team invitations", description = "Invite, resend and revoke team invitations")
@SecurityRequirement(name = "bearerAuth")
public class PartnerInvitationController {

    private final PartnerInvitationService service;

    public PartnerInvitationController(PartnerInvitationService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "List the team's invitations within my team view")
    public List<InvitationView> list(@AuthUser Long uid) {
        return service.list(uid);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.ACCEPTED)
    @Operation(summary = "Invite an address with grants (202, same answer for every address)")
    public InvitationRequestResult invite(@AuthUser Long uid, @Valid @RequestBody InvitationRequest req) {
        return service.invite(uid, req);
    }

    @PostMapping("/{id}/resend")
    @ResponseStatus(HttpStatus.ACCEPTED)
    @Operation(summary = "Resend an invitation with a new link (the previous link stops working)")
    public InvitationRequestResult resend(@AuthUser Long uid, @PathVariable Long id) {
        return service.resend(uid, id);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Revoke a pending invitation")
    public void revoke(@AuthUser Long uid, @PathVariable Long id,
                       @Valid @RequestBody(required = false) PartnerTeamReasonRequest req) {
        service.revoke(uid, id, req == null ? null : req.reason());
    }
}
