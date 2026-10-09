package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.PartnerTeamRole;
import com.example.planyourtrip.model.PayoutMethod;
import com.example.planyourtrip.validation.NoCredentialText;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.List;

public class PartnerSettingsDto {

    public record PartnerSettingsRequest(
        String defaultLanguage,
        String timezone,
        boolean notificationEmailEnabled,
        boolean notificationSmsEnabled,
        boolean notificationInAppEnabled,
        boolean bookingNotificationEnabled,
        boolean paymentNotificationEnabled,
        boolean reviewNotificationEnabled,
        boolean promotionNotificationEnabled
    ) {}

    public record PartnerSettingsResponse(
        Long id,
        Long partnerProfileId,
        String defaultLanguage,
        String timezone,
        boolean notificationEmailEnabled,
        boolean notificationSmsEnabled,
        boolean notificationInAppEnabled,
        boolean bookingNotificationEnabled,
        boolean paymentNotificationEnabled,
        boolean reviewNotificationEnabled,
        boolean promotionNotificationEnabled,
        Instant createdAt,
        Instant updatedAt
    ) {}

    public record PartnerPayoutAccountRequest(
        @NotBlank String accountHolderName,
        @NotBlank String bankName,
        @NotBlank @Size(min = 4, message = "bankAccountNumber must be at least 4 characters") String bankAccountNumber,
        @NotNull PayoutMethod payoutMethod
    ) {}

    public record PartnerPayoutAccountResponse(
        Long id,
        Long partnerProfileId,
        String accountHolderName,
        String bankName,
        String bankAccountLast4,
        String payoutMethod,
        String status,
        Instant createdAt,
        Instant updatedAt
    ) {}

    public record PartnerTeamMemberRequest(
        @Email String email,
        PartnerTeamRole role,
        Boolean active
    ) {}

    /**
     * One membership. {@code role} is the highest grant and {@code active} is {@code status == ACTIVE}, both
     * kept for existing clients. RBAC R3a adds (§25.3): {@code status}, {@code grants} ({@code role} at
     * {@code scope}, e.g. {@code MANAGER} at {@code COMPANY:456}), {@code primaryOwner},
     * {@code pendingOwnerConfirmation}, {@code isSelf} and {@code version} (sent back to
     * {@code PUT /team/{id}/grants}).
     */
    public record PartnerTeamMemberResponse(
        Long id,
        Long partnerProfileId,
        Long userId,
        String userName,
        String userEmail,
        String role,
        boolean active,
        Instant invitedAt,
        Instant joinedAt,
        Instant createdAt,
        Instant updatedAt,
        String status,
        List<PartnerTeamGrantView> grants,
        boolean primaryOwner,
        boolean pendingOwnerConfirmation,
        boolean isSelf,
        Long version
    ) {}

    /** A grant as the API shows and accepts it: a role at a scope written {@code TYPE:id}. */
    public record PartnerTeamGrantView(String role, String scope) {}

    /** RBAC R3a — {@code PUT /api/partner/team/{memberId}/grants} (§15). */
    public record PartnerTeamGrantsRequest(
        List<PartnerTeamGrantItem> grants,
        @Size(max = 500) @NoCredentialText String reason,
        Long version
    ) {}

    public record PartnerTeamGrantItem(PartnerTeamRole role, String scope) {}

    /** RBAC R3a — the optional reason of a suspend or remove (§17). */
    public record PartnerTeamReasonRequest(@Size(max = 500) @NoCredentialText String reason) {}
}
