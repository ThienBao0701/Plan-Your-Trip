package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PartnerAccessDto.AccessDocument;
import com.example.planyourtrip.dto.PartnerInvitationDto.InvitationTokenRequest;
import com.example.planyourtrip.dto.PartnerInvitationDto.MyInvitationView;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.PartnerAccessDocumentService;
import com.example.planyourtrip.service.PartnerInvitationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * RBAC R4 — the invitee's side of partner invitations (RBAC V1.1 §14, §25.3), under {@code /api/me/**}
 * (authenticated): the service, not the URL rule, decides the outcome. The token travels in the request body,
 * never in a URL.
 */
@RestController
@RequestMapping("/api/me/partner-invitations")
@Tag(name = "Me - Partner invitations", description = "Invitations addressed to me; accept or decline")
@SecurityRequirement(name = "bearerAuth")
public class MyPartnerInvitationController {

    private final PartnerInvitationService service;
    private final PartnerAccessDocumentService accessDocuments;

    public MyPartnerInvitationController(PartnerInvitationService service, PartnerAccessDocumentService accessDocuments) {
        this.service = service;
        this.accessDocuments = accessDocuments;
    }

    @GetMapping
    @Operation(summary = "Pending invitations addressed to my own email (verified Partner accounts)")
    public List<MyInvitationView> mine(@AuthUser Long uid) {
        return service.mine(uid);
    }

    @PostMapping("/accept")
    @Operation(summary = "Accept an invitation; returns my new access document")
    public ResponseEntity<AccessDocument> accept(@AuthUser Long uid, @Valid @RequestBody InvitationTokenRequest req) {
        service.accept(uid, req.token());
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(accessDocuments.accessOf(uid));
    }

    @PostMapping("/decline")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Decline an invitation (anyone holding its link)")
    public void decline(@AuthUser Long uid, @Valid @RequestBody InvitationTokenRequest req) {
        service.decline(uid, req.token());
    }
}
