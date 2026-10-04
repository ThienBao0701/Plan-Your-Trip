package com.example.planyourtrip.security.rbac;

import org.springframework.web.bind.annotation.RequestMethod;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

/**
 * How one partner handler is authorized — one row of RBAC V1.1 §25.1.
 *
 * @param permissions      the primary permission; several when {@code condition} says which applies
 * @param condition        null for a single permission; otherwise when each listed permission is required
 *                         (field-diff, OWNER changes, or "after approval" for onboarding)
 * @param fieldPermissions permissions that gate individual response fields (§21.2)
 * @param aggregate        for report endpoints: computed over the caller's scope set or company only
 * @param stepUp           whether the action always needs a fresh token (§18 O-7)
 */
public record PartnerEndpointRule(RequestMethod method, String pattern, EndpointKind kind,
                                  ResourceType resourceType, List<PartnerPermission> permissions,
                                  String condition, Set<PartnerPermission> fieldPermissions,
                                  AggregateScope aggregate, boolean stepUp) {

    /** §25.1 "Aggregate" column. */
    public enum AggregateScope { NONE, FILTERABLE_BY_PROPERTY, COMPANY_ONLY }

    public PartnerEndpointRule {
        permissions = List.copyOf(permissions);
        fieldPermissions = Set.copyOf(fieldPermissions);
    }

    public String key() {
        return EndpointAuthorizationRegistry.key(method, pattern);
    }

    public boolean conditional() {
        return condition != null;
    }

    PartnerEndpointRule withFields(PartnerPermission... fields) {
        return new PartnerEndpointRule(method, pattern, kind, resourceType, permissions, condition,
            Set.of(fields), aggregate, stepUp);
    }

    PartnerEndpointRule withAggregate(AggregateScope scope) {
        return new PartnerEndpointRule(method, pattern, kind, resourceType, permissions, condition,
            fieldPermissions, scope, stepUp);
    }

    PartnerEndpointRule when(String whenEachApplies, PartnerPermission... additional) {
        List<PartnerPermission> all = new ArrayList<>(permissions);
        all.addAll(List.of(additional));
        return new PartnerEndpointRule(method, pattern, kind, resourceType, all, whenEachApplies,
            fieldPermissions, aggregate, stepUp);
    }

    PartnerEndpointRule withStepUp() {
        return new PartnerEndpointRule(method, pattern, kind, resourceType, permissions, condition,
            fieldPermissions, aggregate, true);
    }
}
