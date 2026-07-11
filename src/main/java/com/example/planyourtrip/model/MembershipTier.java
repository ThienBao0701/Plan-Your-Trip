package com.example.planyourtrip.model;

/**
 * Phase 7.19 — Membership Tier &amp; Loyalty Qualification.
 * Ordered lowest → highest by declaration order — {@code ordinal()} is used
 * throughout {@code CustomerMembershipService} to compare tiers (select the
 * "highest qualified tier", detect upgrade vs downgrade direction, etc.), so
 * this declaration order must never be reshuffled. Recommended default
 * qualification thresholds (configurable per-environment via
 * {@link MembershipTierDefinition} DB rows, never hardcoded in service logic):
 * BRONZE 0 pts, SILVER 1,000 pts, GOLD 5,000 pts, PLATINUM 15,000 pts,
 * DIAMOND 40,000 pts.
 */
public enum MembershipTier {
    BRONZE, SILVER, GOLD, PLATINUM, DIAMOND
}
