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

    // ── Phase 7.44 — Partner reply (additive; one reply per review, stored in-place) ──
    // A single authorized partner may post exactly one current reply to this review;
    // repeated PUTs update these same fields rather than creating a new row.

    @Column(columnDefinition = "TEXT")
    private String partnerReply;

    /** Set once, when the first reply is created; never changed on subsequent edits. */
    private Instant partnerRepliedAt;

    /** Bumped on every reply save, including edits. */
    private Instant partnerReplyUpdatedAt;

    /** Which partner authored the reply — used to derive the public display (business) name. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "partner_replied_by_profile_id")
    private PartnerProfile partnerRepliedBy;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
