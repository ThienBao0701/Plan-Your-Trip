package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

/**
 * Phase 7.23 — Personalized Offers &amp; Rule-Based Recommendations.
 * A generated, read-only recommendation SNAPSHOT for one user. It is NOT the
 * source of truth for any Place/Hotel/Promotion/Coupon/Booking data — the target
 * FKs merely reference the live entities, and responses re-map those live
 * entities through their existing response mappers. Exactly one target FK is
 * populated per row, matching {@link #recommendationType}.
 *
 * <p>Engagement lifecycle is captured by four nullable timestamps
 * ({@link #dismissedAt}/{@link #clickedAt}/{@link #convertedAt} — click/convert
 * are idempotent, dismiss hides from the default list). "Active + unengaged"
 * snapshots (all four engagement timestamps null and not expired) are the only
 * rows a regeneration may replace; clicked/converted/dismissed history is
 * preserved.
 */
@Entity
@Table(name = "customer_recommendations",
       indexes = {
           @Index(name = "idx_customer_rec_user", columnList = "user_id"),
           @Index(name = "idx_customer_rec_user_type", columnList = "user_id,recommendation_type"),
           @Index(name = "idx_customer_rec_target_key", columnList = "target_key")
       })
@Getter @Setter
public class CustomerRecommendation {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(name = "recommendation_type", nullable = false, length = 20)
    private RecommendationType recommendationType;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "source_rule_id")
    private PersonalizationRule sourceRule;

    // ── Target FKs — exactly one populated per type (hotels are Places) ────────

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id")
    private Place place;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "hotel_id")
    private Place hotel;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id")
    private HotelRoom room;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "promotion_id")
    private Promotion promotion;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "coupon_definition_id")
    private CouponDefinition couponDefinition;

    /**
     * Derived dedup key ("{type}:{targetId}") — enforces the "no duplicate active
     * recommendation for the same user + type + target" rule cheaply at
     * generation time.
     */
    @Column(name = "target_key", nullable = false, length = 60)
    private String targetKey;

    /** Bounded to 0–100 (see {@code CustomerPersonalizationService} scoring constants). */
    @Column(nullable = false)
    private int score;

    @Enumerated(EnumType.STRING)
    @Column(name = "reason_code", nullable = false, length = 40)
    private RecommendationReasonCode reasonCode;

    @Column(name = "reason_text", length = 500)
    private String reasonText;

    @Column(name = "generated_at", nullable = false)
    private Instant generatedAt;

    /** Nullable — must be after generatedAt when supplied. */
    @Column(name = "expires_at")
    private Instant expiresAt;

    @Column(name = "dismissed_at")
    private Instant dismissedAt;

    @Column(name = "clicked_at")
    private Instant clickedAt;

    @Column(name = "converted_at")
    private Instant convertedAt;

    @Column(name = "metadata_json", columnDefinition = "TEXT")
    private String metadataJson;

    @PrePersist
    void onCreate() { if (generatedAt == null) generatedAt = Instant.now(); }
}
