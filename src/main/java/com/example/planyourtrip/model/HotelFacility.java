package com.example.planyourtrip.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "hotel_facilities")
@Getter @Setter
public class HotelFacility {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "hotel_detail_id", nullable = false)
    private HotelDetail hotelDetail;

    @NotBlank
    @Column(nullable = false)
    private String facilityName;

    @Enumerated(EnumType.STRING)
    private FacilityGroup facilityGroup;

    private String icon;

    private int sortOrder;
}
