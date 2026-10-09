package com.example.planyourtrip.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.List;

/** RBAC R6 — admin access documents and access management (RBAC V1.1 §25.4). */
public final class AdminAccessDto {

    private AdminAccessDto() {}

    /**
     * {@code GET /api/admin/me/access} — what the caller may do in the console. {@code permissions} are the active
     * admin permission keys of the union of {@code profiles}; reserved keys grant nothing and are not listed. The
     * console renders from this document; the server still authorizes every request.
     */
    public record AdminAccessResponse(Long userId, String email, String fullName, List<String> profiles,
                                      List<String> permissions, StepUp stepUp) {}

    /** When the current session stops counting as fresh for step-up actions (§18 O-7). */
    public record StepUp(Instant freshUntil) {}

    /** One administrator in {@code GET /api/admin/access/admins} and the result of a profile change. */
    public record AdminAccountResponse(Long userId, String fullName, String email, boolean enabled, boolean self,
                                       List<String> profiles) {}

    /**
     * {@code PUT /api/admin/access/admins/{userId}/profiles} — the complete set of profiles the administrator should
     * hold; profiles not listed are revoked. {@code reason} is optional and goes to the audit trail.
     */
    public record ReplaceProfilesRequest(
        @NotNull @Size(max = 11) List<String> profiles,
        @Size(max = 500) String reason
    ) {}
}
