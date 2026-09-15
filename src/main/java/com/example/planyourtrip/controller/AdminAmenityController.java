package com.example.planyourtrip.controller;

import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.dto.AmenityDto.AmenityRequest;
import com.example.planyourtrip.dto.AmenityDto.AmenityResponse;
import com.example.planyourtrip.dto.StatusRequest;
import com.example.planyourtrip.service.AmenityService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/amenities")
@Tag(name = "Admin - Amenities", description = "Admin amenity management")
@SecurityRequirement(name = "bearerAuth")
public class AdminAmenityController {

    private final AmenityService service;

    public AdminAmenityController(AmenityService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "List all amenities")
    public List<AmenityResponse> list() {
        return service.getAll(null);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create an amenity")
    public AmenityResponse create(@AuthUser Long uid, @Valid @RequestBody AmenityRequest req) {
        return service.create(uid, req);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update an amenity")
    public AmenityResponse update(@AuthUser Long uid, @PathVariable Long id,
                                  @Valid @RequestBody AmenityRequest req) {
        return service.update(uid, id, req);
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Activate or deactivate an amenity")
    public AmenityResponse updateStatus(@AuthUser Long uid, @PathVariable Long id,
                                        @Valid @RequestBody StatusRequest req) {
        return service.updateStatus(uid, id, req.active());
    }
}
