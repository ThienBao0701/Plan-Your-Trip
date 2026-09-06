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
    private final AdminActivityLogService adminAudit;

    public CategoryService(CategoryRepository repo, AdminActivityLogService adminAudit) {
        this.repo = repo;
        this.adminAudit = adminAudit;
    }

    public List<CategoryResponse> getAll() {
        return repo.findAll().stream().map(this::toResponse).toList();
    }

    public List<CategoryTreeResponse> getTree() {
        return repo.findByParentIsNull().stream().map(this::toTreeResponse).toList();
    }

    // -- D3I . audited administrative writes -----------------------------------
    //
    // Reference data, but administrative reference data: deactivating a category or a location
    // removes it from every place that hangs off it, and renaming one silently changes what
    // customers see. The three writes below are reached only from AdminCategoryController -
    // CategoryController is read-only and DataInitializer seeds through the repository directly -
    // so the audit is inline with the actor first.
    //
    // Operator text goes through AdminActivityLogService.safeText: these request DTOs put no @Size
    // bound on name or slug, and "who renamed this, and to what" is the whole question a reference
    // data audit row exists to answer, so the text is bounded and guard-checked rather than
    // dropped. Long free text (description, icon, colour, cover image URL, fullPath) is excluded.

    @Transactional
    public CategoryResponse create(Long adminUserId, CategoryRequest req) {
        String slug = resolveSlug(req.slug(), req.name());
        if (repo.existsBySlug(slug))
            throw new ApiException(HttpStatus.CONFLICT, "Slug already exists: " + slug);
        Category cat = new Category();
        fill(cat, req, slug);
        CategoryResponse saved = toResponse(repo.save(cat));
        adminAudit.record(adminUserId, "CATEGORY_CREATE", "CATEGORY", saved.id(),
            "Admin created category " + saved.id(), null, summarise(saved));
        return saved;
    }

    @Transactional
    public CategoryResponse update(Long adminUserId, Long id, CategoryRequest req) {
        Category cat = getOrThrow(id);
        // Snapshot to an immutable record before fill() mutates the managed entity.
        String before = summarise(toResponse(cat));
        String slug = resolveSlug(req.slug(), req.name());
        if (!slug.equals(cat.getSlug()) && repo.existsBySlug(slug))
            throw new ApiException(HttpStatus.CONFLICT, "Slug already exists: " + slug);
        fill(cat, req, slug);
        CategoryResponse saved = toResponse(repo.save(cat));
        adminAudit.record(adminUserId, "CATEGORY_UPDATE", "CATEGORY", id,
            "Admin updated category " + id, before, summarise(saved));
        return saved;
    }

    @Transactional
    public CategoryResponse updateStatus(Long adminUserId, Long id, boolean active) {
        Category cat = getOrThrow(id);
        String before = summarise(toResponse(cat));
        cat.setActive(active);
        CategoryResponse saved = toResponse(repo.save(cat));
        adminAudit.record(adminUserId, "CATEGORY_STATUS_UPDATE", "CATEGORY", id,
            "Admin set category " + id + " active=" + active, before, summarise(saved));
        return saved;
    }

    /** The cover image URL is deliberately excluded - it can be a signed URL. */
    private static String summarise(CategoryResponse c) {
        return "active:" + c.active()
            + " parent:" + c.parentId()
            + " type:" + AdminActivityLogService.safeText(c.type(), 24)
            + " sortOrder:" + AdminActivityLogService.safeNumber(c.sortOrder())
            + " slug:" + AdminActivityLogService.safeText(c.slug(), 40)
            + " name:" + AdminActivityLogService.safeText(c.name(), 40);
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
