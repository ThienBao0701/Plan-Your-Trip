package com.example.planyourtrip.dto;

import com.example.planyourtrip.util.AccountEmails;
import com.example.planyourtrip.validation.AccountPassword;
import jakarta.validation.constraints.*;

/**
 * Authentication and account-lifecycle request/response shapes.
 *
 * <p>Phase A: request records trim their free-text fields in the canonical constructor, so
 * validation, duplicate detection and persistence all see the same value. None of them carries a
 * role — the role of a new account is decided by which endpoint created it, never by the body.
 */
public class AuthDtos {

    /** Longest display name accepted for an account. */
    public static final int FULL_NAME_MAX = 120;

    /** Longest one-time token accepted from a client (issued tokens are 43 characters). */
    public static final int TOKEN_MAX = 128;

    /** Traveller self-registration. Creates a USER account. */
    public record RegisterRequest(
        @NotBlank @Size(max = FULL_NAME_MAX) String fullName,
        @NotBlank @Email @Size(max = AccountEmails.MAX_LENGTH) String email,
        @AccountPassword String password
    ) {
        public RegisterRequest {
            fullName = AccountEmails.trim(fullName);
            email = AccountEmails.trim(email);
        }
    }

    /**
     * Partner self-registration. Creates a PARTNER account that must verify its email before it can
     * sign in. {@code acceptTerms} must be explicitly {@code true}; absent or false is refused.
     */
    public record PartnerRegisterRequest(
        @NotBlank @Size(max = FULL_NAME_MAX) String fullName,
        @NotBlank @Email @Size(max = AccountEmails.MAX_LENGTH) String email,
        @AccountPassword String password,
        @NotNull @AssertTrue(message = "must be accepted") Boolean acceptTerms
    ) {
        public PartnerRegisterRequest {
            fullName = AccountEmails.trim(fullName);
            email = AccountEmails.trim(email);
        }
    }

    public record LoginRequest(
        @NotBlank @Email @Size(max = AccountEmails.MAX_LENGTH) String email,
        @NotBlank String password
    ) {
        public LoginRequest {
            email = AccountEmails.trim(email);
        }
    }

    /** Body of the requests that act on an address: resend verification, forgot password. */
    public record EmailRequest(
        @NotBlank @Email @Size(max = AccountEmails.MAX_LENGTH) String email
    ) {
        public EmailRequest {
            email = AccountEmails.trim(email);
        }
    }

    public record VerifyEmailRequest(
        @NotBlank @Size(max = TOKEN_MAX) String token
    ) {}

    public record ResetPasswordRequest(
        @NotBlank @Size(max = TOKEN_MAX) String token,
        @AccountPassword String newPassword
    ) {}

    /** The signed-in account changes its own password; identity comes from the session, never the body. */
    public record ChangePasswordRequest(
        @NotBlank String currentPassword,
        @AccountPassword String newPassword
    ) {}

    public record UserDto(Long id, String fullName, String email, String role) {}

    public record AuthResponse(String token, UserDto user) {}

    /** RBAC R3a — {@code POST /api/me/step-up}: the account's current password, nothing else. */
    public record StepUpRequest(@NotBlank String currentPassword) {}

    /** Partner registration never returns a session: the account cannot sign in until verified. */
    public record PartnerRegistrationResponse(String email, String status, boolean verificationRequired,
                                              String message) {}

    /** {@code status} is {@code VERIFIED} or {@code ALREADY_VERIFIED}. */
    public record VerifyEmailResponse(String status, String message) {}

    /** A deliberately uninformative acknowledgement for requests that must not reveal whether an account exists. */
    public record MessageResponse(String message) {}
}
