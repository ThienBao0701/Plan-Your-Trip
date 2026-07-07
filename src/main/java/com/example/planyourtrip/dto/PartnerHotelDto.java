package com.example.planyourtrip.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;
import java.time.LocalTime;

public class PartnerHotelDto {

    public record PartnerHotelSummaryResponse(
        Long id,
        String name,
        String slug,
        String shortDescription,
        String address,
        boolean active,
        boolean featured,
        boolean verified,
        double ratingAvg,
        int reviewCount,
        String status,
        Instant createdAt,
        Instant updatedAt
    ) {}

    public record PartnerHotelResponse(
        Long id,
        String name,
        String slug,
        String shortDescription,
        String description,
        String address,
        Double latitude,
        Double longitude,
        String phone,
        String email,
        String website,
        String facebook,
        String instagram,
        LocalTime checkIn,
        LocalTime checkOut,
        String childrenPolicy,
        String petPolicy,
        String smokingPolicy,
        boolean active,
        boolean featured,
        boolean verified,
        double ratingAvg,
        int reviewCount,
        String status,
        Long ownerProfileId,
        String ownerBusinessName,
        Instant createdAt,
        Instant updatedAt
    ) {}

    public record PartnerHotelUpdateRequest(
        @NotBlank String name,
        String shortDescription,
        String description,
        @NotBlank String slug
    ) {}

    public record PartnerContactRequest(
        String phone,
        @Email String email,
        String website,
        String facebook,
        String instagram
    ) {}

    public record PartnerPolicyRequest(
        @NotNull LocalTime checkIn,
        @NotNull LocalTime checkOut,
        String childrenPolicy,
        String petPolicy,
        String smokingPolicy
    ) {}

    public record PartnerLocationRequest(
        Double latitude,
        Double longitude,
        @NotBlank String address
    ) {}

    public record AssignOwnerRequest(
        @NotNull Long partnerProfileId
    ) {}
}
