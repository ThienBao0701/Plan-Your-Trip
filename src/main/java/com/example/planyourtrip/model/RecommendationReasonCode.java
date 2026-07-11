package com.example.planyourtrip.model;

/**
 * Phase 7.23 — Personalized Offers &amp; Rule-Based Recommendations.
 * Machine-stable explanation code for why an item was recommended. Pairs with a
 * human-readable {@code reasonText} on {@link CustomerRecommendation}.
 */
public enum RecommendationReasonCode {
    SAVED_SIMILAR_PLACE,
    VIEWED_SIMILAR_PLACE,
    BOOKED_SIMILAR_DESTINATION,
    MATCHED_TRAVEL_STYLE,
    MEMBERSHIP_EXCLUSIVE,
    LOYALTY_EXCLUSIVE,
    POPULAR_NEARBY,
    PRICE_PROMOTION,
    RETURNING_CUSTOMER,
    CONTINUE_PLANNING,
    MANUAL_RULE
}
