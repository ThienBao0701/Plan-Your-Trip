package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

/**
 * Phase 7.23 — Personalized Offers &amp; Rule-Based Recommendations.
 * Admin-configurable rule that governs which customer signal is mined and which
 * resource pool is drawn from when {@code CustomerPersonalizationService}
 * generates recommendations. This is NOT a second promotion/coupon engine and
 * carries no discount logic — it only steers candidate selection; the actual
 * offers still come from the existing {@link Promotion}/{@link CouponDefinition}
 * models. {@code ruleCode} is unique case-insensitively (mirrors
 * {@code ReferralCampaign}/{@code CouponDefinition}), optimistic {@link #version}
 * locking guards concurrent admin edits, and the active + validFrom/validUntil
 * window is honoured at generation time.
 */
@Entity
@Table(name = "personalization_rules",
       uniqueConstraints = @UniqueConstraint(name = "uk_personalization_rule_code", columnNames = "rule_code"),
       indexes = {
           @Index(name = "idx_personalization_rule_active", columnList = "active"),
           @Index(name = "idx_personalization_rule_type", columnList = "rule_type")
       })
@Getter @Setter
public class PersonalizationRule {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Stored normalized (trimmed) — uniqueness is enforced case-insensitively in the service. */
    @Column(name = "rule_code", nullable = false, length = 80)
    private String ruleCode;

    @Column(nullable = false)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(name = "rule_type", nullable = false, length = 30)
    private PersonalizationRuleType ruleType;

    @Column(nullable = false)
    private int priority = 0;

    @Column(nullable = false)
    private boolean active = true;

    /** Nullable — absence means "in effect immediately". */
    @Column(name = "valid_from")
    private Instant validFrom;

    /** Nullable — absence means "no expiry". */
    @Column(name = "valid_until")
    private Instant validUntil;

    /**
     * Nullable membership gate. When set, the rule is only applicable to a
     * customer whose CURRENT EFFECTIVE tier (see
     * {@code CustomerMembershipService#effectiveTierForUser}) is at or above it
     * (compared by {@link MembershipTier} ordinal). A user with no membership is
     * treated as below BRONZE (ineligible), matching the coupon tier-gate rule.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "minimum_membership_tier", length = 20)
    private MembershipTier minimumMembershipTier;

    /** Optional targeting scope — matched against {@code Category#type} (e.g. "ACCOMMODATION"). */
    @Column(name = "target_place_type", length = 100)
    private String targetPlaceType;

    /** MANUAL rule → a specific {@code Place} id. */
    @Column(name = "target_place_id")
    private Long targetPlaceId;

    /** MANUAL rule → a specific hotel {@code Place} id (hotels are Places app-wide). */
    @Column(name = "target_hotel_id")
    private Long targetHotelId;

    /** MANUAL rule → a specific {@code Promotion} id. */
    @Column(name = "target_promotion_id")
    private Long targetPromotionId;

    /** MANUAL rule → a specific {@code CouponDefinition} id. */
    @Column(name = "target_coupon_definition_id")
    private Long targetCouponDefinitionId;

    /** Optional free-form JSON tuning knobs (validated as well-formed JSON on write). */
    @Column(name = "configuration_json", columnDefinition = "TEXT")
    private String configurationJson;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @Version
    private Long version;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
