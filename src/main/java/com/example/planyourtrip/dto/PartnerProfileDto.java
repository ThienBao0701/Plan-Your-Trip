package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.BusinessType;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;

public class PartnerProfileDto {

    public record PartnerProfileRequest(
        @NotBlank String businessName,
        @NotNull BusinessType businessType,
        @NotBlank String representativeName,
        @NotBlank String phone,
        @NotBlank @Email String email,
        @NotBlank String address,
        String taxCode,
        String website
    ) {}

    public record PartnerProfileResponse(
        Long id,
        Long userId,
        String userName,
        String userEmail,
        String businessName,
        String businessType,
        String representativeName,
        String phone,
        String email,
        String address,
        String taxCode,
        String website,
        String verificationStatus,
        String rejectReason,
        Instant submittedAt,
        Instant approvedAt,
        Instant rejectedAt,
        Long approvedById,
        String approvedByName,
        Instant createdAt,
        Instant updatedAt
    ) {}

    public record PartnerSubmitResponse(
        Long id,
        String verificationStatus,
        Instant submittedAt,
        String message
    ) {}

    public record PartnerRejectRequest(
        @NotBlank String rejectReason
    ) {}

    public record PartnerStatusRequest(
        String reason
    ) {}
}
