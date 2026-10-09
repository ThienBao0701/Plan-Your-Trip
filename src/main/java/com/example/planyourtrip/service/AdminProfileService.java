package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.AdminAccessDto.AdminAccessResponse;
import com.example.planyourtrip.dto.AdminAccessDto.AdminAccountResponse;
import com.example.planyourtrip.dto.AdminAccessDto.ReplaceProfilesRequest;
import com.example.planyourtrip.dto.AdminAccessDto.StepUp;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.AccountRole;
import com.example.planyourtrip.model.AdminProfileAssignment;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.AdminProfileAssignmentRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.security.StepUpPolicy;
import com.example.planyourtrip.security.rbac.AdminPermission;
import com.example.planyourtrip.security.rbac.AdminProfile;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * RBAC R6 — admin profiles: the caller's access document and access management (RBAC V1.1 §7 AP-1…AP-4, §25.4).
 *
 * <ul>
 *   <li><b>AP-1</b> only a {@code PLATFORM_OWNER} grants or revokes profiles, and nobody changes their own profiles
 *       ({@code SELF_MODIFICATION_FORBIDDEN}, as E12). The actor's {@code PLATFORM_OWNER} grant is re-read under the
 *       lock below, so an actor revoked a moment earlier cannot act on a stale view.</li>
 *   <li><b>AP-2</b> at least one enabled {@code ADMIN} keeps an active {@code PLATFORM_OWNER} grant
 *       ({@code 409 LAST_PLATFORM_OWNER_REQUIRED}). Every change locks the active {@code PLATFORM_OWNER} rows
 *       first, so two owners revoking each other are serialised.</li>
 *   <li><b>AP-3</b> changes apply on the next request (permissions are read per request) and each granted or
 *       revoked profile writes {@code ADMIN_PROFILE_GRANT} / {@code ADMIN_PROFILE_REVOKE} in the same transaction
 *       (the strict admin trail: a failed audit write fails the change).</li>
 * </ul>
 * Only {@code ADMIN} accounts hold profiles: granting one to any other account would be a privilege escalation, so
 * such a target is answered as not found. The step-up freshness this change requires is enforced by the endpoint
 * registry before the handler runs.
 */
@Service
public class AdminProfileService {

    public static final String LAST_PLATFORM_OWNER_REQUIRED = "LAST_PLATFORM_OWNER_REQUIRED";
    public static final String SELF_MODIFICATION_FORBIDDEN = "SELF_MODIFICATION_FORBIDDEN";

    private final AdminProfileAssignmentRepository assignments;
    private final UserRepository users;
    private final AdminAccessService access;
    private final AdminActivityLogService audit;
    private final StepUpPolicy stepUp;
    private final Clock clock;

    public AdminProfileService(AdminProfileAssignmentRepository assignments, UserRepository users,
                               AdminAccessService access, AdminActivityLogService audit, StepUpPolicy stepUp,
                               Clock clock) {
        this.assignments = assignments;
        this.users = users;
        this.access = access;
        this.audit = audit;
        this.stepUp = stepUp;
        this.clock = clock;
    }

    /** {@code GET /api/admin/me/access}. */
    @Transactional(readOnly = true)
    public AdminAccessResponse accessOf(Long userId, Authentication authentication) {
        User user = users.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Authentication required"));
        Set<AdminProfile> profiles = access.profilesOf(authentication);
        List<String> permissions = AdminProfile.permissionsOf(profiles).stream()
            .filter(p -> !p.reserved())
            .map(AdminPermission::key)
            .sorted()
            .toList();
        return new AdminAccessResponse(user.getId(), user.getEmail(), user.getFullName(), names(profiles),
            permissions, new StepUp(stepUp.freshUntil()));
    }

    /** {@code GET /api/admin/access/admins} — every ADMIN account and its active profiles. */
    @Transactional(readOnly = true)
    public List<AdminAccountResponse> listAdmins(Long actorUserId) {
        List<User> admins = users.findByRoleOrderByEmailAsc(AccountRole.ADMIN.name());
        if (admins.isEmpty()) return List.of();
        Map<Long, Set<AdminProfile>> held = new LinkedHashMap<>();
        for (AdminProfileAssignment a : assignments.findActiveByUserIds(admins.stream().map(User::getId).toList())) {
            held.computeIfAbsent(a.getUser().getId(), k -> EnumSet.noneOf(AdminProfile.class)).add(a.getProfile());
        }
        return admins.stream()
            .map(u -> account(u, actorUserId, held.getOrDefault(u.getId(), Set.of())))
            .toList();
    }

    /** {@code PUT /api/admin/access/admins/{userId}/profiles} — replaces the administrator's profiles. */
    @Transactional
    public AdminAccountResponse replaceProfiles(Long actorUserId, Long targetUserId, ReplaceProfilesRequest request) {
        Set<AdminProfile> desired = parse(request.profiles());
        String reason = request.reason() == null || request.reason().isBlank() ? null : request.reason().trim();
        if (AdminActivityLogService.looksLikeCredential(reason)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "VALIDATION_FAILED", "reason",
                "The reason must not contain credentials");
        }
        if (targetUserId == null || targetUserId.equals(actorUserId)) {
            throw new ApiException(HttpStatus.FORBIDDEN, SELF_MODIFICATION_FORBIDDEN,
                "You cannot change your own admin profiles");
        }
        User target = users.findById(targetUserId)
            .filter(u -> AccountRole.ADMIN.name().equals(u.getRole()))
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Administrator not found"));

        // AP-2 / AP-1 under one lock: the active PLATFORM_OWNER rows of enabled administrators.
        List<AdminProfileAssignment> owners = assignments.lockActiveHoldersOf(AdminProfile.PLATFORM_OWNER);
        boolean actorIsOwner = owners.stream().anyMatch(a -> a.getUser().getId().equals(actorUserId));
        if (!actorIsOwner) {
            throw new ApiException(HttpStatus.FORBIDDEN, PartnerAccessService.PERMISSION_DENIED, "Access denied");
        }

        List<AdminProfileAssignment> current = assignments.findActiveByUserId(targetUserId);
        Set<AdminProfile> held = current.stream().map(AdminProfileAssignment::getProfile)
            .collect(Collectors.toCollection(() -> EnumSet.noneOf(AdminProfile.class)));
        if (held.contains(AdminProfile.PLATFORM_OWNER) && !desired.contains(AdminProfile.PLATFORM_OWNER)) {
            long remaining = owners.stream().filter(a -> !a.getUser().getId().equals(targetUserId)).count();
            if (remaining == 0) {
                throw new ApiException(HttpStatus.CONFLICT, LAST_PLATFORM_OWNER_REQUIRED,
                    "At least one platform owner must remain");
            }
        }

        User actor = users.getReferenceById(actorUserId);
        Instant now = clock.instant();
        for (AdminProfileAssignment assignment : current) {
            if (!desired.contains(assignment.getProfile())) {
                assignment.revoke(actor, now);
                assignments.saveAndFlush(assignment);
                recordRevoke(actorUserId, targetUserId, assignment.getProfile(), reason);
            }
        }
        for (AdminProfile profile : desired) {
            if (held.contains(profile)) continue;
            AdminProfileAssignment grant = new AdminProfileAssignment();
            grant.setUser(target);
            grant.setProfile(profile);
            grant.setGrantedBy(actor);
            grant.setGrantedAt(now);
            assignments.saveAndFlush(grant);
            recordGrant(actorUserId, targetUserId, profile, reason);
        }
        return account(target, actorUserId, desired);
    }

    private void recordGrant(Long actorUserId, Long targetUserId, AdminProfile profile, String reason) {
        audit.record(actorUserId, "ADMIN_PROFILE_GRANT", "USER", targetUserId,
            describe("Granted admin profile " + profile.name(), reason), null, profile.name());
    }

    private void recordRevoke(Long actorUserId, Long targetUserId, AdminProfile profile, String reason) {
        audit.record(actorUserId, "ADMIN_PROFILE_REVOKE", "USER", targetUserId,
            describe("Revoked admin profile " + profile.name(), reason), profile.name(), null);
    }

    private static String describe(String what, String reason) {
        return reason == null ? what : what + ": " + reason;
    }

    /** The requested profile names; an unknown or duplicated value is a 400, never silently dropped. */
    private static Set<AdminProfile> parse(List<String> names) {
        EnumSet<AdminProfile> profiles = EnumSet.noneOf(AdminProfile.class);
        List<String> unknown = new ArrayList<>();
        for (String name : names) {
            AdminProfile profile = AdminProfile.fromName(name).orElse(null);
            if (profile == null || !profiles.add(profile)) unknown.add(String.valueOf(name));
        }
        if (!unknown.isEmpty()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "VALIDATION_FAILED", "profiles",
                "Unknown or repeated admin profile");
        }
        return profiles;
    }

    private static AdminAccountResponse account(User user, Long actorUserId, Set<AdminProfile> profiles) {
        return new AdminAccountResponse(user.getId(), user.getFullName(), user.getEmail(), user.isEnabled(),
            user.getId().equals(actorUserId), names(profiles));
    }

    private static List<String> names(Set<AdminProfile> profiles) {
        return profiles.stream().sorted(Comparator.comparingInt(Enum::ordinal)).map(Enum::name).toList();
    }
}
