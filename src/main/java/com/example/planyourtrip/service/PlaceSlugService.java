package com.example.planyourtrip.service;

import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.util.SlugUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Phase C — the one place a {@code Place} slug is derived and made unique.
 *
 * <p>Extracted unchanged from {@code PlaceService}'s private {@code findUniqueSlug} /
 * {@code isSlugTaken} pair, which still call it: the admin catalogue keeps the exact behaviour it
 * had, and the partner property endpoints get the same algorithm instead of a second copy of it.
 *
 * <p>{@link #uniqueSlug} is a read against the current rows, so two creates racing on the same name
 * can still both settle on one candidate; the unique index on {@code places.slug} is what actually
 * decides, and the loser sees the database's constraint violation rather than a silent duplicate.
 */
@Service
@Transactional(readOnly = true)
public class PlaceSlugService {

    /**
     * The base used when a name produces no slug characters at all — a name written entirely in a
     * script {@link SlugUtils#toSlug} strips, for example. {@code PlaceService} predates this and
     * would have produced an empty slug; the partner path never does.
     */
    public static final String FALLBACK_BASE = "property";

    private final PlaceRepository places;

    public PlaceSlugService(PlaceRepository places) {
        this.places = places;
    }

    /** Returns base if available; otherwise tries base-2, base-3, … until unique. */
    public String uniqueSlug(String base, Long excludeId) {
        String candidate = base;
        int suffix = 2;
        while (isTaken(candidate, excludeId)) {
            candidate = base + "-" + suffix++;
        }
        return candidate;
    }

    /** The unique slug for a place named [name], never blank. */
    public String uniqueSlugForName(String name, Long excludeId) {
        String base = SlugUtils.toSlug(name);
        if (base == null || base.isBlank()) base = FALLBACK_BASE;
        return uniqueSlug(base, excludeId);
    }

    public boolean isTaken(String slug, Long excludeId) {
        if (excludeId == null) return places.existsBySlug(slug);
        return places.existsBySlugAndIdNot(slug, excludeId);
    }
}
