package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.LocationDto.LocationResponse;
import com.example.planyourtrip.service.LocationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/locations")
@Tag(name = "Locations", description = "Public location search and browsing")
public class LocationController {

    private final LocationService service;

    public LocationController(LocationService service) {
        this.service = service;
    }

    @GetMapping("/roots")
    @Operation(summary = "Get top-level locations")
    public List<LocationResponse> roots() {
        return service.getRoots();
    }

    @GetMapping("/{id}/children")
    @Operation(summary = "Get children of a location")
    public List<LocationResponse> children(@PathVariable Long id) {
        return service.getChildren(id);
    }

    @GetMapping("/search")
    @Operation(summary = "Search locations by keyword (supports Vietnamese names, slug, oldName)")
    public List<LocationResponse> search(@RequestParam(defaultValue = "") String keyword) {
        return service.search(keyword);
    }
}
