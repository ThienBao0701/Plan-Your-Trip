package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.time.LocalDate;

/**
 * Phase 7.12 — Travel Wallet Foundation. A unified, cross-trip index of a
 * user's important travel documents/references. Deliberately does NOT store
 * its own file url/thumbnail/mime (that stays on {@link MediaAsset} via
 * {@link TripPlanDocument}) and does NOT hold any money/balance/custody
 * fields — it is a document/reference organizer only, optionally pointing at
 * an existing {@link TripPlanDocument}, {@link Booking} and/or {@link Invoice}
 * row (never all required — see {@code TravelWalletService#create}), or
 * standing alone as metadata (displayTitle) when none of those apply.
 * {@link #referenceNumberMasked} only ever holds an already-masked value —
 * see {@code TravelWalletService#maskReference}.
 */
@Entity
@Table(name = "travel_wallet_items",
       indexes = {
           @Index(name = "idx_travel_wallet_items_user_id", columnList = "user_id"),
           @Index(name = "idx_travel_wallet_items_trip_plan_id", columnList = "trip_plan_id"),
           @Index(name = "idx_travel_wallet_items_document_id", columnList = "trip_plan_document_id"),
           @Index(name = "idx_travel_wallet_items_booking_id", columnList = "booking_id"),
           @Index(name = "idx_travel_wallet_items_invoice_id", columnList = "invoice_id")
       })
@Getter @Setter
public class TravelWalletItem {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trip_plan_id")
    private TripPlan tripPlan;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trip_plan_document_id")
    private TripPlanDocument tripPlanDocument;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "booking_id")
    private Booking booking;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "invoice_id")
    private Invoice invoice;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private TravelWalletItemType walletItemType;

    @Column(nullable = false)
    private String displayTitle;

    private String issuer;

    private String referenceNumberMasked;

    private LocalDate validFrom;

    private LocalDate validUntil;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private TravelWalletItemStatus status = TravelWalletItemStatus.ACTIVE;

    @Column(nullable = false)
    private boolean favorite = false;

    @Column(nullable = false)
    private boolean archived = false;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
