package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.InvoiceStatus;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.Instant;

public class InvoiceDto {

    public record InvoiceRequest(
        @NotNull Long bookingId,
        @NotNull Long paymentId,
        String billingName,
        String billingEmail,
        String billingPhone,
        String billingAddress,
        String taxCode,
        String notes
    ) {}

    public record InvoiceResponse(
        Long id,
        String invoiceNumber,
        Long bookingId,
        String bookingCode,
        Long paymentId,
        String paymentCode,
        Long userId,
        Long hotelId,
        String hotelName,
        String status,
        String currency,
        BigDecimal subtotal,
        BigDecimal discountAmount,
        BigDecimal taxAmount,
        BigDecimal totalAmount,
        Instant issuedAt,
        Instant paidAt,
        Instant cancelledAt,
        String billingName,
        String billingEmail,
        String billingPhone,
        String billingAddress,
        String taxCode,
        String notes,
        Instant createdAt,
        Instant updatedAt
    ) {}

    public record InvoiceSummaryResponse(
        Long id,
        String invoiceNumber,
        Long bookingId,
        String bookingCode,
        String status,
        BigDecimal totalAmount,
        String currency,
        Instant issuedAt
    ) {}

    public record InvoiceStatusRequest(
        @NotNull InvoiceStatus status
    ) {}
}
