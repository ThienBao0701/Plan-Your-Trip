package com.example.planyourtrip.model;

/**
 * Phase 7.17 — Coupon Targeting &amp; Advanced Eligibility.
 * Mirrors {@link PromotionTargetType}'s ALL/HOTEL/ROOM vocabulary (same
 * targetType+targetId pattern) and adds {@code PLACE_TYPE} — targeting by a
 * place's category/type (see {@code CouponDefinition#placeType}) rather than a
 * single entity id.
 */
public enum CouponTargetType {
    ALL, HOTEL, ROOM, PLACE_TYPE
}
