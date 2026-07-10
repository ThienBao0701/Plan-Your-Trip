package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "invoices",
       indexes = {
           @Index(name = "idx_invoices_user_id",   columnList = "user_id"),
           @Index(name = "idx_invoices_booking_id", columnList = "booking_id", unique = true),
           @Index(name = "idx_invoices_status",    columnList = "status"),
           @Index(name = "idx_invoices_number",    columnList = "invoice_number", unique = true)
       })
@Getter @Setter
public class Invoice {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "invoice_number", unique = true)
    private String invoiceNumber;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "booking_id", nullable = false, unique = true)
    private Booking booking;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "payment_id")
    private Payment payment;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "hotel_id", nullable = false)
    private Place hotel;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private InvoiceStatus status = InvoiceStatus.DRAFT;

    @Column(nullable = false, length = 10)
    private String currency = "VND";

    @Column(precision = 15, scale = 2, nullable = false)
    private BigDecimal subtotal;

    @Column(precision = 15, scale = 2, nullable = false)
    private BigDecimal discountAmount;

    // ── Phase 7.16 — itemized coupon/credit lines (snapshotted from the booking
    // at issue time, like subtotal/discountAmount; all nullable so invoices
    // issued before 7.16 — or for bookings without a coupon/credits — are
    // untouched) ──────────────────────────────────────────────────────────────

    /** Coupon code consumed by the booking, when one was applied. */
    @Column(length = 60)
    private String couponCode;

    /** Coupon discount applied at checkout (Phase 7.15), when one was applied. */
    @Column(precision = 15, scale = 2)
    private BigDecimal couponDiscountAmount;

    /** Promotional travel credits redeemed at checkout (Phase 7.15), when any. */
    @Column(precision = 15, scale = 2)
    private BigDecimal creditAmountUsed;

    @Column(precision = 15, scale = 2, nullable = false)
    private BigDecimal taxAmount;

    @Column(precision = 15, scale = 2, nullable = false)
    private BigDecimal totalAmount;

    private Instant issuedAt;

    private Instant paidAt;

    private Instant cancelledAt;

    private String billingName;

    private String billingEmail;

    private String billingPhone;

    @Column(columnDefinition = "TEXT")
    private String billingAddress;

    private String taxCode;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
