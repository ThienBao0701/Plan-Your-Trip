package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

/**
 * Phase 7.24 — Gift Cards Foundation.
 * Defines a gift-card product or campaign (e.g. "Plan Your Trip Gift Card").
 * Admin CRUD only ({@code GiftCardProductService}) — customers never create or
 * mutate a product, only issue {@link GiftCard}s against one. An inactive or
 * out-of-window product cannot issue new gift cards (enforced in
 * {@code GiftCardService#issue}).
 */
@Entity
@Table(name = "gift_card_products",
       uniqueConstraints = @UniqueConstraint(name = "uk_gift_card_product_code", columnNames = "product_code"))
@Getter @Setter
public class GiftCardProduct {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Normalized (trimmed upper-case) on every write — unique case-insensitively, mirrors CouponDefinition#code. */
    @Column(name = "product_code", nullable = false, length = 60)
    private String productCode;

    @Column(nullable = false)
    private String name;

    @Column(length = 2000)
    private String description;

    @Column(nullable = false, length = 10)
    private String currency;

    /** Exactly one fixed amount to issue — mutually complementary with the min/max range; required when customAmountAllowed=false. */
    @Column(precision = 15, scale = 2)
    private BigDecimal fixedAmount;

    @Column(precision = 15, scale = 2)
    private BigDecimal minimumAmount;

    @Column(precision = 15, scale = 2)
    private BigDecimal maximumAmount;

    @Column(nullable = false)
    private boolean customAmountAllowed = false;

    /** Days after activation the card remains valid — combined with validUntil via "earlier of both" at activation. */
    private Integer validDaysAfterActivation;

    @Column(nullable = false)
    private boolean active = true;

    private LocalDate validFrom;

    private LocalDate validUntil;

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
