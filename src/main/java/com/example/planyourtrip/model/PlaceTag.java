package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "place_tags",
       indexes = @Index(name = "idx_place_tags_place_id", columnList = "place_id"))
@Getter @Setter
public class PlaceTag {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "place_id", nullable = false)
    private Place place;

    @Column(nullable = false, length = 100)
    private String tag;

    @Column(nullable = false, length = 100)
    private String tagNormalized;
}
