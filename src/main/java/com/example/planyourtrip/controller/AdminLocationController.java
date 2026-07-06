package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.LocationDto.LocationRequest;
import com.example.planyourtrip.dto.LocationDto.LocationResponse;
import com.example.planyourtrip.dto.StatusRequest;
import com.example.planyourtrip.service.LocationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/locations")
@Tag(name = "Admin - Locations", description = "Admin location management")
@SecurityRequirement(name = "bearerAuth")
public class AdminLocationController {

    private final LocationService service;

    public AdminLocationController(LocationService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "List all locations")
    public List<LocationResponse> list() {
        return service.getAll();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a location")
    public LocationResponse create(@Valid @RequestBody LocationRequest req) {
        return service.create(req);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update a location")
    public LocationResponse update(@PathVariable Long id, @Valid @RequestBody LocationRequest req) {
        return service.update(id, req);
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Activate or deactivate a location")
    public LocationResponse updateStatus(@PathVariable Long id, @RequestBody StatusRequest req) {
        return service.updateStatus(id, req.active());
    }
}
