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

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
@Transactional(readOnly = true)
public class LocationService {

    /**
     * D12 — the separator every derived {@code fullPath} uses.
     *
     * <p>Deliberately identical to the one {@code DataInitializer} has always written
     * ({@code parent.fullPath + " > " + name}), so a backfill over the seeded tree is a no-op and
     * no customer-visible text moves. The traveller app splits on this token to show a place's
     * province, so it is a published format, not an internal detail.
     */
    public static final String PATH_SEPARATOR = " > ";

    /**
     * Hard stop for every downward tree walk (cycle guard, cascade, backfill).
     *
     * <p>The visited sets already make a walk terminate; this is the second, independent bound, so
     * malformed legacy data can never turn a request into an unbounded loop.
     */
    private static final int MAX_TREE_DEPTH = 64;

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

    /**
     * Public keyword search.
     *
     * <p>D12 — a blank or missing keyword returns <b>no rows</b>. It used to fall through to
     * {@code findAll()}, which made an unauthenticated {@code GET /api/locations/search} a complete,
     * uncapped export of the location table; that is fine at the seeded size and is a free
     * full-table dump once the ward/commune tiers exist. Returning empty rather than a capped page
     * keeps the endpoint's shape exactly as it was (a 200 with a JSON array) and introduces no
     * paging contract, which is out of D12's scope.
     *
     * <p>Search with an actual keyword is unchanged, down to the query.
     */
    public List<LocationResponse> search(String keyword) {
        if (keyword == null || keyword.isBlank()) return List.of();
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
        // A row that does not exist yet has no descendants, so no cycle is reachable here. The
        // guard is still called so the two write paths share one rule and a later change cannot
        // quietly skip it on create.
        AdministrativeUnit parent = resolveParent(null, req.parentId());
        fill(unit, req, slug, parent);
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
        AdministrativeUnit parent = resolveParent(id, req.parentId());
        fill(unit, req, slug, parent);
        AdministrativeUnit persisted = repo.save(unit);
        // The node's own path has just been rewritten from the live hierarchy; every descendant
        // hangs off it and must follow. Same transaction as the mutation and the audit row, so a
        // failure anywhere leaves no half-updated subtree behind.
        cascadePaths(persisted);
        LocationResponse saved = toResponse(persisted);
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

    /**
     * Applies the request to the entity. [parent] has already been resolved and cycle-checked by
     * {@link #resolveParent}.
     *
     * <p><b>{@code req.fullPath()} is deliberately ignored.</b> The path is derived from the live
     * hierarchy instead, so a client that sends a stale, hand-typed or simply absent value cannot
     * put wrong ancestry in front of customers — {@code PlaceDto.LocationRef} publishes this string
     * on every place, and the traveller app parses it into the place's province. The field stays on
     * the request record for wire compatibility (the D11 console echoes it back on every PUT); it
     * is read by nothing.
     */
    private void fill(AdministrativeUnit unit, LocationRequest req, String slug,
                      AdministrativeUnit parent) {
        unit.setParent(parent);
        unit.setCode(req.code());
        unit.setName(req.name());
        unit.setSlug(slug);
        unit.setNameNormalized(SlugUtils.normalize(req.name()));
        unit.setType(req.type());
        unit.setLevel(req.level());
        unit.setOldName(req.oldName());
        unit.setFullPath(derivePath(parent, req.name()));
        unit.setLatitude(req.latitude());
        unit.setLongitude(req.longitude());
        unit.setSortOrder(req.sortOrder());
    }

    // ── D12: hierarchy safety and derived paths ───────────────────────────────
    //
    // Three rules, all enforced here rather than in any client:
    //
    //   1. a location may never become its own ancestor;
    //   2. `fullPath` is derived from the live hierarchy, never accepted from the caller;
    //   3. moving or renaming a location rewrites every descendant's path in the same transaction.
    //
    // Rule 2 is the one with customer-facing weight: the string is published in
    // `PlaceDto.LocationRef` and parsed by the traveller app into a place's province, which is in
    // turn a match key in its hotel-destination and saved-place searches.

    /**
     * Resolves and validates the proposed parent.
     *
     * @param selfId the row being updated, or {@code null} on create
     * @return the parent entity, or {@code null} for a root
     * @throws ApiException 404 when the parent id does not exist (unchanged behaviour),
     *                      400 when the parent is the node itself or one of its descendants
     */
    private AdministrativeUnit resolveParent(Long selfId, Long parentId) {
        if (parentId == null) return null;
        if (selfId != null && selfId.equals(parentId)) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "A location cannot be its own parent: " + selfId);
        }
        // 404 first, so an unknown parent keeps answering exactly as it did before D12.
        AdministrativeUnit parent = getOrThrow(parentId);
        if (selfId != null && descendantIdsOf(selfId).contains(parentId)) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "A location cannot be moved under its own descendant: " + parentId);
        }
        return parent;
    }

    /**
     * Every id reachable downwards from [rootId], excluding itself.
     *
     * <p>Breadth-first, one query per level. The visited set means an existing cycle in legacy data
     * is traversed once instead of forever, and {@link #MAX_TREE_DEPTH} bounds the walk a second
     * time.
     */
    private Set<Long> descendantIdsOf(Long rootId) {
        Set<Long> found = new LinkedHashSet<>();
        List<Long> frontier = List.of(rootId);
        for (int depth = 0; depth < MAX_TREE_DEPTH && !frontier.isEmpty(); depth++) {
            List<Long> next = new ArrayList<>();
            for (AdministrativeUnit child : repo.findByParentIdIn(frontier)) {
                Long childId = child.getId();
                if (childId == null || childId.equals(rootId) || !found.add(childId)) continue;
                next.add(childId);
            }
            frontier = next;
        }
        return found;
    }

    /**
     * The path a location must carry, given its parent and name.
     *
     * <p>A root is just its own trimmed name; a child is its parent's path, this separator, and its
     * own name — the rule {@code DataInitializer} has always used.
     *
     * <p>When a parent carries no stored path at all (only possible for legacy rows that predate
     * the backfill) the parent's <em>name</em> is used as the base. That keeps the derivation
     * deterministic and built only from real data rather than dropping the ancestry entirely.
     */
    private static String derivePath(AdministrativeUnit parent, String name) {
        if (parent == null) return joinPath(null, name);
        String base = parent.getFullPath();
        if (base == null || base.isBlank()) base = parent.getName();
        return joinPath(base, name);
    }

    /**
     * The one place a path is assembled from a parent path and a child name.
     *
     * <p>Public and static so the one-time backfill builds paths with exactly this rule rather
     * than a second copy of it — the backfill walks top-down and already holds each parent's
     * freshly derived path, so it needs the string form, not the entity.
     *
     * @param parentPath the parent's derived path, or {@code null}/blank for a root
     */
    public static String joinPath(String parentPath, String name) {
        String trimmed = name == null ? "" : name.trim();
        if (parentPath == null || parentPath.isBlank()) return trimmed;
        return parentPath + PATH_SEPARATOR + trimmed;
    }

    /**
     * Rewrites every descendant's path beneath [node], breadth-first.
     *
     * <p>Runs inside the caller's transaction, so the node, its whole subtree and the audit row
     * commit or roll back together — there is no state in which half a subtree points at the old
     * ancestry.
     *
     * @return how many descendants actually changed
     */
    private int cascadePaths(AdministrativeUnit node) {
        if (node.getId() == null) return 0;
        int changed = 0;
        Set<Long> visited = new HashSet<>();
        visited.add(node.getId());

        // id -> the path that node now carries. Read from here rather than from the parent entity,
        // so a child's derivation never depends on when the ORM happens to flush its parent.
        Map<Long, String> pathById = new HashMap<>();
        pathById.put(node.getId(), node.getFullPath());
        List<Long> frontier = List.of(node.getId());

        for (int depth = 0; depth < MAX_TREE_DEPTH && !frontier.isEmpty(); depth++) {
            List<Long> next = new ArrayList<>();
            for (AdministrativeUnit child : repo.findByParentIdIn(frontier)) {
                // A pre-existing cycle would otherwise revisit a node forever.
                if (child.getId() == null || !visited.add(child.getId())) continue;
                AdministrativeUnit parent = child.getParent();
                String parentPath = parent == null ? null : pathById.get(parent.getId());
                String derived = joinPath(parentPath, child.getName());
                pathById.put(child.getId(), derived);
                if (!derived.equals(child.getFullPath())) {
                    child.setFullPath(derived);
                    repo.save(child);
                    changed++;
                }
                next.add(child.getId());
            }
            frontier = next;
        }
        return changed;
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
