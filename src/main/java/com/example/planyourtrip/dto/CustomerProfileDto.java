package com.example.planyourtrip.dto;

import java.time.Instant;

public class CustomerProfileDto {

    public record CustomerProfileRequest(
        String avatarUrl,
        String preferredLanguage,
        String preferredCurrency,
        String preferredPaymentMethod,
        String nationality,
        // Full passport number, submitted once and never persisted as-is — the
        // service masks it immediately and stores only the masked value.
        String passportNumber,
        String emergencyContactName,
        String emergencyContactPhone,
        String accessibilityNeeds,
        String dietaryPreference,
        String travelStyle,
        boolean marketingConsent
    ) {}

    public record CustomerProfileResponse(
        Long id,
        Long userId,
        String avatarUrl,
        String preferredLanguage,
        String preferredCurrency,
        String preferredPaymentMethod,
        String nationality,
        String passportNumberMasked,
        String emergencyContactName,
        String emergencyContactPhone,
        String accessibilityNeeds,
        String dietaryPreference,
        String travelStyle,
        boolean marketingConsent,
        boolean profileCompleted,
        int completionPercentage,
        Instant createdAt,
        Instant updatedAt
    ) {}
}
