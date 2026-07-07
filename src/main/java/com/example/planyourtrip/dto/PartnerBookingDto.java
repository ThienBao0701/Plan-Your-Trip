package com.example.planyourtrip.dto;

import com.example.planyourtrip.dto.BookingDto.BookingResponse;
import com.example.planyourtrip.dto.BookingDto.BookingTimelineResponse;
import com.example.planyourtrip.dto.InvoiceDto.InvoiceSummaryResponse;
import com.example.planyourtrip.dto.PaymentDto.PaymentResponse;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public class PartnerBookingDto {

    public record PartnerBookingSummaryResponse(
        Long id,
        String bookingCode,
        Long roomId, String roomName, String roomCode,
        String guestName, String guestEmail,
        LocalDate checkIn, LocalDate checkOut, int nights,
        String status,
        BigDecimal finalPrice, String currency,
        Instant createdAt
    ) {}

    public record PartnerBookingDetailResponse(
        BookingResponse booking,
        List<PaymentResponse> payments,
        InvoiceSummaryResponse invoice,
        BookingTimelineResponse timeline
    ) {}

    public record PartnerDashboardResponse(
        long todaysArrivals,
        long todaysDepartures,
        long currentGuests,
        long upcoming,
        long cancelled,
        long completed,
        double occupancyRate,
        BigDecimal revenueToday,
        BigDecimal revenueMonth,
        double averageStayNights
    ) {}
}
