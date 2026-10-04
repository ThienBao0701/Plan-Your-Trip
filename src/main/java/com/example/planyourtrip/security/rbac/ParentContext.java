package com.example.planyourtrip.security.rbac;

import java.util.Set;

/**
 * Which minimal context a member may read to operate inside the scopes they were granted (RBAC V1.1
 * §11.7): every property of the company for a company grant, the granted property for a property grant,
 * and for a unit grant the unit and its parent property — the property's identity only, never its contact
 * details, policies, sibling units or anything behind a field-level permission.
 */
public record ParentContext(boolean companyWide, Set<Long> propertyIds, Set<Long> unitIds) {

    public ParentContext {
        propertyIds = propertyIds == null ? Set.of() : Set.copyOf(propertyIds);
        unitIds = unitIds == null ? Set.of() : Set.copyOf(unitIds);
    }
}
