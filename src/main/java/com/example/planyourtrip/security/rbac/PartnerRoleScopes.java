package com.example.planyourtrip.security.rbac;

import com.example.planyourtrip.model.PartnerTeamRole;

import java.util.EnumSet;
import java.util.Set;

/**
 * RBAC V1.1 §11.3 — at which scope types each partner role may be granted.
 *
 * <ul>
 *   <li>{@code OWNER} and {@code FINANCE}: company only (Q10: FINANCE stays company-only).</li>
 *   <li>{@code MANAGER}, {@code REVENUE}, {@code RESERVATIONS}, {@code FRONT_DESK}, {@code CONTENT},
 *       {@code VIEWER}: company or property.</li>
 *   <li>{@code HOUSEKEEPING}: property or unit (Q8), where a unit is a room type in V1 (Q9).</li>
 * </ul>
 * The same table is the {@code ck_partner_member_grants_role_scope} constraint of V5; a grant outside it
 * is refused when it is written ({@code 422 SCOPE_INVALID}). An unknown role is allowed nowhere.
 */
public final class PartnerRoleScopes {

    private PartnerRoleScopes() {}

    public static Set<ScopeType> allowed(PartnerTeamRole role) {
        if (role == null) return Set.of();
        return switch (role) {
            case OWNER, FINANCE -> Set.of(ScopeType.COMPANY);
            case MANAGER, REVENUE, RESERVATIONS, FRONT_DESK, CONTENT, VIEWER ->
                Set.copyOf(EnumSet.of(ScopeType.COMPANY, ScopeType.PROPERTY));
            case HOUSEKEEPING -> Set.copyOf(EnumSet.of(ScopeType.PROPERTY, ScopeType.UNIT));
        };
    }

    public static boolean allows(PartnerTeamRole role, ScopeType type) {
        return type != null && allowed(role).contains(type);
    }
}
