package com.example.planyourtrip.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;

@Entity
@Table(name = "places",
       indexes = {
           @Index(name = "idx_places_slug",           columnList = "slug",                  unique = true),
           @Index(name = "idx_places_status",          columnList = "status"),
           @Index(name = "idx_places_category_id",     columnList = "category_id"),
           @Index(name = "idx_places_subcategory_id",  columnList = "subcategory_id"),
           @Index(name = "idx_places_admin_unit_id",   columnList = "administrative_unit_id"),
           @Index(name = "idx_places_name_normalized", columnList = "nameNormalized"),
           @Index(name = "idx_places_price_level",     columnList = "priceLevel"),
           @Index(name = "idx_places_rating_avg",      columnList = "ratingAvg"),
           @Index(name = "idx_places_featured",        columnList = "featured"),
           @Index(name = "idx_places_verified",        columnList = "verified")
       })
@Getter @Setter
public class Place {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String nameNormalized;

    @Column(nullable = false, unique = true)
    private String slug;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private Category category;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "subcategory_id")
    private Category subcategory;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "administrative_unit_id", nullable = false)
    private AdministrativeUnit administrativeUnit;

    @NotBlank
    @Column(nullable = false)
    private String address;

    @Column(length = 500)
    private String googleMapUrl;

    private Double latitude;
    private Double longitude;

    @Column(length = 500)
    private String shortDescription;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Min(0) @Max(4)
    private int priceLevel;

    @DecimalMin("0.0") @DecimalMax("5.0")
    private double ratingAvg;

    @Min(0)
    private int reviewCount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PlaceStatus status = PlaceStatus.DRAFT;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_user_id")
    private User ownerUser;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by_id", nullable = false)
    private User createdBy;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "approved_by_id")
    private User approvedBy;

    private Instant approvedAt;

    private boolean featured;

    private boolean verified;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
