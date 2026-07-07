package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PartnerCalendarDto.InventoryFlagRequest;
import com.example.planyourtrip.dto.RatePlanDto.RatePlanRequest;
import com.example.planyourtrip.dto.RatePlanDto.RatePlanResponse;
import com.example.planyourtrip.dto.RoomInventoryDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.PartnerCalendarService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/partner/calendar")
@Tag(name = "Partner - Calendar", description = "Approved partners manage inventory and pricing calendars for rooms they own")
@SecurityRequirement(name = "bearerAuth")
public class PartnerCalendarController {

    private final PartnerCalendarService service;

    public PartnerCalendarController(PartnerCalendarService service) { this.service = service; }

    @GetMapping("/rooms/{roomId}")
    @Operation(summary = "Calendar inventory view (optional date range)")
    public InventoryCalendarResponse getCalendar(
            @AuthUser Long uid,
            @PathVariable Long roomId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return service.getCalendar(uid, roomId, from, to);
    }

    @PutMapping("/rooms/{roomId}/{date}")
    @Operation(summary = "Update single-day inventory")
    public RoomInventoryResponse updateDay(
            @AuthUser Long uid,
            @PathVariable Long roomId,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @Valid @RequestBody RoomInventoryRequest req) {
        return service.updateDay(uid, roomId, date, req);
    }

    @PostMapping("/rooms/{roomId}/bulk")
    @Operation(summary = "Bulk inventory update (create or update per date)")
    public List<RoomInventoryResponse> bulkUpdate(
            @AuthUser Long uid,
            @PathVariable Long roomId,
            @Valid @RequestBody BulkInventoryRequest req) {
        return service.bulkUpdate(uid, roomId, req);
    }

    @PatchMapping("/rooms/{roomId}/{date}/stop-sell")
    @Operation(summary = "Update stop-sell flag for a date")
    public RoomInventoryResponse updateStopSell(
            @AuthUser Long uid,
            @PathVariable Long roomId,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestBody InventoryFlagRequest req) {
        return service.updateStopSell(uid, roomId, date, req.value());
    }

    @PatchMapping("/rooms/{roomId}/{date}/closed-arrival")
    @Operation(summary = "Update closed-to-arrival (CTA) flag for a date")
    public RoomInventoryResponse updateClosedArrival(
            @AuthUser Long uid,
            @PathVariable Long roomId,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestBody InventoryFlagRequest req) {
        return service.updateClosedArrival(uid, roomId, date, req.value());
    }

    @PatchMapping("/rooms/{roomId}/{date}/closed-departure")
    @Operation(summary = "Update closed-to-departure (CTD) flag for a date")
    public RoomInventoryResponse updateClosedDeparture(
            @AuthUser Long uid,
            @PathVariable Long roomId,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestBody InventoryFlagRequest req) {
        return service.updateClosedDeparture(uid, roomId, date, req.value());
    }

    @PutMapping("/rooms/{roomId}/price")
    @Operation(summary = "Set daily price for a date range (reuses RatePlan)")
    public RatePlanResponse updateDailyPrice(
            @AuthUser Long uid,
            @PathVariable Long roomId,
            @Valid @RequestBody RatePlanRequest req) {
        return service.updateDailyPrice(uid, roomId, req);
    }

    @GetMapping("/rooms/{roomId}/price")
    @Operation(summary = "List rate plans (daily prices) for a room")
    public List<RatePlanResponse> getPrices(@AuthUser Long uid, @PathVariable Long roomId) {
        return service.getPrices(uid, roomId);
    }
}
