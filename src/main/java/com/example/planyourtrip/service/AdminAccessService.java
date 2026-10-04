package com.example.planyourtrip.service;

import com.example.planyourtrip.model.AccountRole;
import com.example.planyourtrip.security.rbac.AdminPermission;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.stereotype.Service;

import java.util.Collection;
import java.util.EnumSet;
import java.util.Set;

/**
 * The admin side of the RBAC kernel (RBAC V1.1 §7). Admin permissions have no scope.
 *
 * <p>Phase R1 holds today's rule: every {@code ADMIN} account has every admin permission — exactly the
 * {@code PLATFORM_OWNER} backfill of §7 AP-4 — so no administrator loses access. Admin profiles, and with
 * them narrower permission sets, arrive in R6 by changing {@link #permissionsOf} only.
 *
 * <p>The decision reads the authorities the JWT filter derived from the account's <em>stored</em> role on this
 * request; nothing about permissions is read from the token itself.
 */
@Service
public class AdminAccessService {

    private static final String ADMIN_AUTHORITY = "ROLE_" + AccountRole.ADMIN.name();

    /** The admin permissions held by the authenticated caller; empty for anyone who is not an ADMIN. */
    public Set<AdminPermission> permissionsOf(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) return Set.of();
        boolean admin = authentication.getAuthorities().stream()
            .map(GrantedAuthority::getAuthority)
            .anyMatch(ADMIN_AUTHORITY::equals);
        return admin ? Set.copyOf(EnumSet.allOf(AdminPermission.class)) : Set.of();
    }

    /** True when the caller holds at least one of {@code required}; an empty requirement is never met. */
    public boolean holdsAny(Authentication authentication, Collection<AdminPermission> required) {
        if (required == null || required.isEmpty()) return false;
        Set<AdminPermission> held = permissionsOf(authentication);
        return required.stream().anyMatch(held::contains);
    }
}
