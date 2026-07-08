package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Entity
@Table(name = "trip_plan_days",
       indexes = {
           @Index(name = "idx_trip_plan_days_trip_plan_id", columnList = "trip_plan_id")
       },
       uniqueConstraints = {
           @UniqueConstraint(name = "uk_trip_plan_day_number", columnNames = {"trip_plan_id", "dayNumber"})
       })
@Getter @Setter
public class TripPlanDay {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "trip_plan_id", nullable = false)
    private TripPlan tripPlan;

    @Column(nullable = false)
    private int dayNumber;

    private LocalDate date;

    private String title;

    @Column(columnDefinition = "TEXT")
    private String notes;
}
