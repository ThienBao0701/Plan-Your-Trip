package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.LocationDto.LocationRequest;
import com.example.planyourtrip.dto.LocationDto.LocationResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.AdministrativeUnit;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.util.SlugUtils;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class LocationService {

    private final AdministrativeUnitRepository repo;

    public LocationService(AdministrativeUnitRepository repo) {
        this.repo = repo;
    }

    public List<LocationResponse> getRoots() {
        return repo.findByParentIsNull().stream().map(this::toResponse).toList();
    }

    public List<LocationResponse> getChildren(Long parentId) {
        getOrThrow(parentId);
        return repo.findByParentId(parentId).stream().map(this::toResponse).toList();
    }

    public List<LocationResponse> search(String keyword) {
        if (keyword == null || keyword.isBlank())
            return repo.findAll().stream().map(this::toResponse).toList();
        String kw = keyword.trim().toLowerCase();
        String nkw = SlugUtils.normalize(keyword);
        return repo.search(kw, nkw).stream().map(this::toResponse).toList();
    }

    public List<LocationResponse> getAll() {
        return repo.findAll().stream().map(this::toResponse).toList();
    }

    @Transactional
    public LocationResponse create(LocationRequest req) {
        String slug = resolveSlug(req.slug(), req.name());
        if (repo.existsBySlug(slug))
            throw new ApiException(HttpStatus.CONFLICT, "Slug already exists: " + slug);
        if (req.code() != null && repo.existsByCode(req.code()))
            throw new ApiException(HttpStatus.CONFLICT, "Code already exists: " + req.code());
        AdministrativeUnit unit = new AdministrativeUnit();
        fill(unit, req, slug);
        return toResponse(repo.save(unit));
    }

    @Transactional
    public LocationResponse update(Long id, LocationRequest req) {
        AdministrativeUnit unit = getOrThrow(id);
        String slug = resolveSlug(req.slug(), req.name());
        if (!slug.equals(unit.getSlug()) && repo.existsBySlug(slug))
            throw new ApiException(HttpStatus.CONFLICT, "Slug already exists: " + slug);
        if (req.code() != null && !req.code().equals(unit.getCode()) && repo.existsByCode(req.code()))
            throw new ApiException(HttpStatus.CONFLICT, "Code already exists: " + req.code());
        fill(unit, req, slug);
        return toResponse(repo.save(unit));
    }

    @Transactional
    public LocationResponse updateStatus(Long id, boolean active) {
        AdministrativeUnit unit = getOrThrow(id);
        unit.setActive(active);
        return toResponse(repo.save(unit));
    }

    private void fill(AdministrativeUnit unit, LocationRequest req, String slug) {
        unit.setParent(req.parentId() != null ? getOrThrow(req.parentId()) : null);
        unit.setCode(req.code());
        unit.setName(req.name());
        unit.setSlug(slug);
        unit.setNameNormalized(SlugUtils.normalize(req.name()));
        unit.setType(req.type());
        unit.setLevel(req.level());
        unit.setOldName(req.oldName());
        unit.setFullPath(req.fullPath());
        unit.setLatitude(req.latitude());
        unit.setLongitude(req.longitude());
        unit.setSortOrder(req.sortOrder());
    }

    private String resolveSlug(String slug, String name) {
        return (slug != null && !slug.isBlank()) ? slug.trim() : SlugUtils.toSlug(name);
    }

    private AdministrativeUnit getOrThrow(Long id) {
        return repo.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Location not found: " + id));
    }

    private LocationResponse toResponse(AdministrativeUnit u) {
        return new LocationResponse(
            u.getId(),
            u.getParent() != null ? u.getParent().getId() : null,
            u.getCode(),
            u.getName(),
            u.getSlug(),
            u.getType() != null ? u.getType().name() : null,
            u.getLevel(),
            u.getOldName(),
            u.getFullPath(),
            u.getLatitude(),
            u.getLongitude(),
            u.getSortOrder(),
            u.isActive(),
            u.getCreatedAt(),
            u.getUpdatedAt()
        );
    }
}
