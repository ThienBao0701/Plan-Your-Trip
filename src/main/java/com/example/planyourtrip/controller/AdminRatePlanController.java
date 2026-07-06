package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.RatePlanDto.*;
import com.example.planyourtrip.service.RatePlanService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@Tag(name = "Admin - Rate Plans")
@SecurityRequirement(name = "bearerAuth")
public class AdminRatePlanController {

    private final RatePlanService service;

    public AdminRatePlanController(RatePlanService service) {
        this.service = service;
    }

    @GetMapping("/api/admin/rooms/{roomId}/rate-plans")
    @Operation(summary = "List rate plans for a room")
    public List<RatePlanResponse> listByRoom(@PathVariable Long roomId) {
        return service.getByRoom(roomId);
    }

    @PostMapping("/api/admin/rooms/{roomId}/rate-plans")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a rate plan for a room")
    public RatePlanResponse create(@PathVariable Long roomId,
                                    @Valid @RequestBody RatePlanRequest req) {
        return service.create(roomId, req);
    }

    @GetMapping("/api/admin/rate-plans/{id}")
    @Operation(summary = "Get a rate plan by ID")
    public RatePlanResponse getById(@PathVariable Long id) {
        return service.getById(id);
    }

    @PutMapping("/api/admin/rate-plans/{id}")
    @Operation(summary = "Update a rate plan")
    public RatePlanResponse update(@PathVariable Long id,
                                    @Valid @RequestBody RatePlanRequest req) {
        return service.update(id, req);
    }

    @DeleteMapping("/api/admin/rate-plans/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete a rate plan")
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }
}
