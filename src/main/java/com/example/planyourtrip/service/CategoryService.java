package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.CategoryDto.CategoryRequest;
import com.example.planyourtrip.dto.CategoryDto.CategoryResponse;
import com.example.planyourtrip.dto.CategoryDto.CategoryTreeResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.Category;
import com.example.planyourtrip.repository.CategoryRepository;
import com.example.planyourtrip.util.SlugUtils;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class CategoryService {

    private final CategoryRepository repo;

    public CategoryService(CategoryRepository repo) {
        this.repo = repo;
    }

    public List<CategoryResponse> getAll() {
        return repo.findAll().stream().map(this::toResponse).toList();
    }

    public List<CategoryTreeResponse> getTree() {
        return repo.findByParentIsNull().stream().map(this::toTreeResponse).toList();
    }

    @Transactional
    public CategoryResponse create(CategoryRequest req) {
        String slug = resolveSlug(req.slug(), req.name());
        if (repo.existsBySlug(slug))
            throw new ApiException(HttpStatus.CONFLICT, "Slug already exists: " + slug);
        Category cat = new Category();
        fill(cat, req, slug);
        return toResponse(repo.save(cat));
    }

    @Transactional
    public CategoryResponse update(Long id, CategoryRequest req) {
        Category cat = getOrThrow(id);
        String slug = resolveSlug(req.slug(), req.name());
        if (!slug.equals(cat.getSlug()) && repo.existsBySlug(slug))
            throw new ApiException(HttpStatus.CONFLICT, "Slug already exists: " + slug);
        fill(cat, req, slug);
        return toResponse(repo.save(cat));
    }

    @Transactional
    public CategoryResponse updateStatus(Long id, boolean active) {
        Category cat = getOrThrow(id);
        cat.setActive(active);
        return toResponse(repo.save(cat));
    }

    private void fill(Category cat, CategoryRequest req, String slug) {
        cat.setParent(req.parentId() != null ? getOrThrow(req.parentId()) : null);
        cat.setName(req.name());
        cat.setSlug(slug);
        cat.setType(req.type());
        cat.setIcon(req.icon());
        cat.setColor(req.color());
        cat.setCoverImageUrl(req.coverImageUrl());
        cat.setSortOrder(req.sortOrder());
    }

    private String resolveSlug(String slug, String name) {
        return (slug != null && !slug.isBlank()) ? slug.trim() : SlugUtils.toSlug(name);
    }

    private Category getOrThrow(Long id) {
        return repo.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Category not found: " + id));
    }

    private CategoryResponse toResponse(Category c) {
        return new CategoryResponse(
            c.getId(),
            c.getParent() != null ? c.getParent().getId() : null,
            c.getName(),
            c.getSlug(),
            c.getType(),
            c.getIcon(),
            c.getColor(),
            c.getCoverImageUrl(),
            c.getSortOrder(),
            c.isActive(),
            c.getCreatedAt(),
            c.getUpdatedAt()
        );
    }

    private CategoryTreeResponse toTreeResponse(Category c) {
        List<Category> children = repo.findByParentId(c.getId());
        return new CategoryTreeResponse(
            c.getId(),
            c.getParent() != null ? c.getParent().getId() : null,
            c.getName(),
            c.getSlug(),
            c.getType(),
            c.getIcon(),
            c.getColor(),
            c.getCoverImageUrl(),
            c.getSortOrder(),
            c.isActive(),
            children.stream().map(this::toTreeResponse).toList()
        );
    }
}
