package com.example.planyourtrip.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "hotel_services")
@Getter @Setter
public class HotelService {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "hotel_detail_id", nullable = false)
    private HotelDetail hotelDetail;

    @NotBlank
    @Column(nullable = false)
    private String serviceName;

    private String icon;

    private boolean available;
}
