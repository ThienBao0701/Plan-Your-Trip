package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

/**
 * A customer's named list of saved {@link Place}s — the Google-Maps-Lists /
 * Airbnb-wishlists model. A single user owns MANY of these (e.g. "Japan 2027",
 * "Honeymoon", "Beaches"), which is what distinguishes Saved Collections from the
 * existing {@link Wishlist} (one flat list per user — {@code user_id UNIQUE}).
 * The two features coexist and are entirely separate.
 *
 * <p><b>Naming:</b> the product spec calls this "Collection", but a JPA {@code @Entity}
 * named {@code Collection} would clash constantly with the ubiquitous
 * {@link java.util.Collection}. The entity is therefore named {@code SavedCollection}
 * while the public API paths (/api/me/collections) and DTO names keep the spec's
 * "Collection" wording.
 *
 * <p><b>Privacy:</b> {@code privateCollection} defaults to {@code true} (private is the
 * safe default). It is stored for a future public-sharing phase — in THIS phase every
 * endpoint is owner-scoped (/api/me/**), so no one can view another user's collection
 * regardless of the flag.
 */
@Entity
@Table(name = "saved_collections",
       indexes = {
           @Index(name = "idx_saved_collections_owner_id", columnList = "owner_id")
       })
@Getter @Setter
public class SavedCollection {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "owner_id", nullable = false)
    private User owner;

    @Column(nullable = false)
    private String name;

    @Column(length = 1000)
    private String description;

    /** Plain URL string per spec — deliberately NOT a Media entity. */
    @Column(length = 2048)
    private String coverImageUrl;

    @Column(nullable = false)
    private boolean privateCollection = true;

    /** User-orderable ordering of collections in the customer's list. */
    @Column(nullable = false)
    private int sortOrder = 0;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
