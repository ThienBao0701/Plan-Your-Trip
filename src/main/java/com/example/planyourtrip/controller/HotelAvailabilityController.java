package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.RatePlanDto.HotelAvailabilityResponse;
import com.example.planyourtrip.service.AvailabilityService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@Tag(name = "Availability")
public class HotelAvailabilityController {

    private final AvailabilityService service;

    public HotelAvailabilityController(AvailabilityService service) {
        this.service = service;
    }

    @GetMapping("/api/places/{placeId}/availability")
    @Operation(summary = "Search available rooms for a hotel by date range and guest count")
    public HotelAvailabilityResponse search(
            @PathVariable Long placeId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkIn,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkOut,
            @RequestParam(defaultValue = "1") int adults,
            @RequestParam(defaultValue = "0") int children) {
        return service.search(placeId, checkIn, checkOut, adults, children);
    }
}
