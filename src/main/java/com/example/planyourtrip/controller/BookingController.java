package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.BookingDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.BookingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@Tag(name = "Booking")
public class BookingController {

    private final BookingService service;

    public BookingController(BookingService service) { this.service = service; }

    @PostMapping("/api/bookings")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a new booking")
    public BookingResponse create(@AuthUser Long uid,
                                   @RequestBody @Valid BookingRequest req) {
        return service.create(uid, req);
    }

    @GetMapping("/api/bookings/{id}")
    @Operation(summary = "Get booking by ID (owner or admin only)")
    public BookingResponse getById(@AuthUser Long uid, @PathVariable Long id) {
        return service.getById(uid, id);
    }

    @GetMapping("/api/bookings/{id}/timeline")
    @Operation(summary = "Get booking timeline (owner or admin)")
    public BookingTimelineResponse getTimeline(@AuthUser Long uid, @PathVariable Long id) {
        return service.getTimeline(uid, id);
    }

    @GetMapping("/api/me/bookings")
    @Operation(summary = "List current user's bookings")
    public List<BookingSummaryResponse> getMyBookings(@AuthUser Long uid) {
        return service.getMyBookings(uid);
    }

    @GetMapping("/api/me/bookings/upcoming")
    @Operation(summary = "Upcoming bookings (PENDING / CONFIRMED / CHECK_IN_READY)")
    public List<UpcomingBookingResponse> getUpcoming(@AuthUser Long uid) {
        return service.getUpcomingBookings(uid);
    }

    @GetMapping("/api/me/bookings/history")
    @Operation(summary = "Booking history (completed / cancelled / archived)")
    public List<BookingHistoryResponse> getHistory(@AuthUser Long uid) {
        return service.getBookingHistory(uid);
    }

    @GetMapping("/api/me/bookings/active")
    @Operation(summary = "Active bookings (currently checked in)")
    public List<BookingSummaryResponse> getActive(@AuthUser Long uid) {
        return service.getActiveBookings(uid);
    }

    @PatchMapping("/api/bookings/{id}/cancel")
    @Operation(summary = "Cancel a booking (owner only)")
    public BookingResponse cancel(@AuthUser Long uid,
                                   @PathVariable Long id,
                                   @RequestBody(required = false) CancelRequest req) {
        return service.cancel(uid, id, req != null ? req.cancelReason() : null);
    }

    @PatchMapping("/api/bookings/{id}/modify")
    @Operation(summary = "Modify a PENDING booking's dates / occupancy / rate plan (owner only)")
    public BookingResponse modify(@AuthUser Long uid,
                                   @PathVariable Long id,
                                   @RequestBody @Valid BookingModificationRequest req) {
        return service.modify(uid, id, req);
    }
}
