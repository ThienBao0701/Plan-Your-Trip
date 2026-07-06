package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "place_metadata")
@Getter
@Setter
public class PlaceMetadata {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id", unique = true, nullable = false)
    private Place place;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "place_metadata_travel_styles",
                     joinColumns = @JoinColumn(name = "metadata_id"))
    @Column(name = "style", length = 20)
    @Enumerated(EnumType.STRING)
    private List<TravelStyle> travelStyles = new ArrayList<>();

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "place_metadata_visit_times",
                     joinColumns = @JoinColumn(name = "metadata_id"))
    @Column(name = "visit_time", length = 20)
    @Enumerated(EnumType.STRING)
    private List<BestVisitTime> bestVisitTimes = new ArrayList<>();

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "place_metadata_seasons",
                     joinColumns = @JoinColumn(name = "metadata_id"))
    @Column(name = "season", length = 20)
    @Enumerated(EnumType.STRING)
    private List<BestSeason> bestSeasons = new ArrayList<>();

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "place_metadata_weather_types",
                     joinColumns = @JoinColumn(name = "metadata_id"))
    @Column(name = "weather_type", length = 20)
    @Enumerated(EnumType.STRING)
    private List<WeatherType> weatherTypes = new ArrayList<>();

    private Integer estimatedVisitMinutes;

    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private BudgetLevel estimatedBudgetLevel;

    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private DifficultyLevel difficultyLevel;

    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private AccessibilityLevel accessibilityLevel;

    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private CrowdLevel crowdLevel;

    private boolean romantic;
    private boolean familyFriendly;
    private boolean kidFriendly;
    private boolean petFriendly;
    private boolean wheelchairFriendly;
    private boolean photographySpot;
    private boolean sunsetSpot;
    private boolean sunriseSpot;
    private boolean indoor;
    private boolean outdoor;
    private boolean rainyDaySuitable;

    @Column(length = 2000)
    private String notes;

    @Column(updatable = false)
    private Instant createdAt;
    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
