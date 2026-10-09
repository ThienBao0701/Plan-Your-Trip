package com.example.planyourtrip.service;

import com.example.planyourtrip.model.AccountRole;
import com.example.planyourtrip.repository.AdminProfileAssignmentRepository;
import com.example.planyourtrip.security.UserPrincipal;
import com.example.planyourtrip.security.rbac.AdminPermission;
import com.example.planyourtrip.security.rbac.AdminProfile;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.stereotype.Service;

import java.util.Collection;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;

/**
 * The admin side of the RBAC kernel (RBAC V1.1 §7). Admin permissions have no scope.
 *
 * <p>RBAC R6: an administrator's permissions are the union of the bundles of the admin profiles they hold
 * <em>now</em> ({@code admin_profile_assignments}, §28 M-5), read on every request, so a grant or revocation
 * applies on the next request (AP-3). Deny by default: a caller who is not an {@code ADMIN} account, or an
 * {@code ADMIN} holding no profile, holds no admin permission. The M-5 backfill made every existing
 * {@code ADMIN} a {@code PLATFORM_OWNER} (AP-4), which is exactly R1's "every admin permission".
 *
 * <p>The decision reads the authorities the JWT filter derived from the account's <em>stored</em> role on this
 * request and the stored assignments; nothing about permissions is read from the token itself.
 */
@Service
public class AdminAccessService {

    private static final String ADMIN_AUTHORITY = "ROLE_" + AccountRole.ADMIN.name();

    private final AdminProfileAssignmentRepository assignments;

    public AdminAccessService(AdminProfileAssignmentRepository assignments) {
        this.assignments = assignments;
    }

    /** The admin profiles held by the authenticated caller; empty for anyone who is not an ADMIN. */
    public Set<AdminProfile> profilesOf(Authentication authentication) {
        Long userId = adminUserId(authentication);
        if (userId == null) return Set.of();
        List<AdminProfile> held = assignments.findActiveProfiles(userId);
        return held.isEmpty() ? Set.of() : Set.copyOf(EnumSet.copyOf(held));
    }

    /** The admin permissions held by the authenticated caller; empty for anyone who is not an ADMIN. */
    public Set<AdminPermission> permissionsOf(Authentication authentication) {
        return AdminProfile.permissionsOf(profilesOf(authentication));
    }

    /** True when the caller holds at least one of {@code required}; an empty requirement is never met. */
    public boolean holdsAny(Authentication authentication, Collection<AdminPermission> required) {
        if (required == null || required.isEmpty()) return false;
        Set<AdminPermission> held = permissionsOf(authentication);
        return required.stream().anyMatch(held::contains);
    }

    /** True when the caller holds {@code permission}. */
    public boolean holds(Authentication authentication, AdminPermission permission) {
        return permission != null && permissionsOf(authentication).contains(permission);
    }

    /** The caller's user id when the stored role is ADMIN, else null. */
    private static Long adminUserId(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) return null;
        boolean admin = authentication.getAuthorities().stream()
            .map(GrantedAuthority::getAuthority)
            .anyMatch(ADMIN_AUTHORITY::equals);
        if (!admin) return null;
        return authentication.getPrincipal() instanceof UserPrincipal principal ? principal.id() : null;
    }
}
