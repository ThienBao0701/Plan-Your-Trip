package com.example.planyourtrip.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "hotel_rooms",
       uniqueConstraints = @UniqueConstraint(name = "uk_hotel_room_code", columnNames = {"hotel_detail_id", "room_code"}))
@Getter @Setter
public class HotelRoom {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "hotel_detail_id", nullable = false)
    private HotelDetail hotelDetail;

    @NotBlank
    @Column(nullable = false)
    private String roomName;

    @NotBlank
    @Column(name = "room_code", nullable = false)
    private String roomCode;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RoomType roomType;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Enumerated(EnumType.STRING)
    private BedType bedType;

    @Min(1)
    private Integer bedCount;

    @Min(1)
    private Integer maxAdults;

    @Min(0)
    private Integer maxChildren;

    @Min(1)
    private Integer maxGuests;

    @DecimalMin("0.0")
    private Double roomSizeSqm;

    private Integer floorNumber;

    private boolean smokingAllowed;

    private boolean breakfastIncluded;

    private boolean freeCancellation;

    private boolean instantConfirmation;

    @DecimalMin("0.0")
    @Column(precision = 15, scale = 2)
    private BigDecimal priceFrom;

    @DecimalMin("0.0")
    @Column(precision = 15, scale = 2)
    private BigDecimal originalPrice;

    @Min(0)
    private Integer quantity;

    @Min(0)
    private Integer availableQuantity;

    @Column(nullable = false)
    private boolean active = true;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
