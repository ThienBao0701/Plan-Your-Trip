package com.example.planyourtrip.dto;

import com.example.planyourtrip.dto.PartnerSettingsDto.PartnerTeamGrantItem;
import com.example.planyourtrip.dto.PartnerSettingsDto.PartnerTeamGrantView;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.List;

/**
 * RBAC R4 — partner invitations (RBAC V1.1 §13, §14, §25.3). No response ever carries the invitation token or its
 * hash: the token exists only in the emailed link.
 */
public class PartnerInvitationDto {

    /** {@code POST /api/partner/team/invitations}: an address and the grants it will receive ({@code role} at {@code TYPE:id}). */
    public record InvitationRequest(
        @NotBlank @Email @Size(max = 254) String email,
        List<PartnerTeamGrantItem> grants
    ) {}

    /**
     * The uniform 202 body of create and resend (§13.1 step 8, IN-1): identical whether the address has an account,
     * is a traveller, an administrator, a member elsewhere, or a member outside the caller's scope.
     */
    public record InvitationRequestResult(String status, String message) {

        public static final String REQUESTED = "REQUESTED";

        public static InvitationRequestResult requested() {
            return new InvitationRequestResult(REQUESTED,
                "The invitation request was recorded. If this address can join the team, it receives a link; "
                    + "the delivery status is shown in the team's invitation list.");
        }
    }

    /** One invitation as the team sees it ({@code GET /api/partner/team/invitations}). */
    public record InvitationView(
        Long id,
        String email,
        List<PartnerTeamGrantView> grants,
        String status,
        String statusReason,
        String deliveryStatus,
        Instant expiresAt,
        int resendCount,
        Instant lastSentAt,
        Long invitedByUserId,
        String invitedByName,
        Instant createdAt
    ) {}

    /** One invitation addressed to the caller ({@code GET /api/me/partner-invitations}, §14 AC-5). */
    public record MyInvitationView(
        Long id,
        Long companyId,
        String companyName,
        List<MyInvitationGrant> grants,
        Instant expiresAt
    ) {}

    /** A role with its scope type and the scope's display name (company, property or room type name). */
    public record MyInvitationGrant(String role, String scopeType, String scopeName) {}

    /** {@code POST /api/me/partner-invitations/accept} and {@code /decline}: the token from the link's fragment. */
    public record InvitationTokenRequest(@NotBlank @Size(max = 200) String token) {}
}
