package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.CategoryDto.CategoryRequest;
import com.example.planyourtrip.dto.CategoryDto.CategoryResponse;
import com.example.planyourtrip.dto.StatusRequest;
import com.example.planyourtrip.service.CategoryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/categories")
@Tag(name = "Admin - Categories", description = "Admin category management")
@SecurityRequirement(name = "bearerAuth")
public class AdminCategoryController {

    private final CategoryService service;

    public AdminCategoryController(CategoryService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "List all categories")
    public List<CategoryResponse> list() {
        return service.getAll();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a category")
    public CategoryResponse create(@Valid @RequestBody CategoryRequest req) {
        return service.create(req);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update a category")
    public CategoryResponse update(@PathVariable Long id, @Valid @RequestBody CategoryRequest req) {
        return service.update(id, req);
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Activate or deactivate a category")
    public CategoryResponse updateStatus(@PathVariable Long id, @RequestBody StatusRequest req) {
        return service.updateStatus(id, req.active());
    }
}
