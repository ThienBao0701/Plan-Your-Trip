package com.example.planyourtrip.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "hotel_details")
@Getter @Setter
public class HotelDetail {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id", unique = true, nullable = false)
    private Place place;

    @Min(1) @Max(5)
    private int starRating;

    @NotNull
    @Column(nullable = false)
    private LocalTime checkInTime;

    @NotNull
    @Column(nullable = false)
    private LocalTime checkOutTime;

    @Min(0)
    private Integer distanceToBeachMeters;

    @Min(0)
    private Integer distanceToCityCenterMeters;

    @Min(0)
    private Integer totalRooms;

    @Min(0)
    private Integer availableRooms;

    private boolean freeCancellation;

    @Column(length = 1000)
    private String cancellationPolicy;

    private boolean prepaymentRequired;

    @Column(length = 1000)
    private String paymentPolicy;

    @Column(length = 500)
    private String childrenPolicy;

    @Column(length = 500)
    private String petPolicy;

    @Column(length = 500)
    private String smokingPolicy;

    private boolean breakfastIncluded;

    private boolean airportShuttle;

    // Languages spoken by staff
    @ElementCollection
    @CollectionTable(name = "hotel_languages",
                     joinColumns = @JoinColumn(name = "hotel_detail_id"))
    @Column(name = "language")
    private List<String> languages = new ArrayList<>();

    // Accepted payment methods
    @ElementCollection
    @CollectionTable(name = "hotel_payment_methods",
                     joinColumns = @JoinColumn(name = "hotel_detail_id"))
    @Column(name = "payment_method")
    private List<String> paymentMethods = new ArrayList<>();

    // Parking
    private boolean parkingAvailable;
    private boolean parkingFree;
    @Column(length = 500)
    private String parkingDescription;

    // Internet
    private boolean wifiAvailable;
    private boolean wifiFree;
    @Column(length = 500)
    private String internetDescription;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
