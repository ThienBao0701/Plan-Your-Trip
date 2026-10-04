package com.example.planyourtrip.security.rbac;

import java.util.Set;

/**
 * The scope set {@code S} of RBAC V1.1 §4.5 for one permission: what a {@code COLLECTION} endpoint may list
 * or aggregate. A company grant makes it company-wide; a property grant adds that property only; a unit
 * grant adds that unit only. A narrower grant never widens: a property grant never makes the set
 * company-wide.
 */
public record ScopeSet(Long companyId, boolean companyWide, Set<Long> propertyIds, Set<ScopePath> units) {

    public ScopeSet {
        if (companyId == null) throw new IllegalArgumentException("A scope set belongs to one company");
        propertyIds = propertyIds == null ? Set.of() : Set.copyOf(propertyIds);
        units = units == null ? Set.of() : Set.copyOf(units);
    }

    /** True when the permission is held nowhere — the endpoint answers 403 (§26 E7). */
    public boolean isEmpty() {
        return !companyWide && propertyIds.isEmpty() && units.isEmpty();
    }

    /**
     * Whether an item at {@code target} belongs to this set. Used for every row of a collection and for an
     * optional filter such as {@code ?hotelId=}: a filter outside the set is answered like a missing id.
     */
    public boolean permits(ScopePath target) {
        if (target == null || !companyId.equals(target.companyId())) return false;
        if (companyWide) return true;
        if (target.propertyId() != null && propertyIds.contains(target.propertyId())) return true;
        return units.stream().anyMatch(unit -> unit.covers(target));
    }
}
