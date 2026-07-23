package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/**
 * Phase 7.48 — User Interest Profile (a persisted, DERIVED, one-per-user behavioural summary).
 *
 * <p>This is a read-only <b>foundation</b>: it aggregates a customer's implicit signals
 * (completed bookings, wishlist, saved collections, approved high-rated reviews) into a compact,
 * deterministic snapshot of their travel interests. It is NEVER manually edited — the only way a
 * row changes is a full {@code recalculate} that re-derives every field from current signals.
 *
 * <p><b>Relationship to Phase 7.23.</b> {@code CustomerPersonalizationService#buildProfile} already
 * computes an <i>ephemeral</i> {@code PreferenceProfile} on every read to drive recommendation
 * generation. This entity is deliberately different and complementary: it is <i>persisted</i>, has an
 * explicit recalculation lifecycle ({@link #lastRecalculatedAt}), and aggregates the {@link PlaceMetadata}
 * taxonomy enums (budget / weather / crowd / accessibility / travel style) plus favourite
 * provinces / categories / tags. It REUSES the existing enums and signal-source repositories — it
 * duplicates neither the enums nor the 7.23 recommendation engine.
 *
 * <p>Exactly one row per user (unique {@code user_id}). All list fields are LAZY element collections
 * mapped to DTOs inside the owning transaction (avoids the multiple-eager-bag fetch problem).
 */
@Entity
@Table(name = "user_interest_profiles",
       uniqueConstraints = @UniqueConstraint(name = "uk_user_interest_profile_user", columnNames = "user_id"))
@Getter @Setter
public class UserInterestProfile {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Owning user. One profile per user (unique). Not a hard FK relationship — keyed by id only. */
    @Column(name = "user_id", nullable = false, unique = true)
    private Long userId;

    // ── Preferred taxonomy enums (reused from PlaceMetadata; never duplicated) ──────────────

    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(name = "user_interest_travel_styles",
                     joinColumns = @JoinColumn(name = "profile_id"))
    @Column(name = "style", length = 20)
    @Enumerated(EnumType.STRING)
    private List<TravelStyle> preferredTravelStyles = new ArrayList<>();

    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(name = "user_interest_weather_types",
                     joinColumns = @JoinColumn(name = "profile_id"))
    @Column(name = "weather_type", length = 20)
    @Enumerated(EnumType.STRING)
    private List<WeatherType> preferredWeatherTypes = new ArrayList<>();

    /** Modal budget level across signal places. Null when no metadata carried a budget level. */
    @Enumerated(EnumType.STRING)
    @Column(name = "preferred_budget_level", length = 20)
    private BudgetLevel preferredBudgetLevel;

    /** Modal crowd level across signal places. Null when unknown. */
    @Enumerated(EnumType.STRING)
    @Column(name = "preferred_crowd_level", length = 20)
    private CrowdLevel preferredCrowdLevel;

    /** Modal accessibility level across signal places. Null when unknown. */
    @Enumerated(EnumType.STRING)
    @Column(name = "preferred_accessibility_level", length = 20)
    private AccessibilityLevel preferredAccessibilityLevel;

    // ── Favourite free-form dimensions (deterministic top-N, de-duplicated) ─────────────────

    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(name = "user_interest_provinces",
                     joinColumns = @JoinColumn(name = "profile_id"))
    @Column(name = "province", length = 200)
    private List<String> favoriteProvinces = new ArrayList<>();

    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(name = "user_interest_categories",
                     joinColumns = @JoinColumn(name = "profile_id"))
    @Column(name = "category", length = 200)
    private List<String> favoriteCategories = new ArrayList<>();

    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(name = "user_interest_tags",
                     joinColumns = @JoinColumn(name = "profile_id"))
    @Column(name = "tag", length = 200)
    private List<String> favoriteTags = new ArrayList<>();

    /** Number of distinct (source, place) signals that contributed to the last recalculation. */
    @Column(name = "signal_count", nullable = false)
    private int signalCount = 0;

    /** When the profile was last derived. Null until the first {@code recalculate}. */
    @Column(name = "last_recalculated_at")
    private Instant lastRecalculatedAt;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
