package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.RoomInventoryDto.*;
import com.example.planyourtrip.service.RoomInventoryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/admin/rooms/{roomId}/inventory")
@Tag(name = "Admin - Inventory")
@SecurityRequirement(name = "bearerAuth")
public class AdminInventoryController {

    private final RoomInventoryService service;

    public AdminInventoryController(RoomInventoryService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "Get inventory calendar for a room (optional date range)")
    public InventoryCalendarResponse getCalendar(
            @PathVariable Long roomId,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return service.getCalendar(roomId, from, to);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create inventory for a specific date")
    public RoomInventoryResponse create(@PathVariable Long roomId,
                                         @Valid @RequestBody RoomInventoryRequest req) {
        return service.create(roomId, req);
    }

    @PutMapping("/{date}")
    @Operation(summary = "Update inventory for a specific date")
    public RoomInventoryResponse update(
            @PathVariable Long roomId,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @Valid @RequestBody RoomInventoryRequest req) {
        return service.update(roomId, date, req);
    }

    @PostMapping("/bulk")
    @Operation(summary = "Bulk upsert inventory (create or update per date)")
    public List<RoomInventoryResponse> bulkUpsert(@PathVariable Long roomId,
                                                   @Valid @RequestBody BulkInventoryRequest req) {
        return service.bulkUpsert(roomId, req);
    }
}
