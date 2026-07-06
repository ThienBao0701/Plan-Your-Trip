package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PromotionDto.*;
import com.example.planyourtrip.service.PromotionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/promotions")
@Tag(name = "Admin - Promotions")
@SecurityRequirement(name = "bearerAuth")
public class AdminPromotionController {

    private final PromotionService service;

    public AdminPromotionController(PromotionService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "List all promotions")
    public List<PromotionResponse> listAll() {
        return service.getAll();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a promotion")
    public PromotionResponse create(@Valid @RequestBody PromotionRequest req) {
        return service.create(req);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get a promotion by ID")
    public PromotionResponse getById(@PathVariable Long id) {
        return service.getById(id);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update a promotion")
    public PromotionResponse update(@PathVariable Long id,
                                     @Valid @RequestBody PromotionRequest req) {
        return service.update(id, req);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete a promotion")
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }
}
