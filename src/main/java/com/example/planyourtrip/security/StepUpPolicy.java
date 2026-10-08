package com.example.planyourtrip.security;

import com.example.planyourtrip.exception.ApiException;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;

/**
 * RBAC R3a — step-up freshness (RBAC V1.1 §18 O-7, §25.6).
 *
 * <p>The JWT is unchanged. A session is <em>fresh</em> when its token was issued within the last
 * {@link #FRESHNESS} — by a sign-in, a password change or {@code POST /api/me/step-up}. Owner-level actions
 * (P12 owner management, P53 payout account change) refuse a stale session with 403 {@code STEP_UP_REQUIRED};
 * the client re-enters the password at {@code /api/me/step-up} and retries with the new token.
 *
 * <p>Caveat (O-7): lowering {@code app.jwt.expiration-ms} makes older tokens look fresher by the difference,
 * so such a change must be paired with a {@code tokenVersion} bump.
 */
@Component
public class StepUpPolicy {

    public static final String STEP_UP_REQUIRED = "STEP_UP_REQUIRED";
    public static final Duration FRESHNESS = Duration.ofMinutes(15);

    private final Clock clock;

    public StepUpPolicy(Clock clock) {
        this.clock = clock;
    }

    /** Whether the current request's session was issued within {@link #FRESHNESS}. No session is not fresh. */
    public boolean isFresh() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getDetails() instanceof TokenSession session)
                || session.issuedAt() == null) {
            return false;
        }
        Instant now = clock.instant();
        return !session.issuedAt().isBefore(now.minus(FRESHNESS));
    }

    /** 403 {@code STEP_UP_REQUIRED} unless {@link #isFresh()}. */
    public void requireFresh() {
        if (!isFresh()) {
            throw new ApiException(HttpStatus.FORBIDDEN, STEP_UP_REQUIRED,
                "Confirm your password to continue (POST /api/me/step-up)");
        }
    }
}
