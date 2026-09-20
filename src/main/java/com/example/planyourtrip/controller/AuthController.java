package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.AuthDtos.*;
import com.example.planyourtrip.service.AccountService;
import com.example.planyourtrip.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;

/**
 * Public authentication endpoints ({@code /api/auth/**} is permitAll in SecurityConfig).
 *
 * <p>Phase A added Partner registration, email verification and password reset. Resend-verification
 * and forgot-password always answer 202 with the same body, so they cannot be used to discover accounts.
 */
@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private final AuthService auth;
    private final AccountService accounts;

    public AuthController(AuthService auth, AccountService accounts) {
        this.auth = auth;
        this.accounts = accounts;
    }

    private static final String RESEND_ACK =
        "If that address has an account waiting for verification, a new link is on its way.";
    private static final String FORGOT_ACK =
        "If that address has an account, a password reset link is on its way.";

    @PostMapping("/register")
    ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest r) {
        return ResponseEntity.status(201).body(auth.register(r));
    }

    @PostMapping("/login")
    AuthResponse login(@Valid @RequestBody LoginRequest r) {
        return auth.login(r);
    }

    /** Creates a PARTNER account pending email verification. Returns no session. */
    @PostMapping("/partner/register")
    ResponseEntity<PartnerRegistrationResponse> registerPartner(@Valid @RequestBody PartnerRegisterRequest r) {
        return ResponseEntity.status(201).body(auth.registerPartner(r));
    }

    @PostMapping("/verify-email")
    VerifyEmailResponse verifyEmail(@Valid @RequestBody VerifyEmailRequest r) {
        return accounts.verifyEmail(r.token());
    }

    @PostMapping("/resend-verification")
    ResponseEntity<MessageResponse> resendVerification(@Valid @RequestBody EmailRequest r) {
        accounts.resendVerification(r.email());
        return ResponseEntity.status(HttpStatus.ACCEPTED).body(new MessageResponse(RESEND_ACK));
    }

    @PostMapping("/forgot-password")
    ResponseEntity<MessageResponse> forgotPassword(@Valid @RequestBody EmailRequest r) {
        accounts.forgotPassword(r.email());
        return ResponseEntity.status(HttpStatus.ACCEPTED).body(new MessageResponse(FORGOT_ACK));
    }

    @PostMapping("/reset-password")
    MessageResponse resetPassword(@Valid @RequestBody ResetPasswordRequest r) {
        accounts.resetPassword(r.token(), r.newPassword());
        return new MessageResponse("Your password has been reset. You can now sign in.");
    }
}
