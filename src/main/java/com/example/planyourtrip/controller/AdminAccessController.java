package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.AdminAccessDto.AdminAccessResponse;
import com.example.planyourtrip.dto.AdminAccessDto.AdminAccountResponse;
import com.example.planyourtrip.dto.AdminAccessDto.ReplaceProfilesRequest;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.AdminProfileService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * RBAC R6 — admin access (RBAC V1.1 §25.4). Every handler is authorized by the endpoint registry: the access
 * document needs A01 {@code admin.console.access}; the list and the change need A02 {@code admin.access.manage},
 * which only {@code PLATFORM_OWNER} holds, and the change also needs a fresh session (step-up).
 */
@RestController
@RequestMapping("/api/admin")
@Tag(name = "Admin - Access", description = "Admin profiles and the caller's admin access document")
@SecurityRequirement(name = "bearerAuth")
public class AdminAccessController {

    private final AdminProfileService service;

    public AdminAccessController(AdminProfileService service) {
        this.service = service;
    }

    @GetMapping("/me/access")
    @Operation(summary = "The caller's admin profiles and admin permissions")
    public AdminAccessResponse myAccess(@AuthUser Long uid, Authentication authentication) {
        return service.accessOf(uid, authentication);
    }

    @GetMapping("/access/admins")
    @Operation(summary = "Every administrator and the admin profiles they hold (PLATFORM_OWNER)")
    public List<AdminAccountResponse> admins(@AuthUser Long uid) {
        return service.listAdmins(uid);
    }

    @PutMapping("/access/admins/{userId}/profiles")
    @Operation(summary = "Replace an administrator's admin profiles (PLATFORM_OWNER, fresh session)")
    public AdminAccountResponse replaceProfiles(@AuthUser Long uid, @PathVariable Long userId,
                                                @Valid @RequestBody ReplaceProfilesRequest request) {
        return service.replaceProfiles(uid, userId, request);
    }
}
