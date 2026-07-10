package com.example.planyourtrip.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

/**
 * Phase 7.14 — Customer Coupons &amp; Travel Credits Foundation.
 * An admin-managed, customer-claimable coupon campaign. Deliberately reuses the
 * existing {@link DiscountType} (PERCENTAGE / FIXED_AMOUNT) and the same
 * money-field conventions as {@link Promotion} (BigDecimal, precision 15 scale 2)
 * rather than introducing a second discount vocabulary — this is NOT a second
 * promotion engine; {@link Promotion} remains the pricing-engine campaign model,
 * while CouponDefinition is the claim-by-code customer coupon model.
 *
 * <p>{@code code} is unique case-insensitively — it is normalized to trimmed
 * upper-case on every write path (see {@code CouponDefinitionService#normalizeCode})
 * and looked up with {@code findByCodeIgnoreCase}, so claim-by-code matches
 * regardless of the case the customer types.
 */
@Entity
@Table(name = "coupon_definitions",
       uniqueConstraints = @UniqueConstraint(name = "uk_coupon_definition_code", columnNames = "code"))
@Getter @Setter
public class CouponDefinition {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Always stored normalized (trimmed, upper-case) — see class javadoc. */
    @NotBlank
    @Column(nullable = false, unique = true, length = 60)
    private String code;

    @NotBlank
    @Column(nullable = false)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private DiscountType discountType;

    @NotNull
    @DecimalMin(value = "0.0", inclusive = false)
    @Column(nullable = false, precision = 15, scale = 2)
    private BigDecimal discountValue;

    @DecimalMin("0.0")
    @Column(precision = 15, scale = 2)
    private BigDecimal maxDiscountAmount;

    @DecimalMin("0.0")
    @Column(precision = 15, scale = 2)
    private BigDecimal minimumSpend;

    @NotNull
    @Column(nullable = false)
    private LocalDate validFrom;

    @NotNull
    @Column(nullable = false)
    private LocalDate validUntil;

    @Column(nullable = false)
    private boolean active = true;

    /** Null = unlimited total claims across all users. */
    @Min(1)
    private Integer totalUsageLimit;

    @Min(1)
    @Column(nullable = false)
    private int usageLimitPerUser = 1;

    /** Incremented on each successful claim (no checkout redemption in this phase). */
    @Column(nullable = false)
    private int currentUsageCount = 0;

    // ── Phase 7.17 — Coupon Targeting & Advanced Eligibility ─────────────────
    // All additive/nullable/defaulted so every existing row (WELCOME10) remains
    // valid as ALL/ALL_USERS/combinable=true with no data migration needed.

    /** Mirrors {@link Promotion}'s targetType+targetId pattern — see {@link CouponTargetType}. */
    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private CouponTargetType targetType = CouponTargetType.ALL;

    /** HOTEL → a {@code Place} id (the "hotelId" convention used app-wide); ROOM → a {@code HotelRoom} id. */
    private Long targetId;

    /** PLACE_TYPE target — matched against {@code Category#type} (a plain String, e.g. "ACCOMMODATION"). */
    @Column(length = 100)
    private String placeType;

    @Min(1)
    private Integer minimumStayNights;

    private LocalDate bookingDateFrom;

    private LocalDate bookingDateTo;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private CustomerSegment customerSegment = CustomerSegment.ALL_USERS;

    @Column(nullable = false)
    private boolean firstBookingOnly = false;

    @Column(nullable = false)
    private boolean combinableWithPromotions = true;

    @Column(nullable = false)
    private boolean combinableWithTravelCredits = true;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
