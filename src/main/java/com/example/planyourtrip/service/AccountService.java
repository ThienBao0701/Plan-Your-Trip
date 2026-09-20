package com.example.planyourtrip.service;

import com.example.planyourtrip.config.AuthProperties;
import com.example.planyourtrip.dto.AuthDtos.VerifyEmailResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.AccountRole;
import com.example.planyourtrip.model.AuthTokenPurpose;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.service.mail.AccountEmail;
import com.example.planyourtrip.service.mail.EmailSender;
import com.example.planyourtrip.util.AccountEmails;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;

/**
 * Phase A — email verification and password reset, the two account flows driven by a one-time link.
 *
 * <p><b>No enumeration.</b> Resend-verification and forgot-password answer the same way whether or not
 * the address has an account, whether or not a token was actually issued (cooldown), and whether or not
 * the account is eligible. The only distinguishable outcome is 503 when email delivery is unavailable,
 * which is decided before the address is even looked up.
 *
 * <p><b>Links.</b> The link goes to the surface that matches the account's role
 * ({@code app.auth.*-app-url}) with the token in the URL fragment ({@code #token=}), so it is not sent
 * to any server in a request line or a Referer header. The receiving pages arrive in Phase B; until
 * then the token can be posted to the endpoints directly.
 */
@Service
public class AccountService {

    private final UserRepository users;
    private final AuthTokenService tokens;
    private final EmailSender emailSender;
    private final PasswordEncoder encoder;
    private final AdminActivityLogService adminAudit;
    private final AuthProperties properties;
    private final Clock clock;

    public AccountService(UserRepository users, AuthTokenService tokens, EmailSender emailSender,
                          PasswordEncoder encoder, AdminActivityLogService adminAudit,
                          AuthProperties properties, Clock clock) {
        this.users = users;
        this.tokens = tokens;
        this.emailSender = emailSender;
        this.encoder = encoder;
        this.adminAudit = adminAudit;
        this.properties = properties;
        this.clock = clock;
    }

    /** 503 {@code EMAIL_DELIVERY_UNAVAILABLE} when no email can be sent. Call before creating anything. */
    public void requireEmailDelivery() {
        if (!emailSender.isAvailable()) {
            throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "EMAIL_DELIVERY_UNAVAILABLE",
                "Email delivery is not available right now. Please try again later.");
        }
    }

    /** Issues and sends a verification link for a newly registered account (no cooldown applies to a new account). */
    @Transactional
    public void sendVerification(User user) {
        tokens.issue(user, AuthTokenPurpose.EMAIL_VERIFICATION, properties.getVerificationTokenTtl())
            .ifPresent(t -> send(user, AccountEmail.Kind.EMAIL_VERIFICATION, "/verify-email", t.rawToken()));
    }

    /**
     * Sends a new verification link when the address belongs to an enabled account that is still
     * waiting for verification and the cooldown has passed. Otherwise does nothing — silently.
     */
    @Transactional
    public void resendVerification(String email) {
        requireEmailDelivery();
        users.findByEmail(AccountEmails.normalize(email))
            .filter(User::isEnabled)
            .filter(u -> AccountRole.parse(u.getRole()).isPresent())
            .filter(u -> u.isEmailVerificationRequired() && u.getEmailVerifiedAt() == null)
            .ifPresent(this::sendVerification);
    }

    @Transactional
    public VerifyEmailResponse verifyEmail(String rawToken) {
        User user = tokens.consume(rawToken, AuthTokenPurpose.EMAIL_VERIFICATION);
        if (user.getEmailVerifiedAt() != null) {
            return new VerifyEmailResponse("ALREADY_VERIFIED", "This email address is already verified.");
        }
        user.setEmailVerifiedAt(clock.instant());
        users.save(user);
        return new VerifyEmailResponse("VERIFIED", "Your email address is verified. You can now sign in.");
    }

    /**
     * Sends a password reset link when the address belongs to an enabled account with a recognised
     * role and the cooldown has passed. Otherwise does nothing — silently.
     */
    @Transactional
    public void forgotPassword(String email) {
        requireEmailDelivery();
        users.findByEmail(AccountEmails.normalize(email))
            .filter(User::isEnabled)
            .filter(u -> AccountRole.parse(u.getRole()).isPresent())
            .ifPresent(u -> tokens.issue(u, AuthTokenPurpose.PASSWORD_RESET, properties.getPasswordResetTokenTtl())
                .ifPresent(t -> send(u, AccountEmail.Kind.PASSWORD_RESET, "/reset-password", t.rawToken())));
    }

    /**
     * Sets a new password from a reset link. Every existing session of the account ends (token version
     * bump). An Admin reset is audited without any credential material.
     */
    @Transactional
    public void resetPassword(String rawToken, String newPassword) {
        User user = tokens.consume(rawToken, AuthTokenPurpose.PASSWORD_RESET);
        user.setPasswordHash(encoder.encode(newPassword));
        user.setTokenVersion(user.getTokenVersion() + 1);
        users.save(user);
        if (AccountRole.parse(user.getRole()).filter(r -> r == AccountRole.ADMIN).isPresent()) {
            adminAudit.record(user.getId(), "ADMIN_PASSWORD_RESET", "USER", user.getId(),
                "Admin reset their sign-in credentials by email link; other sessions ended");
        }
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    private void send(User user, AccountEmail.Kind kind, String path, String rawToken) {
        emailSender.send(new AccountEmail(user.getEmail(), kind, linkFor(user, path, rawToken)));
    }

    /** Callers only reach this for a recognised role; an unrecognised one is never mapped onto a surface. */
    private String linkFor(User user, String path, String rawToken) {
        AccountRole role = AccountRole.parse(user.getRole())
            .orElseThrow(() -> new IllegalStateException("No application surface for this account's role"));
        String origin = switch (role) {
            case PARTNER -> properties.getPartnerAppUrl();
            case ADMIN -> properties.getAdminAppUrl();
            case USER -> properties.getUserAppUrl();
        };
        String base = origin.endsWith("/") ? origin.substring(0, origin.length() - 1) : origin;
        return base + path + "#token=" + rawToken;
    }
}
