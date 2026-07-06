package com.example.planyourtrip.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalTime;

@Entity
@Table(name = "place_opening_hours",
       indexes = @Index(name = "idx_poh_place_id", columnList = "place_id"))
@Getter @Setter
public class PlaceOpeningHour {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id", nullable = false)
    private Place place;

    @Min(1) @Max(7)
    @Column(nullable = false)
    private int dayOfWeek;

    private LocalTime openTime;

    private LocalTime closeTime;

    private boolean closed;
}
