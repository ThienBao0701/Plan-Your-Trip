package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.InventoryReservationStatus;

import java.time.Instant;
import java.time.LocalDate;

/**
 * Phase 7.28 — Inventory Lock &amp; Room Hold DTOs.
 */
public class InventoryReservationDto {

    /** Full reservation view (customer status endpoint + admin inspection). */
    public record ReservationResponse(
        Long id,
        Long bookingId,
        String bookingCode,
        Long roomId,
        String roomCode,
        LocalDate checkInDate,
        LocalDate checkOutDate,
        int numberOfRooms,
        InventoryReservationStatus status,
        Instant expiresAt,
        Instant consumedAt,
        Instant releasedAt,
        Instant expiredAt,
        Instant createdAt,
        Instant updatedAt
    ) {}

    /** Result of the admin expiry sweep. */
    public record ExpirationResultResponse(
        int expiredCount
    ) {}
}
