package com.example.planyourtrip.security.rbac;

/**
 * A fully resolved location inside one company: {@code COMPANY:c}, {@code PROPERTY:p} of {@code c}, or
 * {@code UNIT:u} of property {@code p} of {@code c}. Both a grant's scope and a resource's target are
 * {@code ScopePath}s, always built by the server from stored data (§4.3 principle 4) — never from what a
 * client says a resource belongs to.
 *
 * <p>Ids are those of {@code partner_profiles}, {@code places} and {@code hotel_rooms}. A path that names a
 * unit without its property, or carries a missing or non-positive id, is malformed and cannot be built.
 */
public record ScopePath(Long companyId, Long propertyId, Long unitId) {

    public ScopePath {
        if (companyId == null || companyId <= 0)
            throw new IllegalArgumentException("A scope needs a positive company id");
        if (propertyId != null && propertyId <= 0)
            throw new IllegalArgumentException("A property id must be positive");
        if (unitId != null && (unitId <= 0 || propertyId == null))
            throw new IllegalArgumentException("A unit scope needs a positive unit id and its property");
    }

    public static ScopePath company(Long companyId) {
        return new ScopePath(companyId, null, null);
    }

    public static ScopePath property(Long companyId, Long propertyId) {
        if (propertyId == null) throw new IllegalArgumentException("A property scope needs a property id");
        return new ScopePath(companyId, propertyId, null);
    }

    public static ScopePath unit(Long companyId, Long propertyId, Long unitId) {
        if (unitId == null) throw new IllegalArgumentException("A unit scope needs a unit id");
        return new ScopePath(companyId, propertyId, unitId);
    }

    public ScopeType type() {
        if (unitId != null) return ScopeType.UNIT;
        if (propertyId != null) return ScopeType.PROPERTY;
        return ScopeType.COMPANY;
    }

    /**
     * §4.5 {@code covers(s, t)}: a company covers every property and unit of that company, a property covers
     * itself and its units, a unit covers only itself. Never upward and never across companies — a property
     * scope does not cover its company, and a unit scope does not cover its property.
     */
    public boolean covers(ScopePath target) {
        if (target == null || !companyId.equals(target.companyId)) return false;
        if (propertyId != null && !propertyId.equals(target.propertyId)) return false;
        return unitId == null || unitId.equals(target.unitId);
    }
}
