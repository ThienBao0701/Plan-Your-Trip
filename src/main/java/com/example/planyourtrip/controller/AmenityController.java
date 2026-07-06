package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.AmenityDto.AmenityResponse;
import com.example.planyourtrip.service.AmenityService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/amenities")
@Tag(name = "Amenities", description = "Public amenity listing")
public class AmenityController {

    private final AmenityService service;

    public AmenityController(AmenityService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "List amenities, optionally filtered by group (GENERAL, HOTEL, ROOM, RESTAURANT, CAFE)")
    public List<AmenityResponse> list(@RequestParam(required = false) String group) {
        return service.getAll(group);
    }
}
