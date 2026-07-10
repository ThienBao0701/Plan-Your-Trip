package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.BookingDto.*;
import com.example.planyourtrip.service.BookingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/admin/bookings")
@Tag(name = "Admin - Booking")
public class AdminBookingController {

    private final BookingService service;

    public AdminBookingController(BookingService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "List / search bookings (admin)")
    public List<BookingSummaryResponse> getAll(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String hotel,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) String guest,
            @RequestParam(required = false) String bookingCode) {
        boolean hasFilter = status != null || hotel != null || date != null
                            || guest != null || bookingCode != null;
        return hasFilter
            ? service.adminSearch(status, hotel, date, guest, bookingCode)
            : service.adminGetAll();
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get booking by ID")
    public BookingResponse getById(@PathVariable Long id) {
        return service.adminGetById(id);
    }

    @GetMapping("/{id}/timeline")
    @Operation(summary = "Get booking timeline")
    public BookingTimelineResponse getTimeline(@PathVariable Long id) {
        return service.adminGetTimeline(id);
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Force-set booking status (admin override)")
    public BookingResponse updateStatus(@PathVariable Long id,
                                         @RequestBody @Valid BookingStatusRequest req) {
        return service.adminUpdateStatus(id, req.status());
    }

    @PatchMapping("/{id}/check-in")
    @Operation(summary = "Check in guest (requires CONFIRMED or CHECK_IN_READY)")
    public BookingResponse checkIn(@PathVariable Long id) {
        return service.adminCheckIn(id);
    }

    @PatchMapping("/{id}/check-out")
    @Operation(summary = "Check out guest (requires CHECKED_IN)")
    public BookingResponse checkOut(@PathVariable Long id) {
        return service.adminCheckOut(id);
    }

    @PatchMapping("/{id}/complete")
    @Operation(summary = "Complete reservation (requires CHECKED_OUT)")
    public BookingResponse complete(@PathVariable Long id) {
        return service.adminComplete(id);
    }

    @PatchMapping("/{id}/archive")
    @Operation(summary = "Archive reservation (requires COMPLETED)")
    public BookingResponse archive(@PathVariable Long id) {
        return service.adminArchive(id);
    }

    @PostMapping("/{id}/refund-to-credits")
    @Operation(summary = "Refund a CANCELLED booking's PAID payment as promotional travel credits "
        + "(booking and payment become REFUNDED; idempotent REFUND_CREDIT ledger row)")
    public BookingResponse refundToCredits(@PathVariable Long id) {
        return service.adminRefundToCredits(id);
    }
}
