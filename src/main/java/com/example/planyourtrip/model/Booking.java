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
