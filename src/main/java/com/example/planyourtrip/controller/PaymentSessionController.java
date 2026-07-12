package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PaymentSessionDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.PaymentGatewayService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Phase 7.26 — Payment Gateway Foundation (customer-facing).
 *
 * <p>Provider-abstracted checkout sessions. This is a PARALLEL foundation layer — it does
 * not create or settle a {@code Payment} row yet (see {@code PaymentGatewayService}).
 * The {@link #callback} endpoint simulates a provider webhook: it is authenticated at the
 * JWT layer but authorized by the session's {@code callbackToken} (NOT ownership-scoped),
 * exactly as a real provider webhook would be.
 */
@RestController
@RequestMapping("/api/payment-sessions")
@Tag(name = "Payment Sessions", description = "Provider-abstracted checkout sessions (Phase 7.26 foundation)")
@SecurityRequirement(name = "bearerAuth")
public class PaymentSessionController {

    private final PaymentGatewayService service;

    public PaymentSessionController(PaymentGatewayService service) { this.service = service; }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Open a payment session for a booking and get a provider checkout URL")
    public SessionResponse create(@AuthUser Long uid, @Valid @RequestBody CreateSessionRequest req) {
        return service.createSession(uid, req);
    }

    @GetMapping("/{sessionId}")
    @Operation(summary = "Get a payment session by its public sessionId (owner or admin)")
    public SessionResponse get(@AuthUser Long uid, @PathVariable String sessionId) {
        return service.getSession(uid, sessionId);
    }

    @GetMapping("/{sessionId}/events")
    @Operation(summary = "List the immutable lifecycle events for a session (owner or admin)")
    public List<SessionEventResponse> events(@AuthUser Long uid, @PathVariable String sessionId) {
        return service.getSessionEvents(uid, sessionId);
    }

    @PostMapping("/{sessionId}/callback")
    @Operation(summary = "Simulate a provider callback (requires the session callbackToken; idempotent)")
    public SessionResponse callback(@PathVariable String sessionId, @Valid @RequestBody CallbackRequest req) {
        return service.processCallback(sessionId, req);
    }

    @PostMapping("/{sessionId}/capture")
    @Operation(summary = "Capture an AUTHORIZED session (owner or admin; idempotent)")
    public SessionResponse capture(@AuthUser Long uid, @PathVariable String sessionId) {
        return service.capture(uid, sessionId);
    }

    @PostMapping("/{sessionId}/cancel")
    @Operation(summary = "Cancel a non-terminal session (owner or admin; idempotent)")
    public SessionResponse cancel(@AuthUser Long uid, @PathVariable String sessionId) {
        return service.cancel(uid, sessionId);
    }
}
