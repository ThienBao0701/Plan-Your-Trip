package com.example.planyourtrip.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Entity
@Table(name = "partner_profiles",
       indexes = {
           @Index(name = "idx_partner_profiles_user_id", columnList = "user_id", unique = true),
           @Index(name = "idx_partner_profiles_status",  columnList = "verification_status")
       })
@Getter @Setter
public class PartnerProfile {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", unique = true, nullable = false)
    private User user;

    @NotBlank
    @Column(nullable = false)
    private String businessName;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private BusinessType businessType;

    @NotBlank
    @Column(nullable = false)
    private String representativeName;

    @NotBlank
    @Column(nullable = false)
    private String phone;

    @NotBlank
    @Column(nullable = false)
    private String email;

    @NotBlank
    @Column(nullable = false)
    private String address;

    private String taxCode;

    private String website;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PartnerVerificationStatus verificationStatus = PartnerVerificationStatus.DRAFT;

    @Column(columnDefinition = "TEXT")
    private String rejectReason;

    private Instant submittedAt;

    private Instant approvedAt;

    private Instant rejectedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "approved_by")
    private User approvedBy;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
