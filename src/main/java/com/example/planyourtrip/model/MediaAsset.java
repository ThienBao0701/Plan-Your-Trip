package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;

@Entity
@Table(name = "media_assets",
       indexes = {
           @Index(name = "idx_media_owner", columnList = "owner_type, owner_id"),
           @Index(name = "idx_media_active", columnList = "owner_type, owner_id, active")
       })
@Getter @Setter
public class MediaAsset {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(name = "owner_type", nullable = false, length = 20)
    private MediaOwnerType ownerType;

    @Column(name = "owner_id", nullable = false)
    private Long ownerId;

    @Column(nullable = false, length = 1000)
    private String url;

    @Column(length = 1000)
    private String thumbnailUrl;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private MediaType mediaType;

    @Column(length = 500)
    private String altText;

    private int sortOrder;

    private boolean cover;

    private boolean active;

    @Column(name = "uploaded_by")
    private Long uploadedBy;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() {
        createdAt = updatedAt = Instant.now();
        active = true;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }
}
