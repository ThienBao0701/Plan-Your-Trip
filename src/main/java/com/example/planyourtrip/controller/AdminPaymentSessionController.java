package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PaymentSessionDto.*;
import com.example.planyourtrip.service.PaymentGatewayService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Phase 7.26 — Payment Gateway Foundation (admin). Access is restricted to ROLE_ADMIN by
 * SecurityConfig's blanket {@code /api/admin/**} rule.
 */
@RestController
@RequestMapping("/api/admin/payment-sessions")
@Tag(name = "Admin - Payment Sessions", description = "Inspect, expire and audit provider checkout sessions")
@SecurityRequirement(name = "bearerAuth")
public class AdminPaymentSessionController {

    private final PaymentGatewayService service;

    public AdminPaymentSessionController(PaymentGatewayService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "List all payment sessions (newest first)")
    public List<SessionResponse> list() {
        return service.adminList();
    }

    @GetMapping("/{sessionId}")
    @Operation(summary = "Get a payment session by its public sessionId")
    public SessionResponse get(@PathVariable String sessionId) {
        return service.adminGet(sessionId);
    }

    @GetMapping("/{sessionId}/events")
    @Operation(summary = "List the immutable lifecycle events for a session")
    public List<SessionEventResponse> events(@PathVariable String sessionId) {
        return service.adminGetEvents(sessionId);
    }

    @PostMapping("/{sessionId}/expire")
    @Operation(summary = "Force-expire a single non-terminal session (simulates a provider timeout; idempotent)")
    public SessionResponse expire(@PathVariable String sessionId) {
        return service.expire(sessionId);
    }

    @PostMapping("/process-expirations")
    @Operation(summary = "Time-based expiry sweep of all overdue non-terminal sessions (no scheduler in this phase)")
    public ExpirationResultResponse processExpirations() {
        return service.processExpirations();
    }
}
