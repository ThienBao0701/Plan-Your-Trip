package com.example.planyourtrip.model;

/**
 * Phase 7.23 — Personalized Offers &amp; Rule-Based Recommendations.
 * The kind of customer signal a {@link PersonalizationRule} draws its candidates
 * from. Rule-based only — no ML/AI in this phase. Each value maps to a candidate
 * generator inside {@code CustomerPersonalizationService}; scoring is centralized
 * and identical regardless of the originating rule type.
 */
public enum PersonalizationRuleType {
    WISHLIST_AFFINITY,
    RECENTLY_VIEWED,
    BOOKING_HISTORY,
    DESTINATION_AFFINITY,
    TRAVEL_STYLE,
    MEMBERSHIP_TIER,
    LOYALTY_ACTIVITY,
    ABANDONED_INTEREST,
    REENGAGEMENT,
    TRENDING,
    MANUAL
}
