package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Entity
@Table(name = "customer_profiles",
       indexes = {
           @Index(name = "idx_customer_profiles_user_id", columnList = "user_id", unique = true)
       })
@Getter @Setter
public class CustomerProfile {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", unique = true, nullable = false)
    private User user;

    private String avatarUrl;

    @Column(nullable = false)
    private String preferredLanguage = "en";

    @Column(nullable = false)
    private String preferredCurrency = "VND";

    private String preferredPaymentMethod;

    private String nationality;

    // Deliberately only ever holds a masked value (e.g. "****4567") — the full
    // passport number submitted in a request is never persisted.
    private String passportNumberMasked;

    private String emergencyContactName;

    private String emergencyContactPhone;

    @Column(columnDefinition = "TEXT")
    private String accessibilityNeeds;

    private String dietaryPreference;

    private String travelStyle;

    @Column(nullable = false)
    private boolean marketingConsent = false;

    @Column(nullable = false)
    private boolean profileCompleted = false;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
