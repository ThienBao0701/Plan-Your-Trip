package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.CategoryDto.CategoryResponse;
import com.example.planyourtrip.dto.CategoryDto.CategoryTreeResponse;
import com.example.planyourtrip.service.CategoryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/categories")
@Tag(name = "Categories", description = "Public category browsing")
public class CategoryController {

    private final CategoryService service;

    public CategoryController(CategoryService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "List all categories (flat)")
    public List<CategoryResponse> list() {
        return service.getAll();
    }

    @GetMapping("/tree")
    @Operation(summary = "Get full category tree with children nested")
    public List<CategoryTreeResponse> tree() {
        return service.getTree();
    }
}
