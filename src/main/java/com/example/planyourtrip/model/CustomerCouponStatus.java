package com.example.planyourtrip.model;

/**
 * Phase 7.14 — Customer Coupons &amp; Travel Credits Foundation.
 * Lifecycle of a claimed coupon. {@code EXPIRED} is normally computed on read
 * (from the effective expiry — see {@code CustomerCouponService#effectiveStatus})
 * rather than persisted, mirroring the {@code TravelWalletItemStatus} pattern
 * from Phase 7.12.
 */
public enum CustomerCouponStatus {
    AVAILABLE, USED, EXPIRED, REVOKED
}
