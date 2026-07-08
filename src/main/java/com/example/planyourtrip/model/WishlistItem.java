package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Entity
@Table(name = "wishlist_items",
       indexes = {
           @Index(name = "idx_wishlist_items_wishlist_id", columnList = "wishlist_id"),
           @Index(name = "idx_wishlist_items_place_id", columnList = "place_id")
       },
       uniqueConstraints = {
           @UniqueConstraint(name = "uk_wishlist_item_place", columnNames = {"wishlist_id", "place_id"})
       })
@Getter @Setter
public class WishlistItem {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "wishlist_id", nullable = false)
    private Wishlist wishlist;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "place_id", nullable = false)
    private Place place;

    @Column(length = 500)
    private String note;

    @Column(updatable = false)
    private Instant createdAt;

    @PrePersist
    void onCreate() { createdAt = Instant.now(); }
}
