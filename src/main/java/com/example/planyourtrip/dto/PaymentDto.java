package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.PaymentMethod;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.Instant;

public class PaymentDto {

    public record PaymentRequest(
        @NotNull Long bookingId,
        @NotNull PaymentMethod paymentMethod
    ) {}

    public record PaymentResponse(
        Long id,
        String paymentCode,
        Long bookingId,
        String bookingCode,
        BigDecimal amount,
        String currency,
        String paymentMethod,
        String status,
        String provider,
        String providerTransactionId,
        String checkoutUrl,
        String failureReason,
        Instant paidAt,
        Instant failedAt,
        Instant refundedAt,
        Instant createdAt,
        Instant updatedAt
    ) {}

    public record PaymentResultRequest(
        String providerTransactionId,
        Boolean success,
        String failureReason
    ) {}

    public record RefundRequest(
        String reason
    ) {}
}
