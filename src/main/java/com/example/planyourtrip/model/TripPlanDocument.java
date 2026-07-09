package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

/**
 * A travel document attached to a trip. Deliberately does NOT store its own
 * url/thumbnail/file-type — it references an existing {@link MediaAsset} row
 * (owner type {@link MediaOwnerType#TRIP_DOCUMENT}), reusing the same upload
 * registration and mapping already built for Place/Room/Review/Submission media
 * rather than duplicating that logic here.
 */
@Entity
@Table(name = "trip_plan_documents",
       indexes = {
           @Index(name = "idx_trip_plan_documents_trip_plan_id", columnList = "trip_plan_id"),
           @Index(name = "idx_trip_plan_documents_trip_plan_day_id", columnList = "trip_plan_day_id"),
           @Index(name = "idx_trip_plan_documents_trip_plan_item_id", columnList = "trip_plan_item_id"),
           @Index(name = "idx_trip_plan_documents_media_asset_id", columnList = "media_asset_id")
       })
@Getter @Setter
public class TripPlanDocument {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "trip_plan_id", nullable = false)
    private TripPlan tripPlan;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trip_plan_day_id")
    private TripPlanDay tripDay;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trip_plan_item_id")
    private TripPlanItem tripItem;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "media_asset_id", nullable = false)
    private MediaAsset mediaAsset;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "uploaded_by_user_id", nullable = false)
    private User uploadedBy;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TripPlanDocumentType documentType;

    private String title;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @Column(nullable = false)
    private boolean pinned = false;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
