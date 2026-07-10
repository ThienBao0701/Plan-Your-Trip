package com.example.planyourtrip.model;

/**
 * Phase 7.17 — Coupon Targeting &amp; Advanced Eligibility.
 * Evaluated against the requesting user's OWN booking history — see
 * {@code CustomerCouponService#evaluateSegment} for the exact rule per value,
 * including the documented {@code MEMBER} "unsupported — no reliable signal"
 * decision and the {@code HIGH_VALUE} threshold constant.
 */
public enum CustomerSegment {
    ALL_USERS, NEW_USER, RETURNING_USER, MEMBER, HIGH_VALUE, MANUAL
}
