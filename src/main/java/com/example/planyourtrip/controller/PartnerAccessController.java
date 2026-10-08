package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PartnerAccessDto.AccessDocument;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.PartnerAccessDocumentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/** RBAC R3b — the caller's effective partner access (RBAC V1.1 §25.2). */
@RestController
@Tag(name = "Partner - Access", description = "The caller's workspace, grants and effective permissions")
@SecurityRequirement(name = "bearerAuth")
public class PartnerAccessController {

    private final PartnerAccessDocumentService service;

    public PartnerAccessController(PartnerAccessDocumentService service) {
        this.service = service;
    }

    @GetMapping("/api/partner/me/access")
    @Operation(summary = "My workspace, grants and effective permissions (never cached)")
    public ResponseEntity<AccessDocument> myAccess(@AuthUser Long uid) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(service.accessOf(uid));
    }
}
