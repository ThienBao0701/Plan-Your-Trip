package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PaymentSessionDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.BookingRepository;
import com.example.planyourtrip.repository.PaymentSessionEventRepository;
import com.example.planyourtrip.repository.PaymentSessionRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.service.gateway.PaymentGateway;
import com.example.planyourtrip.service.gateway.PaymentGateway.CallbackVerification;
import com.example.planyourtrip.service.gateway.PaymentGateway.GatewayCallback;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Phase 7.26 — Payment Gateway Foundation.
 *
 * <p><b>Provider-agnostic orchestration.</b> This service owns ALL {@link PaymentSession}
 * persistence, the {@link PaymentSessionStatus} state machine, idempotency and
 * notifications. It NEVER branches on provider type for behavior — it only SELECTS the
 * right {@link PaymentGateway} via a {@code Map<PaymentProvider, PaymentGateway>} built
 * once from the injected {@code List<PaymentGateway>} (every gateway self-declares its
 * provider through {@link PaymentGateway#provider()}). A future provider is added by
 * dropping in one new {@code @Component} gateway — zero edits here, in
 * {@code BookingService} or in {@code PaymentService}.
 *
 * <p><b>Fully decoupled from the existing settlement flow.</b> This is ADDITIVE
 * FOUNDATION ONLY (mirroring Gift Cards in 7.24 before the 7.25 checkout wiring). A
 * {@code PaymentSession} does NOT create, mutate or settle a {@link Payment} row and
 * fires NONE of the existing booking-payment hooks (loyalty apply/release, gift-card
 * release, {@code Payment}-level "Payment successful"/"Payment failed" notifications).
 * Nothing in {@code PaymentService}/{@code BookingService} is touched. The session-level
 * "Payment Authorized"/"Payment Failed"/"Payment Captured" notifications emitted here are
 * a SEPARATE concept from the existing {@code Payment}-level ones.
 *
 * <p><b>Idempotency.</b> Every accepted transition writes one immutable
 * {@link PaymentSessionEvent} carrying a deterministic {@code idempotencyKey}
 * (pre-checked + DB-unique backstop) — the same ledger idiom as
 * {@code GiftCardTransaction}. A duplicate provider callback (or a callback that would
 * transition an already-terminal session) is a safe no-op that re-fires no notification.
 * Mutations run under a pessimistic write lock
 * ({@link PaymentSessionRepository#findBySessionIdForUpdate}).
 */
@Service
public class PaymentGatewayService {

    /** Default session lifetime before it is eligible for time-based expiry. */
    private static final long SESSION_TTL_MINUTES = 30;
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final List<PaymentSessionStatus> EXPIRABLE_STATUSES =
        List.of(PaymentSessionStatus.NEW, PaymentSessionStatus.PENDING, PaymentSessionStatus.AUTHORIZED);

    private final PaymentSessionRepository sessionRepo;
    private final PaymentSessionEventRepository eventRepo;
    private final BookingRepository bookingRepo;
    private final UserRepository userRepo;
    private final NotificationService notificationService;
    private final PaymentSettlementBridge settlementBridge;
    private final AdminActivityLogService adminAudit;
    private final Map<PaymentProvider, PaymentGateway> gateways;

    public PaymentGatewayService(PaymentSessionRepository sessionRepo,
                                 PaymentSessionEventRepository eventRepo,
                                 BookingRepository bookingRepo,
                                 UserRepository userRepo,
                                 NotificationService notificationService,
                                 PaymentSettlementBridge settlementBridge,
                                 List<PaymentGateway> gatewayBeans,
                                 AdminActivityLogService adminAudit) {
        this.sessionRepo = sessionRepo;
        this.eventRepo = eventRepo;
        this.bookingRepo = bookingRepo;
        this.userRepo = userRepo;
        this.notificationService = notificationService;
        this.settlementBridge = settlementBridge;
        this.adminAudit = adminAudit;
        Map<PaymentProvider, PaymentGateway> map = new HashMap<>();
        for (PaymentGateway gw : gatewayBeans) {
            map.put(gw.provider(), gw); // last-wins; in practice one bean per provider
        }
        this.gateways = Map.copyOf(map);
    }

    // ═════════════════════════════════════════════════════════════════════
    // CREATE + CHECKOUT URL
    // ═════════════════════════════════════════════════════════════════════

    @Transactional
    public SessionResponse createSession(Long userId, CreateSessionRequest req) {
        Booking booking = bookingRepo.findById(req.bookingId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + req.bookingId()));
        if (!booking.getUser().getId().equals(userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied: booking belongs to another user");
        if (booking.getStatus() == BookingStatus.CANCELLED)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Cannot open a payment session for a cancelled booking");

        PaymentGateway gateway = gatewayOrThrow(req.provider());

        PaymentSession session = new PaymentSession();
        session.setSessionId(generateUniqueSessionId());
        session.setProvider(req.provider());
        session.setBooking(booking);
        session.setAmount(booking.getFinalPrice());
        session.setCurrency(booking.getCurrency());
        session.setStatus(PaymentSessionStatus.NEW);
        session.setExpiresAt(Instant.now().plus(SESSION_TTL_MINUTES, ChronoUnit.MINUTES));
        session.setCallbackToken(generateCallbackToken());
        PaymentSession saved = sessionRepo.save(session);

        // Generate the provider checkout URL and move NEW → PENDING (customer redirected).
        saved.setCheckoutUrl(gateway.createCheckoutUrl(saved));
        saved.setStatus(PaymentSessionStatus.PENDING);
        saved = sessionRepo.save(saved);

        insertEvent(saved, PaymentSessionEventType.CREATED, PaymentSessionStatus.NEW,
            PaymentSessionStatus.PENDING, "Session created; checkout URL generated",
            eventKey(saved, "created"));

        return toResponse(saved, true);
    }

    // ═════════════════════════════════════════════════════════════════════
    // CALLBACK (token-gated; NOT ownership-scoped — the token is the credential)
    // ═════════════════════════════════════════════════════════════════════

    /**
     * Process a (simulated) provider callback. Security: the {@code callbackToken} must
     * match the session secret — an invalid token is rejected with 403 Forbidden (the
     * closest existing convention for "you may not act on this resource"; this codebase
     * reserves 401 for a missing JWT at the security filter). Idempotent: a duplicate
     * callback, or one against an already-terminal session, is a safe no-op.
     */
    @Transactional
    public SessionResponse processCallback(String sessionId, CallbackRequest req) {
        PaymentSession session = sessionRepo.findBySessionIdForUpdate(sessionId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Payment session not found: " + sessionId));

        PaymentGateway gateway = gatewayOrThrow(session.getProvider());
        CallbackVerification v = gateway.verifyCallback(session,
            new GatewayCallback(req.callbackToken(), req.outcome(), req.providerReference()));
        if (!v.valid())
            throw new ApiException(HttpStatus.FORBIDDEN, "Invalid callback token");

        // Terminal session → idempotent no-op (no event, no notification).
        if (session.getStatus().isTerminal())
            return toResponse(session, true);

        return switch (v.outcome()) {
            case AUTHORIZED -> toResponse(applyAuthorized(session, v.providerReference()), true);
            case FAILED -> toResponse(applyFailed(session, v.providerReference()), true);
        };
    }

    // ═════════════════════════════════════════════════════════════════════
    // REAL PROVIDER WEBHOOK (unauthenticated; signature-verified; retry-safe)
    // ═════════════════════════════════════════════════════════════════════

    /**
     * Phase 7.27 — process a REAL, unauthenticated provider webhook. Security is the
     * provider's cryptographic signature over the raw body (verified by the selected
     * gateway with its shared webhook secret), NOT a JWT and NOT the per-session token.
     *
     * <p>End-to-end: select gateway by {@code provider} → verify signature + extract
     * {@code sessionId}/outcome → load the session under a write lock → confirm the
     * session belongs to this provider → drive the state machine, reusing the SAME
     * transition + {@code PaymentSessionEvent} idempotency + settlement-bridge code as the
     * simulation callback. A duplicate delivery on an already-terminal session is a safe
     * no-op. A successful webhook drives the session all the way to CAPTURED (real
     * providers report a completed charge in one shot) and bridges to real settlement.
     */
    @Transactional
    public WebhookAck processWebhook(PaymentProvider provider, String rawBody, String signatureHeader) {
        PaymentGateway gateway = gatewayOrThrow(provider);

        PaymentGateway.WebhookVerification v;
        try {
            v = gateway.verifyWebhook(rawBody, signatureHeader);
        } catch (UnsupportedOperationException e) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "Provider " + provider + " does not expose a signed webhook receiver");
        }
        if (!v.valid())
            throw new ApiException(HttpStatus.BAD_REQUEST, "Invalid webhook signature");

        PaymentSession session = sessionRepo.findBySessionIdForUpdate(v.sessionId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Payment session not found: " + v.sessionId()));

        // Provider isolation: a payload verified for one provider may only drive a session
        // that was opened for that same provider.
        if (session.getProvider() != provider)
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "Webhook provider " + provider + " does not match session provider " + session.getProvider());

        if (session.getStatus().isTerminal())
            return new WebhookAck(session.getSessionId(), session.getStatus(), false,
                "Session already terminal — ignored");

        PaymentSession result = switch (v.outcome()) {
            case AUTHORIZED -> doCaptureTransition(applyAuthorized(session, v.providerReference()));
            case FAILED -> applyFailed(session, v.providerReference());
        };
        return new WebhookAck(result.getSessionId(), result.getStatus(), true, "Processed");
    }

    /** PENDING → AUTHORIZED transition (idempotent). Returns the (possibly unchanged) session. */
    private PaymentSession applyAuthorized(PaymentSession session, String providerReference) {
        if (session.getStatus() == PaymentSessionStatus.AUTHORIZED)
            return session; // idempotent replay
        String key = eventKey(session, "authorized");
        if (eventRepo.findByIdempotencyKey(key).isPresent())
            return session;

        PaymentSessionStatus from = session.getStatus();
        session.setProviderReference(providerReference);
        session.setStatus(PaymentSessionStatus.AUTHORIZED);
        PaymentSession saved = sessionRepo.save(session);

        insertEvent(saved, PaymentSessionEventType.AUTHORIZED, from,
            PaymentSessionStatus.AUTHORIZED, "Provider authorized the payment", key);

        notify(saved, "Payment Authorized",
            "Your payment for booking " + saved.getBooking().getBookingCode() + " was authorized.");
        return saved;
    }

    /** → FAILED transition + bridge to the real failure settlement. Idempotent. */
    private PaymentSession applyFailed(PaymentSession session, String providerReference) {
        String key = eventKey(session, "failed");
        if (eventRepo.findByIdempotencyKey(key).isPresent())
            return session;

        PaymentSessionStatus from = session.getStatus();
        session.setProviderReference(providerReference);
        session.setStatus(PaymentSessionStatus.FAILED);
        PaymentSession saved = sessionRepo.save(session);

        insertEvent(saved, PaymentSessionEventType.FAILED, from,
            PaymentSessionStatus.FAILED, "Provider declined the payment", key);

        notify(saved, "Payment Failed",
            "Your payment for booking " + saved.getBooking().getBookingCode() + " failed.");

        // BRIDGE: route the failure through the EXISTING PaymentService.mockFail hook chain.
        settlementBridge.settleFailure(saved, "Provider declined the payment");
        return saved;
    }

    /**
     * AUTHORIZED → CAPTURED transition + bridge to the real PAID settlement. Shared by the
     * owner/admin capture endpoint and the real webhook success path. Idempotent.
     */
    private PaymentSession doCaptureTransition(PaymentSession session) {
        if (session.getStatus() == PaymentSessionStatus.CAPTURED)
            return session; // idempotent

        gatewayOrThrow(session.getProvider()).capture(session);

        session.setStatus(PaymentSessionStatus.CAPTURED);
        PaymentSession saved = sessionRepo.save(session);

        insertEvent(saved, PaymentSessionEventType.CAPTURED, PaymentSessionStatus.AUTHORIZED,
            PaymentSessionStatus.CAPTURED, "Authorized funds captured", eventKey(saved, "captured"));

        notify(saved, "Payment Captured",
            "Your payment for booking " + saved.getBooking().getBookingCode() + " was captured.");

        // BRIDGE: route the success through the EXISTING PaymentService.mockSuccess hook chain.
        settlementBridge.settleSuccess(saved);
        return saved;
    }

    // ═════════════════════════════════════════════════════════════════════
    // CAPTURE / CANCEL / EXPIRE
    // ═════════════════════════════════════════════════════════════════════

    @Transactional
    public SessionResponse capture(Long userId, String sessionId) {
        PaymentSession pre = sessionOrThrow(sessionId);
        checkOwnerOrAdmin(userId, pre);

        PaymentSession session = sessionRepo.findBySessionIdForUpdate(sessionId).orElseThrow();
        if (session.getStatus() == PaymentSessionStatus.CAPTURED)
            return toResponse(session, true); // idempotent
        if (session.getStatus() != PaymentSessionStatus.AUTHORIZED)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Only an AUTHORIZED session can be captured. Current status: " + session.getStatus());

        return toResponse(doCaptureTransition(session), true);
    }

    @Transactional
    public SessionResponse cancel(Long userId, String sessionId) {
        PaymentSession pre = sessionOrThrow(sessionId);
        checkOwnerOrAdmin(userId, pre);

        PaymentSession session = sessionRepo.findBySessionIdForUpdate(sessionId).orElseThrow();
        if (session.getStatus() == PaymentSessionStatus.CANCELLED)
            return toResponse(session, true); // idempotent
        if (session.getStatus().isTerminal())
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Cannot cancel a session in status " + session.getStatus());

        gatewayOrThrow(session.getProvider()).cancel(session);

        PaymentSessionStatus from = session.getStatus();
        session.setStatus(PaymentSessionStatus.CANCELLED);
        PaymentSession saved = sessionRepo.save(session);

        insertEvent(saved, PaymentSessionEventType.CANCELLED, from,
            PaymentSessionStatus.CANCELLED, "Session cancelled", eventKey(saved, "cancelled"));
        // No customer notification for cancel — only Authorized/Failed/Captured are notified.

        // BRIDGE: a cancelled session releases any held loyalty/gift-card via the existing
        // PaymentService.mockFail hook chain (no-op when nothing was held).
        settlementBridge.settleFailure(saved, "Payment session cancelled");
        return toResponse(saved, true);
    }

    /**
     * Admin force-expire of a single non-terminal session (simulates a provider timeout).
     *
     * <h2>D1d — why the audit call lives here and not in {@link #expireInternal}</h2>
     *
     * <p>{@code expireInternal} is shared with {@link #processExpirations}, which records ONE
     * summary row for a whole sweep. Auditing the shared body would replace that single row with
     * one row per swept session — an unbounded number of audit rows for one click, which is
     * exactly the failure mode D1c's batch rule exists to prevent. The audit therefore sits on
     * the admin-only single-target entry point, and the sweep keeps its own summary row.
     *
     * <p>The record is written after the state actually changed, so the two early returns above
     * are unaudited on purpose: an already-EXPIRED session is a no-op (nothing changed, so there
     * is nothing to record), and a terminal-but-not-expired session throws, which rolls the whole
     * transaction back. This matches the idempotency semantics D1c established for gift-card
     * activation and loyalty release/refund — it does not invent a new rule.
     *
     * <p>Everything — the status flip, the lifecycle event, the settlement bridge that releases
     * any held loyalty/gift-card value, and this audit row — happens inside this one
     * {@code @Transactional} boundary, under the pessimistic lock taken above.
     */
    @Transactional
    public SessionResponse expire(Long adminUserId, String sessionId) {
        PaymentSession session = sessionRepo.findBySessionIdForUpdate(sessionId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Payment session not found: " + sessionId));
        if (session.getStatus() == PaymentSessionStatus.EXPIRED)
            return toResponse(session, true); // idempotent
        if (session.getStatus().isTerminal())
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Cannot expire a session in status " + session.getStatus());

        PaymentSessionStatus before = session.getStatus();
        boolean hadSettlement = session.getPayment() != null;
        PaymentSession expired = expireInternal(session);

        // Safe metadata only: the session's own row id as the target, the booking id as the
        // correlating identifier, and the status pair. The public sessionId string is
        // deliberately NOT recorded — it is a random 32-hex handle, and free text of that shape
        // can contain a 13-19 digit run, which the audit service's card-number backstop rejects.
        // That would abort this transaction and make the session unexpirable (the D1c-NEW-1
        // failure mode). The callback token, provider reference and checkout URL are likewise
        // never recorded: those are the session's bearer material.
        boolean releasedHeldValue = !hadSettlement && expired.getPayment() != null;
        adminAudit.record(adminUserId, "PAYMENT_SESSION_EXPIRE", "PAYMENT_SESSION", expired.getId(),
            "Admin force-expired the checkout session for booking " + expired.getBooking().getId()
                + (releasedHeldValue ? "; held loyalty/gift-card value was released" : ""),
            before.name(), expired.getStatus().name());

        return toResponse(expired, true);
    }

    /** Time-based expiry sweep (admin-triggered; no scheduler in this phase). */
    @Transactional
    public ExpirationResultResponse processExpirations(Long adminUserId) {
        Instant now = Instant.now();
        List<PaymentSession> candidates = sessionRepo.findExpirationCandidates(now, EXPIRABLE_STATUSES);
        int expired = 0;
        for (PaymentSession candidate : candidates) {
            PaymentSession session = sessionRepo.findBySessionIdForUpdate(candidate.getSessionId()).orElseThrow();
            if (session.getStatus().isTerminal()) continue;
            if (session.getExpiresAt() == null || !session.getExpiresAt().isBefore(now)) continue;
            expireInternal(session);
            expired++;
        }
        adminAudit.record(adminUserId, "PAYMENT_SESSION_EXPIRY_SWEEP", "PAYMENT_SESSION", null,
            "Admin ran the payment-session expiry sweep: " + expired + " sessions expired",
            null, "expired:" + expired);
        return new ExpirationResultResponse(expired);
    }

    private PaymentSession expireInternal(PaymentSession session) {
        PaymentSessionStatus from = session.getStatus();
        session.setStatus(PaymentSessionStatus.EXPIRED);
        PaymentSession saved = sessionRepo.save(session);
        insertEvent(saved, PaymentSessionEventType.EXPIRED, from,
            PaymentSessionStatus.EXPIRED, "Session expired", eventKey(saved, "expired"));

        // BRIDGE: a timed-out session releases any held loyalty/gift-card via the existing
        // PaymentService.mockFail hook chain (no-op when nothing was held).
        settlementBridge.settleFailure(saved, "Payment session expired");
        return saved;
    }

    // ═════════════════════════════════════════════════════════════════════
    // READS
    // ═════════════════════════════════════════════════════════════════════

    @Transactional(readOnly = true)
    public SessionResponse getSession(Long userId, String sessionId) {
        PaymentSession session = sessionOrThrow(sessionId);
        checkOwnerOrAdmin(userId, session);
        return toResponse(session, true);
    }

    @Transactional(readOnly = true)
    public List<SessionEventResponse> getSessionEvents(Long userId, String sessionId) {
        PaymentSession session = sessionOrThrow(sessionId);
        checkOwnerOrAdmin(userId, session);
        return eventRepo.findByPaymentSessionIdOrderByCreatedAtAscIdAsc(session.getId())
            .stream().map(this::toEventResponse).toList();
    }

    /** Entity properties an administrator may sort the payment-session grid by (D1c allowlist). */
    private static final Set<String> SESSION_SORT_FIELDS =
        Set.of("createdAt", "updatedAt", "expiresAt", "amount", "status", "provider", "id");

    /**
     * D1c - administrative payment-session search, paged in the database.
     *
     * <p>A session row is written for every checkout attempt, including the ones a customer
     * abandons, so this table grows faster than {@code payment} and never shrinks. The previous
     * contract returned all of them in one response.
     *
     * <p>The row shape is unchanged: this endpoint still returns the same {@code SessionResponse}
     * it always has. Narrowing that shape is a product decision outside this phase, but paging
     * does bound how much of it any single request can return.
     */
    @Transactional(readOnly = true)
    public com.example.planyourtrip.dto.PageResponse<SessionResponse> adminListPaged(
            PaymentSessionStatus status, PaymentProvider provider, Long bookingId,
            String sessionId, Instant from, Instant to,
            Integer page, Integer size, String sort) {

        if (from != null && to != null && from.isAfter(to)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "from must not be after to");
        }
        Pageable pageable = AdminPaging.of(page, size, sort, SESSION_SORT_FIELDS, "createdAt");

        Specification<PaymentSession> spec = (root, query, cb) -> {
            List<Predicate> p = new java.util.ArrayList<>();
            if (status != null) p.add(cb.equal(root.get("status"), status));
            if (provider != null) p.add(cb.equal(root.get("provider"), provider));
            if (bookingId != null) p.add(cb.equal(root.get("booking").get("id"), bookingId));
            if (sessionId != null && !sessionId.isBlank())
                p.add(cb.equal(root.get("sessionId"), sessionId.trim()));
            if (from != null) p.add(cb.greaterThanOrEqualTo(root.get("createdAt"), from));
            if (to != null) p.add(cb.lessThanOrEqualTo(root.get("createdAt"), to));
            return p.isEmpty() ? cb.conjunction() : cb.and(p.toArray(new Predicate[0]));
        };

        return com.example.planyourtrip.dto.PageResponse.of(
            sessionRepo.findAll(spec, pageable).map(x -> toResponse(x, true)));
    }

    @Transactional(readOnly = true)
    public SessionResponse adminGet(String sessionId) {
        return toResponse(sessionOrThrow(sessionId), true);
    }

    @Transactional(readOnly = true)
    public List<SessionEventResponse> adminGetEvents(String sessionId) {
        PaymentSession session = sessionOrThrow(sessionId);
        return eventRepo.findByPaymentSessionIdOrderByCreatedAtAscIdAsc(session.getId())
            .stream().map(this::toEventResponse).toList();
    }

    // ═════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═════════════════════════════════════════════════════════════════════

    private PaymentGateway gatewayOrThrow(PaymentProvider provider) {
        PaymentGateway gw = gateways.get(provider);
        if (gw == null)
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "No payment gateway is registered for provider " + provider
                    + " (not implemented in this phase)");
        return gw;
    }

    private void checkOwnerOrAdmin(Long userId, PaymentSession session) {
        Long ownerId = session.getBooking().getUser().getId();
        if (ownerId.equals(userId)) return;
        User requester = userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));
        if (!"ADMIN".equals(requester.getRole()))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied");
    }

    private PaymentSession sessionOrThrow(String sessionId) {
        return sessionRepo.findBySessionId(sessionId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Payment session not found: " + sessionId));
    }

    private void insertEvent(PaymentSession session, PaymentSessionEventType type,
                             PaymentSessionStatus from, PaymentSessionStatus to,
                             String detail, String idempotencyKey) {
        PaymentSessionEvent event = new PaymentSessionEvent();
        event.setPaymentSession(session);
        event.setEventType(type);
        event.setFromStatus(from);
        event.setToStatus(to);
        event.setDetail(detail);
        event.setIdempotencyKey(idempotencyKey);
        eventRepo.save(event);
    }

    private void notify(PaymentSession session, String title, String message) {
        notificationService.create(session.getBooking().getUser().getId(),
            NotificationType.PAYMENT, Priority.HIGH, title, message,
            RelatedEntityType.PAYMENT, session.getId());
    }

    private String eventKey(PaymentSession session, String suffix) {
        return "session-" + session.getId() + "-" + suffix;
    }

    private String generateUniqueSessionId() {
        for (int i = 0; i < 25; i++) {
            String candidate = "PS-" + UUID.randomUUID().toString().replace("-", "");
            if (sessionRepo.findBySessionId(candidate).isEmpty()) return candidate;
        }
        throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to generate a unique session id");
    }

    private String generateCallbackToken() {
        byte[] bytes = new byte[24];
        RANDOM.nextBytes(bytes);
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) sb.append(String.format("%02x", b));
        return sb.toString();
    }

    private SessionResponse toResponse(PaymentSession s, boolean includeCallbackToken) {
        return new SessionResponse(
            s.getId(), s.getSessionId(), s.getProvider(),
            s.getBooking().getId(), s.getBooking().getBookingCode(),
            s.getAmount(), s.getCurrency(), s.getStatus(),
            s.getCheckoutUrl(), s.getProviderReference(),
            includeCallbackToken ? s.getCallbackToken() : null,
            s.getExpiresAt(), s.getCreatedAt(), s.getUpdatedAt());
    }

    private SessionEventResponse toEventResponse(PaymentSessionEvent e) {
        return new SessionEventResponse(
            e.getId(), e.getEventType(), e.getFromStatus(), e.getToStatus(),
            e.getDetail(), e.getCreatedAt());
    }
}
