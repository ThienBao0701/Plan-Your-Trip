package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

/**
 * Join row placing a {@link Place} inside a {@link SavedCollection}, mirroring the
 * {@link WishlistItem} convention.
 *
 * <p>Insertion order is maintained by an explicit {@code position} int assigned at
 * insert time (next = current max + 1), which is the cleanest way to guarantee a
 * stable "maintain insertion order" contract independent of clock resolution.
 *
 * <p>A DB-level unique constraint on {@code (collection_id, place_id)} forbids the same
 * place twice in one collection (an application pre-check produces a clean 409 first).
 *
 * <p>The {@code place} FK is a reference only — no cascade: deleting a collection removes
 * its join rows but NEVER the underlying {@link Place}.
 */
@Entity
@Table(name = "saved_collection_places",
       indexes = {
           @Index(name = "idx_saved_collection_places_collection_id", columnList = "collection_id"),
           @Index(name = "idx_saved_collection_places_place_id", columnList = "place_id")
       },
       uniqueConstraints = {
           @UniqueConstraint(name = "uk_saved_collection_place",
                             columnNames = {"collection_id", "place_id"})
       })
@Getter @Setter
public class SavedCollectionPlace {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "collection_id", nullable = false)
    private SavedCollection collection;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "place_id", nullable = false)
    private Place place;

    /** Insertion position within the collection (0-based, assigned at add time). */
    @Column(nullable = false)
    private int position;

    @Column(updatable = false)
    private Instant createdAt;

    @PrePersist
    void onCreate() { createdAt = Instant.now(); }
}
