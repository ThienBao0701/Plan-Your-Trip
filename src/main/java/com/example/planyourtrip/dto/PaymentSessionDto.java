package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.CallbackOutcome;
import com.example.planyourtrip.model.PaymentProvider;
import com.example.planyourtrip.model.PaymentSessionEventType;
import com.example.planyourtrip.model.PaymentSessionStatus;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Phase 7.26 — Payment Gateway Foundation DTOs.
 */
public class PaymentSessionDto {

    public record CreateSessionRequest(
        @NotNull Long bookingId,
        @NotNull PaymentProvider provider
    ) {}

    /**
     * Simulated provider callback. In a real integration this would be an unauthenticated
     * webhook carrying a provider signature; in this phase it is a normal authenticated
     * API call whose {@code callbackToken} must match the session's secret.
     */
    public record CallbackRequest(
        @NotNull String callbackToken,
        @NotNull CallbackOutcome outcome,
        String providerReference
    ) {}

    /** Public session view. Callback credentials are never returned to API clients. */
    public record SessionResponse(
        Long id,
        String sessionId,
        PaymentProvider provider,
        Long bookingId,
        String bookingCode,
        BigDecimal amount,
        String currency,
        PaymentSessionStatus status,
        String checkoutUrl,
        String providerReference,
        Instant expiresAt,
        Instant createdAt,
        Instant updatedAt
    ) {}

    public record SessionEventResponse(
        Long id,
        PaymentSessionEventType eventType,
        PaymentSessionStatus fromStatus,
        PaymentSessionStatus toStatus,
        String detail,
        Instant createdAt
    ) {}

    public record ExpirationResultResponse(
        int expiredCount
    ) {}

    /**
     * Phase 7.27 — acknowledgement returned to a real provider webhook. Deliberately does
     * NOT echo the {@code callbackToken}: a real webhook caller is the provider, not the
     * owner. {@code processed} is false for an idempotent no-op (e.g. duplicate delivery on
     * an already-terminal session).
     */
    public record WebhookAck(
        String sessionId,
        PaymentSessionStatus status,
        boolean processed,
        String detail
    ) {}
}
