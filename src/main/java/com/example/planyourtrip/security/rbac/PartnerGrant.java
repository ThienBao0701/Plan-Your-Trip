package com.example.planyourtrip.security.rbac;

import java.util.EnumSet;
import java.util.Set;

/**
 * One grant of a partner workspace: a bundle of permissions held at one resolved scope (§4.2). Roles are
 * only a way of producing bundles; the evaluator works on bundles, so legacy rules (R1) and the V1.1 roles
 * (R3b) use the same code.
 */
public record PartnerGrant(Set<PartnerPermission> permissions, ScopePath scope) {

    public PartnerGrant {
        if (scope == null) throw new IllegalArgumentException("A grant needs a scope");
        permissions = permissions == null || permissions.isEmpty()
            ? Set.of()
            : Set.copyOf(EnumSet.copyOf(permissions));
    }
}
