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

@Entity
@Table(name = "promotions",
       uniqueConstraints = @UniqueConstraint(name = "uk_promotion_code", columnNames = "code"))
@Getter @Setter
public class Promotion {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    @Column(nullable = false)
    private String name;

    @Column(unique = true)
    private String code;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false)
    private boolean active = true;

    @NotNull
    @Column(nullable = false)
    private LocalDate startDate;

    @NotNull
    @Column(nullable = false)
    private LocalDate endDate;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PromotionType promotionType;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DiscountType discountType;

    @NotNull
    @DecimalMin("0.0")
    @Column(nullable = false, precision = 15, scale = 2)
    private BigDecimal discountValue;

    @DecimalMin("0.0")
    @Column(precision = 15, scale = 2)
    private BigDecimal maxDiscountAmount;

    @Min(1)
    private Integer minimumStay;

    @DecimalMin("0.0")
    @Column(precision = 15, scale = 2)
    private BigDecimal minimumSpend;

    @Column(nullable = false)
    private boolean stackable = false;

    @Column(nullable = false)
    private int priority = 0;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PromotionTargetType targetType = PromotionTargetType.ALL;

    private Long targetId;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
