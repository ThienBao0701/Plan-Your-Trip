package com.example.planyourtrip.security;

import org.springframework.stereotype.Component;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * RBAC R3a — at most {@link #MAX_ATTEMPTS} step-up attempts per account in any {@link #WINDOW} (§25.6, E20).
 *
 * <p>Every attempt counts, successful or not, so the password cannot be probed faster by interleaving a
 * correct one. The window is kept in memory: the deployment runs one application instance
 * ({@code DEPLOYMENT.md}); a multi-instance deployment needs a shared store before scaling out.
 */
@Component
public class StepUpRateLimiter {

    public static final int MAX_ATTEMPTS = 5;
    public static final Duration WINDOW = Duration.ofMinutes(15);

    private final Clock clock;
    private final Map<Long, Deque<Instant>> attempts = new ConcurrentHashMap<>();

    public StepUpRateLimiter(Clock clock) {
        this.clock = clock;
    }

    /** Records an attempt for the account and answers whether it is within the limit. */
    public boolean tryAcquire(Long userId) {
        Instant now = clock.instant();
        Deque<Instant> recent = attempts.computeIfAbsent(userId, id -> new ArrayDeque<>());
        synchronized (recent) {
            while (!recent.isEmpty() && !recent.peekFirst().isAfter(now.minus(WINDOW))) recent.pollFirst();
            if (recent.size() >= MAX_ATTEMPTS) return false;
            recent.addLast(now);
            return true;
        }
    }
}
