package com.example.planyourtrip.service;

import com.example.planyourtrip.config.AuthProperties;
import com.example.planyourtrip.dto.AuthDtos.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.AccountRole;
import com.example.planyourtrip.model.AuthTokenPurpose;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.security.JwtService;
import com.example.planyourtrip.security.StepUpPolicy;
import com.example.planyourtrip.security.StepUpRateLimiter;
import com.example.planyourtrip.util.AccountEmails;
import com.example.planyourtrip.validation.AccountPasswordValidator;
import org.hibernate.exception.ConstraintViolationException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;

/**
 * Registration, sign-in and password change.
 *
 * <p>Phase A:
 * <ul>
 *   <li><b>Roles are decided here, never by the request.</b> {@link #register} always creates USER and
 *       {@link #registerPartner} always creates PARTNER; request bodies have no role field and unknown
 *       JSON properties are ignored.</li>
 *   <li><b>Sign-in is refused</b> — after the password has been checked, so none of this is revealed to
 *       someone without it — for a disabled account (403 {@code ACCOUNT_DISABLED}), a stored role that
 *       is not exactly USER/PARTNER/ADMIN (403 {@code ACCOUNT_UNAVAILABLE}) and a self-registered
 *       Partner that has not verified its email (403 {@code EMAIL_NOT_VERIFIED}). A wrong password and
 *       an unknown email both stay the same generic 401.</li>
 *   <li><b>Admin sign-in is audited</b> through {@link AdminActivityLogService}: success, and failure
 *       only when the address belongs to an ADMIN account — an unknown address is never recorded.
 *       This method is deliberately not transactional, so each audit row commits on its own and a
 *       refused sign-in still leaves its trace.</li>
 * </ul>
 */
@Service
public class AuthService {
    private final UserRepository users;
    private final PasswordEncoder encoder;
    private final JwtService jwt;
    private final AccountService accounts;
    private final AuthTokenService tokens;
    private final AdminActivityLogService adminAudit;
    private final AuthProperties properties;
    private final Clock clock;
    private final StepUpRateLimiter stepUpLimiter;

    public AuthService(UserRepository users, PasswordEncoder encoder, JwtService jwt,
                       AccountService accounts, AuthTokenService tokens,
                       AdminActivityLogService adminAudit, AuthProperties properties, Clock clock,
                       StepUpRateLimiter stepUpLimiter) {
        this.users = users;
        this.encoder = encoder;
        this.jwt = jwt;
        this.accounts = accounts;
        this.tokens = tokens;
        this.adminAudit = adminAudit;
        this.properties = properties;
        this.clock = clock;
        this.stepUpLimiter = stepUpLimiter;
    }

    /** Traveller self-registration: a USER account, signed in immediately (unchanged V1 behaviour). */
    @Transactional
    public AuthResponse register(RegisterRequest r) {
        User u = newAccount(r.fullName(), r.email(), r.password(), AccountRole.USER);
        persistNewAccount(u);
        return toAuthResponse(u);
    }

    /**
     * Partner self-registration: a PARTNER account that cannot sign in until its email is verified.
     * No session is returned. The business profile and its Admin approval come afterwards, through the
     * existing partner profile endpoints.
     *
     * <p>When no email can be delivered (production without a provider) nothing is created and the
     * request answers 503: an account whose verification email can never arrive would be unusable.
     */
    @Transactional
    public PartnerRegistrationResponse registerPartner(PartnerRegisterRequest r) {
        accounts.requireEmailDelivery();
        User u = newAccount(r.fullName(), r.email(), r.password(), AccountRole.PARTNER);
        u.setEmailVerificationRequired(true);
        u.setTermsAcceptedAt(clock.instant());
        u.setTermsVersion(properties.getPartnerTermsVersion());
        persistNewAccount(u);
        accounts.sendVerification(u);
        return new PartnerRegistrationResponse(u.getEmail(), "PENDING_VERIFICATION", true,
            "Check your email to verify your address before signing in.");
    }

    public AuthResponse login(LoginRequest r) {
        User u = users.findByEmail(AccountEmails.normalize(r.email())).orElse(null);
        if (u == null || !passwordMatches(r.password(), u.getPasswordHash())) {
            recordRefusedAdminSignIn(u, "credentials did not match");
            throw new ApiException(HttpStatus.UNAUTHORIZED, "INVALID_CREDENTIALS", "Invalid email or password");
        }
        if (!u.isEnabled()) {
            recordRefusedAdminSignIn(u, "account disabled");
            throw new ApiException(HttpStatus.FORBIDDEN, "ACCOUNT_DISABLED", "This account is disabled");
        }
        AccountRole role = AccountRole.parse(u.getRole()).orElseThrow(() ->
            new ApiException(HttpStatus.FORBIDDEN, "ACCOUNT_UNAVAILABLE", "This account cannot sign in"));
        if (u.isEmailVerificationRequired() && u.getEmailVerifiedAt() == null) {
            throw new ApiException(HttpStatus.FORBIDDEN, "EMAIL_NOT_VERIFIED",
                "Verify your email address before signing in");
        }
        if (role == AccountRole.ADMIN) {
            adminAudit.record(u.getId(), "ADMIN_LOGIN_SUCCESS", "USER", u.getId(), "Admin signed in");
        }
        return toAuthResponse(u);
    }

    /**
     * The signed-in account changes its own password. Every existing session of the account ends
     * (token version bump) and any outstanding reset link is retired; the caller receives a fresh token
     * so the session that made the change continues.
     */
    @Transactional
    public AuthResponse changePassword(Long userId, ChangePasswordRequest r) {
        User u = users.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Missing or invalid bearer token"));
        if (!passwordMatches(r.currentPassword(), u.getPasswordHash())) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "CURRENT_PASSWORD_INCORRECT", "currentPassword",
                "is incorrect");
        }
        if (encoder.matches(r.newPassword(), u.getPasswordHash())) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "PASSWORD_UNCHANGED", "newPassword",
                "must differ from the current one");
        }
        u.setPasswordHash(encoder.encode(r.newPassword()));
        u.setTokenVersion(u.getTokenVersion() + 1);
        users.saveAndFlush(u);
        tokens.retireAll(u, AuthTokenPurpose.PASSWORD_RESET);
        if (isAdmin(u)) {
            adminAudit.record(u.getId(), "ADMIN_PASSWORD_CHANGE", "USER", u.getId(),
                "Admin changed their own sign-in credentials; other sessions ended");
        }
        return toAuthResponse(u);
    }

    /**
     * RBAC R3a — step-up (§18 O-7, §25.6): the signed-in account re-enters its password and receives a newly
     * issued token, fresh for {@link StepUpPolicy#FRESHNESS}. Nothing else changes: the previous token stays
     * valid until it expires and no session is ended. At most {@link StepUpRateLimiter#MAX_ATTEMPTS}
     * attempts per account in {@link StepUpRateLimiter#WINDOW} (429 {@code STEP_UP_RATE_LIMITED}). For an
     * ADMIN account both outcomes are audited; the method is deliberately not transactional so a refused
     * attempt still leaves its row.
     */
    public AuthResponse stepUp(Long userId, StepUpRequest r) {
        User u = users.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Missing or invalid bearer token"));
        if (!stepUpLimiter.tryAcquire(u.getId())) {
            throw new ApiException(HttpStatus.TOO_MANY_REQUESTS, "STEP_UP_RATE_LIMITED",
                "Too many attempts. Try again later");
        }
        if (!passwordMatches(r.currentPassword(), u.getPasswordHash())) {
            if (isAdmin(u)) {
                adminAudit.record(u.getId(), "ADMIN_STEP_UP_FAILED", "USER", u.getId(),
                    "Admin step-up refused: credentials did not match");
            }
            throw new ApiException(HttpStatus.BAD_REQUEST, "CURRENT_PASSWORD_INCORRECT", "currentPassword",
                "is incorrect");
        }
        if (isAdmin(u)) {
            adminAudit.record(u.getId(), "ADMIN_STEP_UP", "USER", u.getId(), "Admin re-confirmed their sign-in credentials (step-up)");
        }
        return toAuthResponse(u);
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    /**
     * The single call site for {@code ADMIN_LOGIN_FAILED}. Records only when the address belongs to an
     * ADMIN account; an unknown address, or any other role, leaves no row. {@code reason} is a fixed
     * phrase — never anything the client sent.
     */
    private void recordRefusedAdminSignIn(User u, String reason) {
        if (u == null || !isAdmin(u)) return;
        adminAudit.record(u.getId(), "ADMIN_LOGIN_FAILED", "USER", u.getId(), "Admin sign-in refused: " + reason);
    }

    private User newAccount(String fullName, String email, String password, AccountRole role) {
        String normalized = AccountEmails.normalize(email);
        if (users.existsByEmail(normalized)) throw emailTaken();
        User u = new User();
        u.setFullName(fullName);
        u.setEmail(normalized);
        u.setPasswordHash(encoder.encode(password));
        u.setRole(role.name());
        return u;
    }

    /**
     * Inserts a new account. The duplicate check before this is a courtesy; the unique email index is
     * the real guard, and a second registration racing past the check lands here as a unique-key
     * violation, which is reported as the same 409. Any other integrity failure is rethrown untouched.
     */
    private void persistNewAccount(User u) {
        try {
            users.saveAndFlush(u);
        } catch (DataIntegrityViolationException e) {
            if (isUniqueViolation(e)) throw emailTaken();
            throw e;
        }
    }

    /** The only unique key a new users row can violate is the email; the id is generated. */
    private static boolean isUniqueViolation(DataIntegrityViolationException e) {
        Throwable cause = e.getCause();
        return cause instanceof ConstraintViolationException cve
            && cve.getKind() == ConstraintViolationException.ConstraintKind.UNIQUE;
    }

    private static ApiException emailTaken() {
        return new ApiException(HttpStatus.CONFLICT, "EMAIL_ALREADY_REGISTERED", "Email already registered");
    }

    /** BCrypt cannot hash more than 72 bytes and throws instead; such a password can never match. */
    private boolean passwordMatches(String raw, String hash) {
        if (raw == null || hash == null || AccountPasswordValidator.exceedsMaxBytes(raw)) return false;
        return encoder.matches(raw, hash);
    }

    private static boolean isAdmin(User u) {
        return AccountRole.parse(u.getRole()).filter(r -> r == AccountRole.ADMIN).isPresent();
    }

    AuthResponse toAuthResponse(User u) {
        String token = jwt.createToken(u.getId(), u.getEmail(), u.getTokenVersion());
        return new AuthResponse(token, new UserDto(u.getId(), u.getFullName(), u.getEmail(), u.getRole()));
    }
}
