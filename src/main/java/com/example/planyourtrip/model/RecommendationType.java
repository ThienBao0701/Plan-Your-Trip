package com.example.planyourtrip.model;

/**
 * Phase 7.23 — Personalized Offers &amp; Rule-Based Recommendations.
 * The kind of resource a {@link CustomerRecommendation} points at. Exactly one
 * matching target FK on the recommendation snapshot is populated per type
 * (PLACE/TRIP_IDEA → place, HOTEL → hotel, ROOM → room, PROMOTION → promotion,
 * COUPON → couponDefinition).
 */
public enum RecommendationType {
    PLACE,
    HOTEL,
    ROOM,
    PROMOTION,
    COUPON,
    TRIP_IDEA
}
