package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.AuthDtos.AuthResponse;
import com.example.planyourtrip.dto.AuthDtos.ChangePasswordRequest;
import com.example.planyourtrip.dto.AuthDtos.StepUpRequest;
import com.example.planyourtrip.dto.AuthDtos.UserDto;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.AuthService;
import com.example.planyourtrip.service.UserService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

@RestController
public class UserController {
    private final UserService userService;
    private final AuthService authService;

    public UserController(UserService userService, AuthService authService) {
        this.userService = userService;
        this.authService = authService;
    }

    @GetMapping("/api/me")
    public UserDto me(@AuthUser Long userId) {
        return userService.getCurrentUser(userId);
    }

    /**
     * Phase A — the signed-in account changes its own password. The account is the session's; the body
     * carries no id. Other sessions end; the response carries a new token for this one.
     */
    @PutMapping("/api/me/password")
    public AuthResponse changePassword(@AuthUser Long userId, @Valid @RequestBody ChangePasswordRequest req) {
        return authService.changePassword(userId, req);
    }

    /**
     * RBAC R3a — step-up (§25.6): re-enter the password to obtain a fresh token for owner-level actions. The
     * previous token stays valid; no session ends.
     */
    @PostMapping("/api/me/step-up")
    public AuthResponse stepUp(@AuthUser Long userId, @Valid @RequestBody StepUpRequest req) {
        return authService.stepUp(userId, req);
    }
}
