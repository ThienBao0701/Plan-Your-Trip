package com.example.planyourtrip.security.rbac;

import java.util.EnumSet;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * The normative partner evaluator of RBAC V1.1 §4.5, as pure functions over a resolved
 * {@link PartnerAccessContext}. It never reads the request and never touches the database: callers pass
 * targets the server derived from stored data.
 *
 * <p>Every method fails closed: a null context, permission, type or target, or a grant that belongs to a
 * different company, grants nothing.
 */
public final class PartnerAuthorization {

    private PartnerAuthorization() {}

    /**
     * {@code E(p)}: the scopes at which {@code permission} is held. A grant counts only if its bundle contains
     * the permission, it belongs to the workspace's company, and its type is admitted by the permission's
     * floor — a grant below the floor contributes nothing; it is never rounded up to a wider scope.
     */
    public static Set<ScopePath> effectiveScopes(PartnerAccessContext ctx, PartnerPermission permission) {
        if (ctx == null || permission == null) return Set.of();
        return ctx.grants().stream()
            .filter(grant -> grant.permissions().contains(permission))
            .map(PartnerGrant::scope)
            .filter(scope -> scope.companyId().equals(ctx.companyId()))
            .filter(scope -> permission.floor().admits(scope.type()))
            .collect(Collectors.toUnmodifiableSet());
    }

    /**
     * {@code RESOURCE}: one identified target. Allowed when an effective scope covers the target. Otherwise
     * 403 only if the caller may view resources of this type at a scope covering the target; in every other
     * case — no target, another company, or no view of this type — 404, so existence is never revealed.
     */
    public static AuthorizationDecision resource(PartnerAccessContext ctx, PartnerPermission permission,
                                                 ResourceType type, ScopePath target) {
        if (ctx == null || target == null || !target.companyId().equals(ctx.companyId())) {
            return AuthorizationDecision.NOT_FOUND;
        }
        if (covered(effectiveScopes(ctx, permission), target)) return AuthorizationDecision.ALLOW;
        if (type != null && covered(effectiveScopes(ctx, type.viewPermission()), target)) {
            return AuthorizationDecision.FORBIDDEN;
        }
        return AuthorizationDecision.NOT_FOUND;
    }

    /**
     * {@code COLLECTION}: the scope set {@code S} over which a list or aggregate is computed. An empty set
     * means the endpoint answers 403 — a collection's existence is not secret.
     */
    public static ScopeSet collection(PartnerAccessContext ctx, PartnerPermission permission) {
        if (ctx == null) throw new IllegalArgumentException("A collection needs a workspace");
        boolean companyWide = false;
        Set<Long> properties = new HashSet<>();
        Set<ScopePath> units = new HashSet<>();
        for (ScopePath scope : effectiveScopes(ctx, permission)) {
            switch (scope.type()) {
                case COMPANY -> companyWide = true;
                case PROPERTY -> properties.add(scope.propertyId());
                case UNIT -> units.add(scope);
            }
        }
        return new ScopeSet(ctx.companyId(), companyWide, properties, units);
    }

    /**
     * {@code COMPANY}: a company-level object. Requires the permission at a {@code COMPANY} scope, so a
     * property or unit grant never acts as a company grant. The one exception is workspace entry
     * ({@code P01}, floor UNIT), which any effective grant satisfies (§4.5).
     */
    public static AuthorizationDecision company(PartnerAccessContext ctx, PartnerPermission permission) {
        Set<ScopePath> scopes = effectiveScopes(ctx, permission);
        boolean allowed = permission == PartnerPermission.WORKSPACE_ACCESS
            ? !scopes.isEmpty()
            : scopes.stream().anyMatch(scope -> scope.type() == ScopeType.COMPANY);
        return allowed ? AuthorizationDecision.ALLOW : AuthorizationDecision.FORBIDDEN;
    }

    /**
     * Whether the permission named {@code permissionKey} is held at a scope covering {@code target}. An
     * unknown key, an admin key, or a missing target is never granted.
     */
    public static boolean isGranted(PartnerAccessContext ctx, String permissionKey, ScopePath target) {
        return PartnerPermission.fromKey(permissionKey)
            .map(permission -> covered(effectiveScopes(ctx, permission), target))
            .orElse(false);
    }

    /** §4.5 effective permission calculation: every held permission, listed under the scope granting it. */
    public static EffectivePermissions effectivePermissions(PartnerAccessContext ctx) {
        Set<PartnerPermission> company = EnumSet.noneOf(PartnerPermission.class);
        Map<Long, Set<PartnerPermission>> properties = new HashMap<>();
        Map<Long, Set<PartnerPermission>> units = new HashMap<>();
        for (PartnerPermission permission : PartnerPermission.values()) {
            for (ScopePath scope : effectiveScopes(ctx, permission)) {
                switch (scope.type()) {
                    case COMPANY -> company.add(permission);
                    case PROPERTY -> properties
                        .computeIfAbsent(scope.propertyId(), id -> EnumSet.noneOf(PartnerPermission.class))
                        .add(permission);
                    case UNIT -> units
                        .computeIfAbsent(scope.unitId(), id -> EnumSet.noneOf(PartnerPermission.class))
                        .add(permission);
                }
            }
        }
        Map<Long, Set<PartnerPermission>> frozenProperties = new HashMap<>();
        properties.forEach((id, set) -> frozenProperties.put(id, Set.copyOf(set)));
        Map<Long, Set<PartnerPermission>> frozenUnits = new HashMap<>();
        units.forEach((id, set) -> frozenUnits.put(id, Set.copyOf(set)));
        return new EffectivePermissions(company, frozenProperties, frozenUnits);
    }

    /**
     * §11.7 parent context: the properties and units whose minimal identity the caller may read because a
     * grant of theirs sits inside them. A unit grant yields its unit and its parent property, and nothing
     * wider.
     */
    public static ParentContext parentContext(PartnerAccessContext ctx) {
        if (ctx == null) return new ParentContext(false, Set.of(), Set.of());
        boolean companyWide = false;
        Set<Long> properties = new HashSet<>();
        Set<Long> units = new HashSet<>();
        for (PartnerGrant grant : ctx.grants()) {
            ScopePath scope = grant.scope();
            if (!scope.companyId().equals(ctx.companyId()) || grant.permissions().isEmpty()) continue;
            switch (scope.type()) {
                case COMPANY -> companyWide = true;
                case PROPERTY -> properties.add(scope.propertyId());
                case UNIT -> {
                    properties.add(scope.propertyId());
                    units.add(scope.unitId());
                }
            }
        }
        return new ParentContext(companyWide, properties, units);
    }

    private static boolean covered(Set<ScopePath> scopes, ScopePath target) {
        return target != null && scopes.stream().anyMatch(scope -> scope.covers(target));
    }
}
