package com.example.planyourtrip.model;

/**
 * Phase 7.19 — Membership Tier &amp; Loyalty Qualification.
 * What a {@link MembershipTierHistory} row loosely points back at (soft
 * reference — paired with {@code referenceId}, never a foreign key). Mirrors
 * {@code LoyaltyReferenceType}/{@code TravelCreditReferenceType}'s pattern.
 */
public enum MembershipReferenceType {
    LOYALTY_ACCOUNT, BOOKING, ADMIN, SYSTEM
}
