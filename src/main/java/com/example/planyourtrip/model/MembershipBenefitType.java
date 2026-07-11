package com.example.planyourtrip.model;

/**
 * Phase 7.19 — Membership Tier &amp; Loyalty Qualification.
 * Categorizes a {@link MembershipBenefitDefinition}. This phase stores
 * benefit METADATA only — nothing here is operationally executed (no real
 * room upgrade, no free breakfast fulfillment, no priority-support routing,
 * no automatic coupon issuance). {@code CUSTOM} covers anything not otherwise
 * modeled; {@code numericValue}/{@code textValue} on the definition carry
 * whatever the benefit needs to describe itself (e.g. a discount percentage,
 * a number of late-checkout hours, free-text terms).
 */
public enum MembershipBenefitType {
    POINTS_MULTIPLIER, MEMBER_ONLY_COUPONS, PRIORITY_SUPPORT, EARLY_ACCESS,
    LATE_CHECKOUT, EARLY_CHECKIN, ROOM_UPGRADE, FREE_BREAKFAST, AIRPORT_TRANSFER, CUSTOM
}
