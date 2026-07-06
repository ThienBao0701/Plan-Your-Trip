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

    public AmenityService(AmenityRepository repo) {
        this.repo = repo;
    }

    public List<AmenityResponse> getAll(String group) {
        List<Amenity> list = (group != null && !group.isBlank())
            ? repo.findByGroupName(group.toUpperCase())
            : repo.findAll();
        return list.stream().map(this::toResponse).toList();
    }

    @Transactional
    public AmenityResponse create(AmenityRequest req) {
        String slug = resolveSlug(req.slug(), req.name());
        if (repo.existsBySlug(slug))
            throw new ApiException(HttpStatus.CONFLICT, "Slug already exists: " + slug);
        Amenity a = new Amenity();
        fill(a, req, slug);
        return toResponse(repo.save(a));
    }

    @Transactional
    public AmenityResponse update(Long id, AmenityRequest req) {
        Amenity a = getOrThrow(id);
        String slug = resolveSlug(req.slug(), req.name());
        if (!slug.equals(a.getSlug()) && repo.existsBySlug(slug))
            throw new ApiException(HttpStatus.CONFLICT, "Slug already exists: " + slug);
        fill(a, req, slug);
        return toResponse(repo.save(a));
    }

    @Transactional
    public AmenityResponse updateStatus(Long id, boolean active) {
        Amenity a = getOrThrow(id);
        a.setActive(active);
        return toResponse(repo.save(a));
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
