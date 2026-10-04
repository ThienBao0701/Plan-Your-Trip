package com.example.planyourtrip.security.rbac;

import java.util.Map;
import java.util.Set;

/**
 * The effective partner permissions of one caller, grouped by the scope that grants them (RBAC V1.1 §4.5
 * "Effective permission calculation", §25.2). Scope floors are already applied: a floor-COMPANY permission
 * never appears under a property, and a floor-PROPERTY permission never appears under a unit.
 */
public record EffectivePermissions(Set<PartnerPermission> company,
                                   Map<Long, Set<PartnerPermission>> properties,
                                   Map<Long, Set<PartnerPermission>> units) {

    public EffectivePermissions {
        company = company == null ? Set.of() : Set.copyOf(company);
        properties = properties == null ? Map.of() : Map.copyOf(properties);
        units = units == null ? Map.of() : Map.copyOf(units);
    }
}
