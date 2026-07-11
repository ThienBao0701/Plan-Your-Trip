package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.MembershipBenefitType;
import com.example.planyourtrip.model.MembershipReferenceType;
import com.example.planyourtrip.model.MembershipTier;
import com.example.planyourtrip.model.MembershipTierChangeType;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Phase 7.19 — Membership Tier &amp; Loyalty Qualification.
 * Single-file record style mirrors {@code LoyaltyDto}/{@code TravelCreditDto}.
 */
public class MembershipDto {

    // ── Tier definitions (admin-configured qualification + multiplier) ──────

    public record MembershipTierDefinitionRequest(
        @NotNull MembershipTier tier,
        @NotBlank String displayName,
        String description,
        @NotNull @Min(0) Long minimumLifetimePoints,
        @NotNull @Min(0) Integer minimumCompletedBookings,
        @NotNull @DecimalMin(value = "1.00", message = "pointsMultiplier must be >= 1.00") BigDecimal pointsMultiplier,
        Boolean active,
        @NotNull @Min(0) Integer sortOrder
    ) {}

    public record MembershipTierDefinitionResponse(
        Long id,
        MembershipTier tier,
        String displayName,
        String description,
        long minimumLifetimePoints,
        int minimumCompletedBookings,
        BigDecimal pointsMultiplier,
        boolean active,
        int sortOrder,
        Instant createdAt,
        Instant updatedAt
    ) {}

    // ── Benefit definitions (metadata only — see MembershipBenefitDefinition) ──

    public record MembershipBenefitRequest(
        @NotNull MembershipTier tier,
        @NotNull MembershipBenefitType benefitType,
        @NotBlank String name,
        String description,
        @DecimalMin(value = "0", message = "numericValue must be >= 0") BigDecimal numericValue,
        String textValue,
        Boolean active,
        @Min(0) Integer sortOrder
    ) {}

    public record MembershipBenefitResponse(
        Long id,
        MembershipTier tier,
        MembershipBenefitType benefitType,
        String name,
        String description,
        BigDecimal numericValue,
        String textValue,
        boolean active,
        int sortOrder,
        Instant createdAt,
        Instant updatedAt
    ) {}

    // ── Customer membership ──────────────────────────────────────────────────

    /**
     * {@code currentTier} is the stored tier; {@code effectiveTier} accounts for
     * expiry (falls back to BRONZE when {@code validUntil} has passed) — see
     * {@code CustomerMembershipService#effectiveTier}. Both are always present
     * so a client never has to guess which one to display.
     */
    public record CustomerMembershipResponse(
        Long id,
        Long userId,
        MembershipTier currentTier,
        MembershipTier effectiveTier,
        Instant qualifiedAt,
        Instant validFrom,
        Instant validUntil,
        boolean manuallyAssigned,
        boolean active,
        boolean expired,
        Instant createdAt,
        Instant updatedAt
    ) {}

    /**
     * Qualification progress toward the next tier — computed live from current
     * {@code LoyaltyAccount#lifetimePointsEarned} + completed-booking count, not
     * from the stored membership row alone. Works even for a user who has never
     * enrolled (a preview of what enrolling would grant them right now) —
     * strictly read-only, never creates a {@code CustomerMembership}.
     * {@code progressPercentage} is always bounded to [0, 100]; when
     * {@code nextTier} is null (already at the highest active tier), it is 100.
     */
    public record MembershipProgressResponse(
        MembershipTier currentTier,
        MembershipTier effectiveTier,
        long lifetimePointsEarned,
        long completedBookings,
        MembershipTier nextTier,
        Long pointsRequiredForNextTier,
        Long bookingsRequiredForNextTier,
        double progressPercentage,
        Instant validUntil,
        boolean expired,
        boolean manuallyAssigned
    ) {}

    public record MembershipTierHistoryResponse(
        Long id,
        Long membershipId,
        MembershipTier previousTier,
        MembershipTier newTier,
        MembershipTierChangeType changeType,
        String reason,
        Instant effectiveAt,
        Instant expiresAt,
        MembershipReferenceType referenceType,
        Long referenceId,
        Instant createdAt
    ) {}

    /**
     * Admin manual tier assignment. {@code validUntil} is optional — when
     * omitted, the standard 12-month validity window is applied from now;
     * when supplied, must be strictly in the future. {@code idempotencyKey} is
     * optional, matching the {@code LoyaltyGrantRequest} convention, though
     * (unlike the loyalty ledger) manual assignment is not a repeatable-replay
     * ledger entry — see {@code CustomerMembershipService#adminAssign} javadoc.
     */
    public record MembershipManualAssignmentRequest(
        @NotNull MembershipTier tier,
        @NotBlank String reason,
        Instant validUntil,
        String idempotencyKey
    ) {}

    /** Result of an automatic or admin-triggered evaluation — used by both the internal hook and the admin API. */
    public record MembershipEvaluationResultResponse(
        Long userId,
        MembershipTier previousTier,
        MembershipTier newTier,
        boolean changed,
        String reason,
        Instant evaluatedAt
    ) {}
}
