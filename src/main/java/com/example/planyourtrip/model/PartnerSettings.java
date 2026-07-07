package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Entity
@Table(name = "partner_settings",
       indexes = {
           @Index(name = "idx_partner_settings_profile_id", columnList = "partner_profile_id", unique = true)
       })
@Getter @Setter
public class PartnerSettings {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "partner_profile_id", unique = true, nullable = false)
    private PartnerProfile partnerProfile;

    @Column(nullable = false)
    private String defaultLanguage = "en";

    @Column(nullable = false)
    private String timezone = "Asia/Ho_Chi_Minh";

    @Column(nullable = false)
    private boolean notificationEmailEnabled = true;

    @Column(nullable = false)
    private boolean notificationSmsEnabled = false;

    @Column(nullable = false)
    private boolean notificationInAppEnabled = true;

    @Column(nullable = false)
    private boolean bookingNotificationEnabled = true;

    @Column(nullable = false)
    private boolean paymentNotificationEnabled = true;

    @Column(nullable = false)
    private boolean reviewNotificationEnabled = true;

    @Column(nullable = false)
    private boolean promotionNotificationEnabled = true;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
