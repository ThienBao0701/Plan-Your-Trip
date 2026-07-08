package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Entity
@Table(name = "recently_viewed_places",
       indexes = {
           @Index(name = "idx_recently_viewed_user_id", columnList = "user_id"),
           @Index(name = "idx_recently_viewed_viewed_at", columnList = "viewedAt")
       },
       uniqueConstraints = {
           @UniqueConstraint(name = "uk_recently_viewed_user_place", columnNames = {"user_id", "place_id"})
       })
@Getter @Setter
public class RecentlyViewedPlace {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "place_id", nullable = false)
    private Place place;

    @Column(nullable = false)
    private Instant viewedAt;

    @PrePersist
    void onCreate() {
        if (viewedAt == null) viewedAt = Instant.now();
    }
}
