package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.PartnerTeamRole;
import com.example.planyourtrip.model.PayoutMethod;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;

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
        Instant updatedAt
    ) {}
}
