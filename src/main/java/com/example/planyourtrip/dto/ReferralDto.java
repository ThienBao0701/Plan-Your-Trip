package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.ReferralRewardStatus;
import jakarta.validation.constraints.NotBlank;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/**
 * Phase 7.22 — Referral &amp; Invite Rewards.
 * Single-file record style, mirroring {@code LoyaltyRedemptionDto}. Every money
 * value is {@code BigDecimal}; loyalty points are integer counts ({@code Long}).
 * All reward fields are optional/nullable — a campaign may grant any combination.
 */
public class ReferralDto {

    // ── Campaign (admin) ──────────────────────────────────────────────────────

    public record ReferralCampaignRequest(
        @NotBlank String code,
        @NotBlank String name,
        BigDecimal minimumQualifyingBookingAmount,
        Long inviterRewardPoints,
        Long inviterRewardCouponDefinitionId,
        BigDecimal inviterRewardCreditAmount,
        String inviterRewardCreditCurrency,
        Long inviteeRewardPoints,
        Long inviteeRewardCouponDefinitionId,
        BigDecimal inviteeRewardCreditAmount,
        String inviteeRewardCreditCurrency,
        Boolean active,
        Instant effectiveFrom,
        Instant effectiveUntil
    ) {}

    public record ReferralCampaignResponse(
        Long id,
        String code,
        String name,
        BigDecimal minimumQualifyingBookingAmount,
        Long inviterRewardPoints,
        Long inviterRewardCouponDefinitionId,
        BigDecimal inviterRewardCreditAmount,
        String inviterRewardCreditCurrency,
        Long inviteeRewardPoints,
        Long inviteeRewardCouponDefinitionId,
        BigDecimal inviteeRewardCreditAmount,
        String inviteeRewardCreditCurrency,
        boolean active,
        Instant effectiveFrom,
        Instant effectiveUntil,
        Instant createdAt,
        Instant updatedAt,
        Long version
    ) {}

    // ── Customer: my code + stats ─────────────────────────────────────────────

    public record MyReferralResponse(
        String code,
        long successfulReferrals,
        long pendingReferrals,
        Instant createdAt
    ) {}

    // ── Customer: use a code ──────────────────────────────────────────────────

    public record UseReferralRequest(
        @NotBlank String code
    ) {}

    // ── Customer: history entry (as inviter and/or invitee) ───────────────────

    public record ReferralRewardResponse(
        Long id,
        String role,               // "INVITER" or "INVITEE" relative to the requesting user
        String campaignCode,
        Long inviterUserId,
        Long inviteeUserId,
        ReferralRewardStatus status,
        Instant usedAt,
        Instant qualifiedAt,
        Long qualifyingBookingId,
        Instant rewardedAt,
        Instant createdAt
    ) {}
}
