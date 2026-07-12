package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

@Entity
@Table(name = "bookings",
       indexes = {
           @Index(name = "idx_bookings_user_id",  columnList = "user_id"),
           @Index(name = "idx_bookings_hotel_id", columnList = "hotel_id"),
           @Index(name = "idx_bookings_room_id",  columnList = "room_id"),
           @Index(name = "idx_bookings_status",   columnList = "status"),
           @Index(name = "idx_bookings_check_in", columnList = "check_in_date"),
           @Index(name = "idx_bookings_code",     columnList = "booking_code", unique = true)
       })
@Getter @Setter
public class Booking {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "booking_code", unique = true)
    private String bookingCode;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "hotel_id", nullable = false)
    private Place hotel;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "room_id", nullable = false)
    private HotelRoom room;

    @Column(name = "check_in_date", nullable = false)
    private LocalDate checkInDate;

    @Column(name = "check_out_date", nullable = false)
    private LocalDate checkOutDate;

    @Column(nullable = false)
    private int adults;

    @Column(nullable = false)
    private int children;

    @Column(name = "number_of_rooms", nullable = false)
    private int numberOfRooms;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private BookingStatus status = BookingStatus.PENDING;

    @Column(nullable = false, length = 10)
    private String currency = "VND";

    @Column(precision = 15, scale = 2, nullable = false)
    private BigDecimal basePrice;

    @Column(precision = 15, scale = 2)
    private BigDecimal ratePlanPrice;

    @Column(precision = 15, scale = 2, nullable = false)
    private BigDecimal discountAmount;

    @Column(precision = 15, scale = 2, nullable = false)
    private BigDecimal finalPrice;

    // ── Phase 7.15 — Coupon & Travel Credit checkout integration ─────────────
    // All three are nullable and null for every booking made without a coupon /
    // credits, so pre-7.15 bookings and the plain checkout flow are unchanged.

    /** Snapshot of the applied coupon's normalized code (the linked CustomerCoupon row carries the FK back). */
    @Column(name = "coupon_code", length = 60)
    private String couponCode;

    /** Discount granted by the coupon, applied AFTER the promotion discount ({@link #discountAmount}). */
    @Column(name = "coupon_discount_amount", precision = 15, scale = 2)
    private BigDecimal couponDiscountAmount;

    /** Promotional travel credits redeemed against this booking (already subtracted from {@link #finalPrice}). */
    @Column(name = "credit_amount_used", precision = 15, scale = 2)
    private BigDecimal creditAmountUsed;

    // ── Phase 7.20 — Loyalty points redemption ───────────────────────────────
    // Both nullable and null for every booking made without a loyalty
    // redemption, so pre-7.20 bookings and the plain checkout flow are
    // byte-for-byte unchanged. Set when a redemption is RESERVED against the
    // booking (finalPrice reduced by the discount) and cleared if that
    // reservation is later released/expired/refunded.

    /** Loyalty-points discount reserved/applied against this booking (already subtracted from {@link #finalPrice}). */
    @Column(name = "loyalty_discount_amount", precision = 15, scale = 2)
    private BigDecimal loyaltyDiscountAmount;

    /** Number of loyalty points backing {@link #loyaltyDiscountAmount}. */
    @Column(name = "loyalty_points_redeemed")
    private Long loyaltyPointsRedeemed;

    // ── Phase 7.25 — Gift card checkout integration ──────────────────────────
    // Both nullable and null for every booking made without a gift card, so
    // pre-7.25 bookings and the plain checkout flow are byte-for-byte unchanged.
    // Set when a gift card is redeemed at booking creation (after travel credits;
    // finalPrice reduced by the redeemed amount) and CLEARED when that redemption
    // is released (payment failure) or refunded (booking cancellation) — mirroring
    // the loyalty-redemption fields above.

    /** Gift card value redeemed against this booking (already subtracted from {@link #finalPrice}). */
    @Column(name = "gift_card_amount_used", precision = 15, scale = 2)
    private BigDecimal giftCardAmountUsed;

    /** Masked code of the redeemed gift card (support display only — never the full redeemable secret). */
    @Column(name = "gift_card_reference", length = 32)
    private String giftCardReference;

    @Column(columnDefinition = "TEXT")
    private String specialRequest;

    @Column(columnDefinition = "TEXT")
    private String partnerNote;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    private Instant confirmedAt;

    private Instant cancelledAt;

    private Instant actualCheckInAt;

    private Instant actualCheckOutAt;

    private Instant completedAt;

    private Instant archivedAt;

    private Instant lastStatusChangedAt;

    @Column(columnDefinition = "TEXT")
    private String cancelReason;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
