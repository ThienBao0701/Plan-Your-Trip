package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.AmenityDto.AmenityRequest;
import com.example.planyourtrip.dto.AmenityDto.AmenityResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.Amenity;
import com.example.planyourtrip.repository.AmenityRepository;
import com.example.planyourtrip.util.SlugUtils;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class AmenityService {

    private final AmenityRepository repo;
    private final AdminActivityLogService adminAudit;

    public AmenityService(AmenityRepository repo, AdminActivityLogService adminAudit) {
        this.repo = repo;
        this.adminAudit = adminAudit;
    }

    public List<AmenityResponse> getAll(String group) {
        List<Amenity> list = (group != null && !group.isBlank())
            ? repo.findByGroupName(group.toUpperCase())
            : repo.findAll();
        return list.stream().map(this::toResponse).toList();
    }

    // -- D3I . audited administrative writes -----------------------------------
    //
    // Reference data, but administrative reference data: deactivating a category or a location
    // removes it from every place that hangs off it, and renaming one silently changes what
    // customers see. The three writes below are reached only from AdminAmenityController -
    // AmenityController is read-only and DataInitializer seeds through the repository directly -
    // so the audit is inline with the actor first.
    //
    // Operator text goes through AdminActivityLogService.safeText: these request DTOs put no @Size
    // bound on name or slug, and "who renamed this, and to what" is the whole question a reference
    // data audit row exists to answer, so the text is bounded and guard-checked rather than
    // dropped. Long free text (description, icon, colour, cover image URL, fullPath) is excluded.

    @Transactional
    public AmenityResponse create(Long adminUserId, AmenityRequest req) {
        String slug = resolveSlug(req.slug(), req.name());
        if (repo.existsBySlug(slug))
            throw new ApiException(HttpStatus.CONFLICT, "Slug already exists: " + slug);
        Amenity a = new Amenity();
        fill(a, req, slug);
        AmenityResponse saved = toResponse(repo.save(a));
        adminAudit.record(adminUserId, "AMENITY_CREATE", "AMENITY", saved.id(),
            "Admin created amenity " + saved.id(), null, summarise(saved));
        return saved;
    }

    @Transactional
    public AmenityResponse update(Long adminUserId, Long id, AmenityRequest req) {
        Amenity a = getOrThrow(id);
        // Snapshot to an immutable record before fill() mutates the managed entity.
        String before = summarise(toResponse(a));
        String slug = resolveSlug(req.slug(), req.name());
        if (!slug.equals(a.getSlug()) && repo.existsBySlug(slug))
            throw new ApiException(HttpStatus.CONFLICT, "Slug already exists: " + slug);
        fill(a, req, slug);
        AmenityResponse saved = toResponse(repo.save(a));
        adminAudit.record(adminUserId, "AMENITY_UPDATE", "AMENITY", id,
            "Admin updated amenity " + id, before, summarise(saved));
        return saved;
    }

    @Transactional
    public AmenityResponse updateStatus(Long adminUserId, Long id, boolean active) {
        Amenity a = getOrThrow(id);
        String before = summarise(toResponse(a));
        a.setActive(active);
        AmenityResponse saved = toResponse(repo.save(a));
        adminAudit.record(adminUserId, "AMENITY_STATUS_UPDATE", "AMENITY", id,
            "Admin set amenity " + id + " active=" + active, before, summarise(saved));
        return saved;
    }

    private static String summarise(AmenityResponse a) {
        return "active:" + a.active()
            + " group:" + AdminActivityLogService.safeText(a.groupName(), 24)
            + " sortOrder:" + AdminActivityLogService.safeNumber(a.sortOrder())
            + " slug:" + AdminActivityLogService.safeText(a.slug(), 40)
            + " name:" + AdminActivityLogService.safeText(a.name(), 40);
    }

    private void fill(Amenity a, AmenityRequest req, String slug) {
        a.setName(req.name());
        a.setSlug(slug);
        a.setIcon(req.icon());
        a.setGroupName(req.groupName() != null ? req.groupName().toUpperCase() : null);
        a.setDescription(req.description());
        a.setSortOrder(req.sortOrder());
    }

    private String resolveSlug(String slug, String name) {
        return (slug != null && !slug.isBlank()) ? slug.trim() : SlugUtils.toSlug(name);
    }

    private Amenity getOrThrow(Long id) {
        return repo.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Amenity not found: " + id));
    }

    private AmenityResponse toResponse(Amenity a) {
        return new AmenityResponse(
            a.getId(),
            a.getName(),
            a.getSlug(),
            a.getIcon(),
            a.getGroupName(),
            a.getDescription(),
            a.getSortOrder(),
            a.isActive(),
            a.getCreatedAt(),
            a.getUpdatedAt()
        );
    }
}
