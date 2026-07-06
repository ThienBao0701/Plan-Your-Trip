package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.BookingDto.*;
import com.example.planyourtrip.service.BookingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/bookings")
@Tag(name = "Admin - Booking")
public class AdminBookingController {

    private final BookingService service;

    public AdminBookingController(BookingService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "List all bookings")
    public List<BookingSummaryResponse> getAll() {
        return service.adminGetAll();
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get booking by ID")
    public BookingResponse getById(@PathVariable Long id) {
        return service.adminGetById(id);
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Update booking status")
    public BookingResponse updateStatus(@PathVariable Long id,
                                         @RequestBody @Valid BookingStatusRequest req) {
        return service.adminUpdateStatus(id, req.status());
    }
}
