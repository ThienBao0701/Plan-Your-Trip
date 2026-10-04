package com.example.planyourtrip.security.rbac;

import java.util.Optional;

/**
 * One entry of the frozen RBAC V1.1 permission catalogue
 * ({@code frontend/docs/security/PLAN_YOUR_TRIP_RBAC_PERMISSION_MATRIX_V1.md} §9).
 *
 * <p>The catalogue has exactly 100 entries: 54 {@link PartnerPermission}s and 46 {@link AdminPermission}s.
 * The two namespaces never satisfy each other (design R-S5): a partner check accepts only a
 * {@code PartnerPermission}, an admin check only an {@code AdminPermission}.
 *
 * <p>Identifiers ({@code P01}, {@code A46}) and keys ({@code partner.workspace.access}) are a public
 * contract with the frontend and are never renamed or reused (§8.3). Nothing about a permission is ever
 * carried in the JWT; permissions are resolved on the server for every request.
 */
public sealed interface Permission permits PartnerPermission, AdminPermission {

    /** The two namespaces of the catalogue; the key of every permission starts with one of them. */
    enum Namespace {
        PARTNER("partner."),
        ADMIN("admin.");

        private final String prefix;

        Namespace(String prefix) { this.prefix = prefix; }

        public String prefix() { return prefix; }
    }

    /** Stable identifier, e.g. {@code P14} or {@code A15}. */
    String id();

    /** Stable key, e.g. {@code partner.property.view}. */
    String key();

    Namespace namespace();

    /**
     * True for a capability that has no endpoint yet (§8.2 status {@code RESERVED}). A reserved permission
     * may sit in a bundle but protects nothing until its endpoint ships.
     */
    boolean reserved();

    /**
     * The permission named exactly by {@code key}, or empty. Matching is exact and case-sensitive; an
     * unknown, blank or null key is no permission at all (fail closed, §4.3).
     */
    static Optional<Permission> fromKey(String key) {
        if (key == null) return Optional.empty();
        Optional<Permission> partner = PartnerPermission.fromKey(key).map(p -> p);
        return partner.isPresent() ? partner : AdminPermission.fromKey(key).map(p -> p);
    }
}
