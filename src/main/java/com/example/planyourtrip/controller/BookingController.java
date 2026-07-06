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

    @GetMapping("/api/me/bookings")
    @Operation(summary = "List current user's bookings")
    public List<BookingSummaryResponse> getMyBookings(@AuthUser Long uid) {
        return service.getMyBookings(uid);
    }

    @PatchMapping("/api/bookings/{id}/cancel")
    @Operation(summary = "Cancel a booking (owner only)")
    public BookingResponse cancel(@AuthUser Long uid, @PathVariable Long id) {
        return service.cancel(uid, id);
    }
}
