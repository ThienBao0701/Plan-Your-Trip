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
    private final AdminActivityLogService adminAudit;

    public LocationService(AdministrativeUnitRepository repo, AdminActivityLogService adminAudit) {
        this.repo = repo;
        this.adminAudit = adminAudit;
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

    // -- D3I . audited administrative writes -----------------------------------
    //
    // Reference data, but administrative reference data: deactivating a category or a location
    // removes it from every place that hangs off it, and renaming one silently changes what
    // customers see. The three writes below are reached only from AdminLocationController -
    // LocationController is read-only and DataInitializer seeds through the repository directly -
    // so the audit is inline with the actor first.
    //
    // Operator text goes through AdminActivityLogService.safeText: these request DTOs put no @Size
    // bound on name or slug, and "who renamed this, and to what" is the whole question a reference
    // data audit row exists to answer, so the text is bounded and guard-checked rather than
    // dropped. Long free text (description, icon, colour, cover image URL, fullPath) is excluded.

    @Transactional
    public LocationResponse create(Long adminUserId, LocationRequest req) {
        String slug = resolveSlug(req.slug(), req.name());
        if (repo.existsBySlug(slug))
            throw new ApiException(HttpStatus.CONFLICT, "Slug already exists: " + slug);
        if (req.code() != null && repo.existsByCode(req.code()))
            throw new ApiException(HttpStatus.CONFLICT, "Code already exists: " + req.code());
        AdministrativeUnit unit = new AdministrativeUnit();
        fill(unit, req, slug);
        LocationResponse saved = toResponse(repo.save(unit));
        adminAudit.record(adminUserId, "LOCATION_CREATE", "LOCATION", saved.id(),
            "Admin created location " + saved.id(), null, summarise(saved));
        return saved;
    }

    @Transactional
    public LocationResponse update(Long adminUserId, Long id, LocationRequest req) {
        AdministrativeUnit unit = getOrThrow(id);
        // Snapshot to an immutable record before fill() mutates the managed entity.
        String before = summarise(toResponse(unit));
        String slug = resolveSlug(req.slug(), req.name());
        if (!slug.equals(unit.getSlug()) && repo.existsBySlug(slug))
            throw new ApiException(HttpStatus.CONFLICT, "Slug already exists: " + slug);
        if (req.code() != null && !req.code().equals(unit.getCode()) && repo.existsByCode(req.code()))
            throw new ApiException(HttpStatus.CONFLICT, "Code already exists: " + req.code());
        fill(unit, req, slug);
        LocationResponse saved = toResponse(repo.save(unit));
        adminAudit.record(adminUserId, "LOCATION_UPDATE", "LOCATION", id,
            "Admin updated location " + id, before, summarise(saved));
        return saved;
    }

    @Transactional
    public LocationResponse updateStatus(Long adminUserId, Long id, boolean active) {
        AdministrativeUnit unit = getOrThrow(id);
        String before = summarise(toResponse(unit));
        unit.setActive(active);
        LocationResponse saved = toResponse(repo.save(unit));
        adminAudit.record(adminUserId, "LOCATION_STATUS_UPDATE", "LOCATION", id,
            "Admin set location " + id + " active=" + active, before, summarise(saved));
        return saved;
    }

    /** oldName and fullPath are excluded - fullPath is an unbounded concatenation of ancestors. */
    private static String summarise(LocationResponse u) {
        return "active:" + u.active()
            + " parent:" + u.parentId()
            + " type:" + u.type()
            + " level:" + AdminActivityLogService.safeNumber(u.level())
            + " sortOrder:" + AdminActivityLogService.safeNumber(u.sortOrder())
            + " lat:" + AdminActivityLogService.safeNumber(u.latitude())
            + " lng:" + AdminActivityLogService.safeNumber(u.longitude())
            + " code:" + AdminActivityLogService.safeText(u.code(), 16)
            + " slug:" + AdminActivityLogService.safeText(u.slug(), 40)
            + " name:" + AdminActivityLogService.safeText(u.name(), 40);
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
