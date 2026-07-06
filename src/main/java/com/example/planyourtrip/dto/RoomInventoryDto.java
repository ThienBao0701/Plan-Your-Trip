package com.example.planyourtrip.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public class RoomInventoryDto {

    public record RoomInventoryRequest(
        @NotNull LocalDate inventoryDate,
        @Min(0) int totalInventory,
        @Min(0) int availableInventory,
        @Min(0) int blockedInventory,
        @Min(0) int soldInventory,
        @Min(0) int maintenanceInventory,
        boolean stopSell,
        boolean closedArrival,
        boolean closedDeparture
    ) {}

    public record RoomInventoryResponse(
        Long id,
        Long roomId,
        LocalDate inventoryDate,
        int totalInventory,
        int availableInventory,
        int blockedInventory,
        int soldInventory,
        int maintenanceInventory,
        boolean stopSell,
        boolean closedArrival,
        boolean closedDeparture,
        Instant createdAt,
        Instant updatedAt
    ) {}

    public record InventoryCalendarResponse(
        Long roomId,
        String roomCode,
        String roomName,
        List<RoomInventoryResponse> inventory
    ) {}

    public record BulkInventoryRequest(
        @NotNull List<RoomInventoryRequest> items
    ) {}
}
