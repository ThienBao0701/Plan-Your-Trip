package com.example.planyourtrip.model;

import com.example.planyourtrip.util.SlugUtils;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Entity
@Table(name = "administrative_units",
    indexes = @Index(name = "idx_au_parent", columnList = "parent_id"))
@Getter @Setter
public class AdministrativeUnit {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_id")
    private AdministrativeUnit parent;

    @Column(unique = true)
    private String code;

    @NotBlank
    @Column(nullable = false)
    private String name;

    @Column(unique = true, nullable = false)
    private String slug;

    @Column(name = "name_normalized")
    private String nameNormalized;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private UnitType type;

    private Integer level;

    private String oldName;

    private String fullPath;

    private Double latitude;

    private Double longitude;

    @Column(name = "sort_order")
    private Integer sortOrder;

    private boolean active = true;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() {
        if (nameNormalized == null && name != null) nameNormalized = SlugUtils.normalize(name);
        createdAt = updatedAt = Instant.now();
    }

    @PreUpdate
    void onUpdate() {
        if (name != null) nameNormalized = SlugUtils.normalize(name);
        updatedAt = Instant.now();
    }
}
