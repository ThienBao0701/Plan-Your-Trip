package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Entity
@Table(name = "reviews",
       indexes = {
           @Index(name = "idx_reviews_booking_id", columnList = "booking_id", unique = true),
           @Index(name = "idx_reviews_user_id",    columnList = "user_id"),
           @Index(name = "idx_reviews_place_id",   columnList = "place_id"),
           @Index(name = "idx_reviews_status",     columnList = "status")
       })
@Getter @Setter
public class Review {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "booking_id", nullable = false, unique = true)
    private Booking booking;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "place_id", nullable = false)
    private Place place;

    @Column(name = "rating_overall", nullable = false)
    private int ratingOverall;

    private Integer ratingCleanliness;

    private Integer ratingService;

    private Integer ratingLocation;

    private Integer ratingValue;

    private Integer ratingFacilities;

    private String title;

    @Column(columnDefinition = "TEXT")
    private String content;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ReviewStatus status = ReviewStatus.PENDING;

    @Column(nullable = false)
    private int helpfulCount = 0;

    @Column(nullable = false)
    private int reportedCount = 0;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    private Instant approvedAt;

    private Instant rejectedAt;

    @Column(columnDefinition = "TEXT")
    private String rejectReason;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
